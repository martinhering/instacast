//
//  PlaybackViewController.h
//  Instacast
//
//  Created by Martin Hering on 06.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CDEpisode, ICPlaybackViewControllerDismissedAnimator;

@interface PlaybackViewController : UINavigationController {

}

+ (PlaybackViewController*) playbackViewController;
+ (PlaybackViewController*) playbackViewControllerWithEpisode:(CDEpisode*)episode;
+ (PlaybackViewController*) playbackViewControllerWithEpisode:(CDEpisode*)episode forceReload:(BOOL)force;

- (void) presentFromParentViewController:(UIViewController*)parentViewController;
- (void) presentFromParentViewController:(UIViewController*)parentViewController autostart:(BOOL)autostart completion:(void (^)(void))completion;

@property (nonatomic, strong, readonly) ICPlaybackViewControllerDismissedAnimator* dismissalAnimator;
@property (nonatomic, readonly) BOOL interactive;
- (void) beginInteractiveDismissing;
- (void) endInteractiveDismissing;
@end



@interface ICPlaybackViewControllerPresentedAnimator : NSObject <UIViewControllerAnimatedTransitioning>
@end


@interface ICPlaybackViewControllerDismissedAnimator : UIPercentDrivenInteractiveTransition <UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning, UIGestureRecognizerDelegate>
@property (nonatomic, weak) PlaybackViewController* parent;
- (void) _driveTransitionWithTranslation:(CGPoint)translation velocity:(CGPoint)velocity recognizerState:(UIGestureRecognizerState)state;
@end
