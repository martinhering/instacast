//
//  UIScreen+VemedioKit.h
//  VemedioKit
//
//  Created by Martin Hering on 10.01.16.
//  Copyright © 2016 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, VMScreenResolution)
{
    kVMScreenResolutionUnknown = 0,
    kVMScreenResolutionPhone3,
    kVMScreenResolutionPhone4,
    kVMScreenResolutionPhone5,
    kVMScreenResolutionPhone6,
    kVMScreenResolutionPhone6Plus,
    kVMScreenResolutionPad,
    kVMScreenResolutionPadPro,
};

@interface UIScreen (VemedioKit)

@property (readonly) VMScreenResolution vm_resolution;

@end
