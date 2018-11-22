    //
//  PlaybackViewController.m
//  Instacast
//
//  Created by Martin Hering on 05.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>

#import "PlayerController.h"
#import "PlayerView.h"

#import "ICProgressSlider.h"
#import "UIViewController+ShowNotes.h"

#import "CDModel.h"
#import "CDEpisode+ShowNotes.h"
#import "PlaybackControlsViewController.h"
#import "AlertStylePopoverController.h"

#import "EpisodeViewController.h"
#import "UIImage+Utils.h"
#import "ICMetadata.h"
#import "VDModalInfo.h"

#import "PlayerInfoViewController_v5.h"
#import "PlayerVideoViewController.h"
#import "PlayerFullscreenVideoViewController.h"

enum {
	NoState = 0,
	InitedState,
	LoadedState,
	ReadyState,
} PlaybackViewControllerState;


@interface PlayerController () <UIGestureRecognizerDelegate>

@property (nonatomic, weak) NSTimer* controlTimer;
@property (nonatomic, strong) NSDate* controlStartDate;
@property (nonatomic, strong) UIView* titleView;
@property (nonatomic, strong) NSTimer* gestureTimer;
@property (nonatomic, strong) UIBarButtonItem* bookmarksBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem* upNextBarButtonItem;
@property (nonatomic, strong) UILabel* feedTitleLabel;
@property (nonatomic, assign) NSInteger currentChapterImage;

@property (nonatomic, strong) UIImageView* actionBarShadowView;
@property (nonatomic, assign) BOOL playbackInterupted;
@property (nonatomic, strong) PlaybackControlsViewController* controller;
@property (nonatomic, strong) VDModalInfo* loadingInfo;
@property (nonatomic, strong) CDEpisode* playingEpisode;
@property (nonatomic, strong) UIImage* image;
@property (nonatomic, strong) PlayerInfoViewController_v5* infoViewController;
@property (nonatomic, strong) EpisodeViewController* showNotesController;
@end

#define CONTROLLER_HEIGHT CGRectGetHeight(self.controller.view.frame)

@implementation PlayerController {
    BOOL            _observing;
	NSInteger		_state;
	BOOL			_videoWasPlaying;
	NSTimer*		_showHideTimer;
	BOOL			_changingProgress;
    BOOL            _dismissing;
    BOOL            _viewDidAppear;
}


#pragma mark -

+ (PlayerController*) playerController
{
	return [[self alloc] initWithNibName:@"PlayerController" bundle:nil];
}

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
		_state = InitedState;
		self.backgroundPlayback = YES;
        
    }
    return self;
}

- (void) _setObserving:(BOOL)observing
{
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    PlaybackManager* pman = [PlaybackManager playbackManager];

    if (observing && !_observing)
    {
        WEAK_SELF
        [pman addTaskObserver:self forKeyPath:@"paused" task:^(id obj, NSDictionary *change) {
            [weakSelf.controller updateControlsUI];
        }];
        
        
        [pman addTaskObserver:self forKeyPath:@"currentArtwork" task:^(id obj, NSDictionary *change) {
            [weakSelf _updateArtworkImage];
        }];
        
        [pman addTaskObserver:self forKeyPath:@"playingEpisode" task:^(id obj, NSDictionary *change) {
            CDEpisode* playingEpisode = [PlaybackManager playbackManager].playingEpisode;
            if (playingEpisode)
            {
                UIViewController* presentedViewController = weakSelf.presentedViewController;
                if (![presentedViewController isKindOfClass:[PlayerFullscreenVideoViewController class]] || !playingEpisode.video) {
                    [presentedViewController dismissViewControllerAnimated:YES completion:NULL];
                }
                
                [weakSelf _resetStateMachine];
            }
        }];
        
        [pman addTaskObserver:self forKeyPath:@"playableDuration" task:^(id obj, NSDictionary *change) {
            [weakSelf.controller updateTimeUI];
        }];
        
        [nc addObserver:self selector:@selector(playbackManagerDidUpdateNotification:) name:PlaybackManagerDidUpdateNotification object:nil];
        [nc addObserver:self selector:@selector(playbackManagerDidEndNotification:) name:PlaybackManagerDidEndNotification object:nil];
        [nc addObserver:self selector:@selector(applicationDidRegisterTouchNotification:) name:ApplicationDidRegisterTouchNotification object:nil];
        [nc addObserver:self selector:@selector(deviceOrientationDidChangeNotification:) name:UIDeviceOrientationDidChangeNotification object:nil];
        
        _observing = YES;
    }
    else if (!observing && _observing)
    {
        [pman removeTaskObserver:self forKeyPath:@"paused"];
        [pman removeTaskObserver:self forKeyPath:@"currentArtwork"];
        [pman removeTaskObserver:self forKeyPath:@"playingEpisode"];
        [pman removeTaskObserver:self forKeyPath:@"playableDuration"];
        
        [nc removeObserver:self];
        _observing = NO;
    }
}

- (void) playbackManagerDidUpdateNotification:(NSNotification*)notification
{
    [self _stateMachine];
}

- (void) playbackManagerDidEndNotification:(NSNotification*)notification
{
    if (!_dismissing && _state > InitedState)
    {
        if (self.loadingInfo) {
            [self.loadingInfo close];
            self.loadingInfo = nil;
        }
        
        [self perform:^(id sender) {
                        
            if (self.presentedViewController)
            {
                [self.presentedViewController dismissViewControllerAnimated:YES completion:^{
                    [self perform:^(id sender) {
                        [self dismiss:sender];
                    } afterDelay:0.1];
                }];
            } else {
                [self perform:^(id sender) {
                    [self dismiss:sender];
                } afterDelay:0.1];
            }
        } afterDelay:0.5];
    }
}

- (void) applicationDidRegisterTouchNotification:(NSNotification*)notification
{
    if (_showHideTimer) {
        NSArray* userInfo = [_showHideTimer userInfo];
        
        [_showHideTimer invalidate];
        _showHideTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                          target:self
                                                        selector:@selector(toggleShowControlsTimer:)
                                                        userInfo:userInfo
                                                         repeats:NO];
    }
}

- (void) deviceOrientationDidChangeNotification:(NSNotification*)notification
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    if (pman.movingVideo && pman.ready && self.infoViewController.videoViewController) {
        
        if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) && !self.infoViewController.videoViewController.fullscreen) {
            [self.infoViewController.videoViewController setFullscreen:YES animated:YES completion:NULL];
        }
        else if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation) && self.infoViewController.videoViewController.fullscreen) {
            [self.infoViewController.videoViewController setFullscreen:NO animated:YES completion:NULL];
        }
    }
}

#pragma mark -

- (void) _updateArtworkImage
{
	PlaybackManager* pman = [PlaybackManager playbackManager];
	
	if (!pman.movingVideo && [pman.artworks count] > 0 && pman.currentArtwork >= 0)
	{
        ICMetadataImage* artwork = pman.artworks[pman.currentArtwork];
        [artwork loadPlatformImageScaleToWidth:CGRectGetWidth(self.view.bounds)*[ImageCacheManager scalingFactor]
                                    completion:^(id platformImage) {
                                        self.image = platformImage;
                                    }];
    }
}

- (void) _resetStateMachine
{
    self.playingEpisode = nil;
    
    [_showHideTimer invalidate];
    _showHideTimer = nil;
    
    [self.controller resetControlUI];

    self.image = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? [UIImage imageNamed:@"Podcast Placeholder 580"] : [UIImage imageNamed:@"Podcast Placeholder 320"];
    
    [self.controller updateControlsUI];
    
    self.view.backgroundColor = ICBackgroundColor;
    
    _state = LoadedState;
    [self _stateMachine];
    
    self.feedTitleLabel.text = [AudioSession sharedAudioSession].episode.title;
}

- (void) _stateMachine
{
	PlaybackManager* pman = [PlaybackManager playbackManager];
	
	if (pman.failed)
    {
        if (App.networkAccessTechnology < kICNetworkAccessTechnlogyEDGE) {
            [App showBackgroundErrorWithTitle:@"Media not loaded.".ls message:@"Please make sure you are connected to a cellular or WiFi network.".ls];
        } else {
            [App showBackgroundErrorWithTitle:@"Media not loaded.".ls message:@"The file is not available anymore.".ls];
        }
	}

    if (_state == LoadedState && !pman.ready)
	{
        if (!self.loadingInfo && ![[CacheManager sharedCacheManager] episodeIsCached:pman.playingEpisode]) {
            self.loadingInfo = [VDModalInfo modalInfoWithProgressLabel:@"Loading…".ls];
            [self.loadingInfo show];
        }
    }
	else if (_state == LoadedState && pman.ready && _viewDidAppear)
	{
        [self.infoViewController reload];
        
        CDEpisode* episode = [AudioSession sharedAudioSession].episode;
        CDFeed* feed = episode.feed;
        
        NSURL* imageURL = (episode.imageURL) ? episode.imageURL : feed.imageURL;
        if (imageURL)
        {
            ImageCacheManager* iman = [ImageCacheManager sharedImageCacheManager];
            
            NSInteger size = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 580 : 320;
            
            [iman imageForURL:imageURL size:size grayscale:NO sender:self completion:^(UIImage *image) {
                if ([[pman artworks] count] <= 1) {
                    self.image = image;
                }
                
                [self _updateDynamicTintColorWithImage:image];
            }];
        }
        
				
		_state = ReadyState;

        [self _updateArtworkImage];
        [self.controller updateControlsUI];
        
        if (self.loadingInfo) {
            [self.loadingInfo close];
            self.loadingInfo = nil;
        }
        
//        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
//        if (UIDeviceOrientationIsLandscape(orientation) && !self.infoViewController.videoViewController.fullscreen) {
//            [self.infoViewController.videoViewController setFullscreen:YES animated:YES completion:NULL];
//        }
	}
	
	else if (_state == ReadyState && pman.ready)
	{
		[self.controller updateTimeUI];
	}
}

- (void) _updateDynamicTintColorWithImage:(UIImage*)image
{
    UIColor* calculatedColor = ICTintColor;
    
    if (image) {
        calculatedColor = [UIColor mergedColorOfImage:image];
        
        CGFloat backgroundBrightness = -1;
        [ICBackgroundColor getHue:NULL saturation:NULL brightness:&backgroundBrightness alpha:NULL];
        if (backgroundBrightness < 0) {
            [ICBackgroundColor getWhite:&backgroundBrightness alpha:NULL];
        }
        

        CGFloat hue, saturation, brightness, alpha;
        [calculatedColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
        
        saturation = MIN(saturation+0.3f, 1.0f);

        if (backgroundBrightness > 0.5f) {
            //brightness *= 0.75;
            brightness = MIN(brightness, 0.5f);
        } else {
            //brightness *= 1.25;
            brightness = MAX(brightness, 0.7f);
        }
        
        calculatedColor = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
    }

    self.view.tintColor = calculatedColor;
    self.navigationController.navigationBar.tintColor = calculatedColor;
    self.navigationController.toolbar.tintColor = calculatedColor;
    self.controller.tintColor = calculatedColor;
    self.infoViewController.view.tintColor = calculatedColor;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	
    PlaybackManager* pman = [PlaybackManager playbackManager];
    
    self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    
	UIBarButtonItem* portraitCloseBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Player Close"]
																		style:UIBarButtonItemStylePlain
																	   target:self
                                                                      action:@selector(dismiss:)];
    portraitCloseBarButtonItem.accessibilityLabel = @"Hide".ls;

    
	self.navigationItem.leftBarButtonItem = portraitCloseBarButtonItem;
	


    UIBarButtonItem* chapterButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Toolbar Show Notes"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(showMoreInfos:)];
    chapterButtonItem.accessibilityLabel = @"Show Notes".ls;
    self.navigationItem.rightBarButtonItem = chapterButtonItem;

    
    // load controller and put on the screen
    self.controller = [PlaybackControlsViewController playbackControlViewController];
    
    [self addChildViewController:self.controller];
    //CGRect controllerRect = self.controller.view.frame;
    
    CGRect wb = App.keyWindow.bounds;
    CGRect b = self.view.frame;
    CGFloat statusbarHeight = CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
    CGFloat controllerHeight = MAX(CGRectGetHeight(wb)-statusbarHeight-44-CGRectGetWidth(wb), 184);
    self.controller.view.frame = CGRectMake(0, CGRectGetMaxY(b)-controllerHeight, CGRectGetWidth(b), controllerHeight);


    [self.view addSubview:self.controller.view];
    [self.controller didMoveToParentViewController:self];
	

	if (pman.ready && pman.movingVideo) {
		[pman restart];
	}

	_state = LoadedState;
	[self _stateMachine];
	
	[self.controller updateTimeWhenLoading];
    [self.controller updateControlsUI];
    
    
    // loading image
    CDEpisode* episode = [AudioSession sharedAudioSession].episode;
    CDFeed* feed = episode.feed;
    NSURL* imageURL = (episode.imageURL) ? episode.imageURL : feed.imageURL;
    UIImage* cachedImage = [[ImageCacheManager sharedImageCacheManager] localImageForImageURL:imageURL size:320 grayscale:NO];
    
    if (cachedImage) {
        [self _updateDynamicTintColorWithImage:cachedImage];
        self.image = cachedImage;
    }
    else {
        self.image = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? [UIImage imageNamed:@"Podcast Placeholder 580"] : [UIImage imageNamed:@"Podcast Placeholder 320"];
    }
    
    
    self.infoViewController = [PlayerInfoViewController_v5 viewController];
    self.infoViewController.image = self.image;

    
    [self addChildViewController:self.infoViewController];
    self.infoViewController.view.tintColor = self.view.tintColor;
    self.infoViewController.bottomScrollInset = CONTROLLER_HEIGHT;
    [self.view insertSubview:self.infoViewController.view atIndex:0];
    [self.infoViewController didMoveToParentViewController:self];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    self.view.backgroundColor = ICBackgroundColor;
    self.feedTitleLabel.textColor = ICTextColor;
    
    if (_dismissing || _viewDidAppear) {
        return;
    }
    
    if (self.image) {
        [self _updateDynamicTintColorWithImage:self.image];
    }

    CDEpisode* episode = [PlaybackManager playbackManager].playingEpisode;
    
    if (self.playingEpisode && ![self.playingEpisode isEqual:episode]) {
        [self _resetStateMachine];
    }
    self.playingEpisode = episode;
    
	if (!self.titleView)
    {
        CGRect superRect = self.view.bounds;
        CGFloat margins = 70;
        CGRect frame = CGRectMake(0, 0, CGRectGetWidth(superRect)-margins, 44);
        UIView* titleView = [[UIView alloc] initWithFrame:frame];
        titleView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        titleView.opaque = NO;
        titleView.backgroundColor = [UIColor clearColor];
        titleView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

        
        CDFeed* feed = episode.feed;
        NSString* feedTitle = feed.title;
        
        CGRect tb = titleView.bounds;
        UILabel* feedTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tb), CGRectGetHeight(tb)-2)];
        feedTitleLabel.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        feedTitleLabel.text = [episode cleanTitleUsingFeedTitle:feedTitle];
        feedTitleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
        feedTitleLabel.opaque = NO;
        feedTitleLabel.backgroundColor = [UIColor clearColor];
        feedTitleLabel.numberOfLines = 2;
        feedTitleLabel.textAlignment = NSTextAlignmentCenter;
        [titleView addSubview:feedTitleLabel];
        self.feedTitleLabel = feedTitleLabel;
        
        self.titleView = titleView;
        self.navigationItem.titleView = titleView;
    }
    
    // can change, that's why it needs to go here
    self.feedTitleLabel.textColor = ICTextColor;
    
    [self _setObserving:YES];
    [self _updateArtworkImage];
    [self.controller updateControlsUI];
    
    CGRect b = self.view.bounds;
    self.infoViewController.view.frame = CGRectMake(0, 0, CGRectGetWidth(b), CGRectGetHeight(b));
    [self.infoViewController layoutHeaderView];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
        
    _viewDidAppear = YES;
    [self _stateMachine];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[ImageCacheManager sharedImageCacheManager] cancelImageCacheOperationsWithSender:self];
}

#pragma mark -

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

/*
- (void) applicationDidEnterBackgroundNotification:(NSNotification*)notification
{
	PlaybackManager* pman = [PlaybackManager playbackManager];
	_videoWasPlaying = ([pman.playerView superview] != nil);
	[pman.playerView removeFromSuperview];
}

- (void) applicationWillEnterForegroundNotification:(NSNotification*)notification
{
	PlaybackManager* pman = [PlaybackManager playbackManager];
	if (_videoWasPlaying) {
		[self.view insertSubview:pman.playerView atIndex:0];
		_videoWasPlaying = NO;
	}
}
 */

#pragma mark -

- (void) setImage:(UIImage *)image
{
    if (_image != image) {
        _image = image;
        self.infoViewController.image = image;
    }
}

- (void) showMoreInfos:(id)sender
{
    if (!self.showNotesController) {
        self.showNotesController = [EpisodeViewController episodeViewController];
        self.showNotesController.episode = [PlaybackManager playbackManager].playingEpisode;
        self.showNotesController.view.tintColor = self.view.tintColor;
    }
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self.navigationController pushViewController:self.showNotesController animated:YES];
}


- (void) screenModeAction:(id)sender
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    
    if (pman.playerView) {
        AVPlayerLayer* playerLayer = ((AVPlayerLayer*)pman.playerView.layer);
        
        if (playerLayer.videoGravity == AVLayerVideoGravityResizeAspectFill) {
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        } else {
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        }
        
        playerLayer.frame = self.view.bounds;
    }
}

- (void) dismiss:(id)sender
{
    _dismissing = YES;
    
	[_showHideTimer invalidate];
	_showHideTimer = nil;
	
	PlaybackManager* pman = [PlaybackManager playbackManager];
	
	if ([pman hasMovingVideo]) {
		[pman stopAirPlayVideo];
	}
	
	if (!pman.ready || !self.backgroundPlayback) {
		[pman close];
	}

    
    [DMANAGER save];
    
    if (self.loadingInfo) {
        [self.loadingInfo close];
        self.loadingInfo = nil;
    }
    
    if (![self isBeingDismissed]) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    }
    _dismissing = NO;
}


@end
