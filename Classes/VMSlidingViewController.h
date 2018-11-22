//
//  VMViewController.h
//  SlidingViewController
//
//  Created by Martin Hering on 24.06.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VMSlidingViewController : UIViewController


@property (nonatomic, strong) UIViewController* sidebarViewController;
@property (nonatomic, strong) UIViewController* contentViewController;
@property (nonatomic, readonly) UIBarButtonItem* sidebarMenuItem;

@property (nonatomic, getter = isSidebarShown) BOOL sidebarShown;
- (void) setSidebarShown:(BOOL)shown animated:(BOOL)animated;

- (void) willShowSidebar:(BOOL)shown animated:(BOOL)animated;
- (void) didShowSidebar:(BOOL)shown animated:(BOOL)animated;
- (void) animateAdditionalSidebarViewsDuringShow:(BOOL)reveal;


- (CGRect) rectForContentControllerWhenShown:(BOOL)shown;
- (void) setNeedsContentControllerLayoutUpdateAnimated:(BOOL)animated;
@end
