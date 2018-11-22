//
//  UIViewController+VMFoundation.h
//  Instacast
//
//  Created by Martin Hering on 01/06/14.
//
//

#import <UIKit/UIKit.h>

@interface UIViewController (VMFoundation)

- (void) extendedBeginAppearanceTransition:(BOOL)isAppearing animated:(BOOL)animated;
- (void) extendedEndAppearanceTransition;

@property (nonatomic, readonly, getter = isBeingTransitioned) BOOL beingTransitioned;

- (void) setScrollView:(UIScrollView*)scrollView contentInsets:(UIEdgeInsets)edgeInsets byAdjustingForStandardBars:(BOOL)adjustStandardBars;
@end
