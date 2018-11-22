//
//  PlayerVideoFullscreenViewController.m
//  Instacast
//
//  Created by Martin Hering on 06/08/14.
//
//

#import "PlayerVideoViewController.h"
#import "PlayerView.h"
#import "PlayerFullscreenVideoViewController.h"
#import "InstacastAppDelegate.h"

@interface PlayerVideoViewController ()
@property (nonatomic, strong) UITapGestureRecognizer* tapRecognizer;
@property (nonatomic, strong) UIView* letterboxView;
@property (nonatomic, strong) UIImageView* fullscreenIndicatorView;
@property (nonatomic, readwrite) BOOL fullscreen;
@property (nonatomic, strong) PlayerFullscreenVideoViewController* fullscreenViewController;
@end

@implementation PlayerVideoViewController

+ (instancetype) viewController {
    return [[self alloc] initWithNibName:nil bundle:nil];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    CGRect b = self.view.bounds;
    
    self.view.backgroundColor = [UIColor blackColor];
    self.view.autoresizingMask = UIViewAutoresizingNone;
    
    self.letterboxView = [[UIView alloc] initWithFrame:b];
    self.letterboxView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.letterboxView.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:self.letterboxView];
    
    self.playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.playerView.frame = self.letterboxView.bounds;
    [self.letterboxView addSubview:self.playerView];
    
    self.fullscreenIndicatorView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"Toolbar Fullscreen"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    self.fullscreenIndicatorView.tintColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    self.fullscreenIndicatorView.frame = CGRectMake(CGRectGetWidth(b)-35, CGRectGetHeight(b)-35, 20, 20);
    self.fullscreenIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [self.letterboxView addSubview:self.fullscreenIndicatorView];
    
    UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.letterboxView addGestureRecognizer:tapRecognizer];
    self.tapRecognizer = tapRecognizer;
}

- (void) setPlayerView:(PlayerView *)playerView
{
    if (_playerView != playerView)
    {
        [_playerView removeFromSuperview];
        
        _playerView = playerView;
        
        if (self.letterboxView) {
            playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            playerView.frame = self.letterboxView.bounds;
            [self.letterboxView addSubview:playerView];
        }
    }
}


- (void) _transitionToFullscreen:(BOOL)fullscreen animated:(BOOL)animated completion:(void (^)(void))completion
{
    UIView* letterboxView = self.letterboxView;
    UIView* playerView = self.playerView;
    
    if (fullscreen)
    {
        self.fullscreenIndicatorView.hidden = YES;
        
        CGRect r = [letterboxView convertRect:self.letterboxView.bounds toView:nil];
        [letterboxView removeFromSuperview];
        letterboxView.frame = r;
        [self.view.window addSubview:letterboxView];
        
        self.letterboxView.autoresizesSubviews = NO;
        [UIView animateWithDuration:(animated) ? 0.5 : 0.0
                         animations:^{
                             CGFloat oldWidth = CGRectGetWidth(letterboxView.frame);
                             letterboxView.frame = self.view.window.bounds;
                             
                             CGFloat newWidth = CGRectGetWidth(letterboxView.frame);
                             
                             playerView.center = CGPointMake(CGRectGetWidth(letterboxView.bounds)/2, CGRectGetHeight(letterboxView.bounds)/2);
                             playerView.transform = CGAffineTransformScale(playerView.transform, newWidth/oldWidth, newWidth/oldWidth);
                         }
                         completion:^(BOOL finished) {
                             
                             self.fullscreenViewController = [PlayerFullscreenVideoViewController viewController];
                             self.fullscreenViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                             
                             [self.parentViewController presentViewController:self.fullscreenViewController animated:NO completion:^{
                                 
                                 [self.fullscreenViewController.doneButton addTarget:self action:@selector(closeFullscreen:) forControlEvents:UIControlEventTouchUpInside];
                                 
                                 [letterboxView removeFromSuperview];
                                 letterboxView.frame = self.fullscreenViewController.view.bounds;
                                 playerView.frame = letterboxView.bounds;
                                 
                                 letterboxView.autoresizesSubviews = YES;
                                 [self.fullscreenViewController.view insertSubview:letterboxView atIndex:0];
                                 
                                 self.fullscreen = YES;
                                 
                                 [((InstacastAppDelegate*)(App.delegate)) setNeedsStatusBarAppearanceUpdate];
                                 
                                 if (completion) {
                                     completion();
                                 }
                             }];
                             
                         }];
    }
    else
    {
        if (!animated)
        {
            [self.parentViewController dismissViewControllerAnimated:NO completion:NULL];
            self.fullscreen = NO;
            
            CGRect b = letterboxView.bounds;
            self.fullscreenIndicatorView.frame = CGRectMake(CGRectGetWidth(b)-35, CGRectGetHeight(b)-35, 20, 20);
            self.fullscreenIndicatorView.hidden = NO;
            
            if (completion) {
                completion();
            }
            return;
        }
        
        UIWindow* window = self.letterboxView.window;
        
        [letterboxView removeFromSuperview];
        letterboxView.frame = window.bounds;
        
        CGSize s = CGSizeMake(CGRectGetWidth(letterboxView.frame), floorf(CGRectGetWidth(letterboxView.frame)/(self.videoSize.width/self.videoSize.height)));
        playerView.frame = CGRectMake(0, (CGRectGetHeight(letterboxView.bounds)-s.height)/2, s.width, s.height);
        [window addSubview:letterboxView];
        
        
        [self.fullscreenViewController dismissViewControllerAnimated:NO completion:^{
            
            CGRect r = [self.view convertRect:self.view.bounds toView:nil];
            
            letterboxView.autoresizesSubviews = NO;
            
            [UIView animateWithDuration:0.5
                             animations:^{
                                 
                                 CGFloat oldWidth = CGRectGetWidth(letterboxView.frame);
                                 letterboxView.frame = r;
                                 
                                 CGFloat newWidth = CGRectGetWidth(letterboxView.frame);
                                 
                                 playerView.center = CGPointMake(CGRectGetWidth(letterboxView.bounds)/2, CGRectGetHeight(r)/2);
                                 playerView.transform = CGAffineTransformScale(playerView.transform, newWidth/oldWidth, newWidth/oldWidth);
                             }
                             completion:^(BOOL finished) {
                                 
                                 [letterboxView removeFromSuperview];
                                 letterboxView.frame = self.view.bounds;
                                 [self.view addSubview:letterboxView];
                                 letterboxView.autoresizesSubviews = YES;
                                 
                                 self.fullscreen = NO;
                                 
                                 CGRect b = letterboxView.bounds;
                                 self.fullscreenIndicatorView.frame = CGRectMake(CGRectGetWidth(b)-35, CGRectGetHeight(b)-35, 20, 20);
                                 self.fullscreenIndicatorView.hidden = NO;
                                 
                                 if (completion) {
                                     completion();
                                 }
                             }];
            
            self.fullscreenViewController = nil;
            [((InstacastAppDelegate*)(App.delegate)) setNeedsStatusBarAppearanceUpdate];
        }];
    }
}

- (void) closeFullscreen:(id)sender
{
    [self _transitionToFullscreen:NO animated:YES completion:NULL];
}

- (void) setFullscreen:(BOOL)fullscreen animated:(BOOL)animated completion:(void (^)(void))completion
{
    if (_fullscreen != fullscreen)
    {
        if (!self.parentViewController.view.window) {
            DebugLog(@"no window!");
            return;
        }
        
        [self _transitionToFullscreen:fullscreen animated:animated completion:completion];
    }
    else {
        if (completion) {
            completion();
        }
    }
}

- (void) handleTap:(UITapGestureRecognizer*)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        
        if (self.letterboxView.superview == self.view)
        {
            [self _transitionToFullscreen:YES animated:YES completion:NULL];
        }
        else
        {
            self.fullscreenViewController.controlsVisible = !self.fullscreenViewController.controlsVisible;
        }
    }
}
@end
