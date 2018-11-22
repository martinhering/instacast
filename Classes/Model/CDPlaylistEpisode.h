//
//  CDPlaylistEpisode.h
//  Instacast
//
//  Created by Martin Hering on 09.08.12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CDBase.h"

@class CDEpisode, CDPlaylist;

@interface CDPlaylistEpisode : CDBase

@property (nonatomic) int32_t rank;
@property (nonatomic, retain) CDPlaylist *list;
@property (nonatomic, retain) CDEpisode *episode;

@end
