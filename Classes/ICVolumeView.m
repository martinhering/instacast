//
//  ICVolumeView.m
//  Instacast
//
//  Created by Martin Hering on 22.08.13.
//
//

#import <objc/runtime.h>

#import "ICVolumeView.h"

@interface MPVolumeView ()
//- (void) _setShowsRouteButton:(BOOL)show animated:(BOOL)animated;
@end

@implementation ICVolumeView

+ (void) initialize
{
    NSString* selectorString = [@[@"_", @"setShows", @"RouteButton:", @"animated:"] componentsJoinedByString:@""];
    
    SEL originalSelector = NSSelectorFromString(selectorString);
    Method originalMethod = class_getInstanceMethod([self class], originalSelector);
    
    SEL overrideSelector = @selector(mySetShowsRouteButton:animated:);
    Method overrideMethod = class_getInstanceMethod([self class], overrideSelector);
    
    if (class_addMethod(self, originalSelector, method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod))) {
        class_replaceMethod(self, overrideSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, overrideMethod);
    }
}


- (UIButton*) airPlayButton
{
    for(UIView* subview in self.subviews)
	{
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton* airPlayButton = (UIButton*)subview;
            return airPlayButton;
        }
	}
    return nil;
}

- (void) mySetShowsRouteButton:(BOOL)show animated:(BOOL)animated
{
    [self mySetShowsRouteButton:YES animated:animated];
    
    [self airPlayButton].alpha = 1.0f;
    [self airPlayButton].enabled = show;
}

@end
