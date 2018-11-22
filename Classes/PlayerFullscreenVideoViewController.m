//
//  PlayerFullscreenVideoViewController.m
//  Instacast
//
//  Created by Martin Hering on 06/08/14.
//
//

#import <MediaPlayer/MPVolumeView.h>

#import "PlayerFullscreenVideoViewController.h"
#import "ImageFunctions.h"
#import "PlayerVideoSlider.h"
#import "InstacastAppDelegate.h"

@interface PlayerFullscreenVideoViewController ()
@property (nonatomic, weak) IBOutlet UIView* topBar;
@property (nonatomic, weak) IBOutlet UIView* bottomBar;
@property (nonatomic, weak) IBOutlet UIView* buttonContainerView;
@property (nonatomic, weak) IBOutlet UIButton* playButton;
@property (nonatomic, weak) IBOutlet UIButton* backwardButton;
@property (nonatomic, weak) IBOutlet UIButton* forwardButton;
@property (nonatomic, weak) IBOutlet PlayerVideoSlider* scrubber;
@property (nonatomic, weak) IBOutlet UILabel* elapsedTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel* remainingTimeLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* bottomBarHeightLayoutConstraint;

@property (nonatomic, strong) NSTimer* progressTimer;
@property (nonatomic, strong) NSTimer* skipTimer;
@property (nonatomic, strong) MPVolumeView* volumeView;
@end


@implementation PlayerFullscreenVideoViewController {
    BOOL _observing;
    BOOL _wasPlaying;
}

+ (instancetype) viewController {
    return [[self alloc] initWithNibName:@"FullscreenVideoView" bundle:nil];
}

- (void) dealloc
{
    [self _setObserving:NO];
}

- (void) _setObserving:(BOOL)observing
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    //NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    
    if (observing && !_observing)
    {
        __weak PlayerFullscreenVideoViewController* weakSelf = self;
        
        [pman addTaskObserver:self forKeyPath:@"paused" task:^(id obj, NSDictionary *change) {
            [weakSelf _updatePlayButtonUI];
            self.controlsVisible = YES;
        }];
    
        [pman addTaskObserver:self forKeyPath:@"playableDuration" task:^(id obj, NSDictionary *change) {
            [self _updateScrubberUI];
        }];
        
        [pman addTaskObserver:self forKeyPath:@"time" task:^(id obj, NSDictionary *change) {
            [self _updateScrubberUI];
            [self _updateTimeUIDuringSliding:NO];
        }];
        
        _observing = YES;
    }
    else if (!observing && _observing)
    {
        [pman removeTaskObserver:self forKeyPath:@"paused"];
        [pman removeTaskObserver:self forKeyPath:@"playableDuration"];
        [pman removeTaskObserver:self forKeyPath:@"time"];
        
        _observing = NO;
    }
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.view.tintColor = [UIColor blackColor];
    
    [self.doneButton setTitle:@"Done".ls forState:UIControlStateNormal];
    
    //CGRect b = self.view.bounds;

    
    if (NSClassFromString(@"UIVisualEffectView"))
    {
        self.topBar.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.3];
        self.bottomBar.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.3];
        
        UIBlurEffect* effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        
        UIVisualEffectView* view = [[UIVisualEffectView alloc] initWithEffect:effect];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        view.frame = self.topBar.bounds;
        [self.topBar insertSubview:view atIndex:0];
        
        UIVisualEffectView* bottomBlueView = [[UIVisualEffectView alloc] initWithEffect:effect];
        bottomBlueView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        bottomBlueView.frame = self.bottomBar.bounds;
        [self.bottomBar insertSubview:bottomBlueView atIndex:0];
    }
    else
    {
        self.topBar.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
        self.bottomBar.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
    }
    
    [self _updatePlayButtonUI];
    [self _updateScrubberUI];
    [self _updateTimeUIDuringSliding:NO];
    [self _updateVolumeUI];
    
    [self.backwardButton setImage:[[UIImage imageNamed:@"Player Backward"]  imageWithColor:[UIColor blackColor]] forState:UIControlStateNormal];
    [self.backwardButton setImage:[[UIImage imageNamed:@"Player Backward"]  imageWithColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
    
    [self.forwardButton setImage:[[UIImage imageNamed:@"Player Forward"]  imageWithColor:[UIColor blackColor]] forState:UIControlStateNormal];
    [self.forwardButton setImage:[[UIImage imageNamed:@"Player Forward"]  imageWithColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
    
    [self.scrubber setThumbImage:[UIImage imageNamed:@"Video Slider Thumb"] forState:UIControlStateNormal];
    [self.scrubber setMaximumTrackImage:[[[UIImage imageNamed:@"Video Slider Outline Track"] imageWithColor:[UIColor blackColor]] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)]
                               forState:UIControlStateNormal];
    [self.scrubber setMinimumTrackImage:[[[UIImage imageNamed:@"Video Slider Outline Track"] imageWithColor:[UIColor whiteColor]] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)]
                               forState:UIControlStateNormal];
    
    [self _setObserving:YES];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self traitCollectionDidChange:self.traitCollection];
    self.controlsVisible = YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)prefersStatusBarHidden {
    return (!self.controlsVisible);
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void) _updatePlayButtonUI
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    if (pman.paused) {
        [self.playButton setImage:[[UIImage imageNamed:@"Player Play"] imageWithColor:[UIColor blackColor]] forState:UIControlStateNormal];
        [self.playButton setImage:[[UIImage imageNamed:@"Player Play"] imageWithColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
    } else {
        [self.playButton setImage:[[UIImage imageNamed:@"Player Pause"] imageWithColor:[UIColor blackColor]] forState:UIControlStateNormal];
        [self.playButton setImage:[[UIImage imageNamed:@"Player Pause"] imageWithColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
    }
}

- (void) _updateScrubberUI
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    self.scrubber.loadValue = pman.playableDuration / pman.duration;
    self.scrubber.value = (pman.duration <= 0) ? 0 : pman.time / pman.duration;
}


- (void) _updateTimeUIDuringSliding:(BOOL)duringSliding;
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    NSInteger dur = pman.duration;
    NSInteger cur = (duringSliding) ? dur * self.scrubber.value : pman.time;
    NSInteger rem = dur-cur;
    
    NSString* currentText = (cur < 3600) ? [NSString stringWithFormat:@"%ld:%02ld",(long)(cur/60)%60, (long)cur%60] : [NSString stringWithFormat:@"%ld:%02ld:%02ld", (long)cur/3600, (long)(cur/60)%60, (long)cur%60];
    self.elapsedTimeLabel.text = currentText;
    
    NSString* remainingText = (rem < 3600) ? [NSString stringWithFormat:@"-%ld:%02ld", (long)(rem/60)%60, (long)rem%60] : [NSString stringWithFormat:@"-%ld:%02ld:%02ld", (long)rem/3600, (long)(rem/60)%60, (long)rem%60];
    self.remainingTimeLabel.text = remainingText;
}

- (void) _updateVolumeUI
{
    if (!self.volumeView)
    {
        MPVolumeView* volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(15, 16, 125, 30)];
        volumeView.backgroundColor = [UIColor clearColor];
        volumeView.showsRouteButton = NO;
        volumeView.showsVolumeSlider = YES;
        [volumeView setVolumeThumbImage:[UIImage imageNamed:@"Video Slider Thumb"] forState:UIControlStateNormal];
        [volumeView setMinimumVolumeSliderImage:[[[UIImage imageNamed:@"Video Slider Fill Track"] imageWithColor:[UIColor whiteColor]] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)]
                                       forState:UIControlStateNormal];
        [volumeView setMaximumVolumeSliderImage:[[[UIImage imageNamed:@"Video Slider Fill Track"] imageWithColor:[UIColor blackColor]] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)]
                                       forState:UIControlStateNormal];
        [self.bottomBar addSubview:volumeView];
        self.volumeView = volumeView;
        self.volumeView.hidden = YES;
        
        [self perform:^(id sender) {
            self.volumeView.hidden = NO;
            self.volumeView.alpha = 0;
            [UIView animateWithDuration:0.3 animations:^{
                self.volumeView.alpha = 1;
            }];
        } afterDelay:0.4];
    }
}

- (void) traitCollectionDidChange: (UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange: previousTraitCollection];
    
    UITraitCollection* traitCollection = self.traitCollection;
    if (traitCollection.verticalSizeClass != previousTraitCollection.verticalSizeClass || traitCollection.horizontalSizeClass != previousTraitCollection.horizontalSizeClass)
    {
        [self _updateLayout];
    }
}


- (void) _updateLayout
{
    BOOL portrait = (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact && self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular);
    
    
    CGRect b = self.view.bounds;
    
    if (portrait) {
        self.bottomBar.frame = CGRectMake(0, CGRectGetHeight(b)-80, CGRectGetWidth(b), 80);
        self.bottomBarHeightLayoutConstraint.constant = 80;
        self.volumeView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.volumeView.frame = CGRectMake(15, 50, CGRectGetWidth(b)-30, 30);
    }
    else
    {
        self.bottomBar.frame = CGRectMake(0, CGRectGetHeight(b)-50, CGRectGetWidth(b), 50);
        self.bottomBarHeightLayoutConstraint.constant = 50;
        self.volumeView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        self.volumeView.frame = CGRectMake(15, 16, 125, 30);
    }
}

- (void) setControlsVisible:(BOOL)controlsVisible
{
    if (_controlsVisible != controlsVisible)
    {
        PlaybackManager* pman = [PlaybackManager playbackManager];
        if (pman.paused || !pman.ready || pman.seeking || pman.airPlayVideoActive || self.progressTimer || self.skipTimer) {
            controlsVisible = YES;
        }
        
        _controlsVisible = controlsVisible;
        
        self.topBar.hidden = !controlsVisible;
        self.bottomBar.hidden = !controlsVisible;
        
        if (controlsVisible) {
            [self coalescedPerformSelector:@selector(_hideControlsAfterDelay) afterDelay:5];
        }
        
        [((InstacastAppDelegate*)(App.delegate)) setNeedsStatusBarAppearanceUpdate];
    }
}

- (void) _hideControlsAfterDelay {
    self.controlsVisible = NO;
}
#pragma mark -

- (IBAction) togglePlay:(id)sender
{
    [self coalescedPerformSelector:@selector(_hideControlsAfterDelay) afterDelay:5];
    
    PlaybackManager* pman = [PlaybackManager playbackManager];
    
    if (pman.paused) {
        [pman play];
    } else {
        [pman pause];
    }
}

#pragma mark -

- (IBAction) beganChangingProgress:(id)sender
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    pman.seeking = YES;
    _wasPlaying = !pman.paused;
    [pman pause];
}

- (void) _asynchronouslySeek:(NSTimer*)timer
{
    [self coalescedPerformSelector:@selector(_hideControlsAfterDelay) afterDelay:5];
    
    PlaybackManager* pman = [PlaybackManager playbackManager];
    self.progressTimer = nil;
    
    double progress = self.scrubber.value;
    [pman setPosition:progress];
}

- (IBAction) progress:(id)sender
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    
    if (pman.ready)
    {
        [self.progressTimer invalidate];
        self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_asynchronouslySeek:) userInfo:nil repeats:NO];
        [self _updateTimeUIDuringSliding:YES];
    }
}

- (IBAction) endChangingProgress:(id)sender
{
    [self.progressTimer invalidate];
    self.progressTimer = nil;
    
    PlaybackManager* pman = [PlaybackManager playbackManager];
    
    double progress = self.scrubber.value;
    [pman setPosition:progress];
    
    if (UIAccessibilityIsVoiceOverRunning()) {
        NSInteger cur = pman.time;
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, [NSString stringWithFormat:@"Playback time set to %d:%02d:%02d".ls, cur/3600, (cur/60)%60, cur%60]);
    }
    
    if (_wasPlaying) {
        [pman play];
    }
    pman.seeking = NO;
}

#pragma mark -

- (void) _beginBackwardDelayed
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    [pman beginSeekingBackward];
    self.skipTimer = nil;
}

- (IBAction) beginBackwardAction:(id)sender
{
    [self coalescedPerformSelector:@selector(_hideControlsAfterDelay) afterDelay:5];
    
    [self.skipTimer invalidate];
    self.skipTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                      target:self
                                                    selector:@selector(_beginBackwardDelayed)
                                                    userInfo:nil
                                                     repeats:NO];
}

- (IBAction) endBackwardAction:(id)sender
{
    [self coalescedPerformSelector:@selector(_hideControlsAfterDelay) afterDelay:5];
    
    PlaybackManager* pman = [PlaybackManager playbackManager];
    
    if (self.skipTimer) {
        [self.skipTimer invalidate];
        self.skipTimer = nil;
        [pman seekBackward];
        [self _updateTimeUIDuringSliding:NO];
    }
    else
    {
        [pman endSeeking];
    }
}

- (IBAction) cancelBackwardAction:(id)sender
{
    [self coalescedPerformSelector:@selector(_hideControlsAfterDelay) afterDelay:5];
    
    PlaybackManager* pman = [PlaybackManager playbackManager];
    
    if (self.skipTimer) {
        [self.skipTimer invalidate];
        self.skipTimer = nil;
        [self _updateTimeUIDuringSliding:NO];
    }
    else
    {
        [pman endSeeking];
    }
}

- (void) _beginForwardwardDelayed
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    [pman beginSeekingForward];
    self.skipTimer = nil;
}

- (IBAction) beginForwardAction:(id)sender
{
    [self coalescedPerformSelector:@selector(_hideControlsAfterDelay) afterDelay:5];
    
    [self.skipTimer invalidate];
    self.skipTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                      target:self
                                                    selector:@selector(_beginForwardwardDelayed)
                                                    userInfo:nil
                                                     repeats:NO];
}

- (IBAction) endForwardAction:(id)sender
{
    [self coalescedPerformSelector:@selector(_hideControlsAfterDelay) afterDelay:5];
    
    PlaybackManager* pman = [PlaybackManager playbackManager];
    if (self.skipTimer) {
        [self.skipTimer invalidate];
        self.skipTimer = nil;
        [pman seekForward];
        [self _updateTimeUIDuringSliding:NO];
    }
    else
    {
        [pman endSeeking];
    }
}

- (IBAction) cancelForwardAction:(id)sender
{
    [self coalescedPerformSelector:@selector(_hideControlsAfterDelay) afterDelay:5];
    
    PlaybackManager* pman = [PlaybackManager playbackManager];
    if (self.skipTimer) {
        [self.skipTimer invalidate];
        self.skipTimer = nil;
        [self _updateTimeUIDuringSliding:NO];
    }
    else
    {
        [pman endSeeking];
    }
}

@end
