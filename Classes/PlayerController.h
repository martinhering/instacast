//
//  PlayerController.h
//  Instacast
//
//  Created by Martin Hering on 05.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ProgressSlider;

@interface PlayerController : UIViewController

+ (PlayerController*) playerController;

@property (nonatomic, weak) id delegate;
@property (nonatomic, assign) BOOL backgroundPlayback;

@end
