//
//  DatabaseManager.h
//  Instacast
//
//  Created by Martin Hering on 22.12.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSTimeInterval kTrialReferenceDate;

extern NSString* DatabaseManagerDidUpdateObservedFeedNotification;
extern NSString* DatabaseManagerDidAddBookmarkNotification;


typedef NS_ENUM(NSInteger, ICSubscribeOptions) {
    kSubscribeOptionNone                    = 0,
    kSubscribeOptionDontManageConsumedFlags = 1 << 1,
    kSubscribeOptionDontManageRanking       = 1 << 2
};


#define DMANAGER [DatabaseManager sharedDatabaseManager]

@class ICFeed, ICEpisode, ICMedia, ICFTSController, CDEpisodeList;

@interface DatabaseManager : NSObject
    
+ (DatabaseManager*) sharedDatabaseManager;
+ (NSString*) pathToDocuments;
+ (BOOL) dataStoreNeedsMigration;

@property (nonatomic, strong, readonly) NSManagedObjectContext* objectContext;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator* storeCoordinator;
@property (nonatomic, strong, readonly) NSManagedObjectModel* objectModel;

#if !TARGET_OS_IPHONE
@property (nonatomic, strong, readonly) NSArrayController* feedsController;
@property (nonatomic, strong, readonly) NSArrayController* bookmarksController;
#endif

@property (nonatomic, strong, readonly) ICFTSController* ftsController;
@property (nonatomic, readonly) BOOL ftsIndexing;

- (void) save;

// only syncs affected changes and send out pushes
- (void) saveAndSync:(BOOL)sync;

- (void) beginInterruptSaving;
- (void) endInterruptSaving;

    
@property (strong, readonly) NSURL* databaseURL;
@property (strong, readonly) NSURL* imageCacheURL;
@property (strong, readonly) NSURL* fileCacheURL;

// feeds
@property (readonly) NSArray* feeds; // observable
@property (readonly) NSArray* visibleFeeds; // observable

- (BOOL) feedExists:(CDFeed*)feed;
- (CDFeed*) subscribeFeed:(ICFeed*)feed;
- (CDFeed*) subscribeFeed:(ICFeed*)feed withOptions:(ICSubscribeOptions)options;

- (void) unsubscribeFeed:(CDFeed*)feed;
- (CDFeed*) feedWithTitle:(NSString*)title;
- (CDFeed*) feedWithSourceURL:(NSURL*)sourceURL;

- (void) reorderFeedFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
- (void) sortFeedsByKey:(NSString*)key ascending:(BOOL)ascending selector:(SEL)selector;

// playlists
@property (readonly, strong) NSArray* lists;
- (void) addList:(CDList*)list;
- (void) removeList:(CDList*)list;
- (void) reorderListFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
@property (nonatomic, readonly) CDEpisodeList* unplayedList;

- (CDEpisode*) addNewParserEpisode:(ICEpisode*)episode toFeed:(CDFeed*)feed wasNew:(BOOL*)wasNew;
- (CDEpisode*) addUnsubscribedFeed:(ICFeed*)feed andEpisode:(ICEpisode*)episode;

// bookmarks
@property (readonly, strong) NSArray* bookmarks;
- (void) addBookmark:(CDBookmark*)bookmark;
- (void) removeBookmark:(CDBookmark*)bookmark;


#pragma mark -

- (void) markEpisode:(CDEpisode*)episode asConsumed:(BOOL)flag;
- (void) markEpisode:(CDEpisode*)episode asStarred:(BOOL)flag;
- (void) setEpisode:(CDEpisode*)episode position:(double)position;
- (void) setEpisode:(CDEpisode *)episode archived:(BOOL)archived;
- (void) deleteEpisode:(CDEpisode*)episode;

#pragma mark -

- (CDEpisode*) episodeWithGuid:(NSString*)guid;
- (CDEpisode*) episodeWithObjectHash:(NSString*)objectHash;
- (NSArray*) episodesWithObjectHashes:(NSArray*)hashes;

- (void) _copyFeedValuesFrom:(ICFeed*)parserFeed to:(CDFeed*)persistentFeed;
- (void) _copyEpisodeValuesFrom:(ICEpisode*)parserEpisode to:(CDEpisode*)persistentEpisode;
- (void) _copyMediumValuesFrom:(ICMedia*)parserMedium to:(CDMedium*)persistentMedium;

@end
