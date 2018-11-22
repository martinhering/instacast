//
//  ImageCacheManager.h
//  Instacast
//
//  Created by Martin Hering on 16.06.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ICImageCacheOperation;

@interface ImageCacheManager : NSObject

+ (NSInteger) scalingFactor;
+ (NSURL*) cacheURLForImageURL:(NSURL*)url size:(NSInteger)size;
+ (NSURL*) fileURLToCachedImageForImageURL:(NSURL*)url size:(NSInteger)size grayscale:(BOOL)grayscale;
+ (void) loadImageForURL:(NSURL*)url size:(NSInteger)size grayscale:(BOOL)grayscale completion:(void (^)(IC_IMAGE* platformImage, NSError* error))completion;


+ (ImageCacheManager*) sharedImageCacheManager;

- (void) addImageCacheOperation:(ICImageCacheOperation*)operation sender:(id)sender;
- (void) cancelImageCacheOperationsWithSender:(id)sender;
- (void) imageForURL:(NSURL*)url size:(NSInteger)size grayscale:(BOOL)grayscale sender:(id)sender completion:(void (^)(IC_IMAGE* image))completionHandler;

- (void) cacheImage:(IC_IMAGE*)image forURL:(NSURL*)url size:(NSInteger)size grayscale:(BOOL)grayscale;
+ (IC_IMAGE*) grayscaleImageForImage:(IC_IMAGE*)image;

- (IC_IMAGE*) localImageForImageURL:(NSURL*)url size:(NSInteger)size grayscale:(BOOL)grayscale;

- (void) clearCachedImagesOfFeed:(CDFeed*)feed;
- (BOOL) clearTheFuckingCache;

@end
