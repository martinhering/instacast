//
//  ToolbarLabelsViewController.h
//  Instacast
//
//  Created by Martin Hering on 08.04.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AnimatingLabel;

@interface ToolbarLabelsViewController : UIViewController

+ (id) toolbarLabelsViewController;

@property (nonatomic, strong) NSString* mainText;
@property (nonatomic, strong) NSString* auxiliaryText;
@property (nonatomic) BOOL canDisplayRefreshStatus;

- (void) layout;

@end
