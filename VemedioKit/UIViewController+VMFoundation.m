//
//  UIViewController+VMFoundation.m
//  Instacast
//
//  Created by Martin Hering on 01/06/14.
//
//

#import "UIViewController+VMFoundation.h"
#import "NSObject+VMFoundation.h"

@implementation UIViewController (VMFoundation)

- (BOOL) isBeingTransitioned {
    return [[self associatedObjectForKey:@"beingTransitioned"] boolValue];
}

- (void) setBeingTransitioned:(BOOL)beingTransitioned
{
    [self setAssociatedObject:@(beingTransitioned) forKey:@"beingTransitioned"];
}

- (void) extendedBeginAppearanceTransition:(BOOL)isAppearing animated:(BOOL)animated
{
    self.beingTransitioned = YES;
    [self beginAppearanceTransition:isAppearing animated:animated];
}

- (void) extendedEndAppearanceTransition
{
    [self endAppearanceTransition];
    self.beingTransitioned = NO;
}

- (void) setScrollView:(UIScrollView*)scrollView contentInsets:(UIEdgeInsets)edgeInsets byAdjustingForStandardBars:(BOOL)adjustStandardBars
{
    if (!IS_IOS11) {
        return;
    }
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    BOOL xScreen = (CGRectGetWidth(screenBounds) == 375 && CGRectGetHeight(screenBounds) == 812);
    //CGFloat statusbarHeight = (xScreen) ? 44 : 20;
    CGFloat homebarHeight = (xScreen) ? 34 : 0;
    
    edgeInsets.bottom += homebarHeight;
    
    if (adjustStandardBars)
    {
        UINavigationController* navController = self.navigationController;
        
        if (navController)
        {
            CGRect navBarFrame = self.navigationController.navigationBar.frame;
            edgeInsets.top += CGRectGetMinY(navBarFrame);           // statusbar
            edgeInsets.top += CGRectGetHeight(navBarFrame);         // navbar height
            
            if (!self.navigationController.toolbarHidden) {
                CGRect toolbarFrame = self.navigationController.toolbar.frame;
                edgeInsets.bottom += CGRectGetHeight(toolbarFrame); // toolbar height
            }
        }
        
        if (self.tabBarController)
        {
            CGRect tabBarFrame = self.tabBarController.tabBar.frame;
            edgeInsets.bottom += CGRectGetHeight(tabBarFrame);      // tabbar height
        }
    }
    
    if (@available(iOS 11.0, *)) {
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    scrollView.contentInset = edgeInsets;
    scrollView.scrollIndicatorInsets = edgeInsets;
    if (CGPointEqualToPoint(scrollView.contentOffset, CGPointZero)) {
        scrollView.contentOffset = CGPointMake(0,-edgeInsets.top);
    }
}
@end
