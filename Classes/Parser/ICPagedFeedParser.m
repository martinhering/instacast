//
//  ICPagedFeedParser.m
//  InstacastMac
//
//  Created by Martin Hering on 12.04.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import "ICPagedFeedParser.h"
#import "ICFeedParser.h"

@interface ICPagedFeedParser () <ICFeedParserDelegate>
@property (strong, readwrite) NSMutableDictionary* alternateFeedData;
@end

@implementation ICPagedFeedParser

- (id) init
{
    if ((self = [super init])) {
        _allowsCellularAccess = YES;
    }
    
    return self;
}

- (void) _endWithFeed:(ICFeed*)feed error:(NSError*)error
{
    // remove etag, because it might be wrong
    feed.etag = nil;
    feed.firstPageURL = nil;
    feed.prevPageURL = nil;
    feed.lastPageURL = nil;
    feed.nextPageURL = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([self isCancelled]) {
            if (self.didCancel) {
                self.didCancel();
            }
        }
        
        else if (!feed) {
            if (self.didEndWithError) {
                self.didEndWithError(error);
            }
        }
        
        else {
            if (self.didParseFeedBlock) {
                self.didParseFeedBlock(feed);
            }
        }
    });
}

- (void) main
{
    @autoreleasepool {
        
        NSError* error;
        ICFeed* feed;
        ICFeed* feedOnFirstPage;
        NSInteger loops = 0;
        NSInteger page = 1;
        ICFeedParser* parser;
        
    start:

        parser = [ICFeedParser feedParser];
        parser.username = self.username;
        parser.password = self.password;
        parser.url = self.url;
        parser.presentAlternateFeeds = YES;
        parser.delegate = self;
        parser.dontAskForCredentials = self.dontAskForCredentials;
        parser.allowsCellularAccess = self.allowsCellularAccess;
        
        DebugLog(@"%@", self.url);
        
        feed = [parser parsedFeedReturningError:&error];
        
        // bail if feed is not paged
        if (error || !feed.firstPageURL || !feed.lastPageURL) {
            if (error) {
                ErrLog(@"error parsing feed: %@", error);
            }
            [self _endWithFeed:feed error:error];
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.didParsePage) {
                self.didParsePage(page);
            }
        });
        page++;
        
        NSURL* feedURL = (feed.changedSourceURL) ? feed.changedSourceURL : feed.sourceURL;
        
        // go to first page first
        if (![feedURL isEqual:feed.firstPageURL]) {
            
            if (loops == 0) {            
                self.url = feed.firstPageURL;
                feed = nil;
                loops++;
                goto start;
            }

            ErrLog(@"feed paging generates a loop, bailing.");
            [self _endWithFeed:feed error:error];
            return;
        }
        
        // we're on the first page already
        else
        {
            feedOnFirstPage = feed;
            NSURL* nextFeedURL = feedOnFirstPage.nextPageURL;

            do
            {
                DebugLog(@"%@", nextFeedURL);
                
                error = nil;
                feed = [ICFeedParser parsedFeedWithURL:nextFeedURL error:&error];
                
                if (error) {
                    break;
                }
                
                // merge episodes
                NSMutableArray* episodes = [feedOnFirstPage.episodes mutableCopy];
                
                for(ICEpisode* episode in feed.episodes) {
                    if (![episodes containsObject:episode]) {
                        [episodes addObject:episode];
                    }
                }
                
                feedOnFirstPage.episodes = episodes;
                
                if (![nextFeedURL isEqual:feed.nextPageURL]) {
                    nextFeedURL = feed.nextPageURL;
                } else {
                    nextFeedURL = nil;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.didParsePage) {
                        self.didParsePage(page);
                    }
                });
                page++;
                
                
            } while (nextFeedURL);
            
            
            [self _endWithFeed:feedOnFirstPage error:error];
            return;
        }
        
        ErrLog(@"end without callback?");
    };
}

#pragma mark -

- (NSUInteger) feedParser:(ICFeedParser*)feedParser shouldSwitchOneOfTheAlternativeFeeds:(NSArray*)alternativeFeeds feed:(ICFeed*)feed
{
    if (!self.alternateFeedData) {
        self.alternateFeedData = [[NSMutableDictionary alloc] init];
    }
    
    for(NSDictionary* feedData in alternativeFeeds) {
        NSString* href = feedData[@"href"];
        if (href) {
            self.alternateFeedData[href] = feedData;
        }
    }
    
    return NSNotFound;
}
@end
