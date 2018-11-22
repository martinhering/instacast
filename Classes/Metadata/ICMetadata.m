//
//  ICMetadata.m
//  InstacastMac
//
//  Created by Martin Hering on 26.06.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import "ICMetadata.h"
#import <AVFoundation/AVFoundation.h>

#if TARGET_OS_IPHONE
#define IC_IMAGE UIImage
#else
#define IC_IMAGE NSImage
#endif

@interface ICMetadataAsset ()
@property (nonatomic, strong) AVAsset* asset;
@end

@implementation ICMetadataAsset

- (NSString*) description
{
    return [NSString stringWithFormat:@"<%@: 0x%lx, feedURL=%@, episodeGuid=%@>", NSStringFromClass([self class]), (long)self, self.feedURL, self.episodeGuid];
}

@end

@implementation ICMetadataItem

- (NSComparisonResult) compare:(ICMetadataItem*)otherItem
{
    int32_t result = CMTimeCompare(self.start, otherItem.start);
    
    if (result < 0) {
        return NSOrderedAscending;
    }
    else if (result > 0) {
        return NSOrderedDescending;
    }
    
    return NSOrderedSame;
}

- (NSTimeInterval) durationWithTrackDuration:(NSTimeInterval)trackDuration
{
    if ((self.end.flags & kCMTimeFlags_PositiveInfinity) > 0) {
        NSTimeInterval start = CMTimeGetSeconds(self.start);
        return (trackDuration > start) ? trackDuration - start : 0.f;
    }

    return (double)CMTimeGetSeconds(CMTimeSubtract(self.end, self.start));
}

@end

@implementation ICMetadataChapter

- (NSString*) description
{
    return [NSString stringWithFormat:@"<%@: 0x%lx, title=%@, label=%@, link=%@, linkLabel=%@>", NSStringFromClass([self class]), (long)self, self.title, self.label, self.link, self.linkLabel];
}
@end

@interface ICMetadataImage ()
@property (nonatomic, strong) NSURL* localCacheURL;
@end


@implementation ICMetadataImage


static CGImageRef CreateScaledCGImageFromCGImage(CGImageRef image, CGFloat maxSide)
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
									 colorspace,(CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
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



- (BOOL) loadPlatformImageWithCompletion:(void (^)(id platformImage))completion
{
    return [self loadPlatformImageScaleToWidth:0 completion:completion];
}

- (void) _loadDataFromURL:(NSURL*)url completion:(void (^)(NSData* data))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSData* data = [NSData dataWithContentsOfURL:url];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(data);
        });
    });
}

- (void) _loadDataFromMetadataItem:(id)item completion:(void (^)(NSData* data))completion
{
    AVMetadataItem* metadataItem = (AVMetadataItem*)item;
    
    [item loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"value"] completionHandler:^(void) {
        
        NSError *error = nil;
        AVKeyValueStatus status = [item statusOfValueForKey:@"value" error:&error];
        
        if (status == AVKeyValueStatusLoaded)
        {
            if (completion) {
                id value = metadataItem.value;
                NSData* data = nil;
                
                if ([value isKindOfClass:[NSDictionary class]]) {
                    data = [value objectForKey:@"data"];
                } else if ([value isKindOfClass:[NSData class]]) {
                    data = value;
                }

                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(data);
                });
            }
        }
    }];
}

- (IC_IMAGE*) _scaledImage:(IC_IMAGE*)image width:(CGFloat)scaledWidth
{
    if (scaledWidth > 0) {
        CGImageRef scaledImage = CreateScaledCGImageFromCGImage([image CGImage], scaledWidth);
        image = [[IC_IMAGE alloc] initWithCGImage:scaledImage];
        CGImageRelease(scaledImage);
    }
    
    return image;
}

- (void) _cacheJPGImage:(IC_IMAGE*)image
{
#if TARGET_OS_IPHONE
    //[UIImageJPEGRepresentation(image, 0.8f) writeToFile:path atomically:YES];
#else
    
    NSFileManager* fman = [[NSFileManager alloc] init];
    
    NSError* error = nil;
    NSURL* tempURL = [fman URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    tempURL = [[tempURL URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]] URLByAppendingPathComponent:@"ICMetadata"];
    error = nil;
    [fman createDirectoryAtURL:tempURL withIntermediateDirectories:YES attributes:nil error:&error];
    
    tempURL = [[tempURL URLByAppendingPathComponent:[self.data MD5Hash]] URLByAppendingPathExtension:@"jpg"];
    self.localCacheURL = tempURL;
    
    for(NSBitmapImageRep* imageRep in [image representations]) {
        if ([imageRep isKindOfClass:[NSBitmapImageRep class]]) {
            NSData* jpegData = [imageRep representationUsingType:NSJPEGFileType properties:nil];
            [jpegData writeToURL:tempURL atomically:YES];
            break;
        }
        else {
            DebugLog(@"fail");
        }
    }
#endif
}

- (void) _loadPlatformImageWithData:(NSData*)data scaleToWidth:(CGFloat)scaledWidth completion:(void (^)(id platformImage))completion
{
    IC_IMAGE* image = [[IC_IMAGE alloc] initWithData:self.data];
    
    [self _cacheJPGImage:image];
    
    if (scaledWidth > 0) {
        image = [self _scaledImage:image width:scaledWidth];
    }
    
    if (completion) {
        completion(image);
    }
}

- (BOOL) loadPlatformImageScaleToWidth:(CGFloat)scaledWidth completion:(void (^)(id platformImage))completion
{
    if (!completion) [NSException raise:NSInternalInconsistencyException format:@"completion parameter must not be nil"];
    
    if (self.data) {
        [self _loadPlatformImageWithData:self.data scaleToWidth:scaledWidth completion:completion];
    }
    
    else if (self.url)
    {
        [self _loadDataFromURL:self.url completion:^(NSData *data) {
            
            self.data = data;
            [self _loadPlatformImageWithData:self.data scaleToWidth:scaledWidth completion:completion];
        }];
    }
    
    else if (self.item)
    {
        [self _loadDataFromMetadataItem:self.item completion:^(NSData *data) {
            
            self.data = data;
            [self _loadPlatformImageWithData:self.data scaleToWidth:scaledWidth completion:completion];
        }];
    }
    
    else if (completion)
    {
        completion(nil);
        return NO;
    }
    
    return YES;
}

#pragma mark - QuickLook Support

- (NSURL *)previewItemURL
{
    return self.localCacheURL;
}

- (NSString *)previewItemTitle
{
    if (self.label) {
        return self.label;
    }
    
    return @"Chapter Image";
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"<%@: 0x%lx, mimeType=%@, label=%@, url=%@, item=%@>", NSStringFromClass([self class]), (long)self, self.mimeType, self.label, self.url, self.item];
}
@end