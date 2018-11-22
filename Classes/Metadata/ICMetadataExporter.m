//
//  ICMetadataExporter.m
//  InstacastMac
//
//  Created by Martin Hering on 20.11.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//


#import "ICMetadataExporter.h"
#import "ICMetadata.h"

#import <AVFoundation/AVFoundation.h>

@interface ICMetadataAsset (Private)
@property (nonatomic, strong) AVAsset* asset;
@end

@interface ICMetadataExporter ()
@property (nonatomic, strong, readwrite) ICMetadataAsset* metadataAsset;
@end

@implementation ICMetadataExporter

- (id) initWithAsset:(ICMetadataAsset*)metadataAsset
{
    if ((self = [self init])) {
        _metadataAsset = metadataAsset;
    }
    return self;
}

- (void) exportAsynchronouslyWithCompletionHandler:(ICMetadataCompletionHandler)completionHandler
{
    AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:self.metadataAsset.asset presetName:AVAssetExportPresetPassthrough];
    
    NSArray* fileTypes = session.supportedFileTypes;

    if (completionHandler) {
        completionHandler(NO, nil);
    }
}
@end
