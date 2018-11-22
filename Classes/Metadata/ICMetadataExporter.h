//
//  ICMetadataExporter.h
//  InstacastMac
//
//  Created by Martin Hering on 20.11.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICMetadata.h"

@interface ICMetadataExporter : NSObject

- (id) initWithAsset:(ICMetadataAsset*)metadataAsset;

- (void) exportAsynchronouslyWithCompletionHandler:(ICMetadataCompletionHandler)completionHandler;
@end
