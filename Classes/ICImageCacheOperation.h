//
//  ICImageCacheOperation.h
//  InstacastMac
//
//  Created by Martin Hering on 08.01.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//


@interface ICImageCacheOperation : VMHTTPOperation

- (id) initWithURL:(NSURL*)url size:(NSInteger)size grayscale:(BOOL)grayscale;

#if TARGET_OS_IPHONE
@property (copy) void (^didEndBlock)(UIImage* image, NSError* error);
#else
@property (copy) void (^didEndBlock)(NSImage* image, NSError* error);
#endif

@property (weak) id sender;

@end
