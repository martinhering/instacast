//
//  CacheOperation_iOS7.h
//  Instacast
//
//  Created by Martin Hering on 22/07/13.
//
//

#import <Foundation/Foundation.h>

extern NSString* kUserDefaultsResumeInfoKey;

@protocol CacheOperationDelegate;

@interface CacheOperation_iOS7 : NSOperation <NSURLSessionDownloadDelegate>

- (id) initWithURL:(NSURL*)remoteURL localURL:(NSURL*)localURL identifier:(NSString*)identifier expectedContentLength:(long long)expectedContentLength;
+ (void) removeCacheForRemoteURL:(NSURL*)remoteURL atLocalURL:(NSURL*)url;
+ (void) deleteResumeInfoForIdentifier:(NSString*)identifier;

@property (readonly, copy) NSURL* remoteURL;
@property (readonly, copy) NSURL* localURL;
@property (readonly, strong) NSString* identifier;
@property (weak) id<CacheOperationDelegate> delegate;
@property (nonatomic, strong) id userInfo;

@property (readonly) double progress;
@property (readonly) NSTimeInterval estimatedTimeLeft;
@property (readonly) long long expectedContentLength;
@property (readonly, strong) NSDate* startDate;

@property (assign) BOOL failed;
@property (strong) NSString* username;
@property (strong) NSString* password;
@property BOOL suspended;
@property BOOL overwriteCellularLock;

// mark the caching operation as being invoked by the app and not by the user
@property (assign) BOOL automatic;
@end


@protocol CacheOperationDelegate <NSObject>
- (void) cacheOperationHasBeenSuspended:(CacheOperation_iOS7*)operation;
- (void) cacheOperationDidEnd:(CacheOperation_iOS7*)operation;
- (void) cacheOperation:(CacheOperation_iOS7*)operation didLoadNumberOfBytes:(int64_t)numberOfBytes;
//- (void) cacheOperationDidFail:(CacheOperation_iOS7*)operation;
@end
