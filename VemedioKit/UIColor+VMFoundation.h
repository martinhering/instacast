//
//  UIColor+VMFoundation.h
//  Instacast
//
//  Created by Martin Hering on 28.07.14.
//
//

#import <UIKit/UIKit.h>

@interface UIColor (VMFoundation)
+ (UIColor*) mergedColorOfImage:(UIImage*)image;
- (UIColor*) colorByCappingBrightnessAt:(float)brightness;
+ (UIColor*) colorWithHexString:(NSString*)hex;
@end
