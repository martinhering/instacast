//
//  MediaPopoverController.h
//  Instacast
//
//  Created by Martin Hering on 25.10.11.
//  Copyright (c) 2011 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MediaPopoverController : UIViewController

- (id) initWithContentViewController:(UIViewController*)viewController;
@property (nonatomic, retain) UIViewController* contentViewController;

@property (nonatomic) CGSize popoverContentSize;
@property (nonatomic) CGPoint popoverOffset;

- (void)presentPopoverFromRect:(CGRect)rect inView:(UIView *)view;
- (void)dismissPopoverAnimated:(BOOL)animated;

@property (nonatomic, copy) void (^didDismissBlock)();
@property (nonatomic, copy) void (^valueChangedBlock)();

@end
