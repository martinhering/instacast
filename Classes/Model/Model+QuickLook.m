//
//  Model+QuickLook.m
//  InstacastMac
//
//  Created by Martin Hering on 04.07.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import "Model+QuickLook.h"
#import "ImageCacheManager.h"
#import "CDEpisode+ShowNotes.h"

@implementation CDFeed (QuickLook)

- (NSURL *)previewItemURL
{
    NSURL* fileURL = [ImageCacheManager fileURLToCachedImageForImageURL:self.imageURL size:0 grayscale:NO];
    return ([[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]]) ? fileURL : nil;
}

- (NSString *)previewItemTitle
{
    return self.title;
}

@end


@implementation CDEpisode (QuickLook)

- (NSURL*) _processImageURL
{
    NSURL* imageURL = self.imageURL;
    if (!imageURL) {
        imageURL = self.feed.imageURL;
    }
    
    return imageURL;
}

- (NSURL *)previewItemURL
{
    NSURL* fileURL = [ImageCacheManager fileURLToCachedImageForImageURL:[self _processImageURL] size:0 grayscale:NO];
    return ([[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]]) ? fileURL : nil;
}

- (NSString *)previewItemTitle
{
    return [self cleanTitleUsingFeedTitle:self.feed.title];
}


@end