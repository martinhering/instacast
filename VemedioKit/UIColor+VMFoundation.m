//
//  UIColor+VMFoundation.m
//  Instacast
//
//  Created by Martin Hering on 28.07.14.
//
//

#import "UIColor+VMFoundation.h"

@implementation UIColor (VMFoundation)

+ (UIColor*) mergedColorOfImage:(UIImage*)image
{
    CGImageRef rawImageRef = [image CGImage];
    
    // scale image to an one pixel image
    
    uint8_t  bitmapData[4];
    int bitmapByteCount;
    int bitmapBytesPerRow;
    int width = 1;
    int height = 1;
    
    bitmapBytesPerRow = (width * 4);
    bitmapByteCount = (bitmapBytesPerRow * height);
    memset(bitmapData, 0, bitmapByteCount);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate (bitmapData,width,height,8,bitmapBytesPerRow,
                                                  colorspace,kCGBitmapByteOrder32Little|kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorspace);
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextSetInterpolationQuality(context, kCGInterpolationMedium);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), rawImageRef);
    CGContextRelease(context);
    UIColor* averageColor = [UIColor colorWithRed:bitmapData[2] / 255.0f
                                              green:bitmapData[1] / 255.0f
                                               blue:bitmapData[0] / 255.0f
                                              alpha:1];
    
    return averageColor;
}

- (UIColor*) colorByCappingBrightnessAt:(float)cappedBrightness
{
    CGFloat hue, saturation, brightness, alpha;
    [self getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    
    saturation = MIN(saturation+0.3f, 1.0f);
    if (cappedBrightness > 0.6f) {
        brightness = MIN(brightness, cappedBrightness);
    } else {
        brightness = MAX(cappedBrightness, brightness);
    }
    
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
}

+ (UIColor*) colorWithHexString:(NSString*)hex
{
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];

    // String should be 6 or 8 characters
    if ([cString length] < 6) return [UIColor grayColor];

    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];

    if ([cString length] != 6) return  [UIColor grayColor];

    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];

    range.location = 2;
    NSString *gString = [cString substringWithRange:range];

    range.location = 4;
    NSString *bString = [cString substringWithRange:range];

    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];

    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}


@end
