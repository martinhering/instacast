//
//  CacheManager.m
//  Instacast
//
//  Created by Martin Hering on 03.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//


#import "CDEpisode+ShowNotes.h"
#import "CDFeed+Helper.h"
#import "ICCacheHistory.h"
#import "UtilityFunctions.h"

#import "CacheManager+FileDetector.h"

#if TARGET_OS_IPHONE
#import "CacheOperation_iOS7.h"
#define CACHE_OPERATION_CLASS CacheOperation_iOS7
#else

#import "CacheOperation.h"
#define CACHE_OPERATION_CLASS CacheOperation
#import "CacheManager+FileReflector.h"
#import <IOKit/pwr_mgt/IOPMLib.h>

#define CACHE_OPERATION_CLASS CacheOperation

#endif

static NSString* kUserDefaultsCachingEpisodesKey = @"CachingEpisodesKey";

NSString* CacheManagerDidStartCachingNotification = @"CacheManagerDidStartCachingNotification";
NSString* CacheManagerDidEndCachingNotification = @"CacheManagerDidEndCachingNotification";
NSString* CacheManagerDidAddEpisodeToCachingQueueNotification = @"CacheManagerDidAddEpisodeToCachingQueueNotification";

NSString* CacheManagerDidUpdateNotification = @"CacheManagerDidUpdateNotification";
NSString* CacheManagerDidLoadFeedImageNotification = @"CacheManagerDidLoadFeedImageNotification";
NSString* CacheManagerDidStartCachingEpisodeNotification = @"CacheManagerDidStartCachingEpisodeNotification";
NSString* CacheManagerDidFinishCachingEpisodeNotification = @"CacheManagerDidFinishCachingEpisodeNotification";
NSString* CacheManagerDidClearCacheNotification = @"CacheManagerDidClearCacheNotification";

NSString* CacheManagerWiFiDidBecomeAvailableNotification = @"CacheManagerWiFiDidBecomeAvailableNotification";

static CacheManager* gSharedCacheManager = nil;
static NSString* gPathToCache = nil;

#if TARGET_OS_IPHONE
@interface CacheManager () <CacheOperationDelegate, NSURLSessionDelegate>
#else
@interface CacheManager () <CacheOperationDelegate>
#endif
@property (readwrite) double rate;
@property (nonatomic, strong) ICCacheHistory* cacheHistory;
@property (nonatomic, strong) NSTimer* timer;
@end


@implementation CacheManager {
@protected
	NSMutableSet*               _cachedEpisodes;
	NSMutableDictionary*		_cachedURLIndex;
	NSOperationQueue*			_downloadQueue;
	NSInteger					_totalOps;
	NSInteger					_runningOps;
	NSTimer*					_updateTimer;
#if TARGET_OS_IPHONE
#else
    IOPMAssertionID             _noSystemSleepAssertionID;
#endif
    NSMutableArray*             _cachingEpisodes;
    unsigned long long          _downloadedBytes;
    NSDate*                     _rateDate;
    int64_t                     _rateBytes;
    
    struct {
        unsigned int supressSendUpdate:1;
        unsigned int supressDidClear:1;
    } _flags;
}

+ (NSString*) _pathToCache
{
	if (gPathToCache) {
		return gPathToCache;
	}
	
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* path = [[paths lastObject] stringByAppendingPathComponent:@"Episodes"];
	
	NSFileManager* fman = [NSFileManager defaultManager];
	if (![fman fileExistsAtPath:path])
	{
		NSError* error = nil;
		if (![fman createDirectoryAtPath:path withIntermediateDirectories:YES
							  attributes:nil
								   error:&error]) {
			ErrLog(@"error creating directory %@: %@", path, [error description]);
			return nil;
		}
	}
	
	gPathToCache = [path copy];
	return path;
}

+ (NSString*) _pathToStorageLocation
{
#if TARGET_OS_IPHONE
    if ([NSBundle systemVersion] < 0x50001) {
        return [self _pathToCache];
    }
#endif
    return [DMANAGER.fileCacheURL path];
}


+ (CacheManager*) sharedCacheManager;
{
	if (!gSharedCacheManager) {
		gSharedCacheManager = [self alloc];
		gSharedCacheManager = [gSharedCacheManager init];
	}
	return gSharedCacheManager;
}

- (id) init
{
	if ((self = [super init]))
	{
		_downloadQueue = [[NSOperationQueue alloc] init];
		[_downloadQueue setMaxConcurrentOperationCount:3];
		
		// build cache index
		_cachedEpisodes = [[NSMutableSet alloc] init];
		_cachedURLIndex = [[NSMutableDictionary alloc] init];
        _cachingEpisodes = [[NSMutableArray alloc] init];
        
        NSString* historyFile = [[DatabaseManager pathToDocuments] stringByAppendingPathComponent:@"CacheHistory.plist"];
        _cacheHistory = [[ICCacheHistory alloc] initWithContentsOfFile:historyFile];
		
        
		NSFileManager* fman = [NSFileManager defaultManager];
		NSError* error = nil;
		NSArray* directoryContent = [fman contentsOfDirectoryAtPath:[CacheManager _pathToStorageLocation] error:&error];
		if (!error)
        {
            NSMutableArray* episodeHashes = [[NSMutableArray alloc] init];
			for(NSString* filename in directoryContent)
			{
                NSString* filePath = [[CacheManager _pathToStorageLocation] stringByAppendingPathComponent:filename];
                AddSkipBackupAttributeToFile(filePath);
                
				NSString* hash = [filename stringByDeletingPathExtension];
                [episodeHashes addObject:hash];
			}

            NSArray* cachedEpisodes = [DMANAGER episodesWithObjectHashes:episodeHashes];
            [_cachedEpisodes addObjectsFromArray:cachedEpisodes];
		}
        
        [self saveFileIndex];
        
        
        [App addTaskObserver:self forKeyPath:@"networkAccessTechnology" task:^(id obj, NSDictionary *change) {
            [self _handleNetworkStatusChanged];
        }];
        
#if !TARGET_OS_IPHONE
        [self initFileReflector];
#endif
        [self initFileDetector];
        
        [self restoreCachingEpisodes];
	}
	
	return self;
}

- (BOOL) canDownload
{
    BOOL enabled3G = [USER_DEFAULTS boolForKey:EnableCachingOver3G];
    if (App.networkAccessTechnology == kICNetworkAccessTechnlogyWIFI) {
        return YES;
    }
    
    if (App.networkAccessTechnology > kICNetworkAccessTechnlogyGPRS && enabled3G) {
        return YES;
    }
    
    return NO;
}

- (void) _handleNetworkStatusChanged
{
    DebugLog(@"_handleNetworkStatusChanged");
    
    if (![self canDownload]) {
        NSArray* operations = [_downloadQueue operations];
        for(CACHE_OPERATION_CLASS* operation in operations) {
            CDEpisode* episode = (CDEpisode*)operation.userInfo;
            [self cancelCachingEpisode:episode disableAutoDownload:NO];
        }
    }
}


#pragma mark -

- (NSInteger) totalOperationCount
{
	return _totalOps;
}

- (NSInteger) finishedOperationCount
{
	return _totalOps-[[_downloadQueue operations] count];
}

- (void) _postDidUpdateNotification
{
    if (_rateDate) {
        NSTimeInterval since = [[NSDate date] timeIntervalSinceDate:_rateDate];
        if (since >= 2) {
            self.rate = (double)_rateBytes / (double)since;
            _rateBytes = 0LL;
            _rateDate = nil;
        }
    }
    
    
	//NSInteger rem = [App backgroundTimeRemaining];
	//DebugLog(@"backgroundTimeRemaining %d:%02d", rem/60, rem%60);
	if (!_flags.supressSendUpdate) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CacheManagerDidUpdateNotification object:self];
    }
}

#pragma mark -
#pragma mark Caching

- (NSURL*) URLForCachedEpisode:(CDEpisode*)episode
{
	if (!episode.objectHash) {
		return nil;
	}
	
	NSURL* cachedURL = [_cachedURLIndex objectForKey:episode.objectHash];
	if (cachedURL) {
		return cachedURL;
	}
	
	CDMedium* media = [episode preferedMedium];
	if (!media) {
		return nil;
	}
	
	NSString* extension = [[media.fileURL path] pathExtension];

	// weird thing: possible that [media.url path] fails and return nil
	// we get the path suffix ourself then
	if (!extension) {
		NSString* urlString = [media.fileURL absoluteString];
		NSRange lastDotRange = [urlString rangeOfString:@"." options:NSBackwardsSearch];
		if (lastDotRange.location != NSNotFound && lastDotRange.location < [urlString length]-1) {
			extension = [urlString substringFromIndex:lastDotRange.location+1];
		}
	}
    
    // replaced no extension, .php and so on, at least I hope
    NSDictionary* mimeToExtension = [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"mp3", @"audio/mpeg",
                                     @"m4a", @"audio/mpeg4",
                                     @"m4a", @"audio/mp4a",
                                     @"m4a", @"audio/x-m4a",
                                     @"mp4", @"audio/mp4",
                                     @"m4v", @"video/mpeg4",
                                     @"m4v", @"video/x-m4v",
                                     @"m4v", @"video/mp4",
                                     @"mov", @"video/quicktime",
                                     nil];
    
    NSString* constructedExtension = [mimeToExtension objectForKey:[media.mimeType lowercaseString]];
    NSArray* knownExtensions = [mimeToExtension allValues];
    if (![knownExtensions containsObject:[extension lowercaseString]] && constructedExtension) {
        extension = constructedExtension;
    }
	
	NSString* filename = [NSString stringWithFormat:@"%@.%@", episode.objectHash, extension];
	NSString* path = [[CacheManager _pathToStorageLocation] stringByAppendingPathComponent:filename];
	NSURL* URL = [NSURL fileURLWithPath:path];
	
	if (URL) {
		[_cachedURLIndex setObject:URL forKey:episode.objectHash];
	}
	
	return URL;
}

- (NSURL*) tempURLForCachedEpisode:(CDEpisode*)episode
{
    NSURL* cacheURL = [self URLForCachedEpisode:episode];
    NSString* filename = [[cacheURL lastPathComponent] stringByAppendingString:@".part"];
    NSString* path = [[CacheManager _pathToCache] stringByAppendingPathComponent:filename];
	return [NSURL fileURLWithPath:path];
}

- (BOOL) episodeIsCached:(CDEpisode*)episode
{
	NSURL* url = [self URLForCachedEpisode:episode];
	if (!url) {
		return NO;
	}
	
	NSFileManager* fman = [NSFileManager defaultManager];
	return [fman fileExistsAtPath:[url path]];
}

- (BOOL) episodeIsCached:(CDEpisode*)episode fastLookup:(BOOL)fastLookup
{
	if (!fastLookup) {
		return [self episodeIsCached:episode];
	}
	
	return [_cachedEpisodes containsObject:episode];
}

- (BOOL) _cacheEpisode:(CDEpisode*)episode autoCache:(BOOL)autoCache overwriteCellularLock:(BOOL)overwriteCellularLock
{
	// check if it is not already cached
	if ([self episodeIsCached:episode]) {
		//NSLog(@"episode '%@' is already cached", episode.title);
		return NO;
	}
	
	if ([self isCachingSourceOfEpisode:episode]) {
		//NSLog(@"already caching source of episode '%@'", episode.title);
		return NO;
	}

	NSURL* url = [self URLForCachedEpisode:episode];
	if (!url) {
		return NO;
	}
    
    //NSLog(@"download episode '%@' (url: %@)", episode, [url absoluteString]);
	
	CDMedium* media = [episode preferedMedium];
	CDFeed* feed = episode.feed;
#if TARGET_OS_IPHONE
	CACHE_OPERATION_CLASS* cacheOperation = [[CACHE_OPERATION_CLASS alloc] initWithURL:media.fileURL
                                                                 localURL:[self URLForCachedEpisode:episode]
                                                                            identifier:episode.objectHash
                                                                 expectedContentLength:media.byteSize];
#else
    CACHE_OPERATION_CLASS* cacheOperation = [[CACHE_OPERATION_CLASS alloc] initWithURL:media.fileURL
                                                                              localURL:[self URLForCachedEpisode:episode]
                                                                               tempURL:[self tempURLForCachedEpisode:episode]
                                                                            identifier:episode.objectHash];
#endif
	cacheOperation.delegate = self;
	cacheOperation.userInfo = episode;
	cacheOperation.username = feed.username;
	cacheOperation.password = feed.password;
	cacheOperation.automatic = autoCache;
    cacheOperation.overwriteCellularLock = overwriteCellularLock;
    cacheOperation.suspended = self.suspended;
    if ([cacheOperation respondsToSelector:@selector(setQualityOfService:)]) {
        cacheOperation.qualityOfService = NSOperationQualityOfServiceBackground;
    }
	[_downloadQueue addOperation:cacheOperation];
    
    [self willChangeValueForKey:@"cachingEpisodes"];
    [_cachingEpisodes addObject:episode];
    [self didChangeValueForKey:@"cachingEpisodes"];
	
	if (_totalOps == 0) {
		[[NSNotificationCenter defaultCenter] postNotificationName:CacheManagerDidStartCachingNotification object:self];
	} else {
        [[NSNotificationCenter defaultCenter] postNotificationName:CacheManagerDidAddEpisodeToCachingQueueNotification object:self];
    }
    
    [self saveCachingEpisodes];
    
    _flags.supressSendUpdate = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:CacheManagerDidStartCachingEpisodeNotification
                                                            object:self
                                                          userInfo:@{ @"episode" : episode }];
        _flags.supressSendUpdate = NO;
    });
	
	_totalOps++;
	_runningOps++;
	
	if (!_updateTimer)
	{
		_updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(_postDidUpdateNotification) userInfo:nil repeats:YES];
        
#if TARGET_OS_IPHONE

#else
        IOReturn success = IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleSystemSleep,
                                                       kIOPMAssertionLevelOn,
                                                       CFSTR("Currently downloading"),
                                                       &_noSystemSleepAssertionID);
        if (success != kIOReturnSuccess) {
            _noSystemSleepAssertionID = 0;
        }
#endif
	}
	
	return YES;
}

- (BOOL) cacheEpisode:(CDEpisode*)episode
{
	return [self _cacheEpisode:episode autoCache:NO overwriteCellularLock:NO];
}

- (BOOL) cacheEpisode:(CDEpisode*)episode overwriteCellularLock:(BOOL)overwriteCellularLock
{
    return [self _cacheEpisode:episode autoCache:NO overwriteCellularLock:overwriteCellularLock];
}

- (BOOL) autoCacheEpisode:(CDEpisode*)episode enableFilters:(BOOL)filters
{
    // check if it is not already cached
	if ([self episodeIsCached:episode]) {
		return NO;
	}
    
    if ([self.cacheHistory episodeDidAutoDownload:episode]) {
        return NO;
    }
    
    if (filters)
    {
        CDFeed* feed = episode.feed;
        BOOL autoCacheAudio = [feed boolForKey:AutoCacheNewAudioEpisodes];
        BOOL autoCacheVideo = [feed boolForKey:AutoCacheNewVideoEpisodes];
        
        if (!episode.video && !autoCacheAudio) {
            return NO;
        }
        else if (episode.video && !autoCacheVideo) {
            return NO;
        }
    }
	
    if ([self canDownload]) {
		return [self _cacheEpisode:episode autoCache:YES overwriteCellularLock:NO];
	}
	
	return YES;
}

- (BOOL) autoCacheFeed:(CDFeed*)feed
{
	for(CDEpisode* episode in feed.sortedEpisodes)
    {
		if (!episode.consumed) {
			[self autoCacheEpisode:episode enableFilters:YES];
		}
	}
	return YES;
}

- (void) resetAutoCacheForFeed:(CDFeed*)feed
{
    for(CDEpisode* episode in feed.episodes) {
        [self.cacheHistory resetValuesForEpisode:episode];
    }
}

- (void) removeCacheForEpisode:(CDEpisode*)episode automatic:(BOOL)automatic
{
    if (automatic && episode.starred) {
        DebugLog(@"not removing episode cache of starred episodes");
        return;
    }
    
	if ([self isCachingEpisode:episode]) {
		[self cancelCachingEpisode:episode disableAutoDownload:automatic];
		return;
	}
    
	
    NSURL* remoteURL = [episode preferedMedium].fileURL;
	NSURL* URL = [self URLForCachedEpisode:episode];
#if TARGET_OS_IPHONE
	if (URL) {
		[CACHE_OPERATION_CLASS removeCacheForRemoteURL:remoteURL atLocalURL:URL];
        [CACHE_OPERATION_CLASS deleteResumeInfoForIdentifier:episode.objectHash];
	}
#else
    NSURL* tempURL = [self tempURLForCachedEpisode:episode];
    if (URL) {
        [CacheOperation removeCacheForRemoteURL:remoteURL atLocalURL:URL tempURL:tempURL];
    }
#endif
    [_cachedEpisodes removeObject:episode];
    _downloadedBytes = 0;
    
    episode.lastDownloaded = nil;
    [DMANAGER save];
    
    [self willChangeValueForKey:@"cachedEpisodes"];
    [self didChangeValueForKey:@"cachedEpisodes"];
    
    if (!_flags.supressDidClear) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CacheManagerDidClearCacheNotification object:self userInfo:@{@"episode" : episode}];
    }
}

- (void) removeCacheForFeed:(CDFeed*)feed automatic:(BOOL)automatic
{
    [self cancelCachingFeed:feed];
    
    NSArray* cacheEpisodes = [self cachedEpisodes];
    NSInteger cleared = 0;
    for(CDEpisode* episode in cacheEpisodes)
    {
        if ([episode.feed isEqual:feed]) {
            NSURL* remoteURL = [episode preferedMedium].fileURL;
            NSURL* URL = [self URLForCachedEpisode:episode];
#if TARGET_OS_IPHONE
            if (URL) {
                [CACHE_OPERATION_CLASS removeCacheForRemoteURL:remoteURL atLocalURL:URL];
            }
#else
            NSURL* tempURL = [self tempURLForCachedEpisode:episode];
            if (URL) {
                [CacheOperation removeCacheForRemoteURL:remoteURL atLocalURL:URL tempURL:tempURL];
            }
#endif
            [_cachedEpisodes removeObject:episode];
            cleared++;
        }
    }
    
    if (cleared > 0) {
        _downloadedBytes = 0;
        [[NSNotificationCenter defaultCenter] postNotificationName:CacheManagerDidClearCacheNotification object:self];
    }
}


- (BOOL) isCaching
{
	NSInteger cachingOps = 0;
    
    NSArray* operations = [_downloadQueue operations];
	for(CACHE_OPERATION_CLASS* operation in operations) {
		if (![operation isCancelled]) {
            cachingOps++;
        }
	}
              
	return (cachingOps > 0);
}

- (CACHE_OPERATION_CLASS*) _cacheOperationForEpisode:(CDEpisode*)episode
{
	NSURL* localURL = [self URLForCachedEpisode:episode];
	NSArray* operations = [_downloadQueue operations];
	for(CACHE_OPERATION_CLASS* operation in operations) {
		if ([operation.localURL isEqual:localURL]) {
			return operation;
		}
	}
	return nil;
}


- (BOOL) isCachingSourceOfEpisode:(CDEpisode*)episode
{
	CACHE_OPERATION_CLASS* operation = [self _cacheOperationForEpisode:episode];
	if (operation) {
		return ![operation isCancelled];
	}
	return NO;
}

- (BOOL) isCachingEpisode:(CDEpisode*)episode
{
    return [_cachingEpisodes containsObject:episode];
//	NSArray* operations = [_downloadQueue operations];
//	for(CACHE_OPERATION_CLASS* operation in operations) {
//		if ([operation.userInfo isEqual:episode]) {
//			return (![operation isCancelled] && ![operation isFinished]);
//		}
//	}
//	return NO;
}

- (BOOL) isCachingFeed:(CDFeed*)feed
{
    NSArray* operations = [_downloadQueue operations];
	for(CACHE_OPERATION_CLASS* operation in operations) {
        CDEpisode* episode = (CDEpisode*)operation.userInfo;
        if (![operation isCancelled] && [episode.feed isEqual:feed]) {
            return YES;
        }
	}
    
    return NO;
}

- (void) cancelCaching
{
    for (CDEpisode* episode in [_cachingEpisodes copy]) {
        [self cancelCachingEpisode:episode disableAutoDownload:NO];
    }
}

- (void) cancelCachingEpisode:(CDEpisode*)episode disableAutoDownload:(BOOL)disableAutodownload
{
	CACHE_OPERATION_CLASS* operation = [self _cacheOperationForEpisode:episode];
	if (operation)  {
		//BOOL executing = [operation isExecuting];
		[operation cancel];
        
        if (![operation isExecuting]) {
            [self willChangeValueForKey:@"cachingEpisodes"];
            [_cachingEpisodes removeObject:episode];
            [self didChangeValueForKey:@"cachingEpisodes"];
            _runningOps--;
            
            [self coalescedPerformSelector:@selector(_postDidUpdateNotification) afterDelay:0.1];
        }
    }
    
    if (disableAutodownload) {
        [self.cacheHistory setEpisode:episode didAutoDownload:YES];
    }
}

- (void) cancelCachingFeed:(CDFeed*)feed
{
    for (CDEpisode* episode in [_cachingEpisodes copy]) {
        if ([episode.feed isEqual:feed])
        {
            [self cancelCachingEpisode:episode disableAutoDownload:NO];
        }
    }
}


- (BOOL) isCachingSuspended
{
	if (self.suspended) {
        return YES;
    }
    
    NSArray* operations = [_downloadQueue operations];
	for(CACHE_OPERATION_CLASS* operation in operations) {
        if (operation.suspended) {
            return YES;
        }
	}
    
    return NO;
}

- (void) pauseCaching
{
    self.suspended = YES;
    
	NSArray* operations = [_downloadQueue operations];
	for(CACHE_OPERATION_CLASS* operation in operations) {
        operation.suspended = YES;
	}
    
    _rateDate = nil;
    _rateBytes = 0LL;
}

- (void) pauseCachingEpisode:(CDEpisode*)episode
{
	CACHE_OPERATION_CLASS* operation = [self _cacheOperationForEpisode:episode];
	if (operation) {
		operation.suspended = YES;
	}
    
    _rateDate = nil;
    _rateBytes = 0LL;
}

- (void) resumeCaching
{
    self.suspended = NO;
    
    NSArray* operations = [_downloadQueue operations];
    for(CACHE_OPERATION_CLASS* operation in operations) {
        operation.suspended = NO;
    }
}

- (void) resumeCachingEpisode:(CDEpisode*)episode
{
	CACHE_OPERATION_CLASS* operation = [self _cacheOperationForEpisode:episode];
	if (operation) {
		operation.suspended = NO;
	}
}

- (NSInteger) numberOfCachedEpisodes
{
    return [_cachedEpisodes count];
}


- (NSArray*) cachedEpisodes
{
    return [_cachedEpisodes allObjects];
}

+ (NSSet*) keyPathsForValuesAffectingPartiallyCachedEpisodes {
    return [NSSet setWithObjects:@"cachedEpisodes", nil];
}

- (NSArray*) partiallyCachedEpisodes
{
    NSFileManager* fman = [NSFileManager defaultManager];
    
    NSMutableArray* partiallyCachedEpisodes = [[NSMutableArray alloc] init];
    
    NSError* error = nil;
    NSArray* directoryContent = [fman contentsOfDirectoryAtPath:[CacheManager _pathToCache] error:&error];
    if (!error) {
        for(NSString* filename in directoryContent)
        {
            NSString* hash = [[filename stringByDeletingPathExtension] stringByDeletingPathExtension];
            CDEpisode* episode = [DMANAGER episodeWithObjectHash:hash];
            if (episode) {
                [partiallyCachedEpisodes addObject:episode];
            }
        }
    }
    
    return partiallyCachedEpisodes;
}

- (NSArray*) cachingEpisodes
{
	return _cachingEpisodes;
}

- (void) reorderCachingEpisodeFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    [self willChangeValueForKey:@"cachingEpisodes"];
	id object = [_cachingEpisodes objectAtIndex:fromIndex];
	[_cachingEpisodes removeObject:object];
	[_cachingEpisodes insertObject:object atIndex:toIndex];
    [self didChangeValueForKey:@"cachingEpisodes"];
}

- (void) saveFileIndex
{
    NSMutableArray* index = [[NSMutableArray alloc] init];
    for(CDEpisode* episode in self.cachedEpisodes) {
        NSMutableDictionary* entry = [[NSMutableDictionary alloc] init];
        NSURL* localURL = [self URLForCachedEpisode:episode];
        if (localURL) {
            entry[@"localFile"] = [localURL lastPathComponent];
        }
        
        NSURL* remoteURL = [episode preferedMedium].fileURL;
        if (remoteURL) {
            entry[@"remoteURL"] = [remoteURL absoluteString];
        }
        
        [index addObject:entry];
    }
    
    NSString* fileIndexPath = [[CacheManager _pathToStorageLocation] stringByAppendingPathComponent:@"FileIndex.plist"];
    [index writeToFile:fileIndexPath atomically:YES];
}

#pragma mark -
#pragma mark CacheOperation Delegate


- (void) _endBackgroundTaskAfterSoundPlayed
{
#if TARGET_OS_IPHONE

#else
    
    if (_noSystemSleepAssertionID > 0) {
        IOReturn success = IOPMAssertionRelease(_noSystemSleepAssertionID);
        if (success == kIOReturnSuccess) {
            _noSystemSleepAssertionID = 0;
        }
    }
#endif
}


- (void) cacheOperationDidEnd:(CACHE_OPERATION_CLASS*)operation
{
    _downloadedBytes = 0;
    
	CDEpisode* episode = operation.userInfo;
    
    DebugLog(@"episode did finish download: %@", episode.objectHash);
    
    @try {
        [self willChangeValueForKey:@"cachingEpisodes"];
        [_cachingEpisodes removeObject:episode];
        [self didChangeValueForKey:@"cachingEpisodes"];
    }
    @catch (NSException *exception) {
        ErrLog(@"handled exceptions: %@", exception);
    }
    @finally {
        
    }
    
    
    // find next episode to load
    for(CDEpisode* cachingEpisode in _cachingEpisodes)
    {
        CACHE_OPERATION_CLASS* nextOp = [self _cacheOperationForEpisode:cachingEpisode];
        if (![nextOp isExecuting]) {
            [nextOp setQueuePriority:NSOperationQueuePriorityVeryHigh];
            break;
        }
    }
    
    
	if (![operation isCancelled] && !operation.failed)
	{
        [self willChangeValueForKey:@"cachedEpisodes"];
        [_cachedEpisodes addObject:episode];
        [self didChangeValueForKey:@"cachedEpisodes"];

        if (!operation.automatic) {
            [DMANAGER markEpisode:episode asConsumed:NO];
        }
        
        // did auto-download
        else
        {
            [self.cacheHistory setEpisode:episode didAutoDownload:YES];
#if TARGET_OS_IPHONE
            if ([episode.feed boolForKey:EnableNewEpisodeNotification] && App.applicationState == UIApplicationStateBackground) {
                UILocalNotification* notification = [[UILocalNotification alloc] init];
                NSString* episodeTitle = [NSString stringWithFormat:@"%@ - %@", episode.feed.title, [episode cleanTitleUsingFeedTitle:episode.feed.title]];
                if ([notification respondsToSelector:@selector(alertTitle)]) {
                    notification.alertTitle = @"New Episode".ls;
                }
                if ([notification respondsToSelector:@selector(category)]) {
                    notification.category = @"episode_available";
                }
                notification.alertBody = [NSString stringWithFormat:@"'%@' is available to play.".ls, episodeTitle];
                notification.soundName = @"NewEpisodes";
                notification.userInfo = @{ @"episode_hash" : [episode objectHash], @"podcast" : episode.feed.title, @"episode" : [episode cleanTitleUsingFeedTitle:episode.feed.title]};
                [App presentLocalNotificationNow:notification];
            }
#endif
        }
        
        // in case the episode got deleted in the meantime and fault can't be fulfilled
        @try {
            episode.lastDownloaded = [NSDate date];
        }
        @catch (NSException *exception) {
            
        }
        
		
		// in case we got new authentication values, we store these in the feed
        CDFeed* feed = episode.feed;
        if (![operation.username isEqualToString:feed.username] || ![operation.password isEqualToString:feed.password]) {
            feed.username = operation.username;
            feed.password = operation.password;
            [DMANAGER save];
        }
	}
    
    
    _flags.supressSendUpdate = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:episode forKey:@"episode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:CacheManagerDidFinishCachingEpisodeNotification object:self userInfo:userInfo];
        
        [self saveCachingEpisodes];
        [self saveFileIndex];
        
        _flags.supressSendUpdate = NO;
    });
    
	_runningOps--;
	if (_runningOps == 0)
	{
		_totalOps = 0;
		[_updateTimer invalidate];
		_updateTimer = nil;
		
		if (![operation isCancelled] && !operation.failed)
		{
			BOOL notificationEnabled = [USER_DEFAULTS boolForKey:EnableManualDownloadFinishedNotification];

			if (notificationEnabled) {
#if TARGET_OS_IPHONE
				UILocalNotification* finishedNotification = [[UILocalNotification alloc] init];
				finishedNotification.alertBody = @"Downloads Finished".ls;
				[App presentLocalNotificationNow:finishedNotification];
#else
                NSUserNotification* finishedNotification = [[NSUserNotification alloc] init];
                finishedNotification.title = @"Downloads Finished".ls;
                [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:finishedNotification];
#endif
			}

			PlaySoundFile(@"DownloadFinished",NO);
            
			[self performSelector:@selector(_endBackgroundTaskAfterSoundPlayed) withObject:nil afterDelay:1.0];

        }
        else {
			[self _endBackgroundTaskAfterSoundPlayed];
		}
		
        DebugLog(@"end");
        
        _flags.supressSendUpdate = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:CacheManagerDidEndCachingNotification object:self];
            _flags.supressSendUpdate = NO;
        });
	}
    
    [self autoClearAndMakeRoomForBytes:0 automatic:operation.automatic];
}

- (void) cacheOperationHasBeenSuspended:(CACHE_OPERATION_CLASS*)operation
{
    
}

- (void) cacheOperation:(CACHE_OPERATION_CLASS*)operation didLoadNumberOfBytes:(int64_t)numberOfBytes
{
    if (!_rateDate) {
        _rateDate = [NSDate date];
        _rateBytes = 0LL;
    }
    
    _rateBytes += numberOfBytes;
}

//- (void) cacheOperationDidFail:(CACHE_OPERATION_CLASS*)operation
//{
//    // overwrite failed state when there's an internet connection
//    if (![self canDownload]) {
//        operation.suspended = YES;
//        operation.failed = NO;
//        
//        [self saveCachingEpisodes];
//        [self saveFileIndex];
//    }
//}

#pragma mark -

- (double) progress
{
	float mainProgress = (_totalOps > [[_downloadQueue operations] count]) ? (float)(_totalOps-[[_downloadQueue operations] count]) / _totalOps : 0.0f;
	float progressPerOp = 1.0f/_totalOps;
	
	for(CACHE_OPERATION_CLASS* op in [_downloadQueue operations]) {
		mainProgress += op.progress * progressPerOp;
	}
	
	return (_totalOps > 0) ? mainProgress : 0.0f;
}

- (double) cacheProgressForEpisode:(CDEpisode*)episode
{
	CACHE_OPERATION_CLASS* operation = [self _cacheOperationForEpisode:episode];
	if (operation) {
		return operation.progress;
	}
	return 0;
}

- (double) cacheProgressForFeed:(CDFeed*)feed
{
    NSInteger episodes = 0;
    double progress = 0;
    NSArray* operations = [_downloadQueue operations];
	for(CACHE_OPERATION_CLASS* operation in operations) {
        CDEpisode* episode = (CDEpisode*)operation.userInfo;
        if (![operation isCancelled] && [episode.feed isEqual:feed]) {
            episodes++;
            progress += operation.progress;
        }
	}
    
    return (episodes > 0) ? (progress / (double)episodes) : 0;
}

- (double) cacheProgress
{
    NSInteger episodes = 0;
    double progress = 0;
    NSArray* operations = [_downloadQueue operations];
	for(CACHE_OPERATION_CLASS* operation in operations) {
        if (![operation isCancelled]) {
            episodes++;
            progress += operation.progress;
        }
	}
    
    return (episodes > 0) ? (progress / (double)episodes) : 0;
}

- (long long) expectedContentLengthForEpisode:(CDEpisode*)episode
{
	CACHE_OPERATION_CLASS* operation = [self _cacheOperationForEpisode:episode];
	if (operation) {
		return operation.expectedContentLength;
	}
	return 0;
}

- (BOOL) isLoadingEpisode:(CDEpisode*)episode
{
	CACHE_OPERATION_CLASS* operation = [self _cacheOperationForEpisode:episode];
	if (operation) {
		return [operation isExecuting];
	}
	return 0;
}

- (BOOL) isLoadingEpisodeSuspended:(CDEpisode*)episode
{
	CACHE_OPERATION_CLASS* operation = [self _cacheOperationForEpisode:episode];
	if (operation) {
		return ([operation isExecuting] && operation.suspended);
	}
	return 0;
}

- (NSTimeInterval) cacheTimeLeftForEpisode:(CDEpisode*)episode
{
	CACHE_OPERATION_CLASS* operation = [self _cacheOperationForEpisode:episode];
	if (operation && !operation.suspended) {
        return operation.estimatedTimeLeft;
	}
	return 0;
}

#pragma mark -


- (void) tidyUp
{
	NSFileManager* fman = [NSFileManager defaultManager];
	
	NSMutableDictionary* validHashes = [[NSMutableDictionary alloc] init];
	for(CDFeed* feed in DMANAGER.visibleFeeds)
	{
        NSURL* refURL = feed.imageURL;
        if (!refURL) {
            continue;
        }
        
        [validHashes setObject:[NSNumber numberWithInteger:1] forKey:[[refURL absoluteString] MD5Hash]];
	}
	
	NSInteger i=0;
	NSInteger removed = 0;
	NSDirectoryEnumerator* e = [fman enumeratorAtPath:[DMANAGER.imageCacheURL path]];
	for(NSString* filename in e)
	{
		NSString* f = [filename stringByDeletingPathExtension];
		NSRange r = [f rangeOfString:@"_"];
		if (r.location != NSNotFound)
		{
			f = [f substringToIndex:r.location];
			
			if (![validHashes objectForKey:f])
			{
				NSString* path = [[DMANAGER.imageCacheURL path] stringByAppendingPathComponent:filename];
				NSError* attributesError = nil;
				NSDictionary* fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&attributesError];
				NSDate* modDate = [fileAttributes fileModificationDate];
				
				if ([[NSDate date] timeIntervalSinceDate:modDate] > 86400) {
					[fman removeItemAtPath:path error:nil];
					removed++;
				}
				i++;
			}
		}
		
		/* only check 20 files for performance reasons */
		if (i>=20) {
			break;
		}
	}
#ifdef DEBUG
    if (removed > 0) {
        NSLog(@"tidyup (removed %ld images)", (long)removed);
    }
#endif
    
    NSInteger removed_episodes = 0;
    // checking for part files that are left over
    e = [fman enumeratorAtPath:[CacheManager _pathToStorageLocation]];
    for(NSString* filename in e)
	{
        if (filename.length < 32) {
            continue;
        }
        
        NSString* episodeHash = [filename substringToIndex:32];
        if (![DMANAGER episodeWithObjectHash:episodeHash]) {
            DebugLog(@"removing episode file: %@", filename);
            [fman removeItemAtPath:[[CacheManager _pathToStorageLocation] stringByAppendingPathComponent:filename] error:nil];
            removed_episodes++;
        }
    }
#ifdef DEBUG
    if (removed_episodes > 0) {
        NSLog(@"tidyup (removed %ld episode files)", (long)removed_episodes);
    }
#endif
    _downloadedBytes = 0;
}

+ (NSSet*) keyPathsForValuesAffectingNumberOfDownloadedBytes {
    return [NSSet setWithObjects:@"cachedEpisodes", nil];
}

- (unsigned long long) numberOfDownloadedBytes
{
    if (_downloadedBytes == 0)
    {
        NSMutableArray* files = [[NSMutableArray alloc] init];
        
        NSFileManager* fman = [NSFileManager defaultManager];
        
        NSString* pathToDownloads = [CacheManager _pathToStorageLocation];
        NSDirectoryEnumerator* e = [fman enumeratorAtPath:pathToDownloads];
        for(NSString* filename in e)
        {
            NSString* path = [pathToDownloads stringByAppendingPathComponent:filename];
            [files addObject:path];
        }
        
        NSString* pathToPartialDownloads = [CacheManager _pathToCache];
        e = [fman enumeratorAtPath:pathToPartialDownloads];
        for(NSString* filename in e)
        {
            NSString* path = [pathToPartialDownloads stringByAppendingPathComponent:filename];
            [files addObject:path];
        }
        
        unsigned long long size = 0;
        
        for(NSString* path in files) {
            if ([fman fileExistsAtPath:path]) {
                
                NSError* error = nil;
                NSDictionary* fileAttributes = [fman attributesOfItemAtPath:path error:&error];
                if (!error) {
                    unsigned long long fileSize = [fileAttributes fileSize];
                    size += fileSize;
                }
            }
        }
        
        _downloadedBytes = size;
    }
    
    return _downloadedBytes;
}

- (unsigned long long) numberOfDownloadedBytesForEpisode:(CDEpisode*)episode
{
    NSFileManager* fman = [NSFileManager defaultManager];
    NSError* error = nil;
    
    NSURL* url = [self URLForCachedEpisode:episode];
    NSDictionary* fileAttributes = [fman attributesOfItemAtPath:[url path] error:&error];
    if (!error) {
        return [fileAttributes fileSize];
    }
    
    error = nil;
    url = [self tempURLForCachedEpisode:episode];
    fileAttributes = [fman attributesOfItemAtPath:[url path] error:&error];
    if (!error) {
        return [fileAttributes fileSize];
    }
    
    return 0;
}

- (BOOL) clearTheFuckingCache
{
    if ([self isCaching]) {
        return NO;
    }

    NSFileManager* fman = [NSFileManager defaultManager];
    
    NSString* pathToDownloads = [CacheManager _pathToStorageLocation];
    NSDirectoryEnumerator* e = [fman enumeratorAtPath:pathToDownloads];
	for(NSString* filename in e)
	{
        NSString* path = [pathToDownloads stringByAppendingPathComponent:filename];
        [fman removeItemAtPath:path error:nil];
	}
    
    NSString* pathToPartialDownloads = [CacheManager _pathToCache];
    e = [fman enumeratorAtPath:pathToPartialDownloads];
	for(NSString* filename in e)
	{
        NSString* path = [pathToPartialDownloads stringByAppendingPathComponent:filename];
        [fman removeItemAtPath:path error:nil];
	}
    
    
    [_cachedEpisodes removeAllObjects];
    [_cachedURLIndex removeAllObjects];
    
    _downloadedBytes = 0;
#if TARGET_OS_IPHONE
    [USER_DEFAULTS removeObjectForKey:kUserDefaultsResumeInfoKey];
#endif
    [self.cacheHistory clear];
    
    
    [self willChangeValueForKey:@"cachedEpisodes"];
    [self didChangeValueForKey:@"cachedEpisodes"];
    
    [self willChangeValueForKey:@"partiallyCachedEpisodes"];
    [self didChangeValueForKey:@"partiallyCachedEpisodes"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CacheManagerDidClearCacheNotification object:self];

    return YES;
}

- (void) saveCachingEpisodes
{
    NSMutableArray* cachingEpisodes = [[NSMutableArray alloc] init];
    
    NSArray* operations = [_downloadQueue operations];
    for(CACHE_OPERATION_CLASS* operation in operations) {
        BOOL automatic = operation.automatic;
        BOOL cellular = operation.overwriteCellularLock;
        NSDictionary* dict = @{ @"identifier" : operation.identifier, @"automatic" : @(automatic), @"cellular" : @(cellular) };
        [cachingEpisodes addObject:dict];
    }
    
    [USER_DEFAULTS setObject:cachingEpisodes forKey:kUserDefaultsCachingEpisodesKey];
    [USER_DEFAULTS synchronize];
}

- (void) restoreCachingEpisodes
{
    NSArray* cachingEpisodes = [USER_DEFAULTS objectForKey:kUserDefaultsCachingEpisodesKey];
    
    for (NSDictionary* dict in cachingEpisodes)
    {
        NSString* identifier = dict[@"identifier"];
        BOOL automatic = [dict[@"automatic"] boolValue];
        BOOL cellular = [dict[@"cellular"] boolValue];
        
        CDEpisode* episode = [DMANAGER episodeWithObjectHash:identifier];
        if (episode) {
            [self _cacheEpisode:episode autoCache:automatic overwriteCellularLock:cellular];
        }
    }
}

#pragma mark -

static NSComparisonResult ReverseDownloadDateSort(CDEpisode* obj1, CDEpisode* obj2, void *context)
{
    CDFeed* feed1 = obj1.feed;
	CDFeed* feed2 = obj2.feed;
    
    BOOL nm1 = [feed1 boolForKey:AutoDeleteNewsMode];
    BOOL nm2 = [feed2 boolForKey:AutoDeleteNewsMode];
    
    if (nm1 != nm2) {
        return (nm1) ? NSOrderedAscending : NSOrderedDescending;
    }
    
    if (obj1.consumed != obj2.consumed) {
        return (obj1.consumed) ? NSOrderedAscending : NSOrderedDescending;
    }
    
    NSDate* d1 = obj1.lastDownloaded;
    NSDate* d2 = obj2.lastDownloaded;
    
    if (d1 && d2) {
        if ([d1 earlierDate:d2] == d2) {
            return NSOrderedDescending;
        }
        else if ([d1 earlierDate:d2] == d1) {
            return NSOrderedAscending;
        }
    }
    
	
	if (feed1.rank < feed2.rank) {
		return NSOrderedDescending;
	}
	else if (feed1.rank > feed2.rank) {
		return NSOrderedAscending;
	}
    
    if ([obj1.pubDate earlierDate:obj2.pubDate] == obj2.pubDate) {
		return NSOrderedDescending;
	}
	else if ([obj1.pubDate earlierDate:obj2.pubDate] == obj1.pubDate) {
		return NSOrderedAscending;
	}
	
	return NSOrderedSame;
}

- (void) autoClearAndMakeRoomForBytes:(unsigned long long)bytes automatic:(BOOL)automatic
{
    CacheManager* cman = [CacheManager sharedCacheManager];
    
    unsigned long long maxAllowedBytes = (unsigned long long)[USER_DEFAULTS integerForKey:AutoCacheStorageLimit]*1024LLU*1024LLU;
    
    // User chose No Storage Limit
    if (maxAllowedBytes == 0) {
        return;
    }
    
    unsigned long long loadedBytes = [cman numberOfDownloadedBytes];
    unsigned long long spaceToDelete = loadedBytes - maxAllowedBytes;
    
    if (loadedBytes < maxAllowedBytes) {
        return;
    }
    
    NSArray* loadedEpisodes = [cman cachedEpisodes];
    loadedEpisodes = [loadedEpisodes sortedArrayUsingFunction:ReverseDownloadDateSort context:NULL];
    
    NSFileManager* fman = [[NSFileManager alloc] init];
    
    // delete the cache
    for(CDEpisode* episode in loadedEpisodes)
    {
        if (!episode.starred)
        {
            BOOL shouldBreak = NO;
            NSURL* url = [self URLForCachedEpisode:episode];
            if (!url) {
                continue;
            }
            
            NSError* error = nil;
            NSDictionary* fileAttributes = [fman attributesOfItemAtPath:[url path] error:&error];
            if (!error) {
                unsigned long long fileSize = [fileAttributes fileSize];
                
                if (spaceToDelete > 0) {
                    spaceToDelete -= (fileSize < spaceToDelete) ? fileSize : spaceToDelete;
                }
                if (spaceToDelete == 0) {
                    shouldBreak = YES;
                }
            }
            else {
                shouldBreak = YES;
            }
            
            _flags.supressDidClear = YES;
            [self removeCacheForEpisode:episode automatic:automatic];
            _flags.supressDidClear = NO;
            
            if (shouldBreak) {
                break;
            }
        }
        
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:CacheManagerDidClearCacheNotification object:self];
    //DebugLog(@"%@", loadedEpisodes);

}

#pragma mark - NSURLSession


- (void) handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    DebugLog(@"handleEventsForBackgroundURLSession: %@", identifier);
    
    CACHE_OPERATION_CLASS* foundOperation = nil;
    
    NSArray* operations = [_downloadQueue operations];
	for(CACHE_OPERATION_CLASS* operation in operations) {
		if ([operation.identifier isEqual:identifier]) {
            foundOperation = operation;
			break;
		}
	}
    
    if (!foundOperation) {
        CDEpisode* episode = [DMANAGER episodeWithObjectHash:identifier];
        [self _cacheEpisode:episode autoCache:NO overwriteCellularLock:YES];
    }
    
    
    
    [self perform:^(id sender) {
        DebugLog(@"sending completion handler for: %@", identifier);
        completionHandler();
    } afterDelay:2.f];
}

#pragma mark -

- (void) importFileAtURL:(NSURL*)url forEpisode:(CDEpisode*)episode completion:(void (^)(BOOL success, NSError* error))completion
{
    [self removeCacheForEpisode:episode automatic:NO];
    
    NSURL* cachedURL = [self URLForCachedEpisode:episode];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager* fman = [[NSFileManager alloc] init];
        NSError* error;
        BOOL success = [fman copyItemAtURL:url toURL:cachedURL error:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            [self willChangeValueForKey:@"cachedEpisodes"];
            [_cachedEpisodes addObject:episode];
            [self didChangeValueForKey:@"cachedEpisodes"];
            
            if (completion) {
                completion(success, error);
            }
        });
    });
    
    
    
}
@end
