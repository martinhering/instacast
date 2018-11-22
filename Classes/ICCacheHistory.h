//
//  ICCacheHistory.h
//  Instacast
//
//  Created by Martin Hering on 20.03.13.
//
//

#import <Foundation/Foundation.h>

@interface ICCacheHistory : NSObject

- (id) initWithContentsOfFile:(NSString*)filePath;

- (BOOL) episodeDidAutoDownload:(CDEpisode*)episode;
- (void) setEpisode:(CDEpisode*)episode didAutoDownload:(BOOL)autoDownload;
- (void) resetValuesForEpisode:(CDEpisode*)episode;

- (void) save;
- (void) clear;
@end
