//
//  UIImage+VMFoundation.h
//  VRBankCardPlus2
//
//  Created by Martin Hering on 31.01.14.
//  Copyright (c) 2014 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (VMFoundation)

- (UIImage *)imageWithColor:(UIColor *)theColor;

- (UIImage *)applyBlurWithRadius:(CGFloat)blurRadius
                       tintColor:(UIColor *)tintColor
           saturationDeltaFactor:(CGFloat)saturationDeltaFactor
                       maskImage:(UIImage *)maskImage;

- (UIImage*) borderedImageWithColor:(UIColor*)color;

+ (UIImage*) imageFromByDrawingInContextWithSize:(CGSize)size drawBlock:(void (^)(CGRect rect))drawBlock;
+ (UIImage*) imageFromByDrawingInContextWithSize:(CGSize)size opaque:(BOOL)opaque scale:(CGFloat)scale drawBlock:(void (^)(CGRect rect))drawBlock;
@end
