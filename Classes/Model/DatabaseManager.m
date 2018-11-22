//
//  DatabaseManager.m
//  Instacast
//
//  Created by Martin Hering on 22.12.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import <objc/runtime.h>
#include <sys/xattr.h>

#import "ICManagedObjectContext.h"
#if TARGET_OS_IPHONE
#else
#import "ICSharingManager.h"
#endif

#import "ICFeed.h"
#import "ICEpisode.h"
#import "ICMedia.h"
#import "ICCategory.h"

#import "UIManager.h"
#import "ICFTSController.h"

// legacy migration
#import "CDSmartPlaylist.h"
#import "CDPlaylist.h"
#import "FSCrossbucketConnection.h"


#define MODEL_VERSION 4
NSTimeInterval kTrialReferenceDate = 0;

static DatabaseManager* gSharedDatabaseManager = nil;

NSString* DatabaseManagerDidUpdateObservedFeedNotification = @"DatabaseManagerDidUpdateObservedFeedNotification";
NSString* DatabaseManagerDidAddBookmarkNotification = @"DatabaseManagerDidAddBookmarkNotification";

static NSString* kDefaultEpisodePositionMigrationDone = @"EpisodePositionMigrationDone";
static NSString* kDefaultFTSMigrationDone = @"FTSMigrationDone";

#if TARGET_OS_IPHONE

static NSString* kFeedsProperty = @"feeds";
static NSString* kListsProperty = @"lists";
static NSString* kBookmarksProperty = @"bookmarks";


@interface DatabaseManager () <NSFetchedResultsControllerDelegate>
#else
@interface DatabaseManager ()
#endif

@property (nonatomic, strong, readwrite) ICManagedObjectContext* objectContext;
@property (nonatomic, strong, readwrite) NSPersistentStoreCoordinator* storeCoordinator;
@property (nonatomic, strong, readwrite) NSManagedObjectModel* objectModel;
@property (nonatomic, strong, readwrite) ICFTSController* ftsController;
@property (nonatomic, readwrite) BOOL ftsIndexing;
@end


@implementation DatabaseManager {
@protected
#if TARGET_OS_IPHONE
    NSFetchedResultsController* _feedsController;
    NSFetchedResultsController* _listsController;
    NSFetchedResultsController* _bookmarksController;
#else
    NSArrayController*          _feedsController;
    NSArrayController*          _listsController;
    NSArrayController*          _bookmarksController;
#endif
    NSInteger                   _savingInterruption;
}

+ (NSString*) pathToDocuments
{
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* path = [paths lastObject];
    
#if !TARGET_OS_IPHONE
    path = [path stringByAppendingPathComponent:@"Instacast"];
#endif
    
    return path;
}

+ (NSString*) pathToSubfolder:(NSString*)subfolder parent:(NSString*)pathToParentFolder
{
	if (!pathToParentFolder) {
		return nil;
	}
	
	NSString* pathToSubFolder = [pathToParentFolder stringByAppendingPathComponent:subfolder];
	
	NSFileManager* fman = [NSFileManager defaultManager];
    
	if (![fman fileExistsAtPath:pathToSubFolder])
	{
		NSError* error = nil;
		if (![fman createDirectoryAtPath:pathToSubFolder withIntermediateDirectories:YES
							  attributes:nil
								   error:&error]) {
			ErrLog(@"error creating directory %@: %@", pathToSubFolder, [error description]);
			return nil;
		}
	}
    
    return pathToSubFolder;
}

+ (DatabaseManager*) sharedDatabaseManager
{
	if (!gSharedDatabaseManager) {
		gSharedDatabaseManager = [self alloc];
		gSharedDatabaseManager = [gSharedDatabaseManager init];
	}
	return gSharedDatabaseManager;
}

#pragma mark -

NS_INLINE NSString* _ModelFile() {
    return [NSString stringWithFormat:@"Model%d", MODEL_VERSION];
}

NS_INLINE NSString* _DataStoreFile() {
    return [NSString stringWithFormat:@"DataStore%d.sqlite", MODEL_VERSION];
}

+ (NSURL*) _urlOfLastDataStoreFile
{
    NSFileManager* fman = [[NSFileManager alloc] init];
    NSInteger version;
    for(version = MODEL_VERSION-1; version>0; version--)
    {
        NSURL* url = [NSURL fileURLWithPath:[[DatabaseManager pathToDocuments] stringByAppendingPathComponent:[NSString stringWithFormat:@"DataStore%ld.sqlite", (long)version]]];
        if ([fman fileExistsAtPath:[url path]]) {
            return url;
        }
        
    }
    
    return [NSURL fileURLWithPath:[[DatabaseManager pathToDocuments] stringByAppendingPathComponent:@"DataStore.sqlite"]];;
}

+ (BOOL) dataStoreNeedsMigrationForFileAtURL:(NSURL*)storeURL
{
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:_ModelFile() withExtension:@"momd"];
    NSManagedObjectModel* destinationModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    NSError *error = nil;
    NSDictionary *sourceMetadata;
    
    @try {
        sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
                                                                                    URL:storeURL
                                                                                options:nil
                                                                                  error:&error];
    }
    @catch (NSException *exception) {
        DebugLog(@"core data exception: %@", exception);
    }
    
    return (![destinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata]);
}

+ (BOOL) dataStoreNeedsMigration
{
    // check current file
    NSURL* storeURL = [NSURL fileURLWithPath:[[DatabaseManager pathToDocuments] stringByAppendingPathComponent:_DataStoreFile()]];
    NSFileManager* fman = [[NSFileManager alloc] init];
    if ([fman fileExistsAtPath:[storeURL path]]) {
        return [self dataStoreNeedsMigrationForFileAtURL:storeURL];
    }
    
    // check old file
    NSURL* urlOfLastDataStoreFile = [self _urlOfLastDataStoreFile];
    if ([fman fileExistsAtPath:[urlOfLastDataStoreFile path]]) {
        return [self dataStoreNeedsMigrationForFileAtURL:urlOfLastDataStoreFile];
    }
    
    return NO;
}

- (id) init
{
	if ((self = [super init]))
	{
        _databaseURL = [NSURL fileURLWithPath:[[DatabaseManager pathToDocuments] stringByAppendingPathComponent:_DataStoreFile()]];
        DebugLog(@"%@", _databaseURL);
        
        _imageCacheURL = [NSURL fileURLWithPath:[DatabaseManager pathToSubfolder:@"Images" parent:[DatabaseManager pathToDocuments]]];
        _fileCacheURL = [NSURL fileURLWithPath:[DatabaseManager pathToSubfolder:@"Episodes" parent:[DatabaseManager pathToDocuments]]];
        
        
        // find old database file and make a copy for new database
        if (![[NSFileManager defaultManager] fileExistsAtPath:[_databaseURL path]])
        {
            NSURL* urlOfLastDataStoreFile = [DatabaseManager _urlOfLastDataStoreFile];
            if ([[NSFileManager defaultManager] fileExistsAtPath:[urlOfLastDataStoreFile path]])
            {
                NSError* error;
                if (![[NSFileManager defaultManager] copyItemAtURL:urlOfLastDataStoreFile toURL:_databaseURL error:&error]) {
                    ErrLog(@"error copying old database file to new location");
                }
                
                NSURL* shmURL = [[urlOfLastDataStoreFile URLByDeletingPathExtension] URLByAppendingPathExtension:@"sqlite-shm"];
                NSURL* toShmURL = [[_databaseURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"sqlite-shm"];
                if ([[NSFileManager defaultManager] fileExistsAtPath:[shmURL path]]) {
                    NSError* error;
                    if (![[NSFileManager defaultManager] copyItemAtURL:shmURL toURL:toShmURL error:&error]) {
                        ErrLog(@"error copying old database shm file to new location");
                    }
                }
                
                NSURL* walURL = [[urlOfLastDataStoreFile URLByDeletingPathExtension] URLByAppendingPathExtension:@"sqlite-wal"];
                NSURL* toWalURL = [[_databaseURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"sqlite-wal"];
                if ([[NSFileManager defaultManager] fileExistsAtPath:[walURL path]]) {
                    NSError* error;
                    if (![[NSFileManager defaultManager] copyItemAtURL:walURL toURL:toWalURL error:&error]) {
                        ErrLog(@"error copying old database wal file to new location");
                    }
                }
            }
        }
        
        
        // create initial data when started first
        if (![[NSFileManager defaultManager] fileExistsAtPath:[_databaseURL path]]) {
            [self _createDatabase];
        }
        else {
            [self _migrateDatabase];
            [self _deleteUnsubscribedFeeds];
        }
        
        
        
#if TARGET_OS_IPHONE
        NSFetchRequest* feedsRequest = [[NSFetchRequest alloc] init];
        feedsRequest.entity = [NSEntityDescription entityForName:@"Feed" inManagedObjectContext:self.objectContext];
        feedsRequest.predicate = [NSPredicate predicateWithFormat:@"subscribed == %@", @YES];
        feedsRequest.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"rank" ascending:YES] ];
        
        NSFetchRequest* listsRequest = [[NSFetchRequest alloc] init];
        listsRequest.entity = [NSEntityDescription entityForName:@"List" inManagedObjectContext:self.objectContext];
        listsRequest.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"rank" ascending:YES] ];
        
        NSFetchRequest* bookmarksRequest = [[NSFetchRequest alloc] init];
        bookmarksRequest.entity = [NSEntityDescription entityForName:@"Bookmark" inManagedObjectContext:self.objectContext];
        bookmarksRequest.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"position" ascending:YES] ];
        
        

        [NSFetchedResultsController deleteCacheWithName:@"_databasemanager_feeds_"];
        _feedsController = [[NSFetchedResultsController alloc] initWithFetchRequest:feedsRequest
                                                               managedObjectContext:self.objectContext
                                                                 sectionNameKeyPath:nil
                                                                          cacheName:@"_databasemanager_feeds_"];
        _feedsController.delegate = self;
        [_feedsController performFetch:nil];
        
        
        

        
        [NSFetchedResultsController deleteCacheWithName:@"_databasemanager_lists_"];
        _listsController = [[NSFetchedResultsController alloc] initWithFetchRequest:listsRequest
                                                               managedObjectContext:self.objectContext
                                                                 sectionNameKeyPath:nil
                                                                          cacheName:@"_databasemanager_lists_"];
        _listsController.delegate = self;
        [_listsController performFetch:nil];
        
        

        
        [NSFetchedResultsController deleteCacheWithName:@"_databasemanager_bookmarks_"];
        _bookmarksController = [[NSFetchedResultsController alloc] initWithFetchRequest:bookmarksRequest
                                                               managedObjectContext:self.objectContext
                                                                 sectionNameKeyPath:nil
                                                                          cacheName:@"_databasemanager_bookmarks_"];
        _bookmarksController.delegate = self;
        [_bookmarksController performFetch:nil];
#else
        _feedsController = [[NSArrayController alloc] initWithContent:nil];
        [_feedsController setManagedObjectContext:self.objectContext];
        [_feedsController setEntityName:@"Feed"];
        [_feedsController setFetchPredicate:[NSPredicate predicateWithFormat:@"subscribed == %@", @YES]];
        [_feedsController setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"rank" ascending:YES]]];
        [_feedsController setAutomaticallyPreparesContent:YES];
        [_feedsController setAvoidsEmptySelection:NO];
        [_feedsController fetchWithRequest:nil merge:YES error:nil];
        
        
        _bookmarksController = [[NSArrayController alloc] initWithContent:nil];
        [_bookmarksController setManagedObjectContext:self.objectContext];
        [_bookmarksController setEntityName:@"Bookmark"];
        [_bookmarksController setSortDescriptors:@[ [[NSSortDescriptor alloc] initWithKey:@"position" ascending:YES] ]];
        [_bookmarksController setAutomaticallyPreparesContent:YES];
        [_bookmarksController setAvoidsEmptySelection:NO];
        [_bookmarksController fetchWithRequest:nil merge:YES error:nil];
        
        _listsController = [[NSArrayController alloc] initWithContent:nil];
        [_listsController setManagedObjectContext:self.objectContext];
        [_listsController setEntityName:@"List"];
        [_listsController setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"rank" ascending:YES]]];
        [_listsController setAutomaticallyPreparesContent:YES];
        [_listsController setAvoidsEmptySelection:YES];
        [_listsController fetchWithRequest:nil merge:YES error:nil];
        
#endif
        
        
        _ftsController = [[ICFTSController alloc] initWithSearchIndexURL:[NSURL fileURLWithPath:[[DatabaseManager pathToDocuments] stringByAppendingPathComponent:@"FTSIndex.sqlite"]]];
        [_ftsController open];
        
        [self _migrateFTS];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(managedObjectContextObjectsDidChangeNotification:)
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:self.objectContext];
	}
	
	return self;
}

- (void) _createDatabase
{
    CDEpisodeList* unplayed = [NSEntityDescription insertNewObjectForEntityForName:@"EpisodeList" inManagedObjectContext:self.objectContext];
    unplayed.name = @"Unplayed".ls;
    unplayed.icon = @"List Unplayed";
    unplayed.rank = 0;
    unplayed.played = NO;
    unplayed.orderBy = @"pubDate";
    unplayed.descending = YES;
    unplayed.groupByPodcast = NO;
    unplayed.uid = @"default.unplayed";
    
    
    CDEpisodeList* downloaded = [NSEntityDescription insertNewObjectForEntityForName:@"EpisodeList" inManagedObjectContext:self.objectContext];
    downloaded.name = @"Downloaded".ls;
    downloaded.icon = @"List Downloaded";
    downloaded.rank = 1;
    downloaded.notDownloaded = NO;
    downloaded.orderBy = @"pubDate";
    downloaded.descending = YES;
    downloaded.groupByPodcast = NO;
    downloaded.uid = @"default.downloaded";
    
    
    CDEpisodeList* favorites = [NSEntityDescription insertNewObjectForEntityForName:@"EpisodeList" inManagedObjectContext:self.objectContext];
    favorites.name = @"Favorites".ls;
    favorites.icon = @"List Favorites";
    favorites.rank = 2;
    favorites.notStarred = NO;
    favorites.orderBy = @"pubDate";
    favorites.descending = YES;
    favorites.groupByPodcast = NO;
    favorites.uid = @"default.favorites";
    
    
    CDEpisodeList* video = [NSEntityDescription insertNewObjectForEntityForName:@"EpisodeList" inManagedObjectContext:self.objectContext];
    video.name = @"Videos".ls;
    video.icon = @"List Video";
    video.rank = 3;
    video.audio = NO;
    video.orderBy = @"pubDate";
    video.descending = YES;
    video.groupByPodcast = NO;
    video.uid = @"default.video";
    
    [self save];
}

- (void) _migrateOldSmartPlaylists
{
    NSFetchRequest* listsRequest = [[NSFetchRequest alloc] init];
    listsRequest.entity = [NSEntityDescription entityForName:@"List" inManagedObjectContext:self.objectContext];
    
    NSError* error;
    NSArray* lists = [self.objectContext executeFetchRequest:listsRequest error:&error];
    
    for(CDList* list in lists)
    {
        if ([list isKindOfClass:[CDSmartPlaylist class]])
        {
            CDSmartPlaylist* smartPlaylist = (CDSmartPlaylist*)list;
            
            NSString* type = [smartPlaylist.smartPredicate objectForKey:@"type"];
            
            if ([type isEqualToString:kSmartListTypeUnplayed])
            {
                CDEpisodeList* newList = [NSEntityDescription insertNewObjectForEntityForName:@"EpisodeList" inManagedObjectContext:self.objectContext];
                newList.name = smartPlaylist.name;
                newList.icon = @"List Unplayed";
                newList.rank = smartPlaylist.rank;
                newList.played = NO;
                newList.orderBy = @"pubDate";
                newList.descending = YES;
                newList.groupByPodcast = NO;
                newList.uid = @"default.unplayed";
                
                [self.objectContext deleteObject:smartPlaylist];
            }
            
            else if ([type isEqualToString:kSmartListTypeStarred])
            {
                CDEpisodeList* newList = [NSEntityDescription insertNewObjectForEntityForName:@"EpisodeList" inManagedObjectContext:self.objectContext];
                newList.name = smartPlaylist.name;
                newList.icon = @"List Favorites";
                newList.rank = smartPlaylist.rank;
                newList.notStarred = NO;
                newList.orderBy = @"pubDate";
                newList.descending = YES;
                newList.groupByPodcast = NO;
                newList.uid = @"default.favorites";
                
                [self.objectContext deleteObject:smartPlaylist];
            }
            else if ([type isEqualToString:kSmartListTypeDownload])
            {
                CDEpisodeList* newList = [NSEntityDescription insertNewObjectForEntityForName:@"EpisodeList" inManagedObjectContext:self.objectContext];
                newList.name = smartPlaylist.name;
                newList.icon = @"List Downloaded";
                newList.rank = smartPlaylist.rank;
                newList.notDownloaded = NO;
                newList.orderBy = @"pubDate";
                newList.descending = YES;
                newList.groupByPodcast = NO;
                newList.uid = @"default.downloaded";
                
                [self.objectContext deleteObject:smartPlaylist];
            }
            else if ([type isEqualToString:kSmartListTypePartiallyPlayed])
            {
                CDEpisodeList* newList = [NSEntityDescription insertNewObjectForEntityForName:@"EpisodeList" inManagedObjectContext:self.objectContext];
                newList.name = smartPlaylist.name;
                newList.icon = @"List Partially Played";
                newList.rank = smartPlaylist.rank;
                newList.played = NO;
                newList.unplayed = NO;
                newList.orderBy = @"pubDate";
                newList.descending = YES;
                newList.groupByPodcast = NO;
                newList.uid = @"default.partiallyplayed";
                
                [self.objectContext deleteObject:smartPlaylist];
            }
            else if ([type isEqualToString:kSmartListTypeMostRecent])
            {
                CDEpisodeList* newList = [NSEntityDescription insertNewObjectForEntityForName:@"EpisodeList" inManagedObjectContext:self.objectContext];
                newList.name = smartPlaylist.name;
                newList.icon = @"List Most Recent";
                newList.rank = smartPlaylist.rank;
                newList.orderBy = @"pubDate";
                newList.descending = YES;
                newList.groupByPodcast = NO;
                newList.uid = @"default.mostrecent";
                
                [self.objectContext deleteObject:smartPlaylist];
            }
            else if ([type isEqualToString:kSmartListTypeRecentlyPlayed])
            {
                CDEpisodeList* newList = [NSEntityDescription insertNewObjectForEntityForName:@"EpisodeList" inManagedObjectContext:self.objectContext];
                newList.name = smartPlaylist.name;
                newList.icon = @"List Recently Played";
                newList.rank = smartPlaylist.rank;
                newList.orderBy = @"lastPlayed";
                newList.descending = YES;
                newList.groupByPodcast = NO;
                newList.uid = @"default.recentlyplayed";
                
                [self.objectContext deleteObject:smartPlaylist];
            }
        }
        else if ([list isKindOfClass:[CDPlaylist class]])
        {
            // custom list migration doesn't work and has been removed
            // no support anymore
            [self.objectContext deleteObject:list];
        }
    }
}


- (void) _migrateFTS
{
    if ([USER_DEFAULTS boolForKey:kDefaultFTSMigrationDone]) {
        return;
    }
    
    self.ftsIndexing = YES;
    
    NSManagedObjectContext* childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [childContext setParentContext:self.objectContext];
    
    [childContext performBlock:^{
        
        NSFetchRequest* feedRequest = [[NSFetchRequest alloc] init];
        feedRequest.entity = [NSEntityDescription entityForName:@"Feed" inManagedObjectContext:childContext];
        feedRequest.fetchBatchSize = 50;
        
        NSError* error;
        NSArray* objects = [childContext executeFetchRequest:feedRequest error:&error];
        if (error) {
            ErrLog(@"error fetching feeds from private context: %@", error);
        }
        
        [self.ftsController indexFeeds:objects];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [USER_DEFAULTS setBool:YES forKey:kDefaultFTSMigrationDone];
            self.ftsIndexing = NO;
        });
    }];
}

- (void) _migrateDatabase
{
    [self _migrateOldSmartPlaylists];
}

- (void) _deleteUnsubscribedFeeds
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Feed" inManagedObjectContext:self.objectContext];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"subscribed == NO"];
    NSArray* unsubscribedFeeds = [self.objectContext executeFetchRequest:fetchRequest error:nil];
    
    for(NSManagedObject* feed in unsubscribedFeeds) {
        [self.objectContext deleteObject:feed];
    }
    
}

- (void) save
{
    [self saveAndSync:YES];
}

- (void) saveAndSync:(BOOL)sync
{
    if (_savingInterruption == 0)
    {
        NSMutableSet* set = [[NSMutableSet alloc] init];
        [set unionSet:[self.objectContext insertedObjects]];
        [set unionSet:[self.objectContext updatedObjects]];
        [set unionSet:[self.objectContext deletedObjects]];
        

        for(CDBase* object in set)
        {
            if ([object isKindOfClass:[CDEpisode class]] && [object hasChanges]) {
                [self coalescedPerformSelector:@selector(_invalidateListCaches) afterDelay:0.1];
            }
            else if ([object isKindOfClass:[CDFeed class]] && [object hasChanges]) {
                [self coalescedPerformSelector:@selector(_invalidateListCaches) afterDelay:0.1];
            }
            
        }
        
        
        NSError* error;
        [self.objectContext save:&error];
        
        if (error) {
            ErrLog(@"error saving database context: %@", error);
        }
    }
}


#if TARGET_OS_IPHONE

- (void) _sendObservedFeedsDidChangeNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:DatabaseManagerDidUpdateObservedFeedNotification
                                                        object:self
                                                      userInfo:nil];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    if (controller == _feedsController) {
        [self coalescedPerformSelector:@selector(_sendObservedFeedsDidChangeNotification)];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (controller == _feedsController) {
        [self willChangeValueForKey:kFeedsProperty];
        [self didChangeValueForKey:kFeedsProperty];
    }
    else if (controller == _listsController) {
        [self willChangeValueForKey:kListsProperty];
        [self didChangeValueForKey:kListsProperty];
    }
    else if (controller == _bookmarksController) {
        [self willChangeValueForKey:kBookmarksProperty];
        [self didChangeValueForKey:kBookmarksProperty];
    }
}

#endif

- (void) managedObjectContextObjectsDidChangeNotification:(NSNotification*)notification
{
    NSDictionary* userInfo = [notification userInfo];
    NSSet* insertedObjects = userInfo[NSInsertedObjectsKey];
    NSSet* updatedObjects = userInfo[NSUpdatedObjectsKey];
    NSSet* deletedObjects = userInfo[NSDeletedObjectsKey];
    
    //    NSMutableSet* set = [[NSMutableSet alloc] init];
    //    [set unionSet:insertedObjects];
    //    [set unionSet:updatedObjects];
    //    [set unionSet:deletedObjects];
    
    
    for(NSManagedObject* insertedObject in insertedObjects)
    {
        if ([insertedObject isKindOfClass:[CDEpisode class]]) {
            [self.ftsController addEpisode:(CDEpisode*)insertedObject];
        }
        else if ([insertedObject isKindOfClass:[CDFeed class]]) {
            [self.ftsController addFeed:(CDFeed*)insertedObject];
        }
    }
    
    for(NSManagedObject* updatedObject in updatedObjects)
    {
        NSDictionary* cv = [updatedObject changedValues];
        
        if ([updatedObject isKindOfClass:[CDEpisode class]] && (cv[@"title"] || cv[@"summary"] || cv[@"fulltext"])) {
            [self.ftsController addEpisode:(CDEpisode*)updatedObject];
        }
        else if ([updatedObject isKindOfClass:[CDFeed class]] && (cv[@"title"] || cv[@"author"] || cv[@"summary"])) {
            [self.ftsController addFeed:(CDFeed*)updatedObject];
        }
    }
    
    for(NSManagedObject* deletedObject in deletedObjects)
    {
        if ([deletedObject isKindOfClass:[CDEpisode class]]) {
            [self.ftsController removeEpisode:(CDEpisode*)deletedObject];
        }
        else if ([deletedObject isKindOfClass:[CDFeed class]]) {
            [self.ftsController removeFeed:(CDFeed*)deletedObject];
        }
    }
}


- (void) beginInterruptSaving
{
    @synchronized(self) {
        _savingInterruption++;
    }
}

- (void) endInterruptSaving
{
    @synchronized(self) {
        _savingInterruption--;
    }
}

#pragma mark Feeds

- (NSArray*) feeds
{
#if TARGET_OS_IPHONE
    return [_feedsController fetchedObjects];
#else
    return [_feedsController arrangedObjects];
#endif
}

- (NSArray*) visibleFeeds
{
    return [self.feeds filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"parked == NO"]];
}

- (void) _updateFeedOrderNums:(NSArray*)feeds
{
	NSInteger num = 0;
	for(CDFeed* feed in feeds) {
		feed.rank = (int32_t)num;
		num++;
	}
}


- (BOOL) feedExists:(CDFeed*)aFeed
{
	for(CDFeed* feed in self.feeds) {
		if ([feed isEqual:aFeed]) {
			return YES;
		}
	}
	
	return NO;
}

- (void) _mergeExistingEpisodes:(NSArray*)existingEpisodes withNewEpisodes:(NSArray*)newEpisodes andResetPlaybackStatesOfFeed:(CDFeed*)feed
{
    if ([newEpisodes count] > [existingEpisodes count])
    {
        // merge new episodes with existing ones
        for(ICEpisode* newEpisode in newEpisodes)
        {
            BOOL contained = NO;
            for(CDEpisode* existingEpisode in existingEpisodes) {
                if ([existingEpisode.objectHash isEqualToString:newEpisode.objectHash]) {
                    contained = YES;
                    break;
                }
            }
            
            if (!contained)
            {
                BOOL wasNew;
                CDEpisode* episode = [self addNewParserEpisode:newEpisode toFeed:feed wasNew:&wasNew];
                if (wasNew) {
                    episode.consumed = NO;
                }
            }
        }
    }
}

- (void) _copyFeedValuesFrom:(ICFeed*)parserFeed to:(CDFeed*)persitentFeed
{
    persitentFeed.title = parserFeed.title;
    persitentFeed.subtitle = parserFeed.subtitle;
    persitentFeed.sourceURL = parserFeed.sourceURL;
    persitentFeed.imageURL = parserFeed.imageURL;
    persitentFeed.pubDate = parserFeed.pubDate;
    persitentFeed.lastUpdate = parserFeed.lastUpdate;
    persitentFeed.video = parserFeed.video;
    persitentFeed.completed = parserFeed.completed;
    persitentFeed.linkURL = parserFeed.linkURL;
    persitentFeed.language = parserFeed.language;
    persitentFeed.country = parserFeed.country;
    persitentFeed.summary = parserFeed.summary;
    persitentFeed.fulltext = parserFeed.textDescription;
    persitentFeed.author = parserFeed.author;
    persitentFeed.copyright = parserFeed.copyright;
    persitentFeed.owner = parserFeed.owner;
    persitentFeed.ownerEmail = parserFeed.ownerEmail;
    persitentFeed.explicitContent = parserFeed.explicitContent;
    persitentFeed.paymentURL = parserFeed.paymentURL;
    persitentFeed.username = parserFeed.username;
    persitentFeed.password = parserFeed.password;
    persitentFeed.etag = parserFeed.etag;
    persitentFeed.contentHash = parserFeed.contentHash;
}

- (void) _copyEpisodeValuesFrom:(ICEpisode*)parserEpisode to:(CDEpisode*)persitentEpisode
{
    persitentEpisode.objectHash = parserEpisode.objectHash;
    persitentEpisode.title = parserEpisode.title;
    persitentEpisode.subtitle = parserEpisode.subtitle;
    persitentEpisode.guid = parserEpisode.guid;
    persitentEpisode.pubDate = parserEpisode.pubDate;
    persitentEpisode.imageURL = parserEpisode.imageURL;
    persitentEpisode.linkURL = parserEpisode.link;
    persitentEpisode.author = parserEpisode.author;
    persitentEpisode.summary = parserEpisode.summary;
    persitentEpisode.fulltext = parserEpisode.textDescription;
    persitentEpisode.paymentURL = parserEpisode.paymentURL;
    persitentEpisode.deeplinkURL = parserEpisode.deeplink;
    persitentEpisode.video = parserEpisode.video;
    persitentEpisode.explicitContent = parserEpisode.explicitContent;
    persitentEpisode.duration = (int32_t)parserEpisode.duration;
}

- (void) _copyMediumValuesFrom:(ICMedia*)parserMedium to:(CDMedium*)persitentMedium
{
    persitentMedium.fileURL = parserMedium.fileURL;
    persitentMedium.byteSize = parserMedium.byteSize;
    persitentMedium.mimeType = parserMedium.mimeType;
}

- (CDEpisode*) addNewParserEpisode:(ICEpisode*)parserEpisode toFeed:(CDFeed*)feed wasNew:(BOOL*)wasNew
{
    if (wasNew) *wasNew = NO;
    
    
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:self.objectContext];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"objectHash == %@", parserEpisode.objectHash];
    CDEpisode* persistentEpisode = [[self.objectContext executeFetchRequest:fetchRequest error:nil] firstObject];
    
    if (!persistentEpisode) {
        persistentEpisode = [NSEntityDescription insertNewObjectForEntityForName:@"Episode" inManagedObjectContext:self.objectContext];
        if (wasNew) *wasNew = YES;
    }
    [self _copyEpisodeValuesFrom:parserEpisode to:persistentEpisode];
    
    NSMutableSet* media = [[NSMutableSet alloc] init];
    for(ICMedia* parserMedia in parserEpisode.media)
    {
        if (parserMedia.fileURL) {
            CDMedium* persistentMedium = [NSEntityDescription insertNewObjectForEntityForName:@"Medium" inManagedObjectContext:self.objectContext];
            [self _copyMediumValuesFrom:parserMedia to:persistentMedium];
            [media addObject:persistentMedium];
        }
    }
    persistentEpisode.media = media;
    [feed addEpisodesObject:persistentEpisode];
    
    return persistentEpisode;
}

- (CDEpisode*) addUnsubscribedFeed:(ICFeed*)parserFeed andEpisode:(ICEpisode*)parserEpisode
{
    // create feed
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Feed" inManagedObjectContext:self.objectContext];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"sourceURL_ == %@", parserFeed.sourceURL];
    NSArray* feeds = [self.objectContext executeFetchRequest:fetchRequest error:nil];
    CDFeed* persistentFeed = [feeds lastObject];
    
    if (!persistentFeed)
    {
        persistentFeed = [NSEntityDescription insertNewObjectForEntityForName:@"Feed" inManagedObjectContext:self.objectContext];
        [self _copyFeedValuesFrom:parserFeed to:persistentFeed];
        
        NSMutableSet* categories = [[NSMutableSet alloc] init];
        for(ICCategory* parserCategory in parserFeed.categories) {
            CDCategory* category = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:self.objectContext];
            category.title = parserCategory.title;
            
            if (parserCategory.parent) {
                CDCategory* parentCategory = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:self.objectContext];
                parentCategory.title = parserCategory.parent.title;
                category.parent = parentCategory;
            }
            
            [categories addObject:category];
        }
        persistentFeed.categories = categories;
        persistentFeed.subscribed = YES;
        persistentFeed.parked = YES;
    }
    
    // create episode
    NSFetchRequest* episodeFetchRequest = [[NSFetchRequest alloc] init];
    episodeFetchRequest.entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:self.objectContext];
    episodeFetchRequest.predicate = [NSPredicate predicateWithFormat:@"objectHash == %@", parserEpisode.objectHash];
    NSArray* episodes = [self.objectContext executeFetchRequest:episodeFetchRequest error:nil];
    CDEpisode* persistentEpisode = [episodes lastObject];
    
    if (!persistentEpisode)
    {
        BOOL wasNew;
        persistentEpisode = [self addNewParserEpisode:parserEpisode toFeed:persistentFeed wasNew:&wasNew];
        if (wasNew) {
            persistentEpisode.consumed = NO;
        }
    }
    
    return persistentEpisode;
}


- (CDFeed*) subscribeFeed:(ICFeed*)parserFeed withOptions:(ICSubscribeOptions)options
{
	if (!parserFeed) {
		return nil;
	}

    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Feed" inManagedObjectContext:self.objectContext];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"sourceURL_ == %@", parserFeed.sourceURL];
    NSArray* objects = [self.objectContext executeFetchRequest:fetchRequest error:nil];
    CDFeed* persistentFeed = [objects lastObject];
    
    
    if (persistentFeed && persistentFeed.episodesCount > 0)
    {
        NSSortDescriptor* pubDateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pubDate" ascending:NO];
        NSArray* parserEpisodes = [parserFeed.episodes sortedArrayUsingDescriptors:@[ pubDateDescriptor ]];
        NSArray* persistentEpisodes = [persistentFeed.episodes sortedArrayUsingDescriptors:@[ pubDateDescriptor ]];
        [self _mergeExistingEpisodes:persistentEpisodes withNewEpisodes:parserEpisodes andResetPlaybackStatesOfFeed:persistentFeed];
        
        [[SubscriptionManager sharedSubscriptionManager] updateLocalFeedInfo:persistentFeed withRemoteFeed:parserFeed force:YES];
        
        // delete cached chapters
        for(CDEpisode* episode in persistentFeed.episodes) {
            NSSet* chapters = [episode.chapters copy];
            for(NSManagedObject* chapter in chapters) {
                [self.objectContext deleteObject:chapter];
            }
            
            // recover all deleted episodes
            episode.archived = NO;
        }
    }
    else
    {
        if (!persistentFeed) {
            persistentFeed = [NSEntityDescription insertNewObjectForEntityForName:@"Feed" inManagedObjectContext:self.objectContext];
        }
    
        [self _copyFeedValuesFrom:parserFeed to:persistentFeed];
        
        ICEpisode* firstEpisode = [parserFeed.episodes firstObject];
        
        if (firstEpisode)
        {
            NSDateComponents* firstComps = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay)
                                                                           fromDate:firstEpisode.pubDate];
        
            for(ICEpisode* parserEpisode in parserFeed.episodes)
            {
                BOOL wasNew;
                CDEpisode* persistentEpisode = [self addNewParserEpisode:parserEpisode toFeed:persistentFeed wasNew:&wasNew];
                
                if (wasNew && (options & kSubscribeOptionDontManageConsumedFlags) == 0)
                {
                    NSDateComponents* comps = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay)
                                                                              fromDate:parserEpisode.pubDate];
                    
                    if ([comps day] != [firstComps day] || [comps month] != [firstComps month] || [comps year] != [firstComps year]) {
                        persistentEpisode.consumed = YES;
                    }
                    else {
                        persistentEpisode.consumed = NO;
                    }
                }
            }
        }
        
        NSMutableSet* categories = [[NSMutableSet alloc] init];
        for(ICCategory* parserCategory in parserFeed.categories) {
            CDCategory* category = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:self.objectContext];
            category.title = parserCategory.title;
            
            if (parserCategory.parent) {
                CDCategory* parentCategory = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:self.objectContext];
                parentCategory.title = parserCategory.parent.title;
                category.parent = parentCategory;
            }
            
            [categories addObject:category];
        }
        persistentFeed.categories = categories;
    }
    
    
    persistentFeed.subscribed = YES;
    
    if ((options & kSubscribeOptionDontManageRanking) == 0) {
        NSMutableArray* feedsCopy = [self.feeds mutableCopy];
        [feedsCopy insertObject:persistentFeed atIndex:0];
        [self _updateFeedOrderNums:feedsCopy];
    }
    
    [self save];
    
    return persistentFeed;
}

- (CDFeed*) subscribeFeed:(ICFeed*)feed
{
	return [self subscribeFeed:feed withOptions:kSubscribeOptionNone];
}

- (void) unsubscribeFeed:(CDFeed*)feed
{
	if ([self feedExists:feed])
	{
		feed.subscribed = NO;
        [self save];
	}
}

- (CDFeed*) feedWithTitle:(NSString*)title
{
    for(CDFeed* feed in self.feeds) {
        if ([feed.title isEqual:title]) {
            return feed;
        }
    }
    return nil;
}

- (CDFeed*) feedWithSourceURL:(NSURL*)sourceURL
{
    for(CDFeed* feed in self.feeds) {
        if ([feed.sourceURL isEqual:sourceURL]) {
            return feed;
        }
    }
    return nil;
}

- (void) reorderFeedFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
    if (fromIndex == toIndex) {
        return;
    }

    
    NSMutableArray* feedsCopy = [self.visibleFeeds mutableCopy];
    
	CDFeed* feed = [feedsCopy objectAtIndex:fromIndex];
	[feedsCopy removeObject:feed];
	[feedsCopy insertObject:feed atIndex:toIndex];
	
	[self _updateFeedOrderNums:feedsCopy];
    [self save];
}

- (void) sortFeedsByKey:(NSString*)key ascending:(BOOL)ascending selector:(SEL)selector
{
	NSMutableArray* feedsCopy = [self.feeds mutableCopy];
    

	NSSortDescriptor* descriptor;
    if (selector) {
        descriptor = [[NSSortDescriptor alloc] initWithKey:key
                                                 ascending:ascending
                                                  selector:selector];
    }
    else {
        descriptor = [[NSSortDescriptor alloc] initWithKey:key
                                                 ascending:ascending];
    }
    
                                    
    [feedsCopy sortUsingDescriptors:[NSArray arrayWithObject:descriptor]];
	[self _updateFeedOrderNums:feedsCopy];
    [self save];
}


#pragma mark -
#pragma mark Lists

- (NSArray*) lists
{
#if TARGET_OS_IPHONE
    return [_listsController fetchedObjects];
#else
    return [_listsController arrangedObjects];
#endif
}

- (void) addList:(CDList*)list
{
#if TARGET_OS_IPHONE
    [CDList updateRanksOfLists:self.lists];
#else
    [CDList updateRanksOfLists:self.lists];
#endif
    
    [self save];
}

- (void) removeList:(CDList*)list
{
#if TARGET_OS_IPHONE
    [self.objectContext deleteObject:list];
    [_listsController performFetch:nil];
#else
    [_listsController removeObject:list];
#endif
    
    [self save];
}

- (void) reorderListFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
    NSMutableArray* listsCopy = [self.lists mutableCopy];
	CDList* list = [listsCopy objectAtIndex:fromIndex];
	[listsCopy removeObject:list];
	[listsCopy insertObject:list atIndex:toIndex];
	
	[CDList updateRanksOfLists:listsCopy];
    [self save];
}

- (void) _invalidateListCaches
{
    for(CDEpisodeList* list in self.lists) {
        [list invalidateCaches];
    }
}

- (CDEpisodeList*) unplayedList
{
    for(CDEpisodeList* list in DMANAGER.lists) {
        if ([list isKindOfClass:[CDEpisodeList class]]) {
            if ([list.icon isEqualToString:@"List Unplayed"]) {
                return list;
            }
        }
    }
    
    // if there is not unplayed list, create one
    CDEpisodeList* unplayedList = [NSEntityDescription insertNewObjectForEntityForName:@"EpisodeList" inManagedObjectContext:DMANAGER.objectContext];
    unplayedList.name = @"Unplayed".ls;
    unplayedList.icon = @"List Unplayed";
    unplayedList.rank = (int32_t)[DMANAGER.lists count]+1;
    unplayedList.played = NO;
    unplayedList.orderBy = @"pubDate";
    unplayedList.descending = YES;
    unplayedList.groupByPodcast = NO;
    unplayedList.uid = @"default.unplayed";
    [DMANAGER save];
    
    return unplayedList;
}


#pragma mark -
#pragma mark Bookmarks

- (NSArray*) bookmarks
{
#if TARGET_OS_IPHONE
    return [_bookmarksController fetchedObjects];
#else
    return [_bookmarksController arrangedObjects];
#endif
}

- (void) addBookmark:(CDBookmark*)bookmark
{
    [[NSNotificationCenter defaultCenter] postNotificationName:DatabaseManagerDidAddBookmarkNotification object:self];
}

- (void) removeBookmark:(CDBookmark*)bookmark
{
    [self.objectContext deleteObject:bookmark];
    [self save];
}

#pragma mark -

- (void) markEpisode:(CDEpisode*)episode asConsumed:(BOOL)flag
{
    if (episode.consumed != flag)
    {
        episode.consumed = flag;
    
        if (flag) {
            episode.position = 0;
        }
        [self save];
    }
    
    
    if (!flag) {
        [[SubscriptionManager sharedSubscriptionManager] autoDownloadEpisode:episode];
    }
    else
    {
        if ([episode.feed boolForKey:AutoDeleteAfterMarkedAsPlayed] && !episode.starred) {
            [[CacheManager sharedCacheManager] removeCacheForEpisode:episode automatic:YES];
        }
    }
}

- (void) markEpisode:(CDEpisode*)episode asStarred:(BOOL)flag
{
    if (episode.starred != flag)
    {
        episode.starred = flag;
        [self save];

#if !TARGET_OS_IPHONE
        if (flag) {
            [[ICSharingManager sharedManager] triggerEvent:ICSharingServiceEpisodeMarkedAsStarred object:episode];
        }
#endif
    }
}

- (void) setEpisode:(CDEpisode*)episode position:(double)position
{
    episode.position = position;
}

- (void) _removeEpisodeReferences:(CDEpisode*)episode
{
    [self beginInterruptSaving];
    
    [[AudioSession sharedAudioSession] eraseEpisodesFromUpNext:@[episode]];
    [[CacheManager sharedCacheManager] removeCacheForEpisode:episode automatic:YES];
    
    [self endInterruptSaving];
}

- (void) setEpisode:(CDEpisode *)episode archived:(BOOL)archived
{
    episode.archived = archived;
        
    if (archived)
    {
        [self markEpisode:episode asConsumed:YES];
        [self _removeEpisodeReferences:episode];
    }
    
    [self save];
}

- (void) deleteEpisode:(CDEpisode*)episode
{
    [self _removeEpisodeReferences:episode];
    [self.objectContext deleteObject:episode];
    
    [self save];
}

- (NSArray*) episodesWithObjectHashes:(NSArray*)hashes
{
    NSManagedObjectContext* context = self.objectContext;
    
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:context];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"objectHash IN %@", hashes];
    NSArray* episodes = [context executeFetchRequest:fetchRequest error:nil];
    return episodes;
}

- (CDEpisode*) episodeWithObjectHash:(NSString*)objectHash
{
    NSManagedObjectContext* context = self.objectContext;
    
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:context];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"objectHash == %@", objectHash];
    NSArray* episodes = [context executeFetchRequest:fetchRequest error:nil];
    return [episodes firstObject];
}

- (CDEpisode*) episodeWithGuid:(NSString*)guid
{
    NSManagedObjectContext* context = self.objectContext;
    
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:context];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"guid == %@", guid];
    NSArray* episodes = [context executeFetchRequest:fetchRequest error:nil];
    return [episodes firstObject];
}

- (NSUInteger) numberOfAllUnseenEpisodes
{
    NSManagedObjectContext* context = self.objectContext;
    
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:context];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"feed.subscribed == %@ && feed.parked == %@ && archived == %@ && consumed == %@", @YES, @NO, @NO, @NO];
    return [context countForFetchRequest:fetchRequest error:nil];
}

- (NSArray*) allUnseenEpisodesReverseOrder:(BOOL)reverseOrder
{
    NSManagedObjectContext* context = self.objectContext;
    
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:context];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"feed.subscribed == %@ && feed.parked == %@ && archived == %@ && consumed == %@", @YES, @NO, @NO, @NO];
    fetchRequest.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"pubDate" ascending:reverseOrder] ];
    return [context executeFetchRequest:fetchRequest error:nil];
}


#pragma mark -

- (NSManagedObjectContext *) objectContext
{
    if (_objectContext) {
        return _objectContext;
    }
    
    NSPersistentStoreCoordinator* coordinator = [self persistentStoreCoordinator];
    if (coordinator)
    {
        ICManagedObjectContext* context = [[ICManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        _objectContext = context;
        [_objectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return _objectContext;
}


- (NSManagedObjectModel *) objectModel
{
    if (_objectModel) {
        return _objectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:_ModelFile() withExtension:@"momd"];
    _objectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _objectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_storeCoordinator != nil) {
        return _storeCoordinator;
    }
    
    NSError *error = nil;
    _storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self objectModel]];
    if (![_storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                         configuration:nil
                                                   URL:self.databaseURL
                                               options:@{NSMigratePersistentStoresAutomaticallyOption : @YES, NSInferMappingModelAutomaticallyOption : @YES }
                                                 error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
#ifdef DEBUG
    for(NSPersistentStore* store in [_storeCoordinator persistentStores]) {
        DebugLog(@"%@", [store type]);
    }
#endif
    
    return _storeCoordinator;
}

@end
