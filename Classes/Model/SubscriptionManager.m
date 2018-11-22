//
//  SubscriptionManager.m
//  Instacast
//
//  Created by Martin Hering on 30.12.10.
//  Copyright 2010 Vemedio. All rights reserved.
//


#import "ICFeedParser.h"
#import "ICPagedFeedParser.h"

#import "OPML.h"
#import "CDModel.h"
#import "CDFeed+Helper.h"
#import "CDEpisode+ShowNotes.h"

NSString* SubscriptionManagerWillStartRefreshingFeedsNotification = @"SubscriptionManagerWillStartRefreshingFeedsNotification";
NSString* SubscriptionManagerDidStartRefreshingFeedsNotification = @"SubscriptionManagerDidStartRefreshingFeedsNotification";
NSString* SubscriptionManagerDidFinishRefreshingFeedsNotification = @"SubscriptionManagerDidFinishRefreshingFeedsNotification";

NSString* SubscriptionManagerWillParseFeedNotification = @"SubscriptionManagerWillParseFeedNotification";
NSString* SubscriptionManagerDidParseFeedNotification = @"SubscriptionManagerDidParseFeedNotification";
NSString* SubscriptionManagerDidAddEpisodesNotification = @"SubscriptionManagerDidAddEpisodesNotification";

static SubscriptionManager* gSharedSubscriptionManager = nil;

@interface SubscriptionManager ()
@property (nonatomic, readwrite, strong) NSMutableArray* refreshingFeedURLs;
@property (nonatomic, readwrite, strong) NSMutableArray* refreshedFeeds;
@property (nonatomic, readwrite, weak) NSTimer* refreshCheckTimer;
@property (nonatomic, readwrite, strong) NSURL* refreshedURL;

@property (nonatomic) NSInteger numOfNewEpisodesAfterRefresh;
@property (nonatomic) NSInteger numTotalRefreshFeeds;
//@property (nonatomic, copy) void (^refreshCompletionHandler)(BOOL success, BOOL newData);
@property BOOL importing;
@property (nonatomic, strong) NSOperationQueue* parserQueue;

#if TARGET_OS_IPHONE
@property (nonatomic) UIBackgroundTaskIdentifier backgroundIdentifier;
#else
@property (nonatomic, strong) NSTimer* checkTimer;
#endif

@end



@implementation SubscriptionManager {
    struct {
        unsigned int refreshFailed;
    } _flags;
}

+ (SubscriptionManager*) sharedSubscriptionManager
{
	if (!gSharedSubscriptionManager) {
		gSharedSubscriptionManager = [self alloc];
		gSharedSubscriptionManager = [gSharedSubscriptionManager init];
	}
	return gSharedSubscriptionManager;
}

- (id) init
{
	if ((self = [super init]))
	{
		_refreshingFeedURLs = [[NSMutableArray alloc] init];
        
        _parserQueue = [[NSOperationQueue alloc] init];
        [_parserQueue setMaxConcurrentOperationCount:2];
        
#if TARGET_OS_IPHONE==0
        _checkTimer = [NSTimer scheduledTimerWithTimeInterval:5*60 block:^(NSTimeInterval time) {
            [self refreshAllFeedsForce:NO];
        } repeats:YES];
#endif
	}
	
	return self;
}

- (NSString*) formattedLastRefreshDate
{
    double lastRefreshDate = [USER_DEFAULTS doubleForKey:LastRefreshSubscriptionDate];
    NSDate* date = (lastRefreshDate > 0) ? [NSDate dateWithTimeIntervalSince1970:lastRefreshDate] : nil;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    NSString* formattedDate = [NSString stringWithFormat:@"Last Updated: %@".ls, [formatter stringFromDate:date]];
    return formattedDate;
}

- (NSString*) formattedLastRefreshDateForFeed:(CDFeed*)feed
{
    if (feed.lastUpdate) {
    
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterShortStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        NSString* formattedDate = [NSString stringWithFormat:@"Last Updated: %@".ls, [formatter stringFromDate:feed.lastUpdate]];
        return formattedDate;
    }
    
    return [self formattedLastRefreshDate];
}

- (CDFeed*) subscribeParserFeed:(ICFeed*)parserFeed
{
    return [self subscribeParserFeed:parserFeed autodownload:YES options:kSubscribeOptionNone];
}

- (CDFeed*) subscribeParserFeed:(ICFeed*)parserFeed autodownload:(BOOL)autodownload options:(ICSubscribeOptions)options
{
    if (parserFeed.changedSourceURL) {
        parserFeed.sourceURL = parserFeed.changedSourceURL;
    }
    
    CDFeed* subscribedFeed = [DMANAGER subscribeFeed:parserFeed withOptions:options];
    if (autodownload && !subscribedFeed.parked) {
        [self autoDownloadEpisodesInFeed:subscribedFeed];
    }
    return subscribedFeed;
}

- (void) unsubscribeFeed:(CDFeed*)feed
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    AudioSession* session = [AudioSession sharedAudioSession];
    
    if ([pman.playingEpisode.feed isEqual:feed]) {
        [session stop];
    }
    
    
    // remove cache
    CacheManager* cman = [CacheManager sharedCacheManager];
    [cman removeCacheForFeed:feed automatic:NO];
    [cman resetAutoCacheForFeed:feed];
    
    // remove from Up Next
    [[AudioSession sharedAudioSession] eraseEpisodesFromUpNext:[feed.episodes allObjects]];
    
    [DMANAGER unsubscribeFeed:feed];
}

- (void) reloadContentOfFeed:(CDFeed*)feed recoverArchivedEpisodes:(BOOL)recoverArchived completion:(ICSubscriptionManagerRefreshCompletionBlock)completion
{    
    NSURL* sourceURL = feed.sourceURL;
    ICPagedFeedParser* parser = [[ICPagedFeedParser alloc] init];
    parser.url = sourceURL;
    parser.username = feed.username;
    parser.password = feed.password;
    parser.allowsCellularAccess = [USER_DEFAULTS boolForKey:EnableRefreshingOver3G];
    parser.didParseFeedBlock = ^(ICFeed* parserFeed) {
        
        NSArray* newEpisodes = [self _mergeLocalFeed:feed withWithRemoteFeed:parserFeed force:YES];

        // delete cached chapters
        for(CDEpisode* episode in feed.episodes) {
            NSSet* chapters = [episode.chapters copy];
            for(NSManagedObject* chapter in chapters) {
                [DMANAGER.objectContext deleteObject:chapter];
            }
            
            // recover all deleted episodes
            if (recoverArchived) {
                episode.archived = NO;
            }
            
//                // recreate object hashes, important for sync
//                [episode reconstructObjectHash];
        }
        
        if (![feed boolForKey:kDefaultShowUnavailableEpisodes]) {
            [self _deleteUnavailableEpisodesFromFeed:feed withRemoteFeed:parserFeed];
        }
        
        if ([newEpisodes count] > 0 && [feed boolForKey:AutoDeleteNewsMode]) {
            [self _recycleOldEpisodesInNewsModeFeed:feed];
        }

        [DMANAGER saveAndSync:YES];
        
        if (completion) {
            completion(YES ,newEpisodes, nil);
        }
    };
    parser.didEndWithError = ^(NSError* error) {

        if (completion) {
            completion(NO, nil, error);
        }
    };
    
    [_parserQueue addOperation:parser];
}

- (void) subscribeFeedWithURL:(NSURL*)url options:(ICSubscribeOptions)options completion:(void (^)(CDFeed* feed, NSError* error))completion
{
    if (!url) {
        return;
    }
    
    [App retainNetworkActivity];

    DebugLog(@"subscribing with URL: %@", url);
    
    ICFeedParser* parser = [[ICFeedParser alloc] init];
    parser.url = url;
    parser.allowsCellularAccess = [USER_DEFAULTS boolForKey:EnableRefreshingOver3G];
    parser.didParseFeedBlock = ^(ICFeed* parserFeed) {
        
        CDFeed* persistentFeed = [self subscribeParserFeed:parserFeed
                                              autodownload:YES
                                                   options:options];
        
        [DMANAGER saveAndSync:YES];
        
        if (completion) {
            completion(persistentFeed, nil);
        }
        
        [App releaseNetworkActivity];

    };
    parser.didEndWithError = ^(NSError* error) {
        if (completion) {
            completion(nil, error);
        }
        [App releaseNetworkActivity];
    };
    
    [_parserQueue addOperation:parser];
}

#pragma mark -
#pragma mark Refreshing Feeds


- (BOOL) isRefreshing
{
	return (self.refreshCheckTimer != nil);
}

- (double) refreshProgress
{
    return MAX(0.0, MIN(1.0, (double)(self.numTotalRefreshFeeds - [self.refreshingFeedURLs count])/self.numTotalRefreshFeeds));
}

- (void) refreshAllFeedsForce:(BOOL)force
{
    return [self refreshAllFeedsForce:force etagHandling:YES completion:nil];
}

- (void) refreshAllFeedsForce:(BOOL)force completion:(ICSubscriptionManagerRefreshCompletionBlock)completion
{
    [self refreshAllFeedsForce:force etagHandling:YES completion:completion];
}

- (void) refreshAllFeedsForce:(BOOL)force etagHandling:(BOOL)etagHandling completion:(ICSubscriptionManagerRefreshCompletionBlock)completion
{
    NSMutableArray* feeds = [[NSMutableArray alloc] init];
    NSArray* allNonParkedFeeds = [DMANAGER visibleFeeds];
    
#if TARGET_OS_IPHONE
    [feeds addObjectsFromArray:allNonParkedFeeds];
#else
    // check settings
    if (force) {
        [feeds addObjectsFromArray:allNonParkedFeeds];
    }
    else
    {
        if (App.networkAccessTechnology < kICNetworkAccessTechnlogyEDGE) {
            DebugLog(@"not auto refreshing, because no internet connection");
            return;
        }
        
        for(CDFeed* feed in allNonParkedFeeds)
        {
            NSDate* lastRefreshDate = (feed.lastUpdate) ? feed.lastUpdate : [NSDate distantPast];
            
            AutoRefreshInterval autoRefreshInterval = [feed integerForKey:AutoRefresh];
            
            switch (autoRefreshInterval) {
                case AutoRefreshNever:
                    continue;
                    
                case AutoRefreshOncePerDay:
                {
                    NSCalendar* cal = [NSCalendar currentCalendar];
                    NSDateComponents* lastComps = [cal components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:lastRefreshDate];
                    NSDateComponents* nowComps = [cal components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:[NSDate date]];
                    
                    if ([lastComps year] == [nowComps year] && [lastComps month] == [nowComps month] && [lastComps day] == [nowComps day]) {
                        continue;
                    }
                }
                    break;
                    
                case AutoRefreshEvery12Hours:
                    if ([[NSDate date] timeIntervalSinceDate:lastRefreshDate] < 12*60*60) {
                        continue;
                    }
                    break;
                    
                case AutoRefreshEvery6Hours:
                    if ([[NSDate date] timeIntervalSinceDate:lastRefreshDate] < 6*60*60) {
                        continue;
                    }
                    break;
                    
                case AutoRefreshEveryHour:
                    if ([[NSDate date] timeIntervalSinceDate:lastRefreshDate] < 1*60*60) {
                        continue;
                    }
                    break;
                    
                case AutoRefreshEvery15Minutes:
                    if ([[NSDate date] timeIntervalSinceDate:lastRefreshDate] < 15*60) {
                        continue;
                    }
                    break;
                    
                default:
                    break;
            }
            
            [feeds addObject:feed];
        }
    }
#endif
    
    if ([feeds count] > 0) {
        [self refreshFeeds:feeds etagHandling:etagHandling completion:completion];
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:SubscriptionManagerDidFinishRefreshingFeedsNotification object:self];
        });
    }
}


- (void) refreshFeeds:(NSArray*)feeds etagHandling:(BOOL)etagHandling completion:(ICSubscriptionManagerRefreshCompletionBlock)completion
{
    if (self.importing) {
        return;
    }

    if ([feeds count] == 0) {
        return;
    }
    
    DebugLog(@"refresh %lu feeds", (unsigned long)[feeds count]);
    
    if (!self.refreshCheckTimer)
    {
        PlaySoundFile(@"Scratch2",NO);
        [[NSNotificationCenter defaultCenter] postNotificationName:SubscriptionManagerWillStartRefreshingFeedsNotification object:self];
        
        [App retainNetworkActivity];
        self.refreshCheckTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                                  target:self
                                                                selector:@selector(checkRefreshOperationsTimer:)
                                                                userInfo:feeds
                                                                 repeats:YES];
        
        self.numOfNewEpisodesAfterRefresh = 0;
        self.numTotalRefreshFeeds = [self.refreshingFeedURLs count];
#if TARGET_OS_IPHONE
        self.backgroundIdentifier = [App beginBackgroundTaskWithExpirationHandler:(^(void) {
            [App endBackgroundTask:self.backgroundIdentifier];
            self.backgroundIdentifier = UIBackgroundTaskInvalid;
        })];
#endif
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SubscriptionManagerDidStartRefreshingFeedsNotification object:self];
    }
    
    
    for(CDFeed* feed in feeds)
    {
        [self refreshFeed:feed
             etagHandling:etagHandling
               completion:(([feeds lastObject] == feed) ? completion : nil)];
    }
    
}

- (void) _finishParsingFeed:(CDFeed*)feed url:(NSURL*)url
{
    [self autoDownloadEpisodesInFeed:feed];
    
    [self.refreshingFeedURLs removeObject:url];
    
    //DebugLog(@"%@", self.refreshingFeedURLs);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SubscriptionManagerDidParseFeedNotification
                                                        object:self
                                                      userInfo:(feed)?[NSDictionary dictionaryWithObject:feed forKey:@"feed"]:nil];
}

- (void) refreshFeed:(CDFeed*)feed etagHandling:(BOOL)etagHandling completion:(ICSubscriptionManagerRefreshCompletionBlock)completion
{    
    NSURL* url = [feed.sourceURL copy];
    if (!url) {
        return;
    }
    [self.refreshingFeedURLs addObject:url];

    BOOL notificationBefore = ([self.parserQueue operationCount] == 0);
    if (notificationBefore) {
        self.refreshedURL = feed.sourceURL;
        [[NSNotificationCenter defaultCenter] postNotificationName:SubscriptionManagerWillParseFeedNotification object:self userInfo:@{@"url" : feed.sourceURL}];
    }
    
    ICFeedParser* feedParser = [ICFeedParser feedParser];
    if (etagHandling) {
        feedParser.etag = feed.etag;
    }
    
    feedParser.url = [feed.sourceURL copy];
    feedParser.username = feed.username;
    feedParser.password = feed.password;
    feedParser.timeout = 20;
#if TARGET_OS_IPHONE
    feedParser.dontAskForCredentials = ([App applicationState] != UIApplicationStateActive);
    feedParser.allowsCellularAccess = [USER_DEFAULTS boolForKey:EnableRefreshingOver3G];
#endif
    __weak ICFeedParser* weakFeedParser = feedParser;
    feedParser.didParseFeedBlock = ^(ICFeed* parsedFeed) {
        
        if (!notificationBefore) {
            self.refreshedURL = feed.sourceURL;
            [[NSNotificationCenter defaultCenter] postNotificationName:SubscriptionManagerWillParseFeedNotification object:self userInfo:@{@"url" : url}];
        }
        
        
        NSMutableArray* allNewEpisodes = [NSMutableArray array];
        
        if (parsedFeed)
        {
            // merge
            NSArray* feeds = [DMANAGER visibleFeeds];
            
            for(CDFeed* feed in feeds) {
                if ([feed.sourceURL isEqual:parsedFeed.sourceURL])
                {
                    // import new episodes
                    if (!etagHandling || ![feed.contentHash isEqual:parsedFeed.contentHash]) {
                        NSArray* newEpisodes = [self _mergeLocalFeed:feed withWithRemoteFeed:parsedFeed force:NO];
                        if ([newEpisodes count] > 0) {
                            [allNewEpisodes addObjectsFromArray:newEpisodes];
                        }
                    }
                    
                    // update existing content
                    feed.contentHash = parsedFeed.contentHash;
                    feed.etag = parsedFeed.etag;
                    break;
                }
            }
            
            self.numOfNewEpisodesAfterRefresh += [allNewEpisodes count];
            
            
            if ([allNewEpisodes count] > 0 && [feed boolForKey:AutoDeleteNewsMode]) {
                [self _recycleOldEpisodesInNewsModeFeed:feed];
            }
        }
        if (weakFeedParser.username && ![weakFeedParser.username isEqualToString:feed.username]) {
            feed.username = weakFeedParser.username;
        }
        if (weakFeedParser.password && ![weakFeedParser.password isEqualToString:feed.password]) {
            feed.password = weakFeedParser.password;
        }
        feed.lastUpdate = [NSDate date];
        
        DebugLog(@"parsed %@  (%@:%@)", feed.title, feed.username, feed.password);
        
        [self _finishParsingFeed:feed url:url];
        
        if (completion) {
            completion(YES, allNewEpisodes, nil);
        }
    };
    
    feedParser.didEndWithError = ^(NSError* error) {
        
        if (completion) {
            completion(NO, nil, error);
        }
        
        if (!notificationBefore) {
            [[NSNotificationCenter defaultCenter] postNotificationName:SubscriptionManagerWillParseFeedNotification object:self userInfo:@{@"url" : feed.sourceURL}];
        }
        
        ErrLog(@"error parsing '%@': %@", feed.title, [error description]);
        [self _finishParsingFeed:feed url:url];
    };
    
    [self.parserQueue addOperation:feedParser];
}


- (void) checkRefreshOperationsTimer:(NSTimer*)timer
{
	if ([self.refreshingFeedURLs count] == 0 && [self.parserQueue operationCount] == 0)
	{
        [self.refreshCheckTimer invalidate];
		self.refreshCheckTimer = nil;
        
        
        // save all changes
        [DMANAGER save];
        
        // update application badge
#if TARGET_OS_IPHONE
        App.applicationIconBadgeNumber = ([USER_DEFAULTS boolForKey:ShowApplicationBadgeForUnseen]) ? DMANAGER.unplayedList.numberOfEpisodes : 0;
#endif
        
		[App releaseNetworkActivity];
		
		if (self.numOfNewEpisodesAfterRefresh > 0) {
			PlaySoundFile(@"NewEpisodes",NO);
		} else {
			PlaySoundFile(@"Pop",NO);
		}
        

#if TARGET_OS_IPHONE
        BOOL notificationEnabled = [USER_DEFAULTS boolForKey:EnableManualRefreshFinishedNotification];
        
        if (notificationEnabled && self.backgroundIdentifier != UIBackgroundTaskInvalid && App.applicationState == UIApplicationStateBackground)
        {
            UILocalNotification* finishedNotification = [[UILocalNotification alloc] init];
            if (self.numOfNewEpisodesAfterRefresh > 1) {
                finishedNotification.alertBody = [NSString stringWithFormat:@"Refreshing finished and %d new episodes are available.".ls, self.numOfNewEpisodesAfterRefresh];
            }
            else if (self.numOfNewEpisodesAfterRefresh == 1) {
                finishedNotification.alertBody = @"Refreshing finished and a new episode is available.".ls;
            }
            else {
                finishedNotification.alertBody = @"Refreshing finished and there are no new episodes available.".ls;
            }

            App.applicationIconBadgeNumber = ([USER_DEFAULTS boolForKey:ShowApplicationBadgeForUnseen]) ? DMANAGER.unplayedList.numberOfEpisodes : 0;
            [App presentLocalNotificationNow:finishedNotification];
        }
#endif

 
 
#if TARGET_OS_IPHONE
        [self perform:^(id sender) {
            DebugLog(@"end background task");
            if (self.backgroundIdentifier != UIBackgroundTaskInvalid) {
                [App endBackgroundTask:self.backgroundIdentifier];
                self.backgroundIdentifier = UIBackgroundTaskInvalid;
            }
        } afterDelay:1.0f];
#endif
		
        [self willChangeValueForKey:@"formattedLastRefreshDate"];
		[USER_DEFAULTS setDouble:[[NSDate date] timeIntervalSince1970] forKey:LastRefreshSubscriptionDate];
		[USER_DEFAULTS synchronize];
        [self didChangeValueForKey:@"formattedLastRefreshDate"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SubscriptionManagerDidFinishRefreshingFeedsNotification object:self];
	}
}

- (void) updateLocalFeedInfo:(CDFeed*)localFeed withRemoteFeed:(ICFeed*)remoteFeed force:(BOOL)force
{
    if (!force)
    {    
        if (remoteFeed.changedSourceURL) {
            localFeed.sourceURL = remoteFeed.changedSourceURL;
        }
        localFeed.etag = remoteFeed.etag;
        localFeed.title = remoteFeed.title;
        localFeed.linkURL = remoteFeed.linkURL;
        localFeed.paymentURL = remoteFeed.paymentURL;
        localFeed.imageURL = remoteFeed.imageURL;

        NSMutableDictionary* localEpisodeIndex = [NSMutableDictionary dictionary];
        for(CDEpisode* episode in localFeed.episodes) {
            if (episode.guid) {
                localEpisodeIndex[episode.guid] = episode;
            }
        }

        for(ICEpisode* remoteEpisode in remoteFeed.episodes)
        {
            if (!remoteEpisode.guid) {
                continue;
            }
            
            CDEpisode* localEpisode = localEpisodeIndex[remoteEpisode.guid];
            BOOL newer = ([remoteEpisode.pubDate timeIntervalSince1970] > [localEpisode.pubDate timeIntervalSince1970]);
            
            if (newer) {
                localEpisode.fulltext = remoteEpisode.textDescription;
                localEpisode.imageURL = remoteEpisode.imageURL;
                localEpisode.pubDate = remoteEpisode.pubDate;
            }
            else {
                if (!localEpisode.fulltext || ![localEpisode.fulltext isEqualToString:remoteEpisode.textDescription]) {
                    localEpisode.fulltext = remoteEpisode.textDescription;
                }
                
                if (!localEpisode.imageURL || ![localEpisode.imageURL isEqual:remoteEpisode.imageURL]) {
                    localEpisode.imageURL = remoteEpisode.imageURL;
                }
            }
        }
    }
    
    else
    {
        [DMANAGER _copyFeedValuesFrom:remoteFeed to:localFeed];
        
        NSMutableDictionary* localEpisodeIndex = [NSMutableDictionary dictionary];
        for(CDEpisode* episode in localFeed.episodes) {
            if (episode.guid) {
                localEpisodeIndex[episode.guid] = episode;
            }
        }
        
        for(ICEpisode* episode in remoteFeed.episodes)
        {
            if (!episode.guid) {
                continue;
            }

            CDEpisode* localEpisode = localEpisodeIndex[episode.guid];
            if (!localEpisode) {
                continue;
            }
            [DMANAGER _copyEpisodeValuesFrom:episode to:localEpisode];
            
            
            NSArray* localMedia = [localEpisode.media allObjects];
            for(ICMedia* remoteMedium in episode.media)
            {
                // dont add mediums without file URL, because medium depends on it for syncing
                if (!remoteMedium.fileURL) {
                    continue;
                }
                
                [[episode.media copy] enumerateObjectsUsingBlock:^(ICMedia* media, NSUInteger idx, BOOL *stop) {
                    
                    if ([localMedia count] > idx) {
                        CDMedium* localMedium = localMedia[idx];
                        [DMANAGER _copyMediumValuesFrom:remoteMedium to:localMedium];
                    }
                    else
                    {
                        CDMedium* persistentMedium = [NSEntityDescription insertNewObjectForEntityForName:@"Medium" inManagedObjectContext:DMANAGER.objectContext];
                        [DMANAGER _copyMediumValuesFrom:remoteMedium to:persistentMedium];
                        [[localEpisode mutableSetValueForKey:@"media"] addObject:persistentMedium];
                    }
                    
                }];
            }
        }
        
        // remove duplicate episodes
        NSArray* episodes = [localFeed.episodes sortedArrayUsingDescriptors:@[ [[NSSortDescriptor alloc] initWithKey:@"pubDate" ascending:NO] ]];
        
        NSMutableSet* guids = [NSMutableSet setWithCapacity:[episodes count]];
        for(CDEpisode* episode in episodes) {
            if (!episode.guid) {
                continue;
            }
            if (![guids containsObject:episode.guid]) {
                [guids addObject:episode.guid];
            }
            else {
                [DMANAGER.objectContext deleteObject:episode];
            }
        }
    }
}

- (NSArray*) _mergeLocalFeed:(CDFeed*)localFeed withWithRemoteFeed:(ICFeed*)remoteFeed force:(BOOL)force
{
    NSSet* localEpisodes = localFeed.episodes;
    NSMutableSet* episodeGuids = [[NSMutableSet alloc] initWithCapacity:[localEpisodes count]];

    for(CDEpisode* episode in localEpisodes) {
        if (episode.guid) {
            [episodeGuids addObject:episode.guid];
        }
    }
    
	// merge new entries
	NSArray* remoteEpisodes = [remoteFeed.episodes sortedArrayUsingDescriptors:@[ [[NSSortDescriptor alloc] initWithKey:@"pubDate" ascending:YES] ]];
    CDEpisode* newestLocalEpisode = [[localFeed sortedEpisodes] firstObject];
	
    NSMutableArray* newEpisodes = [[NSMutableArray alloc] init];
    CDEpisode* mostCurrentEpisode = nil;
	for (ICEpisode* remoteEpisode in remoteEpisodes)
	{
		// local episode does not exist
		if (![episodeGuids containsObject:remoteEpisode.guid])
		{
            // make persistent
			DebugLog(@"add episode %@", remoteEpisode.title);
            BOOL wasNew;
            CDEpisode* newPersistentEpisode = [DMANAGER addNewParserEpisode:remoteEpisode toFeed:localFeed wasNew:&wasNew];
            
            // only mark those episodes as unplayed that are newer than the latest episodes we already got
            NSTimeInterval newEpisodeTimeInterval = [newPersistentEpisode.pubDate timeIntervalSince1970];
            NSTimeInterval formerEpisodeTimeInterval = [newestLocalEpisode.pubDate timeIntervalSince1970];
            if (wasNew && newEpisodeTimeInterval > formerEpisodeTimeInterval) {
                newPersistentEpisode.consumed = NO;
            }

            if (!mostCurrentEpisode || [newPersistentEpisode.pubDate laterDate:mostCurrentEpisode.pubDate] == newPersistentEpisode.pubDate) {
                mostCurrentEpisode = newPersistentEpisode;
            }

            [newEpisodes addObject:newPersistentEpisode];

#if !TARGET_OS_IPHONE
            NSUserNotification* finishedNotification = [[NSUserNotification alloc] init];
            finishedNotification.title = @"New episode available in Instacast.".ls;
            finishedNotification.subtitle = [NSString stringWithFormat:@"%@ - %@", localFeed.title, [newPersistentEpisode cleanTitleUsingFeedTitle:localFeed.title]];
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:finishedNotification];
#endif
		}
	}
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SubscriptionManagerDidAddEpisodesNotification
                                                        object:self
                                                      userInfo:@{@"episodes" : newEpisodes}];
    
    [self updateLocalFeedInfo:localFeed withRemoteFeed:remoteFeed force:force];
    
    return newEpisodes;
}

- (void) _deleteUnavailableEpisodesFromFeed:(CDFeed*)localFeed withRemoteFeed:(ICFeed*)remoteFeed
{
    NSMutableSet* episodeGuids = [[NSMutableSet alloc] init];
    
    for(ICEpisode* episode in remoteFeed.episodes) {
        if (episode.guid) {
            [episodeGuids addObject:episode.guid];
        }
    }
    
    for(CDEpisode* episode in [localFeed.episodes copy])
    {
        if (![episodeGuids containsObject:episode.guid]) {
            [DMANAGER deleteEpisode:episode];
        }
    }
}


- (void) _recycleOldEpisodesInNewsModeFeed:(CDFeed*)feed
{
    NSArray* sortedEpisodes = [feed.episodes sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"pubDate" ascending:NO]]];
    NSDate* firstPubDate = [[sortedEpisodes firstObject] pubDate];
    
    if (!firstPubDate) {
        return;
    }
    
    NSDateComponents* firstComps = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay)
                                                              fromDate:firstPubDate];
    
    for (CDEpisode* episode in sortedEpisodes)
    {
        NSDate* pubDate = episode.pubDate;
        
        NSDateComponents* comps = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay)
                                                                      fromDate:pubDate];
        
        if ([comps day] != [firstComps day] || [comps month] != [firstComps month] || [comps year] != [firstComps year])
        {
            // is old episode
            [DMANAGER markEpisode:episode asConsumed:YES];
            [[CacheManager sharedCacheManager] removeCacheForEpisode:episode automatic:YES];
        }
        else
        {
            // is new episode
            [DMANAGER markEpisode:episode asConsumed:NO];
        }
    }
}

#pragma mark -


- (void) autoDownloadAllFeedsAsynchronously
{
    NSManagedObjectContext* childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [childContext setParentContext:DMANAGER.objectContext];
    
    
    [childContext performBlockAndWait:^{
        NSFetchRequest* feedsRequest = [[NSFetchRequest alloc] init];
        feedsRequest.entity = [NSEntityDescription entityForName:@"Feed" inManagedObjectContext:childContext];
        feedsRequest.predicate = [NSPredicate predicateWithFormat:@"subscribed == YES && parked == NO"];
        feedsRequest.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"rank" ascending:YES] ];
        
        NSError* error;
        NSArray* feeds = [childContext executeFetchRequest:feedsRequest error:&error];
        if (error) {
            ErrLog(@"error getting feeds: %@", error);
        }
        
        for(CDFeed* feed in feeds)
        {
            NSArray* sortedEpisodes = [feed chronologicallySortedEpisodes];
            NSMutableArray* sortedEpisodesIds = [[NSMutableArray alloc] init];
            for(CDEpisode* episode in sortedEpisodes) {
                [sortedEpisodesIds addObject:[episode objectID]];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSMutableArray* thisSortedEpisodes = [[NSMutableArray alloc] init];
                for(NSManagedObjectID* objectId in sortedEpisodesIds) {
                    CDEpisode* episode = (CDEpisode*)[DMANAGER.objectContext objectWithID:objectId];
                    if (episode) {
                        [thisSortedEpisodes addObject:episode];
                    }
                }
                
                [self _autoDownloadEpisode:nil sortedEpisodes:thisSortedEpisodes];
            });
        }
    }];
}

- (BOOL) autoDownloadEpisodesInFeed:(CDFeed*)feed
{
    return [self _autoDownloadEpisode:nil inFeed:feed];
}

- (BOOL) autoDownloadEpisode:(CDEpisode*)episode
{
    return [self _autoDownloadEpisode:episode inFeed:episode.feed];
}

- (BOOL) _autoDownloadEpisode:(CDEpisode*)pickedEpisode inFeed:(CDFeed*)feed
{
    if (feed.parked || !feed.subscribed) {
        return NO;
    }
    
    NSArray* sortedEpisodes = [feed chronologicallySortedEpisodes];
    return [self _autoDownloadEpisode:pickedEpisode sortedEpisodes:sortedEpisodes];
}

- (BOOL) _autoDownloadEpisode:(CDEpisode*)pickedEpisode sortedEpisodes:(NSArray*)sortedEpisodes
{
    BOOL caching = NO;
    BOOL onlyMostRecent = YES;
    
    CacheManager* cman = [CacheManager sharedCacheManager];
    
    NSDate* firstPubDate = [[sortedEpisodes firstObject] pubDate];
    
    if (!firstPubDate) {
        return NO;
    }
    
    NSDateComponents* firstComps = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay)
                                                                   fromDate:firstPubDate];
        
    for(CDEpisode* episode in sortedEpisodes)
    {
        // don't download old episodes when we only allow download of most recent once
        if (onlyMostRecent)
        {
            NSDate* pubDate = episode.pubDate;
            NSDateComponents* comps = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay)
                                                                      fromDate:pubDate];
            
            if ([comps day] != [firstComps day] || [comps month] != [firstComps month] || [comps year] != [firstComps year]) {
                continue;
            }
        }
        
        // don't download consumed and archived episodes
        if (episode.consumed || episode.archived) {
            continue;
        }
        /*
        else if ([episode.pubDate timeIntervalSinceDate:[NSDate date]] < -86000*14) {
            continue;
        }
        */
        else if (pickedEpisode && [episode isEqual:pickedEpisode]) {
            caching |= [cman autoCacheEpisode:episode enableFilters:YES];
        }
        
        else if (!pickedEpisode) {
            //NSLog(@"try auto-caching episode '%@'", episode.title);
            caching |= [cman autoCacheEpisode:episode enableFilters:YES];
        }
    }
    
    return caching;
}


#pragma mark -
#pragma mark Importing Stuff

// returns multiple times
- (void) _importURLs:(NSArray*)array completion:(void (^)())completion
{
    __block NSInteger parsedFeeds = 0;
    
    for(NSURL* feedURL in array)
    {
        parsedFeeds++;
        ICFeedParser* feedParser = [ICFeedParser feedParser];
        feedParser.url = [feedURL copy];

        __weak ICFeedParser* weakFeedParser = feedParser;
        feedParser.didParseFeedBlock = ^(ICFeed* feed) {
            
            feed.username = weakFeedParser.username;
            feed.password = weakFeedParser.password;
            feed.lastUpdate = [NSDate date];
            
            [DMANAGER subscribeFeed:feed];
            
            parsedFeeds--;
            if (parsedFeeds == 0 && completion) {
                completion();
            }
        };
        
        feedParser.didEndWithError = ^(NSError* error) {
            
            parsedFeeds--;
            if (parsedFeeds == 0 && completion) {
                completion();
            }
        };
        
        [self.parserQueue addOperation:feedParser];
    }
}

- (void) importURL:(NSURL*)url completion:(void (^)())completion
{
    for(CDFeed* feed in DMANAGER.feeds) {
		if ([feed.sourceURL isEqual:url]) {
			completion(nil);
			return;
		}
	}
    
    [App retainNetworkActivity];

    
    [self _importURLs:[NSArray arrayWithObject:url] completion:^() {

        [App releaseNetworkActivity];
        
        if (completion) {
            completion(nil);
        }
    }];
}


- (void) importOPMLData:(NSData*)data completion:(void (^)())completion
{
	OPMLParser* opmlParser = [OPMLParser opmlParserWithData:data];
    [opmlParser parseWithCompletionHandler:^(NSArray *feeds) {
        
        self.importing = YES;
        [App retainNetworkActivity];
        

        NSMutableDictionary* feedIndex = [NSMutableDictionary dictionary];
        for(CDFeed* feed in DMANAGER.feeds) {
            static NSString* kObj = @"1";
            [feedIndex setObject:kObj forKey:feed.sourceURL];
        }
        
        
        NSMutableArray* urls = [NSMutableArray array];

        for(NSDictionary* feedDict in feeds)
        {
            NSString* xmlURL = [feedDict objectForKey:OPMLFeedXmlUrl];
            if (!xmlURL) {
                continue;
            }
            
            NSURL* feedURL = [NSURL URLWithString:xmlURL];
            if (!feedURL) {
                ErrLog(@"can not make feed URL from: %@", xmlURL);
                continue;
            }

            if (![feedIndex objectForKey:feedURL]) {
                [urls addObject:feedURL];
            }
        }
        
        if ([urls count] > 0)
        {
            [DMANAGER beginInterruptSaving];
            [self _importURLs:urls completion:^() {
                
                [App releaseNetworkActivity];

                self.importing = NO;
                [DMANAGER endInterruptSaving];
                [DMANAGER save];
                
                [self autoDownloadAllFeedsAsynchronously];
                
                if (completion) {
                    completion();
                }
            }];
        }
        else {
            if (completion) {
                completion();
            }
        }

    } errorHandler:^(NSError *error) {
        ErrLog(@"opml didEndWithError: %@", [error description]);
        if (completion) {
            completion();
        }
    }];
}

#pragma mark -

- (NSData*) opmlData
{
	NSArray* feeds = DMANAGER.feeds;
	NSMutableArray* feedDicts = [NSMutableArray array];
	
	for(CDFeed* feed in feeds)
	{
		NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
							  feed.title, OPMLFeedTitle,
							  @"rss", OPMLFeedType,
							  [feed.sourceURL absoluteString], OPMLFeedXmlUrl,
							  [feed.linkURL absoluteString], OPMLFeedHtmlUrl,
							  nil];
		[feedDicts addObject:dict];
	}
	
	NSString* title = [NSString stringWithFormat:@"Instacast Subscriptions from %@".ls, [NSBundle deviceName]];
	OPMLWriter* opmlWriter = [OPMLWriter opmlWriterWithFeeds:feedDicts];
	return [opmlWriter dataWithTitle:title];
}

@end
