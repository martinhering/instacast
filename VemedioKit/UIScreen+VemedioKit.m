//
//  UIScreen+VemedioKit.m
//  VemedioKit
//
//  Created by Martin Hering on 10.01.16.
//  Copyright © 2016 Vemedio. All rights reserved.
//

#import "UIScreen+VemedioKit.h"


@implementation UIScreen (VemedioKit)


- (VMScreenResolution) vm_resolution
{
    CGRect screenBounds = self.bounds;
    CGFloat w = CGRectGetWidth(screenBounds);
    CGFloat h = CGRectGetHeight(screenBounds);
    NSInteger min = MIN(w, h);
    NSInteger max = MAX(w, h);
    
    if (min == 320 && max == 640) {
        return kVMScreenResolutionPhone4;
    }
    
    if (min == 320 && max == 568) {
        return kVMScreenResolutionPhone5;
    }
    
    if (min == 375 && max == 667) {
        return kVMScreenResolutionPhone6;
    }
    
    if (min == 414 && max == 736) {
        return kVMScreenResolutionPhone6Plus;
    }
    
    if (min == 768 && max == 1024) {
        return kVMScreenResolutionPad;
    }
    
    if (min == 1024 && max == 1366) {
        return kVMScreenResolutionPadPro;
    }
    
    return kVMScreenResolutionUnknown;
}

@end
