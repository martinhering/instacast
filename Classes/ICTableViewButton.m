//
//  ICTableViewButton.m
//  Instacast
//
//  Created by Martin Hering on 19.08.14.
//
//

#import "ICTableViewButton.h"

@implementation ICTableViewButton

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    return CGRectMake(5, CGRectGetHeight(contentRect)-34, CGRectGetWidth(contentRect)-10, 20);
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    UIImage* image = self.currentImage;
    CGSize imageSize = image.size;
    
    CGFloat yOffset = 0;
    if (self.currentTitle) {
        yOffset = -8;
    }
    
    return CGRectMake(floorf((CGRectGetWidth(contentRect)-imageSize.width)/2), floorf((CGRectGetHeight(contentRect)-imageSize.height)/2)+yOffset, imageSize.width, imageSize.height);
}
@end
