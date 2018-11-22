//
//  ImageFunctions.m
//  Instacast
//
//  Created by Martin Hering on 23.12.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import "ImageFunctions.h"


CGImageRef CreateScaledCGImageFromCGImage(CGImageRef image, CGFloat maxSide)
{
	// Create the bitmap context
	CGContextRef    context = NULL;
	void *          bitmapData;
	int             bitmapByteCount;
	int             bitmapBytesPerRow;
	
	CGFloat scale = 1.0f;
	if (CGImageGetWidth(image) > CGImageGetHeight(image)) {
		scale = maxSide / CGImageGetWidth(image);
	} else {
		scale = maxSide / CGImageGetHeight(image);
	}
	
	// Get image width, height. We'll use the entire image.
	int width = ceilf(CGImageGetWidth(image) * scale);
	int height = ceilf(CGImageGetHeight(image) * scale);
	
	// Declare the number of bytes per row. Each pixel in the bitmap in this
	// example is represented by 4 bytes; 8 bits each of red, green, blue, and
	// alpha.
	bitmapBytesPerRow   = (width * 4);
	bitmapByteCount     = (bitmapBytesPerRow * height);
	
	// Allocate memory for image data. This is the destination in memory
	// where any drawing to the bitmap context will be rendered.
	bitmapData = malloc( bitmapByteCount );
	if (bitmapData == NULL) {
		return nil;
	}
	
	// Create the bitmap context. We want pre-multiplied ARGB, 8-bits
	// per component. Regardless of what the source image format is
	// (CMYK, Grayscale, and so on) it will be converted over to the format
	// specified here by CGBitmapContextCreate.
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	context = CGBitmapContextCreate (bitmapData,width,height,8,bitmapBytesPerRow,
									 colorspace,kCGImageAlphaNoneSkipFirst);
	CGColorSpaceRelease(colorspace);
	
	if (context == NULL) {
		// error creating context
		return nil;
	}
	
	// Draw the image to the bitmap context. Once we draw, the memory
	// allocated for the context for rendering will then contain the
	// raw image data in the specified color space.
	CGContextSetRGBFillColor(context, 1, 1, 1, 1);
	CGContextFillRect(context, CGRectMake(0, 0, width, width));
	
	CGContextSetBlendMode(context, kCGBlendModeNormal);
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
	
	CGImageRef imgRef = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	free(bitmapData);
	
	return imgRef;
}

CGImageRef CreateSquaredScaledCGImageFromCGImage(CGImageRef image, 
												 CGFloat minSide)
{
	// Create the bitmap context
	CGContextRef    context = NULL;
	void *          bitmapData;
	int             bitmapByteCount;
	int             bitmapBytesPerRow;
	
	CGFloat scale = 1.0f;
	if (CGImageGetWidth(image) < CGImageGetHeight(image)) {
		scale = minSide / CGImageGetWidth(image);
	} else {
		scale = minSide / CGImageGetHeight(image);
	}
	
	// Get image width, height. We'll use the entire image.
	int width = ceilf(CGImageGetWidth(image) * scale);
	int height = ceilf(CGImageGetHeight(image) * scale);
	
	// Declare the number of bytes per row. Each pixel in the bitmap in this
	// example is represented by 4 bytes; 8 bits each of red, green, blue, and
	// alpha.
	bitmapBytesPerRow   = (minSide * 4);
	bitmapByteCount     = (bitmapBytesPerRow * minSide);
	
	// Allocate memory for image data. This is the destination in memory
	// where any drawing to the bitmap context will be rendered.
	bitmapData = malloc( bitmapByteCount );
	if (bitmapData == NULL) {
		return nil;
	}
	
	// Create the bitmap context. We want pre-multiplied ARGB, 8-bits
	// per component. Regardless of what the source image format is
	// (CMYK, Grayscale, and so on) it will be converted over to the format
	// specified here by CGBitmapContextCreate.
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	context = CGBitmapContextCreate (bitmapData,minSide,minSide,8,bitmapBytesPerRow,
									 colorspace,kCGImageAlphaNoneSkipFirst);
	CGColorSpaceRelease(colorspace);
	
	if (context == NULL) {
		// error creating context
		return nil;
	}
	
	// Draw the image to the bitmap context. Once we draw, the memory
	// allocated for the context for rendering will then contain the
	// raw image data in the specified color space.

	CGContextSetRGBFillColor(context, 1, 1, 1, 1);
	CGContextFillRect(context, CGRectMake(0, 0, width, width));
	
	CGContextSetBlendMode(context, kCGBlendModeNormal);
	CGContextDrawImage(context, CGRectMake(-(width-minSide)*0.5, -(height-minSide)*0.5,width, height), image);
	
	CGImageRef imgRef = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	free(bitmapData);
	
	return imgRef;
}

CGImageRef CreateSquaredScaledCroppedCGImageFromCGImage(CGImageRef image,
														CGFloat width,
														CGFloat centerScale,
														CGPoint translatePoint)
{
	CGFloat imageScale = width / 300.f;
	centerScale *= imageScale;
	
	int	sw = ceilf(CGImageGetWidth(image) * centerScale);
	int sh = ceilf(CGImageGetHeight(image) * centerScale);
	
	
	int bitmapBytesPerRow   = (width * 4);
	int bitmapByteCount     = (bitmapBytesPerRow * width);
	
	void* bitmapData = malloc( bitmapByteCount );
	if (bitmapData == NULL) {
		return nil;
	}
	
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	
	CGContextRef context = CGBitmapContextCreate (bitmapData,
												  width,
												  width,
												  8,
												  bitmapBytesPerRow,
												  colorspace,
												  kCGImageAlphaNoneSkipFirst);
	CGColorSpaceRelease(colorspace);
	
	if (context == NULL) {
		return nil;
	}
	
	
	CGRect scaledRect;
	scaledRect.origin.x = -(sw-width)*0.5f + translatePoint.x*centerScale;
	scaledRect.origin.y = -(sh-width)*0.5f - translatePoint.y*centerScale;
	scaledRect.size.width = sw;
	scaledRect.size.height = sh;
	
	//CGRectMake(-(width-minSide)*0.5, -(height-minSide)*0.5,width, height)
	CGContextSetRGBFillColor(context, 1, 1, 1, 1);
	CGContextFillRect(context, CGRectMake(0, 0, width, width));
	
	CGContextSetBlendMode(context, kCGBlendModeNormal);
	CGContextDrawImage(context, scaledRect, image);
	
	CGImageRef imgRef = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	free(bitmapData);
	
	return imgRef;
}


#if TARGET_OS_IPHONE
UIImage* CreateGreyscaleImage(UIImage* i)
#else
NSImage* CreateGreyscaleImage(NSImage* i)
#endif
{
    int kRed = 1;
    int kGreen = 2;
    int kBlue = 4;
	
    int colors = kGreen;
    int m_width = i.size.width;
    int m_height = i.size.height;
	
    uint32_t *rgbImage = (uint32_t *) malloc(m_width * m_height * sizeof(uint32_t));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImage, m_width, m_height, 8, m_width * 4, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetShouldAntialias(context, NO);
    
#if TARGET_OS_IPHONE
    CGImageRef cgImage = [i CGImage];
#else
    CGImageRef cgImage = [i CGImageForProposedRect:NULL context:nil hints:nil];
#endif
    
    CGContextDrawImage(context, CGRectMake(0, 0, m_width, m_height), cgImage);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
	
    // now convert to grayscale
    uint8_t *m_imageData = (uint8_t *) calloc(m_width * m_height*sizeof(uint8_t), 1);
    for(int y = 0; y < m_height; y++) {
        for(int x = 0; x < m_width; x++) {
			uint32_t rgbPixel=rgbImage[y*m_width+x];
			uint32_t sum=0,count=0;
			if (colors & kRed) {sum += (rgbPixel>>24)&255; count++;}
			if (colors & kGreen) {sum += (rgbPixel>>16)&255; count++;}
			if (colors & kBlue) {sum += (rgbPixel>>8)&255; count++;}
			m_imageData[y*m_width+x]=sum/count;
        }
    }
    free(rgbImage);
	
    // convert from a gray scale image back into a UIImage
    uint8_t *result = (uint8_t *) calloc(m_width * m_height * 4, 1);
	
    // process the image back to rgb
    for(int i = 0; i < m_height * m_width; i++) {
        result[i*4]=0;
        double val = m_imageData[i]/255.0;
		val -= 0.5;
		val *= 0.5;  // contrast
		val += 0.5;
		val *= 255.0;
		int v = val;
		if (v > 255) v = 255;
		if (v < 0) v = 0;
		
		result[i*4+1]=MIN(v*1.6,255);
        result[i*4+2]=MIN(v*1.4,255);
        result[i*4+3]=MIN(v*1.4,255);
    }
	free(m_imageData);
	
    // create a UIImage
    colorSpace = CGColorSpaceCreateDeviceRGB();
    context = CGBitmapContextCreate(result, m_width, m_height, 8, m_width * sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
#if TARGET_OS_IPHONE
    UIImage *resultUIImage = [[UIImage alloc] initWithCGImage:image];
#else
    NSImage* resultUIImage = [[NSImage alloc] initWithCGImage:image size:NSZeroSize];
#endif
    
    
    CGImageRelease(image);
	
    // make sure the data will be released by giving it to an autoreleased NSData
    [NSData dataWithBytesNoCopy:result length:m_width * m_height];
	
    return resultUIImage;
}

#if TARGET_OS_IPHONE==1
UIImage* ICImageFromByDrawingInContext(CGSize size, void(^drawBlock)())
{
    UIGraphicsBeginImageContext(size);
    drawBlock();
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

UIImage* ICImageFromByDrawingInContextWithScale(CGSize size, BOOL opaque, CGFloat scale, void(^drawBlock)())
{
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
    drawBlock();
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
#endif