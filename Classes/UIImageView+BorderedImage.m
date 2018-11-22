//
//  UIImageView+BorderedImage.m
//  Instacast
//
//  Created by Martin Hering on 28.07.13.
//
//

#import "UIImageView+BorderedImage.h"

@implementation UIImageView (BorderedImage)

- (void) setBorderedImage:(UIImage *)borderedImage
{
    CGSize imageSize = borderedImage.size;
    CGRect imageBounds = CGRectMake(0, 0, imageSize.width, imageSize.height);
    
    UIGraphicsBeginImageContext(imageSize);
    
    [borderedImage drawInRect:imageBounds];
    
    [[UIColor colorWithRed:106/255.f green:93/255.f blue:80/255.f alpha:0.17f] set];
    UIRectFrameUsingBlendMode(imageBounds, kCGBlendModeMultiply);
    
    UIImage* finalImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    self.image = finalImage;
}

@end
