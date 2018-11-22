//
//  CDEpisodeList.m
//  Instacast
//
//  Created by Martin Hering on 18.08.14.
//
//

NSString* kEpisodeIconUnplayed = @"List Unplayed";

#import "CDEpisodeList.h"
#import "ICFTSController.h"

@interface CDEpisodeList ()
@property (nonatomic) NSNumber* cachedEpisodesCount;
@end

@implementation CDEpisodeList {
    BOOL _observing;
    NSNumber* _cachedEpisodesCount;
}


@dynamic icon;
@dynamic query;

@dynamic audio;
@dynamic video;

@dynamic downloaded;
@dynamic downloading;
@dynamic notDownloaded;

@dynamic starred;
@dynamic notStarred;

@dynamic unplayed;
@dynamic unfinished;
@dynamic played;

@dynamic orderBy;
@dynamic groupByPodcast;
@dynamic descending;
@dynamic continuousPlayback;

@dynamic includedFeeds;
@dynamic episodes;
@dynamic cachedEpisodesCount;



- (void) setObserving:(BOOL)observing
{
    if (!_observing && observing)
    {
        _observing = YES;
    }
    else if (_observing && !observing)
    {
        _observing = NO;
    }
}


- (void) awakeFromFetch
{
    [super awakeFromFetch];
    
    if (self.managedObjectContext == DMANAGER.objectContext) {
        [self setObserving:YES];
    }
    if ([self.orderBy isEqualToString:@"manuel"]) {
        self.orderBy = @"pubDate";
    }
}

- (void) awakeFromInsert
{
    [super awakeFromInsert];
    
    // should have been set correctly in the model, bummer
    self.continuousPlayback = NO;
    
    if (self.managedObjectContext == DMANAGER.objectContext) {
        [self setObserving:YES];
    }
}

- (void) willTurnIntoFault
{
    if (self.managedObjectContext == DMANAGER.objectContext) {
        [self setObserving:NO];
    }
}

- (NSInteger) playbackTime
{
    return 0;
}

- (IC_IMAGE*) image
{
#if TARGET_OS_IPHONE
    UIImage* image = [[UIImage imageNamed:self.icon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    return (image) ? image : [super image];
#else
    return [NSImage imageNamed:self.icon];
#endif
}

- (NSArray*) sortedEpisodes
{
    if ([self.episodes count] > 0) {
        return [self.episodes array];
    }
    
    
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:self.managedObjectContext];
#ifdef DEBUG
    NSDate* start = [NSDate date];
#endif
    NSMutableArray* subPredicates = [[NSMutableArray alloc] init];
    [subPredicates addObject:[NSPredicate predicateWithFormat:@"feed.subscribed == YES AND archived = NO"]];
    
    if (!self.audio) {
        [subPredicates addObject:[NSPredicate predicateWithFormat:@"video == YES"]];
    }
    
    if (!self.video) {
        [subPredicates addObject:[NSPredicate predicateWithFormat:@"video == NO"]];
    }
    
    if (!self.unplayed) {
        [subPredicates addObject:[NSPredicate predicateWithFormat:@"consumed == YES OR (consumed == NO AND position > 0)"]];
    }
    
    if (!self.unfinished) {
        [subPredicates addObject:[NSPredicate predicateWithFormat:@"position == 0"]];
    }
    
    if (!self.played) {
        [subPredicates addObject:[NSPredicate predicateWithFormat:@"consumed == NO"]];
    }
    
    if (!self.starred) {
        [subPredicates addObject:[NSPredicate predicateWithFormat:@"starred == NO"]];
    }
    
    if (!self.notStarred) {
        [subPredicates addObject:[NSPredicate predicateWithFormat:@"starred == YES"]];
    }
    
    if ([self.includedFeeds count] > 0)
    {
        NSMutableArray* includedFeedsSubPredicates = [[NSMutableArray alloc] init];
        for(CDFeed* feed in self.includedFeeds) {
            [includedFeedsSubPredicates addObject:[NSPredicate predicateWithFormat:@"feed == %@", feed]];
        }
        
        [subPredicates addObject:[NSCompoundPredicate orPredicateWithSubpredicates:includedFeedsSubPredicates]];
    }
    
    if ([self.query length] > 0) {
        NSSet* episodeGuids = [DMANAGER.ftsController episodeUIDsForSearchTerm:self.query];
        [subPredicates addObject:[NSPredicate predicateWithFormat:@"guid IN %@", episodeGuids]];
    }
    
    // add filters for order value
//    if (self.orderBy && ![self.orderBy isEqualToString:@"timeLeft"]) {
//        [subPredicates addObject:[NSPredicate predicateWithFormat:@"%K != nil", self.orderBy]];
//    }
    
    // fetch from sql store
    NSPredicate* mainPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];

    fetchRequest.predicate = mainPredicate;
    fetchRequest.includesSubentities = NO;
    fetchRequest.resultType = NSDictionaryResultType;
    
    NSMutableArray* fetchedProperties = [[NSMutableArray alloc] initWithObjects:@"objectHash", nil];
    if ([self.orderBy isEqualToString:@"timeLeft"]) {
        [fetchedProperties addObject:@"duration"];
        [fetchedProperties addObject:@"position"];
    } else if (self.orderBy) {
        [fetchedProperties addObject:self.orderBy];
    }
    
    
    if (self.groupByPodcast) {
        [fetchedProperties addObject:@"feed.rank"];
    }
    fetchRequest.propertiesToFetch = fetchedProperties;
    
    
    
    NSMutableArray* sortDescriptors = [[NSMutableArray alloc] init];
    if (self.groupByPodcast) {
        [sortDescriptors addObject:[[NSSortDescriptor alloc] initWithKey:@"feed.rank" ascending:YES]];
    }
    if (self.orderBy && ![self.orderBy isEqualToString:@"timeLeft"]) {
        [sortDescriptors addObject:[[NSSortDescriptor alloc] initWithKey:self.orderBy ascending:!self.descending]];
    }
    if ([sortDescriptors count] > 0) {
        fetchRequest.sortDescriptors = sortDescriptors;
    }
    
    
    NSError* error;
    NSArray* objects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    // sort manually
    if ([self.orderBy isEqualToString:@"timeLeft"]) {
        objects = [objects sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
            NSInteger timeLeft1 = [obj1[@"duration"] integerValue] - [obj1[@"position"] integerValue];
            NSInteger timeLeft2 = [obj2[@"duration"] integerValue] - [obj2[@"position"] integerValue];
            
            if (timeLeft1 == timeLeft2) {
                return NSOrderedSame;
            }
            
            if (self.descending) {
                return (timeLeft1 > timeLeft2) ? NSOrderedAscending : NSOrderedDescending;
            }
            return (timeLeft1 < timeLeft2) ? NSOrderedAscending : NSOrderedDescending;
        }];
    }
    

    DebugLog(@"stage 1: %lf, %ld", [[NSDate date] timeIntervalSinceDate:start], (long)[objects count]);
    

    
    NSArray* objectHashes = [objects valueForKey:@"objectHash"];
    NSMutableSet* filteredObjectHashes = [[NSMutableSet alloc] initWithArray:objectHashes];
    
    
    // additionally filter for transient properties
    if (!self.downloaded || !self.notDownloaded)
    {
        NSArray* cachedEpisodes = [[CacheManager sharedCacheManager] cachedEpisodes];
        
        // filter all out that are downloaded
        if (!self.downloaded) {
            for(CDEpisode* episode in cachedEpisodes) {
                [filteredObjectHashes removeObject:episode.objectHash];
            }
        }
        
        //filter all out that are not downloaded
        else if (!self.notDownloaded)
        {
            NSMutableSet* cachedHashes = [[NSMutableSet alloc] init];
            for(CDEpisode* episode in cachedEpisodes) {
                [cachedHashes addObject:episode.objectHash];
            }
            
            for(NSString* objectHash in objectHashes) {
                if (![cachedHashes containsObject:objectHash]) {
                    [filteredObjectHashes removeObject:objectHash];
                }
            }
        }
        
        objectHashes = [filteredObjectHashes allObjects];
    }
    
    DebugLog(@"stage 2: %lf, %ld", [[NSDate date] timeIntervalSinceDate:start], (long)[objectHashes count]);
    
    // limit search results to 1000
    if ([objectHashes count] > 500) {
        objectHashes = [objectHashes subarrayWithRange:NSMakeRange(0, 500)];
    }
    
    
    NSFetchRequest* fetchRequest2 = [[NSFetchRequest alloc] init];
    fetchRequest2.entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:self.managedObjectContext];
    fetchRequest2.predicate = [NSPredicate predicateWithFormat:@"objectHash IN %@", objectHashes];
    fetchRequest2.includesSubentities = NO;
    fetchRequest2.sortDescriptors = sortDescriptors;

    
    NSError* error2;
    NSArray* stage3Objects = [self.managedObjectContext executeFetchRequest:fetchRequest2 error:&error2];
    
    DebugLog(@"stage 3: %lf, %ld", [[NSDate date] timeIntervalSinceDate:start], (long)[stage3Objects count]);
    
    if ([self.orderBy isEqualToString:@"timeLeft"]) {
        stage3Objects = [stage3Objects sortedArrayUsingComparator:^NSComparisonResult(CDEpisode* obj1, CDEpisode* obj2) {
            NSInteger timeLeft1 = obj1.duration - obj1.position;
            NSInteger timeLeft2 = obj2.duration - obj2.position;
            
            if (timeLeft1 == timeLeft2) {
                return NSOrderedSame;
            }
            
            if (self.descending) {
                return (timeLeft1 > timeLeft2) ? NSOrderedAscending : NSOrderedDescending;
            }
            return (timeLeft1 < timeLeft2) ? NSOrderedAscending : NSOrderedDescending;
        }];
    }
    
    self.cachedEpisodesCount = @(stage3Objects.count);
    return stage3Objects;
}


- (NSUInteger) numberOfEpisodes
{
    if (!self.cachedEpisodesCount) {
        [self perform:^(id sender) {
            [self calculateNumberOfEpisodesCompletion:^(NSUInteger numberOfEpisodes) {
            }];
        } afterDelay:0.1];
    }
    
    return [self.cachedEpisodesCount unsignedIntegerValue];
}

- (void) calculateNumberOfEpisodesCompletion:(void (^)(NSUInteger numberOfEpisodes))completion
{
    if (!completion) {
        return;
    }
    
    if (self.cachedEpisodesCount) {
        completion([self.cachedEpisodesCount unsignedIntegerValue]);
        return;
    }
    
    if ([self.episodes count] > 0) {
        self.cachedEpisodesCount = @([self.episodes count]);
        completion([self.episodes count]);
        return;
    }
    
    NSManagedObjectID* selfId = [self objectID];
    
    NSManagedObjectContext* childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [childContext performBlock:^{
        
        childContext.persistentStoreCoordinator = DMANAGER.storeCoordinator;
        
        NSError* error;
        CDEpisodeList* contextSelf = (CDEpisodeList*)[childContext existingObjectWithID:selfId error:&error];
        if (error) {
            ErrLog(@"error getting episode list in child context: %@", error);
            return;
        }
        
        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
        fetchRequest.entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:childContext];
#ifdef DEBUG
        NSDate* start = [NSDate date];
#endif
        NSMutableArray* subPredicates = [[NSMutableArray alloc] init];
        [subPredicates addObject:[NSPredicate predicateWithFormat:@"feed.subscribed == YES AND archived = NO"]];
        
        if (!contextSelf.audio) {
            [subPredicates addObject:[NSPredicate predicateWithFormat:@"video == YES"]];
        }
        
        if (!contextSelf.video) {
            [subPredicates addObject:[NSPredicate predicateWithFormat:@"video == NO"]];
        }
        
        if (!contextSelf.unplayed) {
            [subPredicates addObject:[NSPredicate predicateWithFormat:@"consumed == YES OR (consumed == NO AND position > 0)"]];
        }
        
        if (!contextSelf.unfinished) {
            [subPredicates addObject:[NSPredicate predicateWithFormat:@"position == 0"]];
        }
        
        if (!contextSelf.played) {
            [subPredicates addObject:[NSPredicate predicateWithFormat:@"consumed == NO"]];
        }
        
        if (!contextSelf.starred) {
            [subPredicates addObject:[NSPredicate predicateWithFormat:@"starred == NO"]];
        }
        
        if (!contextSelf.notStarred) {
            [subPredicates addObject:[NSPredicate predicateWithFormat:@"starred == YES"]];
        }
        
        if ([contextSelf.includedFeeds count] > 0)
        {
            NSMutableArray* includedFeedsSubPredicates = [[NSMutableArray alloc] init];
            for(CDFeed* feed in contextSelf.includedFeeds) {
                [includedFeedsSubPredicates addObject:[NSPredicate predicateWithFormat:@"feed == %@", feed]];
            }
            
            [subPredicates addObject:[NSCompoundPredicate orPredicateWithSubpredicates:includedFeedsSubPredicates]];
        }
        
        if ([contextSelf.query length] > 0) {
            NSSet* episodeGuids = [DMANAGER.ftsController episodeUIDsForSearchTerm:contextSelf.query];
            [subPredicates addObject:[NSPredicate predicateWithFormat:@"guid IN %@", episodeGuids]];
        }
        
        
        // add filters for order value
        if (contextSelf.orderBy && ![contextSelf.orderBy isEqualToString:@"timeLeft"]) {
            [subPredicates addObject:[NSPredicate predicateWithFormat:@"%K != nil", contextSelf.orderBy]];
        }
        
        // fetch from sql store
        NSPredicate* mainPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
        
        fetchRequest.predicate = mainPredicate;
        fetchRequest.includesSubentities = NO;
        fetchRequest.resultType = NSDictionaryResultType;
        fetchRequest.propertiesToFetch = @[@"objectHash"];
        
        NSError* fetchError;
        NSArray* objects = [childContext executeFetchRequest:fetchRequest error:&fetchError];
        NSArray* objectHashes = [objects valueForKey:@"objectHash"];
        NSMutableSet* filteredObjectHashes = [[NSMutableSet alloc] initWithArray:objectHashes];
        
        
        // additionally filter for transient properties
        if (!contextSelf.downloaded || !contextSelf.notDownloaded)
        {
            NSArray* cachedEpisodes = [[CacheManager sharedCacheManager] cachedEpisodes];
            
            // filter all out that are downloaded
            if (!contextSelf.downloaded) {
                for(CDEpisode* episode in cachedEpisodes) {
                    [filteredObjectHashes removeObject:episode.objectHash];
                }
            }
            
            //filter all out that are not downloaded
            else if (!contextSelf.notDownloaded)
            {
                NSMutableSet* cachedHashes = [[NSMutableSet alloc] init];
                for(CDEpisode* episode in cachedEpisodes) {
                    [cachedHashes addObject:episode.objectHash];
                }
                
                for(NSString* objectHash in objectHashes) {
                    if (![cachedHashes containsObject:objectHash]) {
                        [filteredObjectHashes removeObject:objectHash];
                    }
                }
            }
        }
        
        
        DebugLog(@"count of '%@ (%@)': %lf, %ld", contextSelf.name, contextSelf.uid, [[NSDate date] timeIntervalSinceDate:start], (long)[filteredObjectHashes count]);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSUInteger count = [filteredObjectHashes count];
            self.cachedEpisodesCount = @(count);
            completion(count);
        });

    }];
}

- (void) invalidateCaches {
    [self invalidateSortedEpisodes];
    self.cachedEpisodesCount = nil;
}

- (void) invalidateSortedEpisodes
{
    [self willChangeValueForKey:@"sortedEpisodes"];
    self.episodes = nil;
    [self didChangeValueForKey:@"sortedEpisodes"];
}

//- (void) addNumberOfEpisodes:(NSInteger)number
//{
//    if (!self.cachedEpisodesCount) {
//        return;
//    }
//    
//    self.cachedEpisodesCount = @(MAX(0,[self.cachedEpisodesCount integerValue]+number));
//}

- (NSNumber*) cachedEpisodesCount {
    return _cachedEpisodesCount;
}

- (void) setCachedEpisodesCount:(NSNumber *)cachedEpisodesCount
{
    if ([_cachedEpisodesCount integerValue] != [cachedEpisodesCount integerValue]) {
        [self willChangeValueForKey:@"numberOfEpisodes"];
        _cachedEpisodesCount = cachedEpisodesCount;
        [self didChangeValueForKey:@"numberOfEpisodes"];
    }
}
@end
