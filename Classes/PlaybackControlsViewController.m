//
//  PlaybackControlViewController.m
//  Instacast
//
//  Created by Martin Hering on 09.10.12.
//
//

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MPVolumeView.h>

#import "PlaybackControlsViewController.h"
#import "PlayerController.h"
#import "ICProgressSlider.h"
#import "CDEpisode+ShowNotes.h"

#import "VDModalInfo.h"
#import "ICVolumeView.h"
#import "ImageFunctions.h"

@interface PlaybackControlsViewController () <UIGestureRecognizerDelegate>
@property (nonatomic, weak) NSTimer* progressTimer;
@property (nonatomic, weak) NSTimer* skipTimer;
@property (nonatomic) BOOL toolsVisible;
@property (nonatomic, strong) VDModalInfo* scrubbingModalInfo;
@end

@implementation PlaybackControlsViewController {
    BOOL _wasPlaying;
    BOOL _observing;
    CGRect _controllerRect;
    CGRect _toolsRect;
}

+ (id) playbackControlViewController
{
    return [[self alloc] initWithNibName:@"PlayerControlView" bundle:nil];
}


- (void) createVolumeViews
{
    CGRect b = self.view.bounds;
    
    MPVolumeView* volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(60, 103, CGRectGetWidth(b)-120, 29)];
    volumeView.backgroundColor = [UIColor clearColor];
    volumeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    volumeView.showsRouteButton = NO;
    volumeView.showsVolumeSlider = YES;
    [volumeView setVolumeThumbImage:[UIImage imageNamed:@"Video Slider Thumb"] forState:UIControlStateNormal];
    
    [self.view addSubview:volumeView];
    self.volumeView = volumeView;
    self.volumeView.hidden = YES;
    

    ICVolumeView* routeButton = [[ICVolumeView alloc] initWithFrame:CGRectMake(8, 3, 44, 44)];
    routeButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    routeButton.backgroundColor = [UIColor clearColor];
    routeButton.showsRouteButton = YES;
    routeButton.showsVolumeSlider = NO;
    [routeButton setRouteButtonImage:[[UIImage imageNamed:@"Player AirPlay"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [routeButton setRouteButtonImage:[UIImage imageNamed:@"Player AirPlay Active"] forState:UIControlStateSelected];
    
    [self.toolsView addSubview:routeButton];
    self.routeButton = routeButton;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.shown = YES;
    self.tintColor = ICTintColor;
    
    self.timeSlider.accessibilityLabel = @"Time Value".ls;
    
    self.timeSlider.enabled = NO;
	[self updateControlsUI];
    
    [self.backButton setImage:[[UIImage imageNamed:@"Player Backward"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                     forState:UIControlStateNormal];
    
    [self.forwardButton setImage:[[UIImage imageNamed:@"Player Forward"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                     forState:UIControlStateNormal];
    
    [self.bookmarkButton setImage:[[UIImage imageNamed:@"Player Bookmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                       forState:UIControlStateNormal];
    
    [self.actionButton setImage:[[UIImage imageNamed:@"Player Share"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                     forState:UIControlStateNormal];
    
    
    [self.volumeMinButton setImage:[[UIImage imageNamed:@"Player Volume Min"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                          forState:UIControlStateNormal];
    [self.volumeMaxButton setImage:[[UIImage imageNamed:@"Player Volume Max"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                          forState:UIControlStateNormal];
    
    [self createVolumeViews];
    

}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = ICTransparentBackdropColor;
    
    self.elapsedTimeLabel.textColor = ICTextColor;
    self.remainingTimeLabel.textColor = ICTextColor;
    
    
    CGFloat white;
    [ICTextColor getWhite:&white alpha:NULL];
    white = (white > 0.5f) ? 1.0f : 0.0f;
    self.timeSlider.progressColor = [UIColor colorWithWhite:white alpha:0.1f];
    
    self.volumeMinButton.tintColor = [UIColor colorWithWhite:white alpha:0.2f];
    self.volumeMaxButton.tintColor = [UIColor colorWithWhite:white alpha:0.2f];
    
    UIImage* maxImage = ICImageFromByDrawingInContextWithScale(CGSizeMake(3, 2), NO, self.view.window.screen.scale, ^() {
        UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(0, 0, 3, 2) cornerRadius:1];
        
        CGFloat white;
        [ICTextColor getWhite:&white alpha:NULL];
        white = (white > 0.5f) ? 1.0f : 0.0f;
        [[UIColor colorWithWhite:white alpha:0.2] setFill];
        [rectanglePath fillWithBlendMode:kCGBlendModeNormal alpha:1.0];
    });
    maxImage = [maxImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 1, 0, 1)];
    [self.volumeView setMaximumVolumeSliderImage:maxImage forState:UIControlStateNormal];
    
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGFloat width = CGRectGetWidth(self.view.bounds);
        CGFloat offset = (self.toolsVisible) ? -width : 0;
        
        self.controllerView.frame = CGRectMake(0+offset, 0, width, 96);
        self.toolsView.frame = CGRectMake(width+offset, 0, width, 96);
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.volumeView.hidden) {
        self.volumeView.hidden = NO;
        self.volumeView.alpha = 0;
        [UIView animateWithDuration:0.3 animations:^{
            self.volumeView.alpha = 1;
        }];
    }
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsMake(20, 0, 0, 0);
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = self.view.safeAreaInsets;
    }
    
    CGRect b = self.view.bounds;
    self.toolsView.frame = CGRectMake(0, CGRectGetHeight(b)-safeAreaInsets.bottom-50, CGRectGetWidth(b), 50);
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGFloat width = CGRectGetWidth(self.view.bounds);
        CGFloat offset = (self.toolsVisible) ? -width : 0;
        
        self.controllerView.frame = CGRectMake(0+offset, 0, width, 96);
        self.toolsView.frame = CGRectMake(width+offset, 0, width, 96);
    }
}

- (float)volume
{
    return [[PlaybackManager playbackManager] volume];
}

- (void)setVolume:(float)newVolume
{
    [[PlaybackManager playbackManager] setVolume:newVolume];
}

- (UIColor*) tintColor {
    return self.view.tintColor;
}

- (void) setTintColor:(UIColor *)tintColor
{
    self.view.tintColor = tintColor;
}

- (void) setShown:(BOOL)shown
{
    if (_shown != shown) {
        _shown = shown;
        
        // when controller is not shown, we want the HUD for volume
        self.volumeView.hidden = !shown;
        self.routeButton.hidden = !shown;
    }
}

#pragma mark -

- (void) updateTimeUI
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    
	if (self.progressTimer) {
		return;
	}
	
	NSInteger cur = pman.time;
	NSInteger dur = pman.duration;
	NSInteger rem = dur-cur;
	
	NSString* currentText = [NSString stringWithFormat:@"%ld:%02ld:%02ld", (long)cur/3600, (long)(cur/60)%60, (long)cur%60];
	self.elapsedTimeLabel.text = currentText;
	
	NSString* remainingText = [NSString stringWithFormat:@"-%ld:%02ld:%02ld", (long)rem/3600, (long)(rem/60)%60, (long)rem%60];
	self.remainingTimeLabel.text = remainingText;
	
	self.timeSlider.value = (double)cur / (double) dur;
	self.timeSlider.progress = pman.playableDuration / pman.duration;
    
    //DebugLog(@"cur %d", cur);
}

- (void) updateTimeUIDuringSliding
{
	PlaybackManager* pman = [PlaybackManager playbackManager];
	NSInteger dur = pman.duration;
	NSInteger cur = dur * self.timeSlider.value;
	NSInteger rem = dur-cur;
	
	NSString* currentText = [NSString stringWithFormat:@"%ld:%02ld:%02ld", (long)cur/3600, (long)(cur/60)%60, (long)cur%60];
	self.elapsedTimeLabel.text = currentText;
	
	NSString* remainingText = [NSString stringWithFormat:@"-%ld:%02ld:%02ld", (long)rem/3600, (long)(rem/60)%60, (long)rem%60];
	self.remainingTimeLabel.text = remainingText;
	

	switch (self.timeSlider.scrubbingMode) {
		case kICProgressSliderScrubbingModeHiSpeed:
			self.scrubbingModalInfo.textLabel.text = @"Hi-Speed Scrubbing".ls;
			break;
		case kICProgressSliderScrubbingModeHalf:
			self.scrubbingModalInfo.textLabel.text = @"Half-Speed Scrubbing".ls;
			break;
		case kICProgressSliderScrubbingModeQuarter:
			self.scrubbingModalInfo.textLabel.text = @"Quarter-Speed Scrubbing".ls;
			break;
		case kICProgressSliderScrubbingModeFine:
			self.scrubbingModalInfo.textLabel.text = @"Fine Scrubbing".ls;
			break;
		default:
			self.scrubbingModalInfo.textLabel.text = nil;
			break;
	}
}

- (void) updateTimeWhenLoading
{
	PlaybackManager* pman = [PlaybackManager playbackManager];
	CDEpisode* episode = [AudioSession sharedAudioSession].episode;
	
	if (episode.duration > 0 && episode.position < episode.duration)
	{
		NSInteger cur = episode.position;
		NSInteger dur = episode.duration;
		NSInteger rem = dur-cur;
		
		NSString* currentText = [NSString stringWithFormat:@"%ld:%02ld:%02ld", (long)cur/3600, (long)(cur/60)%60, (long)cur%60];
		self.elapsedTimeLabel.text = currentText;
		
		NSString* remainingText = [NSString stringWithFormat:@"-%ld:%02ld:%02ld", (long)rem/3600, (long)(rem/60)%60, (long)rem%60];
		self.remainingTimeLabel.text = remainingText;
		
		self.timeSlider.value = (double)cur / (double) dur;
	}
    
    if (pman.duration > 0) {
        self.timeSlider.progress = pman.playableDuration / pman.duration;
    }
    else {
        self.timeSlider.progress = 0.0f;
    }
}

- (void) updateControlsUI
{
	PlaybackManager* pman = [PlaybackManager playbackManager];
	if (pman.paused) {
		[self.playButton setImage:[[UIImage imageNamed:@"Player Play"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                         forState:UIControlStateNormal];
        self.playButton.accessibilityLabel = @"Play".ls;
	}
    else
    {
		[self.playButton setImage:[[UIImage imageNamed:@"Player Pause"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                         forState:UIControlStateNormal];
        self.playButton.accessibilityLabel = @"Pause".ls;
	}
    
    self.backButton.accessibilityLabel = @"Backward".ls;
    self.forwardButton.accessibilityLabel = @"Forward".ls;
    
    self.playButton.enabled = pman.ready;
    self.backButton.enabled = pman.ready;
    self.forwardButton.enabled = pman.ready;
    self.timeSlider.enabled = pman.ready;
}

- (void) resetControlUI
{
    self.playButton.enabled = NO;
    self.backButton.enabled = NO;
    self.forwardButton.enabled = NO;
    self.timeSlider.enabled = NO;
    self.timeSlider.progress = 0;
    self.timeSlider.value = 0;
    self.elapsedTimeLabel.text = @"0:00:00";
    self.remainingTimeLabel.text = @"-0:00:00";
}

#pragma mark -

- (void) togglePlay:(id)sender
{
	PlaybackManager* pman = [PlaybackManager playbackManager];
    
	if (pman.paused) {
		[pman play];
	} else {
		[pman pause];
	}
}

- (void) beganChangingProgress:(id)sender
{
	PlaybackManager* pman = [PlaybackManager playbackManager];
    pman.seeking = YES;
	_wasPlaying = !pman.paused;
	[pman pause];
    
    if (!self.scrubbingModalInfo) {
        self.scrubbingModalInfo = [VDModalInfo modalInfo];
        self.scrubbingModalInfo.closableByTap = NO;
        self.scrubbingModalInfo.tapThrough = YES;
        self.scrubbingModalInfo.animation = VDModalInfoAnimationMoveDown;
        self.scrubbingModalInfo.alignment = VDModalInfoAlignmentPhonePlayer;
        self.scrubbingModalInfo.size = CGSizeMake(280, 44);
        
        self.scrubbingModalInfo.textLabel.text = @"Hi-Speed Scrubbing".ls;
        [self.scrubbingModalInfo show];
    }
}

- (void) _asynchronouslySeek:(NSTimer*)timer
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
	self.progressTimer = nil;
	
	double progress = self.timeSlider.value;
	[pman setPosition:progress];
}

- (void) progress:(id)sender
{
	PlaybackManager* pman = [PlaybackManager playbackManager];
	
	if (pman.ready)
	{
		[self.progressTimer invalidate];
		self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_asynchronouslySeek:) userInfo:nil repeats:NO];
		[self updateTimeUIDuringSliding];
	}
}

- (void) endChangingProgress:(id)sender
{
    [self.scrubbingModalInfo close];
    self.scrubbingModalInfo = nil;
    
	[self.progressTimer invalidate];
	self.progressTimer = nil;
	
	PlaybackManager* pman = [PlaybackManager playbackManager];
	
	double progress = self.timeSlider.value;
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

- (void) _beginBackwardDelayed
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
	[pman beginSeekingBackward];
	self.skipTimer = nil;
}

- (void) beginBackwardAction:(id)sender
{
	[self.skipTimer invalidate];
	self.skipTimer = [NSTimer scheduledTimerWithTimeInterval:1
													  target:self
													selector:@selector(_beginBackwardDelayed)
													userInfo:nil
													 repeats:NO];
}

- (void) endBackwardAction:(id)sender
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    
	if (self.skipTimer) {
		[self.skipTimer invalidate];
		self.skipTimer = nil;
		[pman seekBackward];
        [self updateTimeUI];
	}
	else
	{
		[pman endSeeking];
	}
}

- (IBAction) cancelBackwardAction:(id)sender
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    
	if (self.skipTimer) {
		[self.skipTimer invalidate];
		self.skipTimer = nil;
        [self updateTimeUI];
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

- (void) beginForwardAction:(id)sender
{
	[self.skipTimer invalidate];
	self.skipTimer = [NSTimer scheduledTimerWithTimeInterval:1
													  target:self
													selector:@selector(_beginForwardwardDelayed)
													userInfo:nil
													 repeats:NO];
}

- (void) endForwardAction:(id)sender
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
	if (self.skipTimer) {
		[self.skipTimer invalidate];
		self.skipTimer = nil;
		[pman seekForward];
        [self updateTimeUI];
	}
	else
	{
		[pman endSeeking];
	}
}

- (void) cancelForwardAction:(id)sender
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
	if (self.skipTimer) {
		[self.skipTimer invalidate];
		self.skipTimer = nil;
        [self updateTimeUI];
	}
	else
	{
		[pman endSeeking];
	}
}


#pragma mark -


- (IBAction) addBookmark:(id)sender
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    BOOL wasPlaying = (!pman.paused);
    [pman pause];
    
    
    WEAK_SELF
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Add Bookmark".ls
                                                                   message:@"Please enter a bookmark title.".ls
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Bookmark title".ls;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK".ls
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                
                                                NSString* text = self.alertController.textFields.firstObject.text;
                                                
                                                [self perform:^(id sender) {

                                                    PlaybackManager* pman = [PlaybackManager playbackManager];
                                                    CDEpisode* episode = pman.playingEpisode;
                                                    CDFeed* feed = episode.feed;
                                                    
                                                    CDBookmark* bookmark = [NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:DMANAGER.objectContext];
                                                    bookmark.episodeHash = episode.objectHash;
                                                    bookmark.title = text;
                                                    bookmark.position = MAX(0, pman.time - 2);
                                                    bookmark.feedURL = feed.sourceURL;
                                                    bookmark.imageURL = feed.imageURL;
                                                    bookmark.episodeGuid = episode.guid;
                                                    bookmark.feedTitle = feed.title;
                                                    bookmark.episodeTitle = [episode cleanTitleUsingFeedTitle:feed.title];
                                                    
                                                    [DMANAGER addBookmark:bookmark];
                                                    [DMANAGER save];
                                                    
                                                    if (wasPlaying) {
                                                        [pman play];
                                                    }
                                                
                                                } afterDelay:0.3];
                                                self.alertController = nil;
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel".ls
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                if (wasPlaying) {
                                                    [pman play];
                                                }

                                                self.alertController = nil;
                                            }]];
    
    self.alertController = alert;
    [self presentAlertControllerAnimated:YES completion:NULL];
}


@end
