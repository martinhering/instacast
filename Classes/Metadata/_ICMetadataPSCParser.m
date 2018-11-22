//
//  _ICMetadataPSCParser.m
//  InstacastMac
//
//  Created by Martin Hering on 26.06.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>

#import "_ICMetadataPSCParser.h"

@interface _ICMetadataPSCParser () <NSXMLParserDelegate>
@property (nonatomic, strong) NSData* data;
@property (strong) ICMetadataAsset* metadataAsset;
@end

@implementation _ICMetadataPSCParser  {
    NSMutableString*        _elementContent;
	NSMutableDictionary*    _elementAttributes;
    NSString*               _xmlPath;
    BOOL                    _elementOpen;
    
    NSMutableArray*         _chapters;
    NSMutableArray*         _images;
}

- (id) initWithData:(NSData*)data metadataAsset:(ICMetadataAsset*)metadataAsset
{
    if (self = [self init]) {
        _data = data;
        _metadataAsset = metadataAsset;
    }
    
    return self;
}


- (void) _loadData:(NSData*)data completionHandler:(ICMetadataCompletionHandler)completionHandler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        _xmlPath = @"/";
        _elementAttributes = [[NSMutableDictionary alloc] init];
        
        _elementContent = [[NSMutableString alloc] init];
        [_elementContent setString:@""];
        
        NSXMLParser* parser = [[NSXMLParser alloc] initWithData:data];
        [parser setDelegate:self];
        BOOL success = [parser parse];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                self.metadataAsset.chapters = _chapters;
                self.metadataAsset.images = _images;
                completionHandler(success, [parser parserError]);
            }
        });
    });
}

- (void) loadAsynchronouslyWithCompletionHandler:(ICMetadataCompletionHandler)completionHandler
{
    if (self.data) {
        [self _loadData:self.data completionHandler:completionHandler];
    }
}

#pragma mark - NSXMLParser delegate

static NSTimeInterval ParsedPodloveTime(NSString* time)
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


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributes
{
    /*
	if (self.canceled) {
		[parser abortParsing];
		return;
	}
     */
    
    elementName = [elementName lowercaseString];
    
	_xmlPath = [_xmlPath stringByAppendingPathComponent:elementName];
	if (attributes) {
		[_elementAttributes setObject:attributes forKey:_xmlPath];
	}
    
    //DebugLog(@"open %@", self.xmlPath);
	
	_elementOpen = YES;
	[_elementContent setString:@""];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	//NSString* elementContent = [_elementContent copy];
	NSDictionary* attributes = [_elementAttributes objectForKey:_xmlPath];
    elementName = [elementName lowercaseString];
    
    
    if ([elementName isEqualToString:@"psc:chapter"] && attributes[@"start"])
    {
        NSString* startAttribute = attributes[@"start"];
        NSString* titleAttribute = attributes[@"title"];
        NSString* hrefAttribute = attributes[@"href"];
        NSString* imageAttribute = attributes[@"image"];
        
        ICMetadataChapter* chapter = [ICMetadataChapter new];
        chapter.start = CMTimeMake((int64_t)(ParsedPodloveTime(startAttribute)*1000.f), 1000LL) ;
        chapter.title = (titleAttribute) ? titleAttribute : nil;
        chapter.link = (hrefAttribute) ? [NSURL URLWithString:hrefAttribute] : nil;

        if (!_chapters) {
            _chapters = [NSMutableArray new];
        }
        [_chapters addObject:chapter];
        
        
        if (imageAttribute)
        {
            ICMetadataImage* image = [ICMetadataImage new];
            image.url = [NSURL URLWithString:imageAttribute];
            image.start = CMTimeMake((int64_t)(ParsedPodloveTime(startAttribute)*1000.f), 1000LL) ;
            
            if (!_images) {
                _images = [NSMutableArray new];
            }
            [_images addObject:image];
        }
    }
    
    
	_elementOpen = NO;
	[_elementAttributes removeObjectForKey:_xmlPath];
	_xmlPath = [_xmlPath stringByDeletingLastPathComponent];
	
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if (_elementOpen) {
		[_elementContent appendString:string];
	}
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    
}
@end
