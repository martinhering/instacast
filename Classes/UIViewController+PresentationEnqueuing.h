//
//  UIViewController+PresentationEnqueuing.h
//  Instacast
//
//  Created by Martin Hering on 19.09.13.
//
//

#import <UIKit/UIKit.h>

@interface UIViewController (PresentationEnqueuing)

- (void) enqueuePresentationOfViewController:(UIViewController*)viewController animated:(BOOL)animated completion:(void (^)())completion;
- (void) presentNextViewController;
- (void) clearViewControllerPresentationQueue;

@end
