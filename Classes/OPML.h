//
//  OPMLParser.h
//  Countdown
//
//  Created by Jochen Schöllig on 21.03.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* OPMLFeedTitle;
extern NSString* OPMLFeedType;
extern NSString* OPMLFeedXmlUrl;
extern NSString* OPMLFeedHtmlUrl;

@interface OPMLParser : NSObject
+ (OPMLParser*) opmlParserWithData:(NSData*)data;
@property (readonly, strong) NSData* data;

- (void) parseWithCompletionHandler:(void (^)(NSArray* feeds))completion errorHandler:(void (^)(NSError* error))errorHandler;
@end

#pragma mark -

@interface OPMLWriter : NSObject
+ (OPMLWriter*) opmlWriterWithFeeds:(NSArray*)array;
- (NSData*) dataWithTitle:(NSString*)title;
@end
