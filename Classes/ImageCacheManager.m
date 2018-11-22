//
//  ImageCacheManager.m
//  Instacast
//
//  Created by Martin Hering on 16.06.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import "ICImageCacheOperation.h"

#import "ImageFunctions.h"
#import "UtilityFunctions.h"
#import "CDModel.h"


#if TARGET_OS_IPHONE
#define IC_IMAGE UIImage
#define IC_COLOR UIColor
#else
#define IC_IMAGE NSImage
#define IC_COLOR NSColor
#endif

#pragma mark -


@interface IC_COLOR (DarkAddition)

- (BOOL)pc_isDarkColor;
- (BOOL)pc_isDistinct:(IC_COLOR*)compareColor;
- (IC_COLOR*)pc_colorWithMinimumSaturation:(CGFloat)saturation;
- (BOOL)pc_isBlackOrWhite;
- (BOOL)pc_isContrastingColor:(IC_COLOR*)color;

@end


@interface PCCountedColor : NSObject

@property (assign) NSUInteger count;
@property (retain) IC_COLOR *color;

- (id)initWithColor:(IC_COLOR*)color count:(NSUInteger)count;

@end



static NSURL* NoQueryURL(NSURL* url)
{
    if ([url query]) {
        NSString* query = [NSString stringWithFormat:@"?%@",[url query]];
        NSString* URLString = [[url absoluteString] stringByReplacingOccurrencesOfString:query withString:@""];
        return [NSURL URLWithString:URLString];
    }
    return url;
}

static ImageCacheManager* gSharedCacheManager = nil;

@interface ImageCacheManager ()
@property (strong) NSMutableDictionary* cancelRequests;
@property (strong) NSMutableDictionary* imageCache;
@property (strong) NSMutableDictionary* failedImages;
@property (nonatomic, readwrite, strong) NSOperationQueue* operationQueue;
@end


@implementation ImageCacheManager {
    dispatch_queue_t        _queue;
}

+ (NSInteger) scalingFactor
{
    // multiply size with scale to support retina images
#if TARGET_OS_IPHONE
    NSInteger scale = [UIScreen mainScreen].scale;
#else
    NSInteger scale = [[NSScreen mainScreen] backingScaleFactor];
#endif
    
    return scale;
}

+ (NSString*) cacheKeyWithURL:(NSURL*)url size:(NSInteger)size grayscale:(BOOL)grayscale
{
    NSInteger scaledSize = size*[ImageCacheManager scalingFactor];
    return [NSString stringWithFormat:@"%@_%ld_%d", [url absoluteString], (long)scaledSize, grayscale];
}

+ (NSURL*) cacheURLForImageURL:(NSURL*)url size:(NSInteger)size
{
    NSInteger scaledSize = size*[ImageCacheManager scalingFactor];
    
    NSString* awsURLString = [NSString stringWithFormat:@"http://pcast-images.vemedio.com/image?ref=%@&size=%ld", [[url absoluteString] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]], (long)scaledSize];
    return [NSURL URLWithString:awsURLString];
}

+ (NSURL*) fileURLToCachedImageForImageURL:(NSURL*)url size:(NSInteger)size grayscale:(BOOL)grayscale
{
	NSInteger scaledSize = size*[ImageCacheManager scalingFactor];
    
    NSString* imageIdentifier = [[url absoluteString] MD5Hash];
	NSString* filename = [NSString stringWithFormat:@"%@_%ld%@.jpg", imageIdentifier, (long)scaledSize, (grayscale ? @"g" : @"")];
	NSString* localPath = [[DMANAGER.imageCacheURL path] stringByAppendingPathComponent:filename];
    return (localPath) ? [NSURL fileURLWithPath:localPath] : nil;
}


+ (IC_IMAGE*) grayscaleImageForImage:(IC_IMAGE*)image
{
    return CreateGreyscaleImage(image);
}

+ (void) loadImageForURL:(NSURL*)url size:(NSInteger)size grayscale:(BOOL)grayscale completion:(void (^)(IC_IMAGE* platformImage, NSError* error))completion
{
    ICImageCacheOperation* operation = [[ICImageCacheOperation alloc] initWithURL:url size:size grayscale:grayscale];
    operation.didEndBlock = ^(IC_IMAGE* image, NSError* error) {
        if (image) {
            [[self sharedImageCacheManager] cacheImage:image forURL:url size:size grayscale:grayscale];
        }
        if (completion) {
            completion(image, error);
        }
    };
    [[self sharedImageCacheManager] addImageCacheOperation:operation sender:[self sharedImageCacheManager]];
}

+ (ImageCacheManager*) sharedImageCacheManager;
{
	if (!gSharedCacheManager) {
		
		static dispatch_once_t once = 0; 
		dispatch_once(&once, ^{
			gSharedCacheManager = [self alloc];
			gSharedCacheManager = [gSharedCacheManager init];
		});
	}
	return gSharedCacheManager;
}

- (id) init
{
	if ((self = [super init]))
	{
        _imageCache = [[NSMutableDictionary alloc] init];
        _failedImages = [[NSMutableDictionary alloc] init];
		_cancelRequests = [[NSMutableDictionary alloc] init];
		_queue = dispatch_queue_create("com.vemedio.instacast.image-cache", DISPATCH_QUEUE_CONCURRENT);
        _operationQueue = [[NSOperationQueue alloc] init];
        [_operationQueue setMaxConcurrentOperationCount:5];
        
#if TARGET_OS_IPHONE
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationDidReceiveMemoryWarningNotification:)
													 name:UIApplicationDidReceiveMemoryWarningNotification
												   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidReceiveMemoryWarningNotification:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
#endif
	}
	
	return self;
}

- (void) applicationDidReceiveMemoryWarningNotification:(NSNotification*)notification
{
	DebugLog(@"purge in-memory image cache");
	[self.imageCache removeAllObjects];
}

- (void) addImageCacheOperation:(ICImageCacheOperation*)operation sender:(id)sender
{
    operation.sender = sender;
    [self.operationQueue addOperation:operation];
}

- (void) cancelImageCacheOperationsWithSender:(id)sender
{
    for(ICImageCacheOperation* operation in [self.operationQueue operations]) {
        if (operation.sender == sender) {
            [operation cancel];
        }
    }
}

- (IC_IMAGE*) cachedImageForKey:(NSString*)cacheKey
{
    return [self.imageCache objectForKey:cacheKey];
}

- (void) cacheImage:(IC_IMAGE*)image forURL:(NSURL*)url size:(NSInteger)size grayscale:(BOOL)grayscale
{
    NSString* cacheKey = [ImageCacheManager cacheKeyWithURL:url size:size grayscale:grayscale];
    @synchronized(self.imageCache) {
        [self.imageCache setObject:image forKey:cacheKey];
    }
}

- (IC_IMAGE*) localImageForImageURL:(NSURL*)url size:(NSInteger)size grayscale:(BOOL)grayscale
{
    // try to find image in memory cache
    NSString* cacheKey = [ImageCacheManager cacheKeyWithURL:url size:size grayscale:grayscale];
    IC_IMAGE* image = [self cachedImageForKey:cacheKey];
    if (image) {
        return image;
    }
    
    // try to find image in file storage
    NSURL* fileURL = [ImageCacheManager fileURLToCachedImageForImageURL:url size:size grayscale:grayscale];
    image = [[IC_IMAGE alloc] initWithContentsOfFile:[fileURL path]];
    if (image) {
        [self cacheImage:image forURL:url size:size grayscale:grayscale];
    }
    return image;
}

- (void) imageForURL:(NSURL*)url size:(NSInteger)size grayscale:(BOOL)grayscale sender:(id)sender completion:(void (^)(IC_IMAGE* image))completionHandler
{
    IC_IMAGE* cachedImage = [self localImageForImageURL:url size:size grayscale:grayscale];
    if (cachedImage) {
        completionHandler(cachedImage);
    }
    else {
        ICImageCacheOperation* operation = [[ICImageCacheOperation alloc] initWithURL:url size:size grayscale:NO];
        operation.didEndBlock = ^(IC_IMAGE* image, NSError* error) {
            if (image) {
                completionHandler(image);
            }
        };
        [self addImageCacheOperation:operation sender:sender];
    }
}

- (void) _clearCachedImageWithRefURL:(NSURL*)refURL size:(NSInteger)size grayscale:(BOOL)grayscale
{
    // multiply size with scale to support retina images
	NSInteger scaledSize = size*[ImageCacheManager scalingFactor];
    
    NSString* imageIdentifier = [[refURL absoluteString] MD5Hash];
	NSString* filename = [NSString stringWithFormat:@"%@_%ld%@.jpg", imageIdentifier, (long)scaledSize, (grayscale ? @"g" : @"")];
	NSString* localPath = [[DMANAGER.imageCacheURL path] stringByAppendingPathComponent:filename];
	
    [[NSFileManager defaultManager] removeItemAtPath:localPath error:nil];
    
    NSString* cacheKey = [ImageCacheManager cacheKeyWithURL:refURL size:size grayscale:grayscale];
    [self.imageCache removeObjectForKey:cacheKey];
}


- (void) clearCachedImagesOfFeed:(CDFeed*)feed
{
    NSURL* refURL = feed.imageURL;
	if (!refURL) {
		return;
	}

    [self _clearCachedImageWithRefURL:refURL size:56 grayscale:NO];
    [self _clearCachedImageWithRefURL:refURL size:60 grayscale:NO];
    [self _clearCachedImageWithRefURL:refURL size:72 grayscale:YES];
    [self _clearCachedImageWithRefURL:refURL size:320 grayscale:NO];
}

- (BOOL) clearTheFuckingCache
{
    [self.imageCache removeAllObjects];
    
    NSFileManager* fman = [NSFileManager defaultManager];
    
    NSString* pathToImages = [DMANAGER.imageCacheURL path];
	NSDirectoryEnumerator* e = [fman enumeratorAtPath:pathToImages];
	for(NSString* filename in e)
	{
        NSString* path = [pathToImages stringByAppendingPathComponent:filename];
        [fman removeItemAtPath:path error:nil];
	}
    
    
    return YES;
}

@end


#pragma mark -


#if TARGET_OS_IPHONE

@implementation IC_COLOR (DarkAddition)

- (BOOL)pc_isDarkColor
{
	IC_COLOR *convertedColor = self; //[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	CGFloat r, g, b, a;
    
	[convertedColor getRed:&r green:&g blue:&b alpha:&a];
	
	CGFloat lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    
	if ( lum < .5 )
	{
		return YES;
	}
	
	return NO;
}


- (BOOL)pc_isDistinct:(IC_COLOR*)compareColor
{
	IC_COLOR *convertedColor = self; //[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	IC_COLOR *convertedCompareColor = compareColor; //[compareColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	CGFloat r, g, b, a;
	CGFloat r1, g1, b1, a1;
    
	[convertedColor getRed:&r green:&g blue:&b alpha:&a];
	[convertedCompareColor getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    
	CGFloat threshold = .25; //.15
    
	if ( fabs(r - r1) > threshold ||
		fabs(g - g1) > threshold ||
		fabs(b - b1) > threshold ||
		fabs(a - a1) > threshold )
    {
        // check for grays, prevent multiple gray colors
        
        if ( fabs(r - g) < .03 && fabs(r - b) < .03 )
        {
            if ( fabs(r1 - g1) < .03 && fabs(r1 - b1) < .03 )
                return NO;
        }
        
        return YES;
    }
    
	return NO;
}


- (IC_COLOR*)pc_colorWithMinimumSaturation:(CGFloat)minSaturation
{
	IC_COLOR *tempColor = self; //[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	
	if ( tempColor != nil )
	{
		CGFloat hue = 0.0;
		CGFloat saturation = 0.0;
		CGFloat brightness = 0.0;
		CGFloat alpha = 0.0;
        
		[tempColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
		
		if ( saturation < minSaturation )
		{
			return [IC_COLOR colorWithHue:hue saturation:minSaturation brightness:brightness alpha:alpha];
		}
	}
	
	return self;
}


- (BOOL)pc_isBlackOrWhite
{
	IC_COLOR *tempColor = self; //[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	
	if ( tempColor != nil )
	{
		CGFloat r, g, b, a;
        
		[tempColor getRed:&r green:&g blue:&b alpha:&a];
		
		if ( r > .91 && g > .91 && b > .91 )
			return YES; // white
        
		if ( r < .09 && g < .09 && b < .09 )
			return YES; // black
	}
	
	return NO;
}


- (BOOL)pc_isContrastingColor:(IC_COLOR*)color
{
	IC_COLOR *backgroundColor = self; //[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	IC_COLOR *foregroundColor = color; //[color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	
	if ( backgroundColor != nil && foregroundColor != nil )
	{
		CGFloat br, bg, bb, ba;
		CGFloat fr, fg, fb, fa;
		
		[backgroundColor getRed:&br green:&bg blue:&bb alpha:&ba];
		[foregroundColor getRed:&fr green:&fg blue:&fb alpha:&fa];
        
		CGFloat bLum = 0.2126 * br + 0.7152 * bg + 0.0722 * bb;
		CGFloat fLum = 0.2126 * fr + 0.7152 * fg + 0.0722 * fb;
        
		CGFloat contrast = 0.;
		
		if ( bLum > fLum )
			contrast = (bLum + 0.05) / (fLum + 0.05);
		else
			contrast = (fLum + 0.05) / (bLum + 0.05);
        
		//return contrast > 3.0; //3-4.5 W3C recommends a minimum ratio of 3:1
		return contrast > 1.6;
	}
	
	return YES;
}


@end


@implementation PCCountedColor

- (id)initWithColor:(IC_COLOR*)color count:(NSUInteger)count
{
	self = [super init];
	
	if ( self )
	{
		self.color = color;
		self.count = count;
	}
	
	return self;
}


- (NSComparisonResult)compare:(PCCountedColor*)object
{
	if ( [object isKindOfClass:[PCCountedColor class]] )
	{
		if ( self.count < object.count )
		{
			return NSOrderedDescending;
		}
		else if ( self.count == object.count )
		{
			return NSOrderedSame;
		}
	}
    
	return NSOrderedAscending;
}


@end
#endif
