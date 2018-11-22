//
//  UIViewController+Alert.m
//  Instacast
//
//  Created by Martin Hering on 11.02.16.
//  Copyright © 2016 Vemedio. All rights reserved.
//

#import "UIViewController+Alert.h"

@implementation UIViewController (Alert)

- (UIAlertController*) alertController {
    return [self associatedObjectForKey:@"__alertController"];
}

- (void) setAlertController:(UIAlertController *)alertController
{
    [self setAssociatedObject:alertController forKey:@"__alertController"];
}

- (BOOL) _isChildViewControllerOfViewController:(UIViewController*)viewController
{
    for(UIViewController* childViewController in viewController.childViewControllers) {
        if (self == childViewController) {
            return YES;
        }
        BOOL isChildViewControllerOfChildViewController = [self _isChildViewControllerOfViewController:childViewController];
        if (isChildViewControllerOfChildViewController) {
            return YES;
        }
    }
    return NO;
}

- (BOOL) _presentAlertControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    UIViewController* topViewController = self.navigationController.topViewController;
    BOOL isChildViewControllerOfTopViewController = [self _isChildViewControllerOfViewController:topViewController];
    if (self.navigationController && self != topViewController && !isChildViewControllerOfTopViewController) {
        return NO;
    }
    
    [self presentViewController:self.alertController animated:animated completion:completion];
    return YES;
}

- (BOOL) presentAlertControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    if (!self.alertController) {
        return NO;
    }

    if (self.presentedViewController) {
        if ([self.presentedViewController isKindOfClass:[UIAlertController class]]) {
            [self.presentedViewController dismissViewControllerAnimated:NO completion:^{
                [self _presentAlertControllerAnimated:animated completion:completion];
            }];
            return YES;
        }
        else {
            return NO;
        }
    }
    
    return [self _presentAlertControllerAnimated:animated completion:completion];
}

- (BOOL) presentAlertControllerWithTitle:(NSString*)title message:(NSString*)message button:(NSString*)buttonTitle animated:(BOOL)animated completion:(void (^)(void))completion
{
    WEAK_SELF
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:buttonTitle
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                self.alertController = nil;
                                            }]];
    
    self.alertController = alert;
    return [self presentAlertControllerAnimated:YES completion:completion];
}

- (BOOL) presentError:(NSError*)error
{
    if ([error code] == -1009) {
        [App handleNoInternetConnection];
        return NO;
    }
    
    return [self presentAlertControllerWithTitle:error.localizedDescription
                                         message:error.localizedRecoverySuggestion
                                          button:@"OK".ls
                                        animated:YES
                                      completion:NULL];
}
@end
