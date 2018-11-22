//
//  SubscriptionManager.h
//  Instacast
//
//  Created by Martin Hering on 30.12.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* SubscriptionManagerWillStartRefreshingFeedsNotification;
extern NSString* SubscriptionManagerDidStartRefreshingFeedsNotification;
extern NSString* SubscriptionManagerWillParseFeedNotification;
extern NSString* SubscriptionManagerDidParseFeedNotification;       // userinfo "feed": CDFeed object
extern NSString* SubscriptionManagerDidAddEpisodesNotification;
extern NSString* SubscriptionManagerDidFinishRefreshingFeedsNotification;

@class CDFeed;
@class CDEpisode;
@class ICFeed;

typedef void(^ICSubscriptionManagerRefreshCompletionBlock)(BOOL success, NSArray* newEpisodes, NSError* error);

@interface SubscriptionManager : NSObject

+ (SubscriptionManager*) sharedSubscriptionManager;

- (CDFeed*) subscribeParserFeed:(ICFeed*)parserFeed;
- (CDFeed*) subscribeParserFeed:(ICFeed*)parserFeed autodownload:(BOOL)autodownload options:(ICSubscribeOptions)options;
- (void) unsubscribeFeed:(CDFeed*)feed;

- (void) reloadContentOfFeed:(CDFeed*)feed recoverArchivedEpisodes:(BOOL)recoverArchived completion:(ICSubscriptionManagerRefreshCompletionBlock)completion;
- (void) subscribeFeedWithURL:(NSURL*)url options:(ICSubscribeOptions)options completion:(void (^)(CDFeed* feed, NSError* error))completion;

@property (nonatomic, readonly) NSString* formattedLastRefreshDate;
- (NSString*) formattedLastRefreshDateForFeed:(CDFeed*)feed;

- (void) refreshAllFeedsForce:(BOOL)force;
- (void) refreshAllFeedsForce:(BOOL)force completion:(ICSubscriptionManagerRefreshCompletionBlock)handler;
- (void) refreshAllFeedsForce:(BOOL)force etagHandling:(BOOL)etagHandling completion:(ICSubscriptionManagerRefreshCompletionBlock)handler;

- (void) refreshFeeds:(NSArray*)feeds etagHandling:(BOOL)etagHandling completion:(ICSubscriptionManagerRefreshCompletionBlock)handler;

//- (void) callbackWhenRefreshCompleted:(void(^)())handler;
- (void) updateLocalFeedInfo:(CDFeed*)localFeed withRemoteFeed:(ICFeed*)remoteFeed force:(BOOL)force;

@property (nonatomic, readonly, getter=isRefreshing) BOOL refreshing;
@property (nonatomic, readonly, strong) NSMutableArray* refreshingFeedURLs;
@property (nonatomic, readonly, assign) double refreshProgress;
@property (nonatomic, readonly, strong) NSURL* refreshedURL;

/* Enforcing Download Settings */
- (BOOL) autoDownloadEpisodesInFeed:(CDFeed*)feed;
- (BOOL) autoDownloadEpisode:(CDEpisode*)episode;
- (void) autoDownloadAllFeedsAsynchronously;

/* Importing */

- (void) importURL:(NSURL*)url completion:(void (^)())completion;
- (void) importOPMLData:(NSData*)data completion:(void (^)())completion;

- (NSData*) opmlData;

@end
