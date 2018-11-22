//
//  PlaybackManager.m
//  Instacast
//
//  Created by Martin Hering on 05.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#if TARGET_OS_IPHONE
#import <MediaPlayer/MediaPlayer.h>
#import "PlayerView.h"
#else
#import "AudioSession_OSX.h"
#import "ICPlayerView_OSX.h"
#import "PlaybackManager+Mikey.h"
#import "PlaybackManager+AudioDevice.h"
#import "PlaybackManager+RemoteControl.h"
#import "ICSharingManager.h"
#endif



#import "ImageFunctions.h"
#import "CDModel.h"
#import "CDEpisode+ShowNotes.h"
#import "CDChapter.h"
#import "ICMetadataParser.h"
#import "ICImageCacheOperation.h"

#define SEND_UPDATE [self _sendUpdateNotification];

#if !TARGET_OS_IPHONE
#ifdef __MAC_10_9
#define ENABLE_10_9_AUDIO_DEVICE_BEHAVIOR 1
#endif
#endif

NSString* PlaybackManagerDidStartNotification = @"MPPlaybackManagerDidStartNotification";
NSString* PlaybackManagerDidEndNotification = @"MPPlaybackManagerDidEndNotification";
NSString* PlaybackManagerDidUpdateNotification = @"MPPlaybackManagerDidUpdateNotification";
NSString* PlaybackManagerDidChangeEpisodeNotification = @"MPPlaybackManagerDidChangeEpisodeNotification";


#if TARGET_OS_IPHONE
static NSString* kMediaItemInstacastCurrentArtwork =  @"Instacast_currentArtwork";
static NSString* kMediaItemInstacastEpisodeHash =  @"Instacast_episodeHash";
#endif

static NSString* kDefaultTemporaryPlaybackPositions = @"TemporaryPlaybackPositions";
static NSString* kDefaultPlaybackVolume = @"PlaybackVolume";

enum {
	IdleState,
	InitializedState,
	ShouldRunState,
	RunningState,
	VideoPausedInBackground
};


@interface AudioSession ()
@property (nonatomic, readwrite, strong) CDEpisode* episode;
@property (nonatomic, readwrite, strong) NSMutableArray* playlist;
@property BOOL autoStopDisabled;
@end

@interface PlaybackManager ()
@property (nonatomic, readwrite, strong) CDEpisode* playingEpisode;
@property (nonatomic, readwrite, getter=isReady) BOOL ready;
@property (nonatomic, readwrite) BOOL failed;
@property (nonatomic, readwrite, getter=hasMovingVideo) BOOL movingVideo;
@property (nonatomic, readwrite) CGSize viewImageSize;

@property (nonatomic, readwrite, strong) AVURLAsset* mediaAsset;
@property (nonatomic, readwrite, strong) AVPlayer* player;
@property (readwrite, strong) PlayerView* playerView;
@property (nonatomic, readwrite, strong) NSDate* lastPauseDate;

@property (nonatomic) BOOL changingEpisode;
@property (nonatomic) BOOL changingPosition;

@property (readwrite, strong) NSArray* chapters;
@property (readwrite, strong) NSArray* artworks;

@property (nonatomic, weak) NSTimer* controlTimer;
@property (nonatomic, strong) NSDate* controlStartDate;

#if TARGET_OS_IPHONE
@property (nonatomic) UIBackgroundTaskIdentifier bufferNextItemTaskIdentifier;
#endif

@property (nonatomic) double initialPlaybackTime;
@property (nonatomic, weak) id playbackObserver;
@property (nonatomic, weak) id positionObserver;
@property (assign) NSInteger state;

@property (nonatomic) BOOL inTransitionToNextTrack;
@property (nonatomic, strong) NSMutableDictionary* nowPlayingInfo;
@property (nonatomic, strong) NSTimer* nowPlayingDelayTimer;
@property (nonatomic) double seekingPosition;
@property (nonatomic, strong) NSDate* seekingPositionChangeDate;
@property (nonatomic, strong) ICMetadataChapter* seekingChapter;
@end


@implementation PlaybackManager {
    float       _volume;
    float*      _chapterTimesIdx;
    float*      _artworkTimesIdx;
}

#pragma mark -

+ (PlaybackManager*) playbackManager;
{
	static PlaybackManager* gPlaybackManager = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        gPlaybackManager = [[PlaybackManager alloc] init];
    });
	return gPlaybackManager;
}



- (id) init
{
	if ((self = [super init]))
	{
#if TARGET_OS_IPHONE
        
        // overwrite current default on iOS, because we actually use the system volume
        [USER_DEFAULTS setFloat:1.0f forKey:kDefaultPlaybackVolume];
#else
        dispatch_async(dispatch_get_main_queue(), ^{
            [self initializeMikey];
            [self initializeAudioDeviceListener];
#ifndef APP_STORE
            [self initializeRemoteControl];
#endif
            [self _setAudioEndpointToCurrentSystemAudioDevice];
        });
#endif
	}
	
	return self;
}


- (void) _sendUpdateNotification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:PlaybackManagerDidUpdateNotification object:self];
}

- (void) _endNextItemHandover
{
#if TARGET_OS_IPHONE
	if (self.bufferNextItemTaskIdentifier != UIBackgroundTaskInvalid) {
        DebugLog(@"end item handover");
		[App endBackgroundTask:self.bufferNextItemTaskIdentifier];
		self.bufferNextItemTaskIdentifier = UIBackgroundTaskInvalid;
	}
#endif
}

- (void) _startNextItemHandover
{
	[self _endNextItemHandover];
#if TARGET_OS_IPHONE
    DebugLog(@"start item handover");
	self.bufferNextItemTaskIdentifier = [App beginBackgroundTaskWithExpirationHandler:^(void) {
        [App endBackgroundTask:self.bufferNextItemTaskIdentifier];
		self.bufferNextItemTaskIdentifier = UIBackgroundTaskInvalid;
	}];
#endif
}


- (void) _setNowPlayingInfoOfEpisode:(CDEpisode*)anEpisode
{
    //DebugLog(@"_setNowPlayingInfoOfEpisode");
#if TARGET_OS_IPHONE
    if (!self.nowPlayingInfo) {
        self.nowPlayingInfo = [NSMutableDictionary dictionary];
    }
    else if (![self.nowPlayingInfo isKindOfClass:[NSMutableArray class]])
    {
        self.nowPlayingInfo = [self.nowPlayingInfo mutableCopy];
    }
    
    
    [self.nowPlayingInfo setObject:@(MPMediaTypePodcast) forKey:MPMediaItemPropertyMediaType];
    
	
    if (anEpisode)
    {
        CDFeed* feed = anEpisode.feed;
    
        if (feed.title) {
            [self.nowPlayingInfo setObject:feed.title forKey:MPMediaItemPropertyArtist];
        }
    
        if (anEpisode.title && feed.title) {
            NSString* title = [anEpisode cleanTitleUsingFeedTitle:feed.title];
            [self.nowPlayingInfo setObject:title forKey:MPMediaItemPropertyTitle];
        }
   
        if (feed.author) {
            [self.nowPlayingInfo setObject:feed.author forKey:MPMediaItemPropertyAlbumTitle];
        }
    }
    
    // change episode title in case we have chapters
    if ([self.chapters count] > 0 && self.currentChapter >= 0 && self.currentChapter < [self.chapters count])
    {
        ICMetadataChapter* chapter = [self.chapters objectAtIndex:self.currentChapter];
        [self.nowPlayingInfo setObject:chapter.title forKey:MPMediaItemPropertyAlbumTitle];
    }

    
    // set image in case we have chapter based images
    if (!self.movingVideo && [self.artworks count] > 0 && self.currentArtwork >= 0)
    {
        ICMetadataImage* artwork = self.artworks[self.currentArtwork];
        NSNumber* currentArtwork = self.nowPlayingInfo[kMediaItemInstacastCurrentArtwork];
        
        if (!currentArtwork || [currentArtwork integerValue] != self.currentArtwork)
        {
            [artwork loadPlatformImageWithCompletion:^(id platformImage) {

                if (platformImage)
                {
                    MPMediaItemArtwork* artwork = [[MPMediaItemArtwork alloc] initWithImage:platformImage];
                    self.nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork;
                    self.nowPlayingInfo[kMediaItemInstacastCurrentArtwork] = @(self.currentArtwork);
                }
                else {
                    [self.nowPlayingInfo removeObjectForKey:MPMediaItemPropertyArtwork];
                }
                
                [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = self.nowPlayingInfo;

            }];
        }
    }

    else if (anEpisode && ![self.nowPlayingInfo[kMediaItemInstacastEpisodeHash] isEqual:anEpisode.objectHash])
    {
        [self.nowPlayingInfo setObject:anEpisode.objectHash forKey:kMediaItemInstacastEpisodeHash];
        
        DebugLog(@"load episode image for lock screen");
        
        // set image in case we have an episode based image
        void (^displayImage)(IC_IMAGE*) = ^(IC_IMAGE* image) {
            MPMediaItemArtwork* artwork = [[MPMediaItemArtwork alloc] initWithImage:image];
            if (artwork) {
                [self.nowPlayingInfo setObject:artwork forKey:MPMediaItemPropertyArtwork];
            }
        };
        
        ImageCacheManager* iman = [ImageCacheManager sharedImageCacheManager];
        IC_IMAGE* cachedImage = [iman localImageForImageURL:anEpisode.imageURL size:320 grayscale:NO];
        if (cachedImage) {
            displayImage(cachedImage);
        }
        else
        {
            IC_IMAGE* cachedImage = [iman localImageForImageURL:anEpisode.feed.imageURL size:320 grayscale:NO];
            if (cachedImage) {
                displayImage(cachedImage);
            }
            else
            {
                ICImageCacheOperation* operation = [[ICImageCacheOperation alloc] initWithURL:anEpisode.imageURL size:320 grayscale:NO];
                operation.didEndBlock = ^(IC_IMAGE* image, NSError* error) {
                    if (image) {
                        displayImage(image);
                        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = self.nowPlayingInfo;
                    }
                    else
                    {
                        ICImageCacheOperation* operation = [[ICImageCacheOperation alloc] initWithURL:anEpisode.feed.imageURL size:320 grayscale:NO];
                        operation.didEndBlock = ^(IC_IMAGE* image, NSError* error) {
                            if (image) {
                                displayImage(image);
                            }
                            else {
                                [self.nowPlayingInfo removeObjectForKey:MPMediaItemPropertyArtwork];
                            }
                            [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = self.nowPlayingInfo;
                        };
                        [iman addImageCacheOperation:operation sender:self];
                    }
                };
                [iman addImageCacheOperation:operation sender:self];
            }
        }
    }
    
    [self.nowPlayingInfo setObject:[NSNumber numberWithFloat:self.duration] forKey:MPMediaItemPropertyPlaybackDuration];
    
    [self.nowPlayingInfo setObject:[NSNumber numberWithDouble:self.player.rate] forKey:MPNowPlayingInfoPropertyPlaybackRate];
    [self.nowPlayingInfo setObject:[NSNumber numberWithDouble:(double)self.time] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    
    if (self.chapters && self.currentChapter >= 0) {
        [self.nowPlayingInfo setObject:[NSNumber numberWithUnsignedInteger:[self.chapters count]] forKey:MPNowPlayingInfoPropertyChapterCount];
        [self.nowPlayingInfo setObject:[NSNumber numberWithInteger:self.currentChapter] forKey:MPNowPlayingInfoPropertyChapterNumber];
    } else {
        [self.nowPlayingInfo removeObjectForKey:MPNowPlayingInfoPropertyChapterCount];
        [self.nowPlayingInfo removeObjectForKey:MPNowPlayingInfoPropertyChapterNumber];
    }
    
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = self.nowPlayingInfo;
    
#endif
}


- (void) _setupRemotePlaybackCenterWithEpisode:(CDEpisode*)episode
{
#if TARGET_OS_IPHONE
    MPRemoteCommandCenter *rcc = [MPRemoteCommandCenter sharedCommandCenter];
    
    // reset all commands first
    MPRemoteCommand *pauseCommand = rcc.pauseCommand;
    pauseCommand.enabled = NO;
    [pauseCommand removeTarget:self];
    //
    MPRemoteCommand *playCommand = rcc.playCommand;
    playCommand.enabled = NO;
    [playCommand removeTarget:self];
    
    MPRemoteCommand *togglePlayPauseCommand = rcc.togglePlayPauseCommand;
    togglePlayPauseCommand.enabled = NO;
    [togglePlayPauseCommand removeTarget:self];
    
    
    MPSkipIntervalCommand* skipBackwardIntervalCommand = rcc.skipBackwardCommand;
    skipBackwardIntervalCommand.enabled = NO;
    [skipBackwardIntervalCommand removeTarget:self];
    
    MPSkipIntervalCommand* skipForwardIntervalCommand = rcc.skipForwardCommand;
    skipForwardIntervalCommand.enabled = NO;
    [skipForwardIntervalCommand removeTarget:self];
    
    
    MPRemoteCommand* nextTrackCommand = rcc.nextTrackCommand;
    nextTrackCommand.enabled = NO;
    [nextTrackCommand removeTarget:self];
    
    MPRemoteCommand* previousTrackCommand = rcc.previousTrackCommand;
    previousTrackCommand.enabled = NO;
    [previousTrackCommand removeTarget:self];
    
    MPRemoteCommand* skipForwardCommand = rcc.seekForwardCommand;
    skipForwardCommand.enabled = NO;
    [skipForwardCommand removeTarget:self];
    
    MPRemoteCommand* seekBackwardCommand = rcc.seekBackwardCommand;
    seekBackwardCommand.enabled = NO;
    [seekBackwardCommand removeTarget:self];
    
    
    if (episode)
    {
        CDFeed* feed = episode.feed;
        
        MPRemoteCommand *pauseCommand = rcc.pauseCommand;
        pauseCommand.enabled = YES;
        [pauseCommand addTarget:self action:@selector(_playPauseEvent:)];
        //
        MPRemoteCommand *playCommand = rcc.playCommand;
        playCommand.enabled = YES;
        [playCommand addTarget:self action:@selector(_playPauseEvent:)];
        
        MPRemoteCommand *togglePlayPauseCommand = rcc.togglePlayPauseCommand;
        togglePlayPauseCommand.enabled = YES;
        [togglePlayPauseCommand addTarget:self action:@selector(_playPauseEvent:)];
        
        if ([feed integerForKey:kDefaultPlayerControls] == kPlayerSkippingControls)
        {
            MPSkipIntervalCommand* skipBackwardIntervalCommand = rcc.skipBackwardCommand;
            skipBackwardIntervalCommand.enabled = YES;
            [skipBackwardIntervalCommand addTarget:self action:@selector(_skipBackwardEvent:)];
            skipBackwardIntervalCommand.preferredIntervals = @[@([feed integerForKey:PlayerSkipBackPeriod])];
            
            MPSkipIntervalCommand* skipForwardIntervalCommand = rcc.skipForwardCommand;
            skipForwardIntervalCommand.enabled = YES;
            skipForwardIntervalCommand.preferredIntervals = @[@([feed integerForKey:PlayerSkipForwardPeriod])];
            [skipForwardIntervalCommand addTarget:self action:@selector(_skipForwardEvent:)];
            
            MPRemoteCommand* nextTrackCommand = rcc.nextTrackCommand;
            nextTrackCommand.enabled = YES;
            [nextTrackCommand addTarget:self action:@selector(_skipForwardEvent:)];
            
            MPRemoteCommand* previousTrackCommand = rcc.previousTrackCommand;
            previousTrackCommand.enabled = YES;
            [previousTrackCommand addTarget:self action:@selector(_skipBackwardEvent:)];
        }
        else
        {
            if ([feed integerForKey:kDefaultPlayerControls] == kPlayerSeekingAndSkippingChaptersControls)
            {
                MPRemoteCommand* nextTrackCommand = rcc.nextTrackCommand;
                nextTrackCommand.enabled = YES;
                [nextTrackCommand addTarget:self action:@selector(_nextChapterEvent:)];
                
                MPRemoteCommand* previousTrackCommand = rcc.previousTrackCommand;
                previousTrackCommand.enabled = YES;
                [previousTrackCommand addTarget:self action:@selector(_previousChapterEvent:)];
            }
            else
            {
                MPRemoteCommand* nextTrackCommand = rcc.nextTrackCommand;
                nextTrackCommand.enabled = YES;
                [nextTrackCommand addTarget:self action:@selector(_skipForwardEvent:)];
                
                MPRemoteCommand* previousTrackCommand = rcc.previousTrackCommand;
                previousTrackCommand.enabled = YES;
                [previousTrackCommand addTarget:self action:@selector(_skipBackwardEvent:)];
            }
            
            
            MPRemoteCommand* skipForwardCommand = rcc.seekForwardCommand;
            skipForwardCommand.enabled = YES;
            [skipForwardCommand addTarget:self action:@selector(_seekForwardEvent:)];
            
            MPRemoteCommand* seekBackwardCommand = rcc.seekBackwardCommand;
            seekBackwardCommand.enabled = YES;
            [seekBackwardCommand addTarget:self action:@selector(_seekBackwardEvent:)];
        }
        
    }
#endif
}

#if TARGET_OS_IPHONE

-(MPRemoteCommandHandlerStatus) _seekForwardEvent: (MPSeekCommandEvent *) seekEvent
{
    if (seekEvent.type == MPSeekCommandEventTypeBeginSeeking) {
        [self beginSeekingForward];
    }
    if (seekEvent.type == MPSeekCommandEventTypeEndSeeking) {
        [self endSeeking];
    }
    return MPRemoteCommandHandlerStatusSuccess;
}

-(MPRemoteCommandHandlerStatus) _seekBackwardEvent: (MPSeekCommandEvent *) seekEvent
{
    if (seekEvent.type == MPSeekCommandEventTypeBeginSeeking) {
        [self beginSeekingBackward];
    }
    if (seekEvent.type == MPSeekCommandEventTypeEndSeeking) {
       [self endSeeking];
    }
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus) _playPauseEvent:(MPRemoteCommandEvent*)event
{
    [self playPause];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus) _skipBackwardEvent:(MPRemoteCommandEvent*)event
{
    [self seekBackward];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus) _skipForwardEvent:(MPRemoteCommandEvent*)event
{
    [self seekForward];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus) _nextChapterEvent:(MPRemoteCommandEvent*)event
{
    [self nextChapter];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus) _previousChapterEvent:(MPRemoteCommandEvent*)event
{
    [self previousChapter];
    return MPRemoteCommandHandlerStatusSuccess;
}
#endif

#pragma mark -

- (void) openWithEpisode:(CDEpisode*)anEpisode at:(NSTimeInterval)time autostart:(BOOL)autostart
{
	if (self.player) {
		self.changingEpisode = YES;
		[self closeAndSaveCurrentPosition:!self.inTransitionToNextTrack];
        self.inTransitionToNextTrack = NO;
	}

    [[NSNotificationCenter defaultCenter] postNotificationName:((self.changingEpisode) ? PlaybackManagerDidChangeEpisodeNotification : PlaybackManagerDidStartNotification) object:self];
	self.changingEpisode = NO;
	
    [self _setNowPlayingInfoOfEpisode:anEpisode];
    [self _setupRemotePlaybackCenterWithEpisode:anEpisode];
	
	// create background task until the first data is buffered and the app is ready to play
	[self _startNextItemHandover];
	
	self.ready = NO;
	self.failed = NO;
    self.movingVideo = NO;
	self.currentChapter = -1;
    self.currentArtwork = -1;
    self.initialPlaybackTime = time;
	
	CacheManager* eman = [CacheManager sharedCacheManager];
	CDMedium* media = [anEpisode preferedMedium];
	
	NSURL* url = ([eman episodeIsCached:anEpisode]) ? [eman URLForCachedEpisode:anEpisode] : media.fileURL;
    
    // workaround for a bug in the feed parser up to version 3.0.2
    NSString* urlString = [url absoluteString];
    if ([urlString rangeOfString:@"%25"].location != NSNotFound) {
        urlString = [urlString stringByRemovingPercentEncoding];
        url = [NSURL URLWithString:urlString];
    }
	DebugLog(@"play url: %@", [url absoluteString]);
	
    self.playingEpisode = anEpisode;
	self.state = InitializedState;
	
	self.mediaAsset = [AVURLAsset URLAssetWithURL:url options:nil];
	
	[self.mediaAsset loadValuesAsynchronouslyForKeys:@[@"tracks", @"duration"] completionHandler:^(void) {
		NSError *error = nil;
		AVKeyValueStatus tracksStatus = [self.mediaAsset statusOfValueForKey:@"tracks" error:&error];
		switch (tracksStatus) {
			case AVKeyValueStatusLoaded:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    DebugLog(@"open AVKeyValueStatusLoaded");
                    [self _continueOpeningAsset:self.mediaAsset autostart:autostart];
                });
				break;
            }
			case AVKeyValueStatusFailed:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    DebugLog(@"open AVKeyValueStatusFailed: %@", [error description]);
                    self.failed = YES;
                    [self close];
                    SEND_UPDATE
                });
				break;
            }
			case AVKeyValueStatusCancelled:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    DebugLog(@"open AVKeyValueStatusCancelled");
                    self.mediaAsset = nil;
                    [self _endNextItemHandover];
                });
				break;
            }
            default:
                break;
		}
	}];
}


- (void) _continueOpeningAsset:(AVURLAsset*)asset autostart:(BOOL)autostart
{
    if (self.initialPlaybackTime == 0) {
        // also handle special case, where we don't have a duration
        self.initialPlaybackTime = (self.playingEpisode.position < self.playingEpisode.duration - 5 || self.playingEpisode.duration < 1) ? self.playingEpisode.position : 0;
        
        NSString* key = self.playingEpisode.objectHash;
        NSDictionary* playbackPositions = [USER_DEFAULTS objectForKey:kDefaultTemporaryPlaybackPositions];
        NSNumber* temporaryPosition = playbackPositions[key];
        if (temporaryPosition) {
            self.initialPlaybackTime = [temporaryPosition doubleValue];
        }
    }
    
    AVPlayerItem* playerItem = [AVPlayerItem playerItemWithAsset:asset];
    if (!playerItem) {
        self.failed = YES;
        [self close];
        SEND_UPDATE
        return;
    }
    
    __weak PlaybackManager* weakSelf = self;
    
    [playerItem addTaskObserver:self forKeyPath:@"status" task:^(id obj, NSDictionary *change)
    {
        AVPlayerItem* currentItem = self.player.currentItem;
        DebugLog(@"AVPlayerItem.status: %ld", (long)currentItem.status);
        if (currentItem.status == AVPlayerItemStatusReadyToPlay && self.state == InitializedState)
        {
            CDEpisode* episode = self.playingEpisode;
            CDFeed* feed = episode.feed;
            
            episode.lastPlayed = [NSDate date];
            [DMANAGER saveAndSync:NO];
            
            // check if we have moving video
            weakSelf.movingVideo = NO;
            
            NSArray* tracks = currentItem.tracks;
            for(AVPlayerItemTrack* track in tracks) {
                AVAssetTrack* assetTrack = track.assetTrack;
                
                if ([assetTrack.mediaType isEqualToString:AVMediaTypeVideo]) //track.enabled && 
                {
                    CMFormatDescriptionRef formatDescription = (__bridge CMFormatDescriptionRef)[[assetTrack formatDescriptions] lastObject];
                    if (CMFormatDescriptionGetMediaSubType(formatDescription) != kCMVideoCodecType_JPEG) {
                        weakSelf.movingVideo = YES;
                        
                        CGSize videodimensions = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, true, true);
                        self.viewImageSize = videodimensions;
                        break;
                    }
                }
            }
            
#if TARGET_OS_IPHONE
            if ([weakSelf.player respondsToSelector:@selector(allowsAirPlayVideo)]) {
                weakSelf.player.allowsExternalPlayback = weakSelf.movingVideo;
            }
            
            if (!weakSelf.playerView && weakSelf.movingVideo) {
                weakSelf.playerView = [[PlayerView alloc] init];
                [(PlayerView*)weakSelf.playerView setPlayer:weakSelf.player];
            }
            
#else
            if (!weakSelf.playerView && weakSelf.movingVideo) {
                weakSelf.playerView = [[PlayerView alloc] initWithFrame:NSZeroRect];
                [(PlayerView*)weakSelf.playerView setPlayer:weakSelf.player];
            }
#endif
            
            
            if (weakSelf.initialPlaybackTime > 0) {
                [weakSelf seekToTime:weakSelf.initialPlaybackTime];
                weakSelf.initialPlaybackTime = 0;
            }
#if !TARGET_OS_IPHONE
            else {
                [[ICSharingManager sharedManager] triggerEvent:ICSharingServiceEpisodeDidStartPlaying object:self.playingEpisode];
            }
#endif
            
            weakSelf.ready = YES;
            weakSelf.state = (autostart) ? ShouldRunState : RunningState;

            // don't use the setter, otherwise the value will be stored
            [weakSelf willChangeValueForKey:@"speedControl"];
            _speedControl = [feed integerForKey:DefaultPlaybackSpeed];
            [weakSelf didChangeValueForKey:@"speedControl"];
            
            [weakSelf willChangeValueForKey:@"duration"];
            [weakSelf didChangeValueForKey:@"duration"];

            SEND_UPDATE
            [weakSelf _startLoadingChapters];
            
            if (weakSelf.player.currentItem.playbackLikelyToKeepUp && autostart) {
                [self play];
            }
        }
        
        else if (self.player.status == AVPlayerItemStatusFailed) {
            ErrLog(@"playback failed/interrupted due to error :%@", self.player.error);
            self.failed = YES;
            [self close];
        }
    }];
    
    [playerItem addTaskObserver:self forKeyPath:@"playbackLikelyToKeepUp" task:^(id obj, NSDictionary *change)
    {
        if (self.state == ShouldRunState) {
            [self play];
        }
    }];
    
    [playerItem addTaskObserver:self forKeyPath:@"playbackBufferFull" task:^(id obj, NSDictionary *change)
     {
         if (self.state == ShouldRunState) {
             [self play];
         }
     }];
    
    
    [playerItem addTaskObserver:self forKeyPath:@"loadedTimeRanges" task:^(id obj, NSDictionary *change) {
        [self willChangeValueForKey:@"playableDuration"];
        [self didChangeValueForKey:@"playableDuration"];
        
        if ([self playableDuration] > 60 && self.state == ShouldRunState) {
            [self play];
        }
    }];
    
    
    
    self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    self.player.volume = [USER_DEFAULTS floatForKey:kDefaultPlaybackVolume];

#if ENABLE_10_9_AUDIO_DEVICE_BEHAVIOR==1
    if ([NSBundle systemVersion] >= VM_SYSTEM_VERSION_OS_X_10_9 && [AVPlayer implementsSelector:@selector(audioOutputDeviceUniqueID)]) {
        [PlaybackManager setDataSourceOfAudioDeviceForEndpoint:self.audioEndpoint];
        self.player.audioOutputDeviceUniqueID = self.audioEndpoint.UID;
    }
#endif
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTimeNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    

    [self.player addTaskObserver:self forKeyPath:@"rate" task:^(id obj, NSDictionary *change)
    {
        DebugLog(@"kPlayerRateChangedContext: %lf", weakSelf.player.rate);
        float rate = weakSelf.player.rate;
                
        if (rate > 0 && weakSelf.state == ShouldRunState) {
            weakSelf.state = RunningState;
            [weakSelf performSelector:@selector(_endNextItemHandover) withObject:nil afterDelay:1.0];
        }

        if (weakSelf.mediaAsset && rate == 0 && weakSelf.state == RunningState)
        {
            [weakSelf _saveCurrentPlaybackPosition];
        }
        
        if (weakSelf.ready) {
            [weakSelf willChangeValueForKey:@"paused"];
            [weakSelf didChangeValueForKey:@"paused"];
        }
        
        [weakSelf perform:^(id sender) {
            [weakSelf _setNowPlayingInfoOfEpisode:(rate==0) ? nil : weakSelf.playingEpisode];
            [weakSelf _setupRemotePlaybackCenterWithEpisode:weakSelf.playingEpisode];
        } afterDelay:0.1];
        
    }];

    self.playbackObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1,25000) queue:NULL usingBlock:^(CMTime time) {
        
        // make sure we're not resetting the position here when we first need to seek to it on startup
        CDEpisode* episode = weakSelf.playingEpisode;
        
        if (weakSelf.initialPlaybackTime == 0 && episode.duration < 5)
        {
            // update position on consumable
            AVPlayerItem* item = weakSelf.player.currentItem;
            
            CMTime duration = item.asset.duration;
            NSInteger dur = (duration.timescale != 0) ? duration.value/duration.timescale : 0;
            
            // add duration parameter to episode if there is none
            episode.duration = (int32_t)dur;
            [DMANAGER saveAndSync:NO];
        }
        
        if (weakSelf.player.rate > 0)
        {
            if (weakSelf.speedControl == PlaybackSpeedControlNormalSpeed &&  fabs(weakSelf.player.rate-1.0) > 0.02) {
                weakSelf.player.rate = 1.0;
            }
            else if (weakSelf.speedControl == PlaybackSpeedControlDoubleSpeed &&  fabs(weakSelf.player.rate-1.5) > 0.02) {
                weakSelf.player.rate = 1.5;
            }
            else if (weakSelf.speedControl == PlaybackSpeedControlPlusHalfSpeed && fabs(weakSelf.player.rate-1.2) > 0.02) {
                weakSelf.player.rate = 1.2;
            }
            else if (weakSelf.speedControl == PlaybackSpeedControlMinusHalfSpeed &&  fabs(weakSelf.player.rate-0.71) > 0.02) {
                weakSelf.player.rate = 0.71;
            }
            else if (weakSelf.speedControl == PlaybackSpeedControlTripleSpeed &&  fabs(weakSelf.player.rate-2.0) > 0.02) {
                weakSelf.player.rate = 2.0;
            }

            NSInteger chapter = weakSelf.currentChapter;
            NSInteger artwork = weakSelf.currentArtwork;
            [weakSelf _findAndSetCurrentChapter:-1];
            [weakSelf _findAndSetCurrentArtwork];
            
            if (weakSelf.currentChapter != chapter || weakSelf.currentArtwork != artwork) {
                [weakSelf _setNowPlayingInfoOfEpisode:episode];
            }
        }

        [weakSelf willChangeValueForKey:@"time"];
        [weakSelf didChangeValueForKey:@"time"];
        
        [weakSelf _sendUpdateNotification];
    }];
    
    
    self.positionObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(30,25000) queue:NULL usingBlock:^(CMTime time) {
        if (weakSelf.ready) {
            [weakSelf _temporarySavePosition];
        }
    }];
    
    [self.playingEpisode addTaskObserver:self forKeyPath:@"position" task:^(id obj, NSDictionary *change) {
        if (!weakSelf.changingPosition && weakSelf.paused) {
            [weakSelf seekToTime:weakSelf.playingEpisode.position];
        }
    }];

    self.state = InitializedState;
    
    SEND_UPDATE
}

- (void) playerItemDidPlayToEndTimeNotification:(NSNotification*)notification
{
    CDEpisode* episode = self.playingEpisode;
    AudioSession* session = [AudioSession sharedAudioSession];

    // only mark episode as played if we actually finished playing this episode
    // could end prematurely if streaming and internet not available
    if (episode && [self time] > [self duration] - 10)
    {
        _changingPosition = YES;
        episode.consumed = YES;
        episode.position = 0;
        _changingPosition = NO;
        
        [self _removeTemporarySavePosition];
        
        if ([episode.feed boolForKey:AutoDeleteAfterFinishedPlaying] && !episode.starred) {
            session.autoStopDisabled = YES;
            [[CacheManager sharedCacheManager] removeCacheForEpisode:episode automatic:YES];
            session.autoStopDisabled = NO;
        }
        
        CDEpisode* nextEpisode = [session nextPlayableEpisode];
        if (nextEpisode) {
            self.inTransitionToNextTrack = YES;
            [session playEpisode:nextEpisode queueUpCurrent:NO at:0 autostart:YES];
        }
        else {
            [self closeAndSaveCurrentPosition:NO];
        }

        
#if TARGET_OS_IPHONE==0
        [[ICSharingManager sharedManager] triggerEvent:ICSharingServiceEpisodeDidEndPlaying object:episode];
#endif
    }

    else
    {
        [self closeAndSaveCurrentPosition:NO];
    }
}

- (void) _temporarySavePosition
{
    if (!self.paused)
    {
        CDEpisode* episode = self.playingEpisode;
        NSString* key = self.playingEpisode.objectHash;
        
        NSMutableDictionary* playbackPositions = [[USER_DEFAULTS objectForKey:kDefaultTemporaryPlaybackPositions] mutableCopy];
        if (!playbackPositions) {
            playbackPositions = [[NSMutableDictionary alloc] init];
        }
        
        // update position on consumable
        AVPlayerItem* item = self.player.currentItem;
        if (item && episode && key) {
            CMTime current = [item currentTime];
            NSInteger cur = current.value/current.timescale;
            
            [playbackPositions setObject:@(cur) forKey:key];
            [USER_DEFAULTS setObject:playbackPositions forKey:kDefaultTemporaryPlaybackPositions];
            [USER_DEFAULTS synchronize];
        }
    }
}

- (void) _removeTemporarySavePosition
{
    NSString* key = self.playingEpisode.objectHash;
    
    NSMutableDictionary* playbackPositions = [[USER_DEFAULTS objectForKey:kDefaultTemporaryPlaybackPositions] mutableCopy];
    [playbackPositions removeObjectForKey:key];
    [USER_DEFAULTS setObject:playbackPositions forKey:kDefaultTemporaryPlaybackPositions];
    [USER_DEFAULTS synchronize];
}

- (void) _saveCurrentPlaybackPosition
{
    CDEpisode* episode = self.playingEpisode;
    
    // update position on consumable
    AVPlayerItem* item = self.player.currentItem;
    if (item && episode) {
        CMTime current = [item currentTime];
        NSInteger cur = current.value/current.timescale;        

        _changingPosition = YES;
        [DMANAGER setEpisode:episode position:(double)cur];
        _changingPosition = NO;
        [DMANAGER saveAndSync:YES];
        
        [self _removeTemporarySavePosition];
    }
}

- (void) restart
{
	CDEpisode* episode = self.playingEpisode;
	
	self.changingEpisode = YES;
    [self openWithEpisode:episode at:0 autostart:YES];
}

- (void) close
{
    [self closeAndSaveCurrentPosition:YES];
}

- (void) closeAndSaveCurrentPosition:(BOOL)saveCurrentPosition
{
	// stop the skipping thing in case the user holds down the buttons until the end
    self.ready = NO;
    
	[self.controlTimer invalidate];
	self.controlTimer = nil;
	
	[self.mediaAsset cancelLoading];
	self.mediaAsset = nil;
	
    if (!self.changingEpisode) {
        [self _endNextItemHandover];
    }
	
	if (self.player)
	{
        if (saveCurrentPosition) {
            [self _saveCurrentPlaybackPosition];
        }
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
        
        
        if (self.player.rate > 0) {
			[self.player pause];
		}
        
        [self.player.currentItem removeTaskObserver:self forKeyPath:@"status"];
        [self.player.currentItem removeTaskObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        [self.player.currentItem removeTaskObserver:self forKeyPath:@"playbackBufferFull"];
        [self.player.currentItem removeTaskObserver:self forKeyPath:@"loadedTimeRanges"];
        [self.player removeTaskObserver:self forKeyPath:@"rate"];

		if (self.playbackObserver) { 
			[self.player removeTimeObserver:self.playbackObserver]; 
			self.playbackObserver = nil;
		}
        
        if (self.positionObserver) {
            [self.player removeTimeObserver:self.positionObserver];
            self.positionObserver = nil;
        }
        
        [self.playingEpisode removeTaskObserver:self forKeyPath:@"position"];
		
		[self.playerView removeFromSuperview];
		self.playerView = nil;
		
		//_state = IdleState;
		self.ready = NO;
        
		self.chapters = nil;
        if (_chapterTimesIdx) {
            free(_chapterTimesIdx);
            _chapterTimesIdx = NULL;
        }
        
        self.artworks = nil;
        if (_artworkTimesIdx) {
            free(_artworkTimesIdx);
            _artworkTimesIdx = nil;
        }
		
		self.player = nil;
        [self _setupRemotePlaybackCenterWithEpisode:nil];
	}
    
    if (!self.changingEpisode && self.playingEpisode) {
        self.playingEpisode = nil;
        [[AudioSession sharedAudioSession] clear];
        [[NSNotificationCenter defaultCenter] postNotificationName:PlaybackManagerDidEndNotification object:self];
    }
}

+ (NSSet*) keyPathsForValuesAffectingVolume {
    return [NSSet setWithObject:@"ready"];
}

- (float) volume
{
    return [USER_DEFAULTS floatForKey:kDefaultPlaybackVolume];
}

- (void) setVolume:(float)volume
{
    if (_volume != volume) {
        _volume = volume;

        self.player.volume = volume;
        [USER_DEFAULTS setFloat:volume forKey:kDefaultPlaybackVolume];
    }
}

+ (NSSet*) keyPathsForValuesAffectingWaitingForLoad {
    return [NSSet setWithObject:@"state"];
}


- (BOOL) isWaitingForLoad {
    return (self.state == ShouldRunState);
}

+ (NSSet*) keyPathsForValuesAffectingPaused {
    return [NSSet setWithObjects:@"state", @"player.rate", nil];
}

- (BOOL) isPaused
{
    if (self.state == ShouldRunState) {
        return NO;
    }
    
	return (self.player.rate == 0 && self.state != InitializedState);
}

- (void) play
{
	// rewind 30 seconds if we paused more than 10 mins
	if (self.lastPauseDate)
	{
		if ([USER_DEFAULTS boolForKey:PlayerReplayAfterPause] && [[NSDate date] timeIntervalSinceDate:self.lastPauseDate] > 600)
		{
			CMTime current = [self.player.currentItem currentTime];
			NSInteger cur = current.value/current.timescale;
			NSTimeInterval next = MAX(cur-30, 0);
			[self seekToTime:next];
		}
		self.lastPauseDate = nil;
	}
	
	switch (self.speedControl) {
		case PlaybackSpeedControlNormalSpeed:
			self.player.rate = 1.0;
			break;
		case PlaybackSpeedControlDoubleSpeed:
			self.player.rate = 1.5;
			break;
        case PlaybackSpeedControlPlusHalfSpeed:
			self.player.rate = 1.2;
			break;
		case PlaybackSpeedControlMinusHalfSpeed:
			self.player.rate = 0.71;
			break;
        case PlaybackSpeedControlTripleSpeed:
            self.player.rate = 2.0;
			break;
		default:
			break;
	}
    
	SEND_UPDATE
}

- (void) pause
{
    if (!self.paused)
    {
        [self.player pause];
        self.lastPauseDate = [NSDate date];
        
        // prevent starting auto-playback when playthrough available
        self.state = RunningState;
        
        [self _saveCurrentPlaybackPosition];
        SEND_UPDATE
    }
}

- (void) playPause
{
    if (self.paused) {
        [self play];
    } else {
        [self pause];
    }
}

- (void) seekToTime:(NSTimeInterval)time
{
	[self seekToTime:time tolerance:YES];
}

- (void) seekToTime:(NSTimeInterval)time tolerance:(BOOL)tolerance
{
	CMTime current = CMTimeMake((int64_t)(time*1000), 1000);
    if (!tolerance) {
        [self.player seekToTime:current toleranceBefore:CMTimeMake(0, 1000) toleranceAfter:CMTimeMake(1000, 1000)];
    } else {
        [self.player seekToTime:current];
    }

	SEND_UPDATE
    
	[self _findAndSetCurrentChapter:time];
    [self _findAndSetCurrentArtwork];
    [self coalescedPerformSelector:@selector(_setNowPlayingInfoOfEpisode:) object:nil afterDelay:1.0];
    
    if (self.paused) {
        [self _saveCurrentPlaybackPosition];
    }
}

- (void) seekToChapter:(ICMetadataChapter*)chapter
{
    // fix chapter display for 5 seconds due to seeking fuzzyness
    self.seekingChapter = chapter;
    
    [self perform:^(id sender) {
        self.seekingChapter = nil;
        [self _findAndSetCurrentChapter:-1];
    } afterDelay:5.0];
    
    NSTimeInterval time = CMTimeGetSeconds(chapter.start);
    [self seekToTime:time tolerance:NO];
}

- (NSTimeInterval) _scrubbTime
{
	NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:self.controlStartDate];
	if (t < 1) {
		return 1.0f;
	}
	else if (t < 2) {
		return 2.0f;
	}
	else if (t < 3) {
		return 5.0f;
	}
	else if (t < 4) {
		return 10.0f;
	}
	else if (t < 5) {
		return 15.0f;
	}
	else if (t < 6) {
		return 30.0f;
	}
	else if (t < 7) {
		return 60.0f;
	}
	else if (t < 8) {
		return 120.0f;
	}
	
	return 240.0f;
}

- (void) _scrubb:(NSTimeInterval)time
{
	NSInteger cur = self.time;
	NSInteger dur = self.duration;
	
	NSTimeInterval t = MIN(MAX(cur+time,0),dur);
	[self seekToTime:t];
}

- (void) _backwardScrubb:(NSTimer*)timer
{
	NSTimeInterval scrubTime = [self _scrubbTime];
	[self _scrubb:-scrubTime];
}

- (void) _forwardScrubb:(NSTimer*)timer
{
	NSTimeInterval scrubTime = [self _scrubbTime];
	[self _scrubb:scrubTime];
}


- (void) beginSeekingBackward
{
    self.seeking = YES;
	[self.controlTimer invalidate];
	self.controlTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_backwardScrubb:) userInfo:nil repeats:YES];
	self.controlStartDate = [NSDate date];
}

- (void) beginSeekingForward
{
    self.seeking = YES;
	[self.controlTimer invalidate];
	self.controlTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_forwardScrubb:) userInfo:nil repeats:YES];
	self.controlStartDate = [NSDate date];
}

- (void) endSeeking
{
	[self.controlTimer invalidate];
	self.controlTimer = nil;
	self.controlStartDate = nil;
    self.seeking = NO;
    
    if (self.paused) {
        [self _saveCurrentPlaybackPosition];
    }
}

- (void) seekForward
{
    CDFeed* feed = self.playingEpisode.feed;
    
	NSInteger skipPeriod = [feed integerForKey:PlayerSkipForwardPeriod];
	
	NSInteger cur = self.time;
	NSInteger dur = self.duration;
	
	NSInteger next = MIN(dur-1,cur + skipPeriod);
	if (next < dur) {
		[self seekToTime:next];
	}
}

- (void) seekBackward
{
    CDFeed* feed = self.playingEpisode.feed;
    
	NSInteger skipPeriod = [feed integerForKey:PlayerSkipBackPeriod];
	NSTimeInterval cur = self.time;
	NSInteger next = MAX(cur - skipPeriod,0);
    if (cur > 2) {
        [self seekToTime:next];
    }
}


- (void) rewind30Seconds
{
	NSTimeInterval cur = self.time;
	NSInteger next = MAX(cur - 30, 0);
	[self seekToTime:next];
}

- (BOOL) hasPlaylist
{
    return ([[AudioSession sharedAudioSession].playlist count] > 1);
}

/*
- (void) nextTrack
{
    CDEpisode* episode = self.playingEpisode;
    NSArray* playlist = [AudioSession sharedAudioSession].playlist;
    NSInteger index = [playlist indexOfObject:episode];
    
    if ([playlist count] < 1 || index == NSNotFound) {
        return;
    }
    
    CDEpisode* nextEpisode = nil;
    
    // if not last item, play next item
    if (index < [playlist count]-1) {
        nextEpisode = [playlist objectAtIndex:index+1];
    }
    // if last item, play the first item
    else {
        nextEpisode = [playlist objectAtIndex:0];
    }
    
    if ([[AudioSession sharedAudioSession] canContinuePlayingEpisode:nextEpisode]) {
        [[AudioSession sharedAudioSession] playEpisode:nextEpisode];
    }
}

- (void) previousTrack
{
    CDEpisode* episode = self.playingEpisode;
    NSArray* playlist = [AudioSession sharedAudioSession].playlist;
    NSInteger index = [playlist indexOfObject:episode];
    
    if ([playlist count] == 0 || index == NSNotFound) {
        return;
    }
    
    CDEpisode* previousEpisode = nil;
    
    // if not first item, play previous item
    if (index > 0) {
        previousEpisode = [playlist objectAtIndex:index-1];
    }
    // if first item, play last item
    else {
        previousEpisode = [playlist lastObject];
    }
    
    if ([[AudioSession sharedAudioSession] canContinuePlayingEpisode:previousEpisode]) {
        [[AudioSession sharedAudioSession] playEpisode:previousEpisode];
    }
}
*/

- (void) nextChapter
{
    if (self.currentChapter < [self.chapters count]-1)
    {
        ICMetadataChapter* nextChapter = [self.chapters objectAtIndex:self.currentChapter+1];
        NSTimeInterval time = (NSTimeInterval)CMTimeGetSeconds(nextChapter.start);
        
        [self seekToTime:time tolerance:NO];
    }
}

- (void) previousChapter
{
    if (self.currentChapter > 0)
    {
        ICMetadataChapter* previousChapter = [self.chapters objectAtIndex:self.currentChapter-1];
        NSTimeInterval time = (NSTimeInterval)CMTimeGetSeconds(previousChapter.start);

        [self seekToTime:time tolerance:NO];
    }
}

- (void) setSpeedControl:(PlaybackSpeedControl)_speed
{
	if (_speedControl != _speed) {
		_speedControl = _speed;
		
        [USER_DEFAULTS setInteger:_speed forKey:DefaultPlaybackSpeed];
		
		if (self.player.rate > 0)
        {
            switch (_speedControl) {
                case PlaybackSpeedControlNormalSpeed:
                    self.player.rate = 1.0;
                    break;
                case PlaybackSpeedControlDoubleSpeed:
                    self.player.rate = 1.5;
                    break;
                case PlaybackSpeedControlPlusHalfSpeed:
                    self.player.rate = 1.2;
                    break;
                case PlaybackSpeedControlMinusHalfSpeed:
                    self.player.rate = 0.71;
                    break;
                case PlaybackSpeedControlTripleSpeed:
                    self.player.rate = 2.0;
                    break;
                default:
                    break;
            }
        }
		
		SEND_UPDATE
	}
}

- (void) updateForSpeedControlSettingsChanged
{
    CDFeed* feed = self.playingEpisode.feed;
    _speedControl = [feed integerForKey:DefaultPlaybackSpeed];
    
    if (self.player.rate > 0)
    {
        switch (_speedControl) {
            case PlaybackSpeedControlNormalSpeed:
                self.player.rate = 1.0;
                break;
            case PlaybackSpeedControlDoubleSpeed:
                self.player.rate = 1.5;
                break;
            case PlaybackSpeedControlPlusHalfSpeed:
                self.player.rate = 1.2;
                break;
            case PlaybackSpeedControlMinusHalfSpeed:
                self.player.rate = 0.71;
                break;
            case PlaybackSpeedControlTripleSpeed:
                self.player.rate = 2.0;
                break;
            default:
                break;
        }
    }
}

+ (NSSet*) keyPathsForValuesAffectingPosition
{
    return [NSSet setWithObjects:@"time", @"duration", @"ready", nil];
}

- (double) position
{
    if (self.seekingPositionChangeDate && [self.seekingPositionChangeDate timeIntervalSinceNow] > -1) {
        return self.seekingPosition;
    }
    
    return (self.duration > 0) ? self.time / self.duration : 0;
}

- (void) setPosition:(double)position
{
	NSTimeInterval time = [self duration]*position;
	[self seekToTime:time];
    
    self.seekingPosition = position;
    self.seekingPositionChangeDate = [NSDate date];
}

+ (NSSet*) keyPathsForValuesAffectingPlayablePosition
{
    return [NSSet setWithObjects:@"playableDuration", @"duration", nil];
}

- (double) playablePosition
{
    return (self.duration > 0) ? self.playableDuration / self.duration : 0;
}

- (NSTimeInterval) time
{
	AVPlayerItem* item = self.player.currentItem;
	CMTime current = [item currentTime];
	NSTimeInterval time = (current.timescale > 0) ? (NSTimeInterval)current.value/(NSTimeInterval)current.timescale : 0;
    return MIN(time, self.duration);
}

- (NSTimeInterval) duration
{
	AVPlayerItem* item = self.player.currentItem;
    AVAsset* asset = item.asset;
    
    AVKeyValueStatus status = [asset statusOfValueForKey:@"duration" error:nil];
    if (status == AVKeyValueStatusLoaded) {
        CMTime duration = item.asset.duration;
        NSTimeInterval dur = (duration.timescale > 0) ? (NSTimeInterval)duration.value/(NSTimeInterval)duration.timescale : 0;
        return floorf(dur);
    }
    
    return 0;
}

- (NSTimeInterval) playableDuration
{
	if (!self.player.currentItem) {
		return 0.0f;
	}
	
	AVPlayerItem* item = self.player.currentItem;
	CMTimeRange loadRange = [[item.loadedTimeRanges lastObject] CMTimeRangeValue];
	NSTimeInterval dur =  (NSTimeInterval)((double)loadRange.start.value / (double)loadRange.start.timescale + (double)loadRange.duration.value / (double)loadRange.duration.timescale);
    return floorf(dur);
}

- (void) stopAirPlayVideo
{
#if TARGET_OS_IPHONE
	if ([self.player respondsToSelector:@selector(allowsAirPlayVideo)]) {
		self.player.allowsExternalPlayback = NO;
	}
#endif
}

- (BOOL) isAirPlayVideoActive
{
#if TARGET_OS_IPHONE
	if ([self.player respondsToSelector:@selector(isAirPlayVideoActive)]) {
		return [self.player isExternalPlaybackActive];
	}
#endif
    return NO;
}

#pragma mark -

- (void) _findAndSetCurrentChapter:(NSTimeInterval)time
{
    if (self.seekingChapter) {
        self.currentChapter = [self.chapters indexOfObject:self.seekingChapter];
        if (self.currentChapter != NSNotFound) {
            return;
        }
    }
    
	if (!_chapterTimesIdx) {
		return;
	}
	
    if (time < 0) {
        time = self.time;
    }
    
    //DebugLog(@"time %f",time);
	
	NSInteger i;
	NSInteger c = -1;
	
	for(i=0; i<[self.chapters count]; i++)
	{
		if (time >= _chapterTimesIdx[i]) {
			c = i;
		} else {
			break;
		}
	}
	
    if (self.currentChapter != c) {
        self.currentChapter = c;
    }
}

- (void) _findAndSetCurrentArtwork
{
	if (!_artworkTimesIdx) {
		return;
	}
	
	NSTimeInterval time = self.time;
	
	NSInteger i;
	NSInteger c = -1;
	
	for(i=0; i<[self.artworks count]; i++)
	{
		if (time >= _artworkTimesIdx[i]) {
			c = i;
		} else {
			break;
		}
	}
	
    if (self.currentArtwork != c) {
        self.currentArtwork = c;
    }
}

#pragma mark -
#pragma mark Chapter Support

- (void) _startLoadingChapters
{
    ICMetadataParser* parser = [[ICMetadataParser alloc] initWithAsset:self.mediaAsset];
    [parser loadAsynchronouslyWithCompletionHandler:^(BOOL success, NSError *error) {
        
        NSArray* chapters = parser.metadataAsset.chapters;
        
        // create chapter index for fast chapter search
        _chapterTimesIdx = (float*)malloc(sizeof(float)*[chapters count]);
        [chapters enumerateObjectsUsingBlock:^(ICMetadataChapter* chapter, NSUInteger idx, BOOL *stop) {
            _chapterTimesIdx[idx] = (float)CMTimeGetSeconds(chapter.start);
        }];
        
        [self _findAndSetCurrentChapter:-1];
        self.chapters = chapters;
        
        
        NSArray* images = parser.metadataAsset.images;

        _artworkTimesIdx = (float*)malloc(sizeof(float)*[images count]);
        [images enumerateObjectsUsingBlock:^(ICMetadataImage* image, NSUInteger idx, BOOL *stop) {
            _artworkTimesIdx[idx] = (float)CMTimeGetSeconds(image.start);
        }];
        
        [self _findAndSetCurrentArtwork];
        self.artworks = images;
        
        [self _setNowPlayingInfoOfEpisode:nil];
        DebugLog(@"chapters loaded");
    }];
}


#pragma mark - Audio Output


#if !TARGET_OS_IPHONE

- (void) setAudioEndpoint:(ICAudioEndpoint *)audioEndpoint
{
    if (_audioEndpoint != audioEndpoint) {
        _audioEndpoint = audioEndpoint;

#if ENABLE_10_9_AUDIO_DEVICE_BEHAVIOR == 1
        if ([NSBundle systemVersion] >= VM_SYSTEM_VERSION_OS_X_10_9 && [AVPlayer implementsSelector:@selector(audioOutputDeviceUniqueID)]) {
            [PlaybackManager setDataSourceOfAudioDeviceForEndpoint:audioEndpoint];
            self.player.audioOutputDeviceUniqueID = audioEndpoint.UID;
            return;
        }
#endif

        [PlaybackManager setAudioEndpointToCurrentSystemOutput:audioEndpoint];
    }
}

- (void) _handleChangeOfCurrentSystemAudioOutputDevice
{
#if ENABLE_10_9_AUDIO_DEVICE_BEHAVIOR == 1
    if ([NSBundle systemVersion] >= VM_SYSTEM_VERSION_OS_X_10_9 && [AVPlayer implementsSelector:@selector(audioOutputDeviceUniqueID)]) {
        return;
    }
#endif
    [self _setAudioEndpointToCurrentSystemAudioDevice];
}

- (void) _setAudioEndpointToCurrentSystemAudioDevice
{
    for (ICAudioEndpoint* endpoint in [PlaybackManager audioOutputEndpoints]) {
        if ([PlaybackManager audioEndpointIsCurrentSystemOutput:endpoint]) {
            [self willChangeValueForKey:@"audioEndpoint"];
            _audioEndpoint = endpoint;
            [self didChangeValueForKey:@"audioEndpoint"];
        }
    }
}

#endif
@end
