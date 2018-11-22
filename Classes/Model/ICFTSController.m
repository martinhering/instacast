//
//  ICFTSController.m
//  Instacast
//
//  Created by Martin Hering on 28.08.14.
//
//

#import "ICFTSController.h"

@interface ICFTSController ()
@property (nonatomic, strong) NSURL* searchIndexURL;
@property (nonatomic, strong) FMDatabaseQueue *queue;
@end

@implementation ICFTSController

- (id) initWithSearchIndexURL:(NSURL*)url
{
    if ((self = [super init])) {
        _searchIndexURL = url;
    }

    return self;
}

- (void) open
{
    self.queue = [FMDatabaseQueue databaseQueueWithPath:[self.searchIndexURL path]];
    [self.queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"CREATE VIRTUAL TABLE IF NOT EXISTS feeds USING fts4(title, author, summary, uid)"];
        [db executeUpdate:@"CREATE VIRTUAL TABLE IF NOT EXISTS episodes USING fts4(title, summary, fulltext, uid, feed_uid)"];
    }];
}


- (void) indexFeeds:(NSArray*)feeds
{
    [self.queue inDatabase:^(FMDatabase *db) {
        [db beginTransaction];
        for(CDFeed* feed in feeds)
        {
            @autoreleasepool {
                if (![db executeUpdate:@"INSERT INTO feeds (title, author, summary, uid) VALUES(?,?,?,?)", feed.title, feed.author, feed.summary, [feed.sourceURL absoluteString]]) {
                    ErrLog(@"%@", [db lastErrorMessage]);
                };
                
                for(CDEpisode* episode in feed.episodes) {
                    if (![db executeUpdate:@"INSERT INTO episodes (title, summary, fulltext, uid, feed_uid) VALUES(?,?,?,?,?)", episode.title, episode.summary, [episode.fulltext stringByStrippingHTML], episode.guid, [episode.feed.sourceURL absoluteString]]) {
                        ErrLog(@"%@", [db lastErrorMessage]);
                    };
                }
            }
        }
        [db commit];
    }];
}



- (void) addFeed:(CDFeed*)feed
{
    [self.queue inDatabase:^(FMDatabase *db) {
        if (![db executeUpdate:@"INSERT INTO feeds (title, author, summary, uid) VALUES(?,?,?,?)", feed.title, feed.author, feed.summary, [feed.sourceURL absoluteString]]) {
            ErrLog(@"%@", [db lastErrorMessage]);
        };
    }];
}

- (void) removeFeed:(CDFeed*)feed
{
    [self.queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"DELETE FROM feeds WHERE uid = ?", [feed.sourceURL absoluteString]];
    }];
}

- (void) addEpisode:(CDEpisode*)episode
{
    [self.queue inDatabase:^(FMDatabase *db) {
        if (![db executeUpdate:@"INSERT INTO episodes (title, summary, fulltext, uid, feed_uid) VALUES(?,?,?,?,?)", episode.title, episode.summary, [episode.fulltext stringByStrippingHTML], episode.guid, [episode.feed.sourceURL absoluteString]]) {
            ErrLog(@"%@", [db lastErrorMessage]);
        };
    }];
}

- (void) removeEpisode:(CDEpisode*)episode
{
    [self.queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"DELETE FROM episodes WHERE uid = ?", episode.objectHash];
    }];
}

#pragma mark -

- (NSSet*) feedUIDsForSearchTerm:(NSString*)searchTerm
{
    __block NSMutableSet* uids = [[NSMutableSet alloc] init];
    
    [self.queue inDatabase:^(FMDatabase *db) {
        NSString* searchQuery = [NSString stringWithFormat:@"title:%@* OR author:%@* OR summary:%@*", searchTerm, searchTerm, searchTerm];
        FMResultSet *rs = [db executeQuery:@"SELECT uid FROM feeds WHERE feeds MATCH ?", searchQuery];
        while ([rs next]) {
            NSString* uid = [rs stringForColumn:@"uid"];
            if (uid) {
                [uids addObject:uid];
            }
        }
        [rs close];
    }];
    
    [self.queue inDatabase:^(FMDatabase *db) {
        NSString* searchQuery = [NSString stringWithFormat:@"title:%@* OR summary:%@* OR fulltext:%@*", searchTerm, searchTerm, searchTerm];
        FMResultSet *rs = [db executeQuery:@"SELECT DISTINCT feed_uid FROM episodes WHERE episodes MATCH ?", searchQuery];
        while ([rs next]) {
            NSString* uid = [rs stringForColumn:@"feed_uid"];
            if (uid) {
                [uids addObject:uid];
            }
        }
        [rs close];
    }];
    
    return uids;
}

- (NSSet*) episodeUIDsForSearchTerm:(NSString*)searchTerm
{
    __block NSMutableSet* uids = [[NSMutableSet alloc] init];
    
    [self.queue inDatabase:^(FMDatabase *db) {
        NSString* searchQuery = [NSString stringWithFormat:@"title:%@* OR summary:%@* OR fulltext:%@*", searchTerm, searchTerm, searchTerm];
        FMResultSet *rs = [db executeQuery:@"SELECT DISTINCT uid FROM episodes WHERE episodes MATCH ?", searchQuery];
        while ([rs next]) {
            NSString* uid = [rs stringForColumn:@"uid"];
            if (uid) {
                [uids addObject:uid];
            }
        }
        [rs close];
    }];
    
    return uids;
}
@end
