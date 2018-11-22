//
//  PlaybackManager.h
//  Instacast
//
//  Created by Martin Hering on 05.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

enum {
	PlaybackSpeedControlNormalSpeed = 0,
	PlaybackSpeedControlDoubleSpeed,
	PlaybackSpeedControlHalfSpeed
};
typedef NSInteger PlaybackSpeedControl;

extern NSString* PlaybackManagerPlaybackDidUpdateNotification;
extern NSString* PlaybackManagerPlaybackDidEndNotification;
extern NSString* PlaybackManagerDidChangeEpisodeNotification;

@class SQEpisode;
@class PlayerView;

@interface PlaybackManager : NSObject <AVAudioSessionDelegate> {
@protected
	AVPlayer*			_player;
	PlayerView*			_playerView;
	id					_playbackObserver;
	id					_chapterObserver;
	NSInteger			_state;
	double				_shouldSetPosition;
	NSInteger			_loadedChapters;
}

+ (PlaybackManager*) playbackManager;
+ (BOOL) advancedPlaybackAvailable;

@property (nonatomic, retain) NSArray* playlist;

@property (readonly, retain) SQEpisode* episode;
@property (readonly, getter=isReady) BOOL ready;
@property (readonly) BOOL failed;
@property (readonly, getter=hasMovingVideo) BOOL movingVideo;
@property (readonly) AVPlayer* player;
@property (readonly) PlayerView* playerView;
@property (readonly, retain) UIBarButtonItem* playButtonItem;
@property (readonly, retain) AVTimedMetadataGroup* currentChapterGroup;
@property (readonly, retain) NSDictionary* chapterLinkIndex;
@property (readonly, retain) NSArray* chapterGroups;

- (void) openWithEpisode:(SQEpisode*)episode;
- (void) cancelOpening;
- (void) close;
- (void) play;
- (void) pause;

@property (readonly, getter=isPlaying) BOOL playing;
- (void) seekToProgress:(double)progress;
- (void) seekToTime:(NSTimeInterval)time;
- (void) seekToChapterDelta:(NSInteger)delta;

- (void) beginSeekingBackward;
- (void) endSeekingBackward;

- (void) beginSeekingForward;
- (void) endSeekingForward;

- (void) rewind30Seconds;

@property (nonatomic) PlaybackSpeedControl speedControl;
@end
