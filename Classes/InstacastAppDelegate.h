//
//  InstacastAppDelegate.h
//  Instacast
//
//  Created by Martin Hering on 22.12.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MainViewController_4;

@interface InstacastAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) MainViewController_4* mainViewController;

- (void) setNeedsStatusBarAppearanceUpdate;
@end

