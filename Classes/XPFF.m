//
//  XPFF.m
//  Instacast
//
//  Created by Martin Hering on 11.04.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import "XPFF.h"
#import "CDBookmark.h"


NSTimeInterval ParsedPodloveTime(NSString* time);

NSTimeInterval ParsedPodloveTime(NSString* time)
{
    NSString* timeWithoutMilliseconds = nil;
    
    NSString* hours = nil;
    NSString* minutes = nil;
    NSString* seconds = nil;
    NSString* milliseconds = nil;
    
    // split up milliseconds
    NSArray* timeComponents1 = [time componentsSeparatedByString:@"."];

    if ([timeComponents1 count] == 1) {
        timeWithoutMilliseconds = time;
    }
    else if ([timeComponents1 count] > 1) {
        timeWithoutMilliseconds = [timeComponents1 objectAtIndex:0];
        milliseconds = [timeComponents1 objectAtIndex:0];
    }
    
    NSArray* timeComponents2 = [timeWithoutMilliseconds componentsSeparatedByString:@":"];
    if ([timeComponents2 count] == 1) {
        seconds = timeWithoutMilliseconds;
    }
    else if ([timeComponents2 count] == 2) {
        minutes = [timeComponents2 objectAtIndex:0];
        seconds = [timeComponents2 objectAtIndex:1];
    }
    else if ([timeComponents2 count] > 2) {
        hours = [timeComponents2 objectAtIndex:0];
        minutes = [timeComponents2 objectAtIndex:1];
        seconds = [timeComponents2 objectAtIndex:2];
    }
    
    NSInteger h = [hours integerValue];
    NSInteger m = [minutes integerValue];
    NSInteger s = [seconds integerValue];
    NSInteger ms = [milliseconds integerValue];
    
    return h*3600+m*60+s+ms/1000.f;
}

@interface XPFFParserDelegate : NSObject <NSXMLParserDelegate> {
    NSString* _episodeTitle;
    NSString* _episodeGuid;
    NSString* _feedTitle;
    NSURL* _feedURL;
    NSURL* _feedImageURL;
}
@property (nonatomic, strong) NSMutableArray* bookmarks;
@end

@implementation XPFFParserDelegate

- (id) init
{
    if ((self = [super init])) {
        _bookmarks = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)parserDidStartDocument:(NSXMLParser *)parser 
{
	
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{	
	if ([elementName isEqualToString:@"podmarks"]) 
	{
		NSString* version = [attributeDict objectForKey:@"version"];
        
		if (!version || ![version isEqualToString:@"1.0"]) {
            ErrLog(@"xpff: version not 1.0");
		}
    }
    
	if ([elementName isEqualToString:@"episode"]) 
	{
        _episodeTitle = [attributeDict objectForKey:@"title"];
        
        _episodeGuid = [attributeDict objectForKey:@"guid"];
	}
    
    if ([elementName isEqualToString:@"source"]) 
	{
        _feedTitle = [attributeDict objectForKey:@"title"];
        
        NSString* url = [attributeDict objectForKey:@"url"];
        _feedURL = [NSURL URLWithString:url];
        
        NSString* imageUrl = [attributeDict objectForKey:@"image"];
        _feedImageURL = [NSURL URLWithString:imageUrl];
	}
	
	if ([elementName isEqualToString:@"mark"])
	{
		NSString* title = [attributeDict objectForKey:@"title"];
        NSString* timeStr = [attributeDict objectForKey:@"time"];
        NSTimeInterval time = ParsedPodloveTime(timeStr);
        
        CDBookmark* bookmark = [NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:DMANAGER.objectContext];
        bookmark.episodeHash = [[NSString stringWithFormat:@"%@%@", [_feedURL absoluteString], _episodeGuid] MD5Hash];
        bookmark.title = title;
        bookmark.position = time;
        bookmark.feedTitle = _feedTitle;
        bookmark.feedURL = _feedURL;
        bookmark.imageURL =_feedImageURL;
        bookmark.episodeTitle = _episodeTitle;
        bookmark.episodeGuid = _episodeGuid;
        
        [self.bookmarks addObject:bookmark];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{	
	// Noch keine Verwendung	
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	// Noch keine Verwendung
}

- (void)parserDidEndDocument:(NSXMLParser *)parser 
{
    
}


@end


NSData* XPFFDataWithBookmarks(NSArray* bookmarks)
{
    return XPFFDataWithBookmarksFilterHashes(bookmarks, nil);
}

NSData* XPFFDataWithBookmarksFilterHashes(NSArray* bookmarks, NSSet* filterHashes)
{
    NSMutableString* xpff = [NSMutableString string];
    [xpff appendString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"];
	[xpff appendString:@"<podmarks version=\"1.0\" xmlns=\"http://vemedio.com/podmarks\">\n"];
	

    NSMutableDictionary* bookmarkIndex = [[NSMutableDictionary alloc] init];
    
    for(CDBookmark* bookmark in DMANAGER.bookmarks)
    {
        NSMutableArray* groupedBookmarks = bookmarkIndex[bookmark.episodeHash];
        if (!groupedBookmarks) {
            groupedBookmarks = [[NSMutableArray alloc] init];
            bookmarkIndex[bookmark.episodeHash] = groupedBookmarks;
        }
        
        [groupedBookmarks addObject:bookmark];
    }
    
    for(NSString* episodeHash in bookmarkIndex)
    {
        if (filterHashes && ![filterHashes containsObject:episodeHash]) {
            continue;
        }

        NSArray* bookmarks = bookmarkIndex[episodeHash];
        
        CDBookmark* bookmark = [bookmarks lastObject];
        [xpff appendFormat:@"\t<episode title=\"%@\" guid=\"%@\">\n", [bookmark.episodeTitle stringByEncodingStandardHTMLEntities], [bookmark.episodeGuid stringByEncodingStandardHTMLEntities]];
        
        NSURL* imageURL = bookmark.imageURL;
        if (imageURL) {
            [xpff appendFormat:@"\t\t<source title=\"%@\" url=\"%@\" image=\"%@\" />\n", [bookmark.feedTitle stringByEncodingStandardHTMLEntities], [[bookmark.feedURL absoluteString] stringByEncodingStandardHTMLEntities], imageURL];
        } else {
            [xpff appendFormat:@"\t\t<source title=\"%@\" url=\"%@\" />\n", [bookmark.feedTitle stringByEncodingStandardHTMLEntities], [[bookmark.feedURL absoluteString] stringByEncodingStandardHTMLEntities]];
        }
        
        for(CDBookmark* bookmark in bookmarks)
        {
            NSInteger t = bookmark.position;
            NSString* time = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)t/3600, (long)(t/60)%60, (long)t%60];
            [xpff appendFormat:@"\t\t<mark title=\"%@\" time=\"%@\" />\n", [bookmark.title stringByEncodingStandardHTMLEntities], time];
        }
        
        [xpff appendString:@"\t</episode>\n"];

    }
    
    [xpff appendString:@"</podmarks>\n"];
    
    return [xpff dataUsingEncoding:NSUTF8StringEncoding];
}

BOOL XPFFImportData(NSData* data, void(^completion)(NSArray* bookmarks, NSError* error))
{
    if (!completion) {
        return NO;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
       
        XPFFParserDelegate* delegate = [[XPFFParserDelegate alloc] init];
        
        NSXMLParser* parser = [[NSXMLParser alloc] initWithData:data];
        parser.delegate = delegate;
        
        BOOL result = [parser parse];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion((result)?delegate.bookmarks:nil, [parser parserError]);
            }
        });
    });

    return YES;
}