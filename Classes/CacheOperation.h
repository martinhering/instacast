//
//  CacheOperation.h
//  Instacast
//
//  Created by Martin Hering on 03.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CacheOperationDelegate;

@interface CacheOperation : NSOperation

- (id) initWithURL:(NSURL*)remoteURL localURL:(NSURL*)localURL tempURL:(NSURL*)tempURL identifier:(NSString*)identifier;
+ (void) removeCacheForRemoteURL:(NSURL*)remoteURL atLocalURL:(NSURL*)url tempURL:(NSURL*)tempURL;
+ (void) deleteResumeInfoForRemoteURL:(NSURL*)url;

@property (readonly, copy) NSURL* remoteURL;
@property (readonly, copy) NSURL* localURL;
@property (readonly, strong) NSString* identifier;
@property (readonly) double progress;
@property (readonly) NSTimeInterval estimatedTimeLeft;
@property (weak) id<CacheOperationDelegate> delegate;
@property (nonatomic, strong) id userInfo;
@property long long expectedContentLength;
@property (readonly, strong) NSDate* startDate;
@property (assign) BOOL failed;
@property (strong) NSString* username;
@property (strong) NSString* password;
@property (getter=isSuspended) BOOL suspended;
@property BOOL overwriteCellularLock;

// mark the caching operation as being invoked by the app and not by the user
@property (assign) BOOL automatic;
@end


@protocol CacheOperationDelegate <NSObject>
- (void) cacheOperationHasBeenSuspended:(CacheOperation*)operation;
- (void) cacheOperationDidEnd:(CacheOperation*)operation;
- (void) cacheOperation:(CacheOperation*)operation didLoadNumberOfBytes:(int64_t)numberOfBytes;
@end