//
//  ICSidebarPanGestureRecognizer.h
//  Instacast
//
//  Created by Martin Hering on 21.08.13.
//
//

#import <UIKit/UIKit.h>

@interface ICSidebarPanGestureRecognizer : UIPanGestureRecognizer

@property (nonatomic, readonly) CGPoint firstTouchLocation;
@property (nonatomic, strong) UIView* viewOfLocationCoordinateSystem;
@end
