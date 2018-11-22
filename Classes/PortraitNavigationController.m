//
//  PortraitNavigationController.m
//  Instacast
//
//  Created by Martin Hering on 14.09.12.
//
//

#import "PortraitNavigationController.h"



@interface PortraitNavigationController ()

@end

@implementation PortraitNavigationController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.view.tintColor = ICTintColor;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    }
    
    return UIInterfaceOrientationMaskPortrait;
}

- (UIViewController*) _fullscreenVideoControllerWithCurrentViewController:(UIViewController*)viewController
{
    if ([viewController isKindOfClass:NSClassFromString(@"PlayerFullscreenVideoViewController")]) {
        return viewController;
    }
    
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        return [self _fullscreenVideoControllerWithCurrentViewController:((UINavigationController*)viewController).topViewController];
    }
    if (viewController.presentedViewController) {
        return [self _fullscreenVideoControllerWithCurrentViewController:viewController.presentedViewController];
    }
    
    return nil;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [ICAppearanceManager sharedManager].appearance.statusBarStyle;
}

- (BOOL) prefersStatusBarHidden {
    return NO;
}

- (UIViewController*) childViewControllerForStatusBarHidden {
    return [self _fullscreenVideoControllerWithCurrentViewController:self];
}

- (UIViewController*) childViewControllerForStatusBarStyle {
    return [self _fullscreenVideoControllerWithCurrentViewController:self];
}

@end
