//
//  UIViewController+UIViewController_NavbarFix.m
//  Instacast
//
//  Created by Martin Hering on 30.09.14.
//
//

#import "UIViewController+UIViewController_NavbarFix.h"

@implementation UIViewController (UIViewController_NavbarFix)

+ (void)load {
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        
        NSString* insetSelectorString = [@[@"_",@"setNavigationController", @"ContentInsetAdjustment:"] componentsJoinedByString:@""];
        NSString* offsetSelectorString = [@[@"_",@"setNavigationController", @"ContentOffsetAdjustment:"] componentsJoinedByString:@""];
        
        [self swizzleSelector:NSSelectorFromString(insetSelectorString) withSelector:@selector(_mySetNavigationControllerContentInsetAdjustment:)];
        [self swizzleSelector:NSSelectorFromString(offsetSelectorString) withSelector:@selector(_mySetNavigationControllerContentOffsetAdjustment:)];
    });
}

- (void) _mySetNavigationControllerContentInsetAdjustment:(UIEdgeInsets)insets
{
    NSString* className = NSStringFromClass([self class]);
    NSArray* systemControllerWhitelist = @[@"_UIActivity", @"MFMail"];
    for (NSString* classNamePrefix in systemControllerWhitelist) {
        if ([className hasPrefix:classNamePrefix]) {
            [self _mySetNavigationControllerContentInsetAdjustment:insets];
            break;
        }
    };
    //DebugLog(@"_mySetNavigationControllerContentInsetAdjustment %@", NSStringFromClass([self class]));
}

- (void) _mySetNavigationControllerContentOffsetAdjustment:(float)offset
{
    //DebugLog(@"_mySetNavigationControllerContentOffsetAdjustment %@", NSStringFromClass([self class]));

    NSString* className = NSStringFromClass([self class]);
    NSArray* systemControllerWhitelist = @[@"_UIActivity", @"MFMail"];
    for (NSString* classNamePrefix in systemControllerWhitelist) {
        if ([className hasPrefix:classNamePrefix]) {
            [self _mySetNavigationControllerContentOffsetAdjustment:offset];
            break;
        }
    };
}


@end
