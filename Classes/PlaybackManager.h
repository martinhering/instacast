/*
 *  AVPlayerManager.h
 *  Instacast
 *
 *  Created by Martin Hering on 01.07.11.
 *  Copyright 2011 Vemedio. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>
#import "PlaybackDefines.h"

#if TARGET_OS_IPHONE
#define IC_IMAGE UIImage
#else
#define IC_IMAGE NSImage
#endif

@class CDEpisode;
@class PlayerView;
@class ICAudioEndpoint;
@class ICMetadataChapter;

@interface PlaybackManager : NSObject {
@protected
	
}

+ (PlaybackManager*) playbackManager;

@property (nonatomic, readonly, strong) CDEpisode* playingEpisode;
@property (nonatomic, readonly, getter=isReady) BOOL ready;
@property (nonatomic, readonly) BOOL failed;
@property (nonatomic, readonly, getter=hasMovingVideo) BOOL movingVideo;
@property (nonatomic, readonly) CGSize viewImageSize;
@property (nonatomic, readonly, getter=isAirPlayVideoActive) BOOL airPlayVideoActive;
@property (nonatomic) PlaybackSpeedControl speedControl;
@property (nonatomic, readonly, getter=isPaused) BOOL paused;
@property (nonatomic, assign, getter=isSeeking) BOOL seeking;
@property (nonatomic, readonly, getter=isWaitingForLoad) BOOL waitingForLoad;
@property (nonatomic) BOOL hasBeenPlayingWhenInterrupted;

@property (readonly, strong) PlayerView* playerView;
- (void) restart;

- (void) openWithEpisode:(CDEpisode*)episode at:(NSTimeInterval)time autostart:(BOOL)autostart;
- (void) close;
- (void) play;
- (void) pause;
- (void) playPause;

@property (nonatomic) float volume;

@property (nonatomic, readonly) NSTimeInterval time;
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) NSTimeInterval playableDuration;

@property (nonatomic) double position;
@property (nonatomic, readonly) double playablePosition;

- (void) seekToTime:(NSTimeInterval)time;
- (void) seekToTime:(NSTimeInterval)time tolerance:(BOOL)tolerance;
- (void) seekToChapter:(ICMetadataChapter*)chapter;

- (void) beginSeekingBackward;
- (void) beginSeekingForward;
- (void) endSeeking;

- (void) seekForward;
- (void) seekBackward;

- (void) rewind30Seconds;

- (void) nextChapter;
- (void) previousChapter;

@property (readonly, strong) NSArray* chapters;
@property (assign) NSInteger currentChapter;

@property (readonly, strong) NSArray* artworks;
@property (assign) NSInteger currentArtwork; /* observable */

- (void) stopAirPlayVideo;

@property (nonatomic, strong) ICAudioEndpoint* audioEndpoint;


#if !TARGET_OS_IPHONE
- (void) updateForSpeedControlSettingsChanged;
#endif
@end
