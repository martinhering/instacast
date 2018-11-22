//
//  StatusBarFixingViewController.m
//  Instacast
//
//  Created by Martin Hering on 26.07.14.
//
//

#import "StatusBarFixingViewController.h"

@interface StatusBarFixingViewController ()

@end

@implementation StatusBarFixingViewController

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.view.backgroundColor = ICBackgroundColor;
}

- (UIViewController*) childViewControllerForStatusBarStyle {
    return [self.childViewControllers firstObject];
}

- (UIViewController*) childViewControllerForStatusBarHidden {
    return [self.childViewControllers firstObject];
}

@end
