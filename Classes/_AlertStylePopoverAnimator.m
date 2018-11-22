//
//  _AlertStylePopoverAnimator.m
//  Instacast
//
//  Created by Martin Hering on 03.07.13.
//
//

#import "_AlertStylePopoverAnimator.h"
#import "AlertStylePopoverController.h"

@implementation _AlertStylePopoverAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.3f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    if (self.presenting)
    {
        UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];  // main view controller
        AlertStylePopoverController *toVC = (AlertStylePopoverController*)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        UIViewController* contentViewController = toVC.contentController;
        UIView* backdropView = toVC.backdropView;
        
        CGRect endFrame = [transitionContext initialFrameForViewController:fromVC];
        // xxx: API does not give correct frame origin
        if (IS_IOS8 && fromVC.modalPresentationStyle == UIModalPresentationFormSheet) {
            endFrame.origin = CGPointMake(floorf((CGRectGetWidth(backdropView.frame)-CGRectGetWidth(endFrame))/2), floorf((CGRectGetHeight(backdropView.frame)-CGRectGetHeight(endFrame))/2));
        }
        
        fromVC.view.frame = endFrame;
        [transitionContext.containerView addSubview:fromVC.view];
        
        UIView *toView = [toVC view];
        toView.frame = endFrame;
        backdropView.alpha = 0.0f;
        [transitionContext.containerView addSubview:toView];
        
        contentViewController.view.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext]
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             backdropView.alpha = 1.0f;
                         }
                         completion:^(BOOL finished) {
                             [transitionContext completeTransition:YES];
                         }];

        [UIView animateWithDuration:0.6f
                              delay:0.0
             usingSpringWithDamping:0.6f
              initialSpringVelocity:0.0f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             contentViewController.view.transform = CGAffineTransformIdentity;
                         }
                         completion:^(BOOL finished) {
                             
                         }];

    }
    else
    {
        AlertStylePopoverController *fromVC = (AlertStylePopoverController*)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];  // main view controller
        UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        UIViewController* contentViewController = fromVC.contentController;
        UIView* backdropView = fromVC.backdropView;
        

        [UIView animateWithDuration:[self transitionDuration:transitionContext]
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             backdropView.alpha = 0.0f;
                             contentViewController.view.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
                             contentViewController.view.alpha = 0.0f;
                         }
                         completion:^(BOOL finished) {
                             [transitionContext completeTransition:YES];
                             
                             /// xxx: IOS 8 removing toViewController from window after dismissal
                             if (IS_IOS8) {
                                 [[UIApplication sharedApplication].keyWindow addSubview:toVC.view];
                             }
                         }];
    }
}
@end
