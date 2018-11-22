//
//  CDPlaylist.h
//  Instacast
//
//  Created by Martin Hering on 09.08.12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CDList.h"

extern NSString* CDPlaylistDidChangeEpisodesNotification;

@class CDEpisode;

@interface CDPlaylist : CDList

- (void) addEpisode:(CDEpisode*)episode;
- (void) removeEpisode:(CDEpisode*)episode;
- (void) removeEpisodesFromFeed:(CDFeed*)feed;
- (void) removeEpisodeAtIndex:(NSInteger)index;
- (void) removeAllEpisodes;
- (void) removeAllPlayedEpisodes;
- (void) reorderEpisodeFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;

- (void) _clearCacheWhenChangingExternally;
@end

