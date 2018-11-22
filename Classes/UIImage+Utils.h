//
//  UIImage+Utils.h
//  TimeLog5
//
//  Created by Stefan Fuerst on 14.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Utils)

-(UIImage *)imageWithColor:(UIColor *)theColor;

- (UIImage *)applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage;

@end
