//
//  ICMetadata.h
//  InstacastMac
//
//  Created by Martin Hering on 26.06.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CMTime.h>

@class AVMetadataItem;

typedef void (^ICMetadataCompletionHandler)(BOOL success, NSError* error);

@interface ICMetadataItem : NSObject
@property CMTime start;
@property CMTime end;

- (NSTimeInterval) durationWithTrackDuration:(NSTimeInterval)trackDuration;
@end

@interface ICMetadataChapter : ICMetadataItem
@property (strong) NSString* title;
@property (strong) NSString* label;
@property (strong) NSURL* link;
@property (strong) NSString* linkLabel;
@end

@interface ICMetadataImage : ICMetadataItem
/* data */
@property NSData* data;
@property NSString* mimeType;
@property NSString* label;
/* references */
@property NSURL* url;
@property AVMetadataItem* item;

- (BOOL) loadPlatformImageWithCompletion:(void (^)(id platformImage))completion;
- (BOOL) loadPlatformImageScaleToWidth:(CGFloat)scaledWidth completion:(void (^)(id platformImage))completion;
@end


@interface ICMetadataAsset : NSObject

@property (strong) NSString* title;
@property (strong) NSString* subtitle;
@property (strong) NSString* album;
@property (strong) NSString* artist;
@property (strong) NSDate* pubDate;

@property CMTime duration;
@property BOOL video;
@property CGSize pictureSize;

@property BOOL podcast;
@property (strong) NSString* podcastDescription;
@property (strong) NSURL* feedURL;
@property (strong) NSString* episodeGuid;


@property (strong) NSArray* chapters;
@property (strong) NSArray* images;

@property (strong) NSArray* metadata;

@end