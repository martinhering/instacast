//
//  UIViewController+UIViewController_NavbarFix.h
//  Instacast
//
//  Created by Martin Hering on 30.09.14.
//
//

#import <UIKit/UIKit.h>

@interface UIViewController (UIViewController_NavbarFix)

- (void) _mySetNavigationControllerContentInsetAdjustment:(UIEdgeInsets)insets;
- (void) _mySetNavigationControllerContentOffsetAdjustment:(float)offset;

@end
