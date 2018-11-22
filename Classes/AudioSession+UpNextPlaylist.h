//
//  AudioSession+UpNextPlaylist.h
//  Instacast
//
//  Created by Martin Hering on 04.08.13.
//
//

#import "AudioSession.h"

@interface AudioSession (UpNextPlaylist)

@property (nonatomic, readonly, strong) NSArray* playlist;


/* Up Next Support */
- (void) prependToUpNext:(NSArray*)episodes;
- (void) appendToUpNext:(NSArray*)episodes;
- (void) eraseEpisodesFromUpNext:(NSArray*)episodes;
- (void) eraseAllEpisodesFromUpNext;
- (void) insertUpNextEpisode:(CDEpisode*)episode atIndex:(NSUInteger)index;
- (void) reorderUpNextEpisodeFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;

@end
