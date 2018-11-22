//
//  ICFTSController.h
//  Instacast
//
//  Created by Martin Hering on 28.08.14.
//
//

#import <Foundation/Foundation.h>

@interface ICFTSController : NSObject

- (id) initWithSearchIndexURL:(NSURL*)url;

- (void) open;

- (void) indexFeeds:(NSArray*)feeds;

- (void) addFeed:(CDFeed*)feed;
- (void) removeFeed:(CDFeed*)feed;

- (void) addEpisode:(CDEpisode*)episode;
- (void) removeEpisode:(CDEpisode*)episode;

- (NSSet*) feedUIDsForSearchTerm:(NSString*)search;
- (NSSet*) episodeUIDsForSearchTerm:(NSString*)search;

@end
