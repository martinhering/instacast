//
//  _AlertStylePopoverAnimator.m
//  Instacast
//
//  Created by Martin Hering on 03.07.13.
//
//

#import "VMAlertStylePopoverAnimator.h"
#import "VMAlertStylePopoverController.h"

@implementation VMAlertStylePopoverAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.3f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    
    // Get the 'from' and 'to' views/controllers.
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    BOOL hasViewForKey = [transitionContext respondsToSelector:@selector(viewForKey:)]; // viewForKey is iOS8+.
    UIView *fromView = hasViewForKey ? [transitionContext viewForKey:UITransitionContextFromViewKey] : fromVC.view;
    UIView *toView = hasViewForKey ? [transitionContext viewForKey:UITransitionContextToViewKey] : toVC.view;
    
    UIView* backdropView = ([fromVC isKindOfClass:[VMAlertStylePopoverController class]]) ? [fromVC valueForKey:@"backdropView"] : [toVC valueForKey:@"backdropView"];
    UIView* contentView = ([fromVC isKindOfClass:[VMAlertStylePopoverController class]]) ? [fromVC valueForKeyPath:@"contentController.view"] : [toVC valueForKeyPath:@"contentController.view"];
    
    // iOS8 has a bug where viewForKey:to is nil: http://stackoverflow.com/a/24589312/59198
    // The workaround is: A) get the 'toView' from 'toVC'; B) manually add the 'toView' to the container's
    // superview (eg the root window) after the completeTransition call.
    BOOL toViewNilBug = !toView;
    if (!toView) { // Workaround by getting it from the view.
        toView = toVC.view;
    }
    UIView *container = [transitionContext containerView];
    UIView *containerSuper = container.superview; // Used for the iOS8 bug workaround.
    CGRect containerSuperFrame = containerSuper.frame;

    
    if (self.presenting)
    {
        // Perform the transition.
        fromView.frame = [transitionContext initialFrameForViewController:fromVC];
        toView.frame = container.bounds;
        
        [container addSubview:fromView];
        [container addSubview:toView];
        
        contentView.transform = CGAffineTransformMakeTranslation(0, CGRectGetHeight(containerSuperFrame));
        backdropView.alpha = 0.0f;
        
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            backdropView.alpha = 1.0f;
            
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
            
            if (toViewNilBug) {
                [containerSuper addSubview:toView];
            }
        }];
        
        [UIView animateWithDuration:0.6f
                              delay:0.0
             usingSpringWithDamping:0.6f
              initialSpringVelocity:0.0f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             contentView.transform = CGAffineTransformIdentity;
                         }
                         completion:^(BOOL finished) {
                             
                         }];
    }
    else
    {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            backdropView.alpha = 0.0f;
            contentView.transform = CGAffineTransformMakeTranslation(0, CGRectGetHeight(containerSuperFrame));
            
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
            
            if (toViewNilBug) {
                [containerSuper addSubview:toView];
            }
        }];
    }
}
@end
