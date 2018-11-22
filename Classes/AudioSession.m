//
//  AudioSession.m
//  Instacast
//
//  Created by Martin Hering on 19.07.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MPNowPlayingInfoCenter.h>

#import "AudioSession.h"
#import "AudioSession+UpNextPlaylist.h"

#import "ICMetadata.h"

static NSString* kPlaybackStateEpisode = @"PlaybackEpisode";
static NSString* kPlaybackStatePlaylist = @"PlaybackPlaylist";

NSString* AudioSessionAudioRouteDidChangeNotification = @"AudioSessionAudioRouteDidChangeNotification";
NSString* AudioSessionDidRestorePlaybackNotification = @"AudioSessionDidRestorePlaybackNotification";

@interface AudioSession () <AVAudioSessionDelegate>
@property (nonatomic, readwrite, strong) CDEpisode* episode;

- (void) _savePlaybackStateInUserDefaults;
- (void) _restorePlaybackStateFromUserDefaults;

@property (nonatomic, strong) NSTimer* playbackTimer;
@property (nonatomic, strong) NSDate* stopDate;
@property BOOL playerWasPlayingBeforeWentToBackground;
@property BOOL continuousPlaybackTemporarilyDisabled;
@property BOOL autoStopDisabled;
@end


@implementation AudioSession


#pragma mark -

+ (AudioSession*) sharedAudioSession
{
	static AudioSession* gSharedAudioSession = nil;
	
	if (!gSharedAudioSession) {
		gSharedAudioSession = [self alloc];
		gSharedAudioSession = [gSharedAudioSession init];
	}
	return gSharedAudioSession;
}

- (id) init
{
	if ((self = [super init]))
	{
        AVAudioSession* session = [AVAudioSession sharedInstance];
        
        NSError* categoryError = nil;
        if (![session setCategory:AVAudioSessionCategoryPlayback withOptions:0 error:&categoryError]) {
            ErrLog(@"error setting audio category: %@", categoryError);
        }
        
        //dispatch_async(dispatch_get_main_queue(), ^{
            [self _restorePlaybackStateFromUserDefaults];
        //});

    
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillResignActiveNotification:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:App];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackgroundNotification:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:App];
        
        [self _observeAudioSessionForChanges];
        [self _observePlaybackForStoringChapters];
        [self _observeEpisodeCacheBeingDeleted];
	}
	
	return self;
}

- (void) resetSession
{
    AVAudioSession* session = [AVAudioSession sharedInstance];
    
    NSError* categoryError = nil;
    if (![session setCategory:AVAudioSessionCategoryPlayback withOptions:0 error:&categoryError]) {
        ErrLog(@"error setting audio category: %@", categoryError);
    }
}

- (void) _updateAudioSessionCategory
{
    AVAudioSession* session = [AVAudioSession sharedInstance];
    
    if (![PlaybackManager playbackManager].playingEpisode) {
        [self perform:^(id sender) {
            NSError* error;
            [session setActive:NO error:&error];
            if (error) {
                ErrLog(@"error deactivating audio session %@", error);
            }
        } afterDelay:1.0];
        
    }
    else
    {
        NSError* error;
        [session setActive:YES error:&error];
        
        if (error) {
            ErrLog(@"error (activating audio session %@", error);
        }
    }
    
    
}

// XXX Hack to keep video playing in background
- (void)applicationWillResignActiveNotification:(UIApplication *)application
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    
    self.playerWasPlayingBeforeWentToBackground = (!pman.paused);
}

-(void)resumePlayback
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    
    if (self.playerWasPlayingBeforeWentToBackground && pman.paused) {
        [pman play];
    }
}
- (void)applicationDidEnterBackgroundNotification:(UIApplication *)application
{
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(resumePlayback) userInfo:nil repeats:NO];
}


- (void) _observeEpisodeCacheBeingDeleted
{
    [[NSNotificationCenter defaultCenter] addObserverForName:CacheManagerDidClearCacheNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                                                           
                                                           if (!self.autoStopDisabled && [self.episode isEqual:note.userInfo[@"episode"]]) {
                                                               [self stop];
                                                           }
                                                           
                                                       }];
}

- (void) _observeAudioSessionForChanges
{
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    
    // AVAudioSessionInterruptionNotification
    [nc addObserver:self selector:@selector(audioSessionInterruptionNotification:) name:AVAudioSessionInterruptionNotification object:nil];
    [nc addObserver:self selector:@selector(audioSessionRouteChangeNotification:) name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void) audioSessionInterruptionNotification:(NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        PlaybackManager* pman = [PlaybackManager playbackManager];
        
        NSDictionary* userInfo = [notification userInfo];
        NSInteger interruptionType = [userInfo[AVAudioSessionInterruptionTypeKey] integerValue];
        NSInteger option = [userInfo[AVAudioSessionInterruptionOptionKey] integerValue];
        
        DebugLog(@"userInfo: %@", userInfo);
        
        BOOL wasPlaying = pman.hasBeenPlayingWhenInterrupted;
        
        if (interruptionType == AVAudioSessionInterruptionTypeBegan) {
            pman.hasBeenPlayingWhenInterrupted = !pman.paused;
            [pman pause];
        }
        else if (interruptionType == AVAudioSessionInterruptionTypeEnded && wasPlaying) {
            if (option == AVAudioSessionInterruptionOptionShouldResume) {
                [pman play];
            }
        }
    });
}

- (void) audioSessionRouteChangeNotification:(NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        PlaybackManager* pman = [PlaybackManager playbackManager];
        
        NSDictionary* userInfo = [notification userInfo];
        DebugLog(@"userInfo: %@", userInfo);
        
        [self willChangeValueForKey:@"airPlayActive"];
        [self didChangeValueForKey:@"airPlayActive"];
        
        [self willChangeValueForKey:@"headphonesAttached"];
        [self didChangeValueForKey:@"headphonesAttached"];
        
        
        AVAudioSessionRouteChangeReason reason = [userInfo[AVAudioSessionRouteChangeReasonKey] integerValue];
        
        if (reason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
            [pman pause];
            [pman setHasBeenPlayingWhenInterrupted:NO];
        }
        
        else if (reason == AVAudioSessionRouteChangeReasonCategoryChange) {
            [self resetSession];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:AudioSessionAudioRouteDidChangeNotification object:self];
    });
}


- (void) _observePlaybackForStoringChapters
{
    [[PlaybackManager playbackManager] addTaskObserver:self forKeyPath:@"chapters" task:^(id obj, NSDictionary *change) {
        PlaybackManager* pman = [PlaybackManager playbackManager];
        
        NSSet* storedChapters = [pman.playingEpisode chapters];
        
        if (pman.chapters > 0 && [storedChapters count] == 0)
        {
            [pman.chapters enumerateObjectsUsingBlock:^(ICMetadataChapter* chapter, NSUInteger idx, BOOL *stop) {
                
                CDChapter* ch = [NSEntityDescription insertNewObjectForEntityForName:@"Chapter" inManagedObjectContext:DMANAGER.objectContext];
                ch.index = (int32_t)idx;
                ch.title = chapter.title;
                ch.timecode = (double)CMTimeGetSeconds(chapter.start);
                ch.duration = [chapter durationWithTrackDuration:pman.duration];
                ch.linkURL = chapter.link;
                [pman.playingEpisode addChaptersObject:ch];
                
            }];
            
            [DMANAGER save];
        }
    }];
    
    [[PlaybackManager playbackManager] addTaskObserver:self forKeyPath:@"playingEpisode" task:^(id obj, NSDictionary *change) {
        [self _updateAudioSessionCategory];
    }];
}

#pragma mark -


- (CDEpisode*) nextPlayableEpisode
{
    if (self.continuousPlaybackTemporarilyDisabled) {
        return nil;
    }
    
	BOOL canStartEpisode = YES;

    CDEpisode* anEpisode = [[self playlist] firstObject];

    BOOL warn3G = (App.networkAccessTechnology < kICNetworkAccessTechnlogyWIFI && ![USER_DEFAULTS boolForKey:EnableStreamingOver3G]);
    BOOL episodeIsCached = [[CacheManager sharedCacheManager] episodeIsCached:anEpisode];
    
    if (!episodeIsCached && warn3G) {
        canStartEpisode = NO;
    }

	return (canStartEpisode && [anEpisode preferedMedium]) ? anEpisode : nil;
}

- (void) playEpisode:(CDEpisode*)anEpisode
{
    [self playEpisode:anEpisode queueUpCurrent:NO];
}

- (void) playEpisode:(CDEpisode*)anEpisode queueUpCurrent:(BOOL)queueUpCurrent
{
    [self playEpisode:anEpisode queueUpCurrent:queueUpCurrent at:0 autostart:YES];
}

- (void) playEpisode:(CDEpisode*)anEpisode queueUpCurrent:(BOOL)queueUpCurrent at:(NSTimeInterval)time autostart:(BOOL)autostart
{
    if (!anEpisode) {
        return;
    }
    
    [self resetSession];
    
    CDEpisode* currentEpisode = self.episode;

    self.episode = anEpisode;
    [self eraseEpisodesFromUpNext:@[anEpisode]];
    
    if (currentEpisode && queueUpCurrent) {
        [self prependToUpNext:@[currentEpisode]];
    }

	[self _savePlaybackStateInUserDefaults];
    [[PlaybackManager playbackManager] openWithEpisode:anEpisode at:0 autostart:autostart];
    
    self.continuousPlaybackTemporarilyDisabled = NO;
}

- (void) clear
{
    if (self.episode) {
        self.episode = nil;
        [self _savePlaybackStateInUserDefaults];
        
        DebugLog(@"endReceivingRemoteControlEvents");
        
        [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;
    }
}

- (void) stop
{
    [[PlaybackManager playbackManager] close];
    [self clear];
}

- (void) togglePlay
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    if (pman.paused)
    {
        if (!pman.ready && self.episode) {
            [self playEpisode:self.episode];
        }
        
        else {
            [pman play];
        }
        
    } else {
        [pman pause];
    }
}

- (void) disableContinuousPlaybackForCurrentEpisode
{
    self.continuousPlaybackTemporarilyDisabled = YES;
}

- (void) setEpisode:(CDEpisode *)episode
{
    __weak AudioSession* weakSelf = self;
    
    if (_episode != episode)
    {
        [_episode removeTaskObserver:self forKeyPath:@"archived"];
        [_episode.feed removeTaskObserver:self forKeyPath:@"subscribed"];
        
        _episode = episode;
        
        [episode addTaskObserver:self forKeyPath:@"archived" task:^(id obj, NSDictionary *change) {
            if (weakSelf.episode.archived) {
                [weakSelf stop];
            }
        }];
        
        [episode.feed addTaskObserver:self forKeyPath:@"subscribed" task:^(id obj, NSDictionary *change) {
            if (!weakSelf.episode.feed.subscribed) {
                [weakSelf stop];
            }
        }];
    }
}

#pragma mark -

- (void) _savePlaybackStateInUserDefaults
{
	if (self.episode && self.episode.objectHash) {
		[USER_DEFAULTS setObject:self.episode.objectHash forKey:kPlaybackStateEpisode];
	} else {
		[USER_DEFAULTS removeObjectForKey:kPlaybackStateEpisode];
	}
	
	if (self.playlist) {
		NSMutableArray* hashes = [[NSMutableArray alloc] initWithCapacity:[self.playlist count]];
		
		for(CDEpisode* anEpisode in self.playlist) {
			if (anEpisode.guid) {
				[hashes addObject:anEpisode.objectHash];
			}
		}
		
		[USER_DEFAULTS setObject:hashes forKey:kPlaybackStatePlaylist];
		
	} else {
		[USER_DEFAULTS removeObjectForKey:kPlaybackStatePlaylist];
	}
	
	[USER_DEFAULTS synchronize];
}

- (void) _restorePlaybackStateFromUserDefaults
{
	NSString* episodeHash = [USER_DEFAULTS objectForKey:kPlaybackStateEpisode];
	NSArray* playlistHashes = [USER_DEFAULTS objectForKey:kPlaybackStatePlaylist];
	
	[self restorePlaybackStateWithEpisodeHash:episodeHash playlistHashes:playlistHashes time:-1];
}

- (BOOL) canRestorePlaybackState
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    return (pman.paused);
}

- (void) restorePlaybackStateWithEpisodeHash:(NSString*)episodeHash playlistHashes:(NSArray*)playlistHashes time:(NSTimeInterval)time
{
    if (![self canRestorePlaybackState]) {
        return;
    }
    
    if (episodeHash)
    {
        PlaybackManager* pman = [PlaybackManager playbackManager];
		CDEpisode* anEpisode = [DMANAGER episodeWithObjectHash:episodeHash];
        
		if (anEpisode && !anEpisode.archived)
        {
            if ([self.episode isEqual:anEpisode]) {
                NSTimeInterval t = (time >= 0) ? time : anEpisode.position;
                [pman seekToTime:t];
            }

			self.episode = anEpisode;
		}
	}
	
	if (playlistHashes)
	{
		NSMutableArray* aPlaylist = [[NSMutableArray alloc] initWithCapacity:[playlistHashes count]];
		
		for (NSString* hash in playlistHashes) {
			CDEpisode* anEpisode = [DMANAGER episodeWithObjectHash:hash];
			if (anEpisode) {
				[aPlaylist addObject:anEpisode];
			}
		}
		
		if ([aPlaylist count] > 0) {
            [self appendToUpNext:aPlaylist];
		}
	}
    
    [self _savePlaybackStateInUserDefaults];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AudioSessionDidRestorePlaybackNotification object:self];
}

#pragma mark -

- (BOOL) isAirPlayActive
{
    AVAudioSession* session = [AVAudioSession sharedInstance];
    AVAudioSessionRouteDescription* currentRoute = session.currentRoute;
    NSArray* outputs = currentRoute.outputs;
    
    for(AVAudioSessionPortDescription* portDescription in outputs) {
        NSString* portType = portDescription.portType;
        NSString* portTypeAirPlay = AVAudioSessionPortAirPlay;
        NSString* portTypeBluetooth = AVAudioSessionPortBluetoothA2DP;
        
        if ([portType isEqualToString:portTypeAirPlay] || [portType isEqualToString:portTypeBluetooth]) {
            return YES;
        }
        
    }
    return NO;
}

- (BOOL) headphonesAttached
{
    AVAudioSession* session = [AVAudioSession sharedInstance];
    AVAudioSessionRouteDescription* currentRoute = session.currentRoute;
    NSArray* outputs = currentRoute.outputs;
    
    for(AVAudioSessionPortDescription* portDescription in outputs) {
        NSString* portType = portDescription.portType;
        if ([portType isEqualToString:AVAudioSessionPortHeadphones]) {
            return YES;
        }
        
    }
    return NO;
}

#pragma mark -
#pragma mark Playback Timer

- (NSTimeInterval) timerRemainingTime
{
    if (self.stopDate) {
        NSTimeInterval remaining = [self.stopDate timeIntervalSinceDate:[NSDate date]];
        return remaining;
    }
    
    return 0;
}

- (void) setTimerValue:(PlaybackStopTimeValue)timerValue
{
    if (_timerValue != timerValue) {
        _timerValue = timerValue;
    }
    
    [self.playbackTimer invalidate];
    self.playbackTimer = nil;
    
    if (timerValue > 0)
    {
        self.stopDate = [NSDate dateWithTimeIntervalSinceNow:timerValue*60];
        
        self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:60
                                                              target:self
                                                            selector:@selector(stopPlaybackTimer:)
                                                            userInfo:nil
                                                             repeats:YES];
    }
    
    [self willChangeValueForKey:@"timerRemainingTime"];
    [self didChangeValueForKey:@"timerRemainingTime"];
}

- (void) stopPlaybackTimer:(NSTimer*)timer
{
    [self willChangeValueForKey:@"timerRemainingTime"];
    [self didChangeValueForKey:@"timerRemainingTime"];
    
    NSDate* now = [NSDate date];
    if ([self.stopDate earlierDate:now] == self.stopDate)
    {
        [self.playbackTimer invalidate];
        self.playbackTimer = nil;
        
        if (self.timerValue != PlaybackStopTimeNoValue)
        {
            self.timerValue = PlaybackStopTimeNoValue;
            [[PlaybackManager playbackManager] pause];
            self.stopDate = nil;
        }
    }
}

@end
