//
//  CacheManager.h
//  Instacast
//
//  Created by Martin Hering on 03.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* CacheManagerDidStartCachingNotification;
extern NSString* CacheManagerDidEndCachingNotification;
extern NSString* CacheManagerDidAddEpisodeToCachingQueueNotification;

extern NSString* CacheManagerDidUpdateNotification;
extern NSString* CacheManagerDidStartCachingEpisodeNotification;		// userinfo = episode
extern NSString* CacheManagerDidFinishCachingEpisodeNotification;		// userinfo = episode
extern NSString* CacheManagerDidLoadFeedImageNotification;
extern NSString* CacheManagerDidClearCacheNotification;                 // userinfo = episode

extern NSString* CacheManagerWiFiDidBecomeAvailableNotification;

@class CDFeed, CDEpisode;

@interface CacheManager : NSObject

+ (CacheManager*) sharedCacheManager;

- (NSURL*) URLForCachedEpisode:(CDEpisode*)episode;
- (BOOL) episodeIsCached:(CDEpisode*)episode;
- (BOOL) episodeIsCached:(CDEpisode*)episode fastLookup:(BOOL)fastLookup;
- (BOOL) cacheEpisode:(CDEpisode*)episode;
- (BOOL) cacheEpisode:(CDEpisode*)episode overwriteCellularLock:(BOOL)overwriteCellular;
- (void) removeCacheForEpisode:(CDEpisode*)episode automatic:(BOOL)automatic;
- (void) removeCacheForFeed:(CDFeed*)feed automatic:(BOOL)automatic;
- (BOOL) isCaching;
- (BOOL) isCachingEpisode:(CDEpisode*)episode;
- (BOOL) isCachingSourceOfEpisode:(CDEpisode*)episode;
- (BOOL) isCachingFeed:(CDFeed*)feed;
- (void) cancelCaching;
- (void) cancelCachingEpisode:(CDEpisode*)episode disableAutoDownload:(BOOL)disableAutodownload;
- (void) cancelCachingFeed:(CDFeed*)feed;


@property (nonatomic) BOOL suspended;
- (void) pauseCaching;
- (void) pauseCachingEpisode:(CDEpisode*)episode;
- (BOOL) isCachingSuspended;
- (void) resumeCaching;
- (void) resumeCachingEpisode:(CDEpisode*)episode;

- (NSInteger) numberOfCachedEpisodes;

@property (nonatomic, readonly) NSArray* cachedEpisodes;
@property (nonatomic, readonly) NSArray* partiallyCachedEpisodes;


- (NSArray*) cachingEpisodes;  // observable
- (void) reorderCachingEpisodeFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

- (BOOL) autoCacheEpisode:(CDEpisode*)episode enableFilters:(BOOL)filters;
- (BOOL) autoCacheFeed:(CDFeed*)feed;
- (void) resetAutoCacheForFeed:(CDFeed*)feed;


@property (readonly) double progress;
@property (readonly) double rate;  // in bytes

- (double) cacheProgressForEpisode:(CDEpisode*)episode;
- (long long) expectedContentLengthForEpisode:(CDEpisode*)episode;
- (NSTimeInterval) cacheTimeLeftForEpisode:(CDEpisode*)episode;
- (double) cacheProgressForFeed:(CDFeed*)feed;
- (double) cacheProgress;
- (BOOL) isLoadingEpisode:(CDEpisode*)episode;
- (BOOL) isLoadingEpisodeSuspended:(CDEpisode*)episode;

@property (nonatomic, readonly) unsigned long long numberOfDownloadedBytes;
- (unsigned long long) numberOfDownloadedBytesForEpisode:(CDEpisode*)episode;

- (void) tidyUp;
- (BOOL) clearTheFuckingCache;

- (void) autoClearAndMakeRoomForBytes:(unsigned long long)bytes automatic:(BOOL)automatic;

- (void) handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler;

- (void) importFileAtURL:(NSURL*)url forEpisode:(CDEpisode*)episode completion:(void (^)(BOOL success, NSError* error))completion;
@end
