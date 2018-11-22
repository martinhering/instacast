//
//  OPMLParser.m
//  Countdown
//
//  Created by Jochen Schöllig on 21.03.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import "OPML.h"

NSString* OPMLFeedTitle = @"text";
NSString* OPMLFeedType = @"type";
NSString* OPMLFeedXmlUrl = @"xmlUrl";
NSString* OPMLFeedHtmlUrl = @"htmlUrl";

@interface OPMLParser () <NSXMLParserDelegate>
@property (readwrite, strong) NSMutableArray* feeds;
@property (readwrite, strong) NSData* data;
@end


@implementation OPMLParser

+ (OPMLParser*) opmlParserWithData:(NSData*)data
{
	OPMLParser* parser = [[self alloc] init];
	parser.data = data;
	return parser;
}


- (id) init
{
	if ((self = [super init]))
	{
		_feeds = [[NSMutableArray alloc] init];
	}
	
	return self;
}



- (void) parseWithCompletionHandler:(void (^)(NSArray* feeds))completion errorHandler:(void (^)(NSError* error))errorHandler
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSData* data = self.data;
        
        NSString* utf8String = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (!utf8String) {
            utf8String = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
            data = [utf8String dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        }
        
        NSXMLParser* xmlParser = [[NSXMLParser alloc] initWithData:data];
        [xmlParser setDelegate:self];
        [xmlParser parse];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError* opmlError = [xmlParser parserError];

            if (completion && [self.feeds count] > 0)
            {
                completion(self.feeds);
            }
            else if (opmlError && errorHandler) {
                errorHandler(opmlError);
            }
        });
    });
}

#pragma mark -
#pragma mark NSXMLParserDelegate


- (void)parserDidStartDocument:(NSXMLParser *)parser 
{
	
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"opml"]) 
	{
		NSString* opmlVersion = [attributeDict objectForKey:@"version"];
		if (!opmlVersion || ![opmlVersion isEqualToString:@"1.0"]) {
            
		}
	}
	
	if ([elementName isEqualToString:@"outline"])
	{
		[self.feeds addObject:attributeDict];
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

#pragma mark -

@interface OPMLWriter () 
@property (readwrite, strong) NSArray* feeds;
@end


@implementation OPMLWriter

@synthesize feeds;

- (id) init
{
	self = [super init];
	if (self != nil) {
		feeds = [[NSMutableArray alloc] init];
	}
	return self;
}


+ (OPMLWriter*) opmlWriterWithFeeds:(NSArray*)array
{
	OPMLWriter* writer = [[self alloc] init];
	writer.feeds = array;
	return writer;
}

- (NSData*) dataWithTitle:(NSString*)title
{
	NSString* xmlHeader = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
	NSString* opmlHeader = @"<opml version=\"1.0\">";
	NSString* endOpml = @"</opml>";
	
	NSString* startHead = @"<head>";
	NSString* endHead = @"</head>";
	NSString* startBody = @"<body>";
	NSString* endBody = @"</body>";

	NSString* titleHeader = [NSString stringWithFormat:@"\t<title>%@</title>", (title)?[title stringByEncodingStandardHTMLEntities]:@""];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	[dateFormatter setLocale:locale];
	[dateFormatter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss"];
	[dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
	NSString* dateString = [[dateFormatter stringFromDate:[NSDate date]] stringByAppendingString:@" GMT"];
	
	NSString* dateCreated = [NSString stringWithFormat:@"\t<dateCreated>%@</dateCreated>", dateString];
	NSString* dateModified = [NSString stringWithFormat:@"\t<dateModified>%@</dateModified>", dateString];
	
	NSMutableString* content = [NSMutableString string];
	
	for (NSDictionary* dict in self.feeds)
	{
		[content appendFormat:@"\n\t<outline text=\"%@\" type=\"%@\" xmlUrl=\"%@\"",
			[[dict objectForKey:OPMLFeedTitle] stringByEncodingStandardHTMLEntities], 
			[dict objectForKey:OPMLFeedType], 
			[[dict objectForKey:OPMLFeedXmlUrl] stringByEncodingStandardHTMLEntities]];
		
		if ([dict objectForKey:OPMLFeedHtmlUrl])
		{
			[content appendFormat:@" htmlUrl=\"%@\" />", [[dict objectForKey:OPMLFeedHtmlUrl] stringByEncodingStandardHTMLEntities]];
		} else {
			[content appendString:@" />"];
		}
		
	}
	
	NSString* fullXmlString = [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@%@\n%@\n%@\n", xmlHeader, opmlHeader, startHead, titleHeader, dateCreated, dateModified, endHead, startBody, content, endBody, endOpml];
	return [fullXmlString dataUsingEncoding:NSUTF8StringEncoding];
}


@end
