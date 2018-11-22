//
//  ICMetadataParser.h
//  InstacastMac
//
//  Created by Martin Hering on 26.06.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICMetadata.h"

@class AVAsset;
@class ICMetadataAsset;

@interface ICMetadataParser : NSObject

- (id) initWithAssetURL:(NSURL*)url;
- (id) initWithAsset:(AVAsset*)asset;
- (id) initWithPSCURL:(NSURL*)url;
- (id) initWithPSCData:(NSData*)data;

- (void) loadAsynchronouslyWithCompletionHandler:(ICMetadataCompletionHandler)completionHandler;

@property (nonatomic, strong, readonly) ICMetadataAsset* metadataAsset;
@end
