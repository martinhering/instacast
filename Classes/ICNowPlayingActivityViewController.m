//
//  ICNowPlayingActivityViewController.m
//  Instacast
//
//  Created by Martin Hering on 26.08.14.
//
//

#import "ICNowPlayingActivityViewController.h"
#import "ICNowPlayingActivityControl.h"
#import "CDEpisode+ShowNotes.h"
#import "UpNextTableViewController.h"

@interface ICNowPlayingActivityViewController ()
@property (nonatomic, strong, readwrite) ICNowPlayingActivityControl* nowPlayingControl;
@property (nonatomic, readwrite) BOOL visible;
@property (nonatomic, readwrite) BOOL appeared;
@end

@implementation ICNowPlayingActivityViewController {
    BOOL _observing;
}

- (void) dealloc
{
    [self _setObserving:NO];
}

- (void) _setObserving:(BOOL)observing
{
    AudioSession* session = [AudioSession sharedAudioSession];
    PlaybackManager* pman = [PlaybackManager playbackManager];
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];

    if (observing && !_observing)
    {
        __weak ICNowPlayingActivityViewController* weakSelf = self;
        
        [session addTaskObserver:self forKeyPath:@"episode" task:^(id obj, NSDictionary *change) {
            [weakSelf _updateNowPlayingAnimated:YES];
            [weakSelf _updateVisibleAndNotify];
        }];
        
        [session addTaskObserver:self forKeyPath:@"playlist" task:^(id obj, NSDictionary *change) {
            [weakSelf _updateNowPlayingAnimated:YES];
            [weakSelf _updateVisibleAndNotify];
        }];
        
        [pman addTaskObserver:self forKeyPath:@"position" task:^(id obj, NSDictionary *change) {
            [weakSelf _updatePositionAnimated:YES];
        }];
        
        [pman addTaskObserver:self forKeyPath:@"paused" task:^(id obj, NSDictionary *change) {
            [weakSelf _updatePlayButton];
        }];
        
        [nc addObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil handler:^(NSNotification *notification) {
            weakSelf.nowPlayingControl.marqueePaused = YES;
        }];
        
        [nc addObserver:self name:UIApplicationWillEnterForegroundNotification object:nil handler:^(NSNotification *notification) {
            if (weakSelf.appeared) {
                weakSelf.nowPlayingControl.marqueePaused = NO;
            }
        }];
        
        _observing = YES;
    }
    else if (!observing && _observing) {
        [session removeTaskObserver:self forKeyPath:@"episode"];
        [session removeTaskObserver:self forKeyPath:@"playlist"];
        [pman removeTaskObserver:self forKeyPath:@"position"];
        [pman removeTaskObserver:self forKeyPath:@"paused"];
        [nc removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
        [nc removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
        _observing = NO;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    CGRect b = self.view.bounds;
    self.nowPlayingControl = [[ICNowPlayingActivityControl alloc] initWithFrame:b];
    self.nowPlayingControl.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    [self.nowPlayingControl.rightButton addTarget:self action:@selector(nowPlayingControlRightButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    UILongPressGestureRecognizer* recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.nowPlayingControl addGestureRecognizer:recognizer];
    
    [self _updateNowPlayingAnimated:NO];
    [self _updatePlayButton];
    
    [self.view addSubview:self.nowPlayingControl];
    
    [self _updateVisibleAndNotify];
    [self _setObserving:YES];
}

- (void) nowPlayingControlRightButtonAction:(id)sender
{
    [[AudioSession sharedAudioSession] togglePlay];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.nowPlayingControl.backgroundColor = ICDarkBackgroundColor;
    self.nowPlayingControl.progressView.progressTintColor = ICTintColor;
    self.nowPlayingControl.progressView.trackTintColor = [UIColor clearColor];
    
    [self _updateNowPlayingAnimated:NO];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.nowPlayingControl.marqueePaused = NO;
    _appeared = YES;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    _appeared = YES;
    self.nowPlayingControl.marqueePaused = YES;
}

- (void) _updateNowPlayingAnimated:(BOOL)animated
{
    AudioSession* session = [AudioSession sharedAudioSession];
    CDEpisode* playingEpisode = session.episode;
    
    if (playingEpisode) {
        self.nowPlayingControl.label2.text = [NSString stringWithFormat:@"%@ - %@", playingEpisode.feed.title, [playingEpisode cleanTitleUsingFeedTitle:playingEpisode.feed.title]];
        [self _updatePositionAnimated:animated];
    }
    
    if ([session.playlist count] == 0) {
        self.nowPlayingControl.label1.text = @"Now Playing".ls;
    }
    else {
        self.nowPlayingControl.label1.text = [NSString stringWithFormat:@"Now Playing - %ld queued".ls, [session.playlist count]];
    }
}

- (void) _updatePositionAnimated:(BOOL)animated
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    AudioSession* session = [AudioSession sharedAudioSession];
    CDEpisode* playingEpisode = session.episode;
    
    if (pman.ready) {
        [self.nowPlayingControl.progressView setProgress:pman.position animated:animated];
    }
    else if (playingEpisode.duration > 0) {
        [self.nowPlayingControl.progressView setProgress:(float)playingEpisode.position/(float)playingEpisode.duration animated:animated];
    }
    else {
        [self.nowPlayingControl.progressView setProgress:0 animated:animated];
    }
}

- (void) _updatePlayButton
{
    if ([PlaybackManager playbackManager].paused) {
        UIImage* image = [[UIImage imageNamed:@"Activity Button Play"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.nowPlayingControl.rightButton setImage:image forState:UIControlStateNormal];
    }
    else {
        UIImage* image = [[UIImage imageNamed:@"Activity Button Pause"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.nowPlayingControl.rightButton setImage:image forState:UIControlStateNormal];
    }
}

- (void) _updateVisibleAndNotify {
    AudioSession* session = [AudioSession sharedAudioSession];
    CDEpisode* playingEpisode = session.episode;
    self.visible = (playingEpisode != nil);
}

- (void) handleLongPress:(UILongPressGestureRecognizer*)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        AudioSession* session = [AudioSession sharedAudioSession];
        [session stop];
    }
}
@end
