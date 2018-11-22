//
//  ICFeedParser.h
//  ICFeedParser
//
//  Created by Martin Hering on 23.12.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ICFeed.h"
#import "ICCategory.h"
#import "ICEpisode.h"
#import "ICMedia.h"
#import "ICChapter.h"

@class ICFeed;
@protocol ICFeedParserDelegate;

@interface ICFeedParser : VMHTTPOperation <NSXMLParserDelegate>

+ (ICFeedParser*) feedParser;

@property (weak) id<ICFeedParserDelegate> delegate;
@property BOOL presentAlternateFeeds;
@property BOOL dontAskForCredentials;
@property BOOL allowsCellularAccess;

@property (strong) NSURL* url;
@property (strong) NSString* etag;
@property (strong) id userInfo;
@property (readonly) NSUInteger feedLength;
@property (weak, readonly) NSArray* alternatives;

// only parses xml if fetched data hash is different
@property (strong) NSString* dataHash;

+ (ICFeed*) parsedFeedWithURL:(NSURL*)url;
+ (ICFeed*) parsedFeedWithURL:(NSURL*)url error:(NSError**)error;

- (ICFeed*) parsedFeedReturningError:(NSError**)error;

@property (copy) void (^didParseFeedBlock)(ICFeed* feed);
@property (copy) void (^didEndWithError)(NSError* error);

@end

@protocol ICFeedParserDelegate <NSObject>
@optional
- (void) feedParser:(ICFeedParser*)feedParser willParseFeedWithURL:(NSURL*)url;
- (void) feedParser:(ICFeedParser*)feedParser didParseFeed:(ICFeed*)feed;
- (void) feedParser:(ICFeedParser*)feedParser didEndWithError:(NSError*)error;
- (void) feedParserDidCancel:(ICFeedParser*)feedParser;

// return feed index or NSNotFound
// called is returned from asynchronous background thread
- (NSUInteger) feedParser:(ICFeedParser*)feedParser shouldSwitchOneOfTheAlternativeFeeds:(NSArray*)alternativeFeeds feed:(ICFeed*)feed;
@end