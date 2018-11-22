//
//  AudioSession.h
//  Instacast
//
//  Created by Martin Hering on 19.07.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlaybackDefines.h"

extern NSString* AudioSessionAudioRouteDidChangeNotification;
extern NSString* AudioSessionDidRestorePlaybackNotification;

@class CDEpisode;
@class CDFeed;

@interface AudioSession : NSObject {
@protected
}

+ (AudioSession*) sharedAudioSession;

- (void) resetSession;

- (void) playEpisode:(CDEpisode*)anEpisode;
- (void) playEpisode:(CDEpisode*)anEpisode queueUpCurrent:(BOOL)queueUpCurrent;
- (void) playEpisode:(CDEpisode*)anEpisode queueUpCurrent:(BOOL)queueUpCurrent at:(NSTimeInterval)time autostart:(BOOL)autostart;
- (void) clear;
- (void) stop;
- (void) togglePlay;

- (CDEpisode*) nextPlayableEpisode;
- (void) disableContinuousPlaybackForCurrentEpisode;

@property (nonatomic, readonly, strong) CDEpisode* episode;

- (BOOL) canRestorePlaybackState;
- (void) restorePlaybackStateWithEpisodeHash:(NSString*)episodeHash playlistHashes:(NSArray*)playlistHashes time:(NSTimeInterval)time;
@property (nonatomic, readonly, getter = isAirPlayActive) BOOL airPlayActive;
@property (nonatomic, readonly, getter = isHeadphonesAttached) BOOL headphonesAttached;

@property (nonatomic, readonly) NSTimeInterval timerRemainingTime;
@property (nonatomic, assign) PlaybackStopTimeValue timerValue;

@end

