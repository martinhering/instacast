//
//  AudioSession+UpNextPlaylist.m
//  Instacast
//
//  Created by Martin Hering on 04.08.13.
//
//

#import "AudioSession+UpNextPlaylist.h"

@interface AudioSession ()
@property (nonatomic, strong) NSMutableArray* mutablePlaylist;
- (void) _savePlaybackStateInUserDefaults;
@end


@implementation AudioSession (UpNextPlaylist)

- (NSArray*) playlist
{
    return [[self mutablePlaylist] copy];
}

- (NSMutableArray*) mutablePlaylist
{
    NSMutableArray* mutablePlaylist = [self associatedObjectForKey:@"mutablePlaylist"];
    
    if (!mutablePlaylist) {
        mutablePlaylist = [[NSMutableArray alloc] init];
        [self setAssociatedObject:mutablePlaylist forKey:@"mutablePlaylist"];
    }
    return mutablePlaylist;
}

- (void) setMutablePlaylist:(NSMutableArray *)mutablePlaylist
{
    [self setAssociatedObject:mutablePlaylist forKey:@"mutablePlaylist"];
}

- (void) prependToUpNext:(NSArray*)episodes
{
    // currently playing episode can not be in up next
    NSMutableArray* mutableEpisodes = [episodes mutableCopy];
    [mutableEpisodes removeObject:self.episode];
    
    [self willChangeValueForKey:@"playlist"];
    [self _eraseEpisodesFromUpNext:mutableEpisodes];
    [self.mutablePlaylist insertObjects:mutableEpisodes
                              atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [mutableEpisodes count])]];
    [self didChangeValueForKey:@"playlist"];
    [self _savePlaybackStateInUserDefaults];
}

- (void) appendToUpNext:(NSArray*)episodes
{
    // currently playing episode can not be in up next
    NSMutableArray* mutableEpisodes = [episodes mutableCopy];
    [mutableEpisodes removeObject:self.episode];
    
    [self willChangeValueForKey:@"playlist"];
    [self _eraseEpisodesFromUpNext:mutableEpisodes];
    [self.mutablePlaylist addObjectsFromArray:mutableEpisodes];
    [self didChangeValueForKey:@"playlist"];
    [self _savePlaybackStateInUserDefaults];
}

- (void) _eraseEpisodesFromUpNext:(NSArray*)episodes
{
    NSMutableArray* filteredArray = [[NSMutableArray alloc] init];
    
    for(CDEpisode* episode in self.playlist) {
        if (![episodes containsObject:episode]) {
            [filteredArray addObject:episode];
        }
    }
    
    self.mutablePlaylist = filteredArray;
}

- (void) eraseEpisodesFromUpNext:(NSArray*)episodes
{
    [self willChangeValueForKey:@"playlist"];
    [self _eraseEpisodesFromUpNext:episodes];
    [self didChangeValueForKey:@"playlist"];
    [self _savePlaybackStateInUserDefaults];
}

- (void) eraseAllEpisodesFromUpNext
{
    [self willChangeValueForKey:@"playlist"];
    [self.mutablePlaylist removeAllObjects];
    [self didChangeValueForKey:@"playlist"];
    [self _savePlaybackStateInUserDefaults];
}

- (void) insertUpNextEpisode:(CDEpisode*)episode atIndex:(NSUInteger)index
{
    [self willChangeValueForKey:@"playlist"];
    [self.mutablePlaylist insertObject:episode atIndex:index];
    [self didChangeValueForKey:@"playlist"];
    [self _savePlaybackStateInUserDefaults];
}

- (void) reorderUpNextEpisodeFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
    [self willChangeValueForKey:@"playlist"];
    [self.mutablePlaylist moveObjectFromIndex:fromIndex toIndex:toIndex];
    [self didChangeValueForKey:@"playlist"];
    [self _savePlaybackStateInUserDefaults];
}

@end
