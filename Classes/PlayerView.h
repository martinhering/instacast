//
//  PlayerView.h
//  Instacast
//
//  Created by Martin Hering on 06.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

@class AVPlayer;

#if TARGET_OS_IPHONE
@interface PlayerView : UIView {
#else
@interface PlayerView : NSView {
#endif

}
@property (nonatomic, strong) AVPlayer *player;

@end
