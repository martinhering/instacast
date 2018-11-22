//
//  CDPlaylist.m
//  Instacast
//
//  Created by Martin Hering on 09.08.12.
//
//

#import "CDPlaylist.h"
#import "CDPlaylistEpisode.h"
#import "CDEpisode.h"

NSString* CDPlaylistDidChangeEpisodesNotification = @"CDPlaylistDidChangeEpisodesNotification";

@interface CDPlaylist ()
@property (nonatomic, retain) NSSet* playlistEpisodes;
@property (nonatomic) BOOL dummyClear;
@end


@interface CDPlaylist (CoreDataGeneratedAccessors)

- (void)addEpisodesObject:(CDPlaylistEpisode *)value;
- (void)removeEpisodesObject:(CDPlaylistEpisode *)value;
- (void)addEpisodes:(NSSet *)values;
- (void)removeEpisodes:(NSSet *)values;

@end


@implementation CDPlaylist {
    NSMutableArray* _cachedEpisodes;
    BOOL _userAction;
    BOOL _observing;
}

- (void) setObserving:(BOOL)observing
{
    if (!_observing && observing)
    {
        __weak CDPlaylist* weakSelf = self;
        [self addTaskObserver:self forKeyPath:@"playlistEpisodes" task:^(id obj, NSDictionary *change) {
            [weakSelf _clearCacheWhenChangingExternally];
        }];
        
        _observing = YES;
    }
    else if (_observing && !observing)
    {
        [self removeTaskObserver:self forKeyPath:@"playlistEpisodes"];
        _observing = NO;
    }
}

- (void) awakeFromFetch
{
    [super awakeFromFetch];
    if (self.managedObjectContext == DMANAGER.objectContext) {
        [self setObserving:YES];
    }
}

- (void) awakeFromInsert
{
    [super awakeFromInsert];
    if (self.managedObjectContext == DMANAGER.objectContext) {
        [self setObserving:YES];
    }
}

- (void) willTurnIntoFault
{
    _cachedEpisodes = nil;
    if (self.managedObjectContext == DMANAGER.objectContext) {
        [self setObserving:NO];
    }
}


@dynamic dummyClear;
@dynamic playlistEpisodes;

- (void) _clearCacheWhenChangingExternally
{
    if (!_userAction) {
        [self willChangeValueForKey:@"sortedEpisodes"];
        _cachedEpisodes = nil;
        [self didChangeValueForKey:@"sortedEpisodes"];
        [[NSNotificationCenter defaultCenter] postNotificationName:CDPlaylistDidChangeEpisodesNotification object:self];
    }
}

- (NSUInteger) numberOfEpisodes
{
    if (_cachedEpisodes) {
        return [_cachedEpisodes count];
    }
    
    NSFetchRequest* feedsRequest = [[NSFetchRequest alloc] init];
    feedsRequest.entity = [NSEntityDescription entityForName:@"PlaylistEpisode" inManagedObjectContext:self.managedObjectContext];
    feedsRequest.predicate = [NSPredicate predicateWithFormat:@"list == %@", self];
    NSUInteger count = [self.managedObjectContext countForFetchRequest:feedsRequest error:nil];
    return count;
}

- (NSMutableArray*) _cachedEpisodes
{
    if (!_cachedEpisodes) {
        _cachedEpisodes = [[NSMutableArray alloc] init];
        
        NSSet* playlistEpisodes = self.playlistEpisodes;
        NSArray* sortedPlaylistEpisodes = [playlistEpisodes sortedArrayUsingDescriptors:@[ [[NSSortDescriptor alloc] initWithKey:@"rank" ascending:YES] ]];
        
        for(CDPlaylistEpisode* playlistEpisode in sortedPlaylistEpisodes) {
            if (playlistEpisode.episode) {
                [_cachedEpisodes addObject:playlistEpisode.episode];
            }
        }
    }
    
    return _cachedEpisodes;
}


- (NSArray*) sortedEpisodes
{
    return [self _cachedEpisodes];
}

#pragma mark -

- (void) addEpisode:(CDEpisode*)episode
{
    _userAction = YES;
    NSNumber* maxRank = [self.playlistEpisodes valueForKeyPath:@"@max.rank"];
    
    CDPlaylistEpisode* playlistEpisode = [NSEntityDescription insertNewObjectForEntityForName:@"PlaylistEpisode" inManagedObjectContext:self.managedObjectContext];
    playlistEpisode.list = self;
    playlistEpisode.episode = episode;
    playlistEpisode.rank = (int32_t)[maxRank integerValue] + 1;
    
    [self willChangeValueForKey:@"sortedEpisodes"];
    NSMutableArray* cachedEpisodes = [self _cachedEpisodes];
    if (![cachedEpisodes containsObject:episode]) {
        [cachedEpisodes addObject:episode];
    }
    [self didChangeValueForKey:@"sortedEpisodes"];
    _userAction= NO;
}

- (void) removeEpisode:(CDEpisode*)episode
{
    _userAction = YES;
    [self willChangeValueForKey:@"sortedEpisodes"];
    NSSet* playlistEpisodes = [episode valueForKey:@"playlistEpisodes"];
    
    for(CDPlaylistEpisode* playlistEpisode in [playlistEpisodes copy])
    {
        if ([playlistEpisode.episode isEqual:episode]) {
            [[self mutableSetValueForKey:@"playlistEpisodes"] removeObject:playlistEpisode];
            [self.managedObjectContext deleteObject:playlistEpisode];
        }
    }
    
    [_cachedEpisodes removeObject:episode];
    [self didChangeValueForKey:@"sortedEpisodes"];
    _userAction = NO;
}

- (void) removeEpisodesFromFeed:(CDFeed*)feed
{
    NSArray* episodes = [[self sortedEpisodes] copy];
    for(CDEpisode* episode in episodes) {
        if ([episode.feed isEqual:feed]) {
            [self removeEpisode:episode];
        }
    }
}


- (void) removeEpisodeAtIndex:(NSInteger)index
{
    NSArray* episodes = [self sortedEpisodes];
    [self removeEpisode:episodes[index]];
}

- (void) removeAllEpisodes
{
    _userAction = YES;
    NSSet* playlistEpisodes = self.playlistEpisodes;
    for(CDPlaylistEpisode* playlistEpisode in playlistEpisodes) {
        [self.managedObjectContext deleteObject:playlistEpisode];
    }
    
    [self willChangeValueForKey:@"sortedEpisodes"];
    _cachedEpisodes = nil;
    [self didChangeValueForKey:@"sortedEpisodes"];
    
    _userAction = NO;
}

- (void) removeAllPlayedEpisodes
{
    _userAction = YES;
    NSSet* playlistEpisodes = self.playlistEpisodes;
    for(CDPlaylistEpisode* playlistEpisode in playlistEpisodes) {
        if (playlistEpisode.episode.consumed) {
            [self.managedObjectContext deleteObject:playlistEpisode];
        }
    }
    
    [self willChangeValueForKey:@"sortedEpisodes"];
    _cachedEpisodes = nil;
    [self didChangeValueForKey:@"sortedEpisodes"];
    
    _userAction = NO;
}

- (void) reorderEpisodeFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
    _userAction = YES;
    
    [self willChangeValueForKey:@"sortedEpisodes"];
    
    // reorder cached episodes
    NSMutableArray* cachedEpisodes = [self _cachedEpisodes];
    [cachedEpisodes moveObjectFromIndex:fromIndex toIndex:toIndex];
    
    // reorder data model
    NSSet* playlistEpisodes = self.playlistEpisodes;
    NSMutableArray* sortedPlaylistEpisodes = [[playlistEpisodes sortedArrayUsingDescriptors:@[ [[NSSortDescriptor alloc] initWithKey:@"rank" ascending:YES] ]] mutableCopy];
    [sortedPlaylistEpisodes moveObjectFromIndex:fromIndex toIndex:toIndex];

    NSInteger rank = 1;
    for(CDPlaylistEpisode* playlistEpisode in sortedPlaylistEpisodes) {
        playlistEpisode.rank = (int32_t)rank;
        rank++;
    }
    
    [self didChangeValueForKey:@"sortedEpisodes"];
    
    _userAction = NO;
}
/*
- (BOOL) validateName:(NSString**)name error:(NSError**)error
{
    return ([*name length] > 0);
}
*/
@end
