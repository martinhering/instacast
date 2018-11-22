//
//  FeedEpisodeExtraction.h
//  Instacast
//
//  Created by Martin Hering on 07.12.11.
//  Copyright (c) 2011 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CDFeed, CDEpisode;

typedef void (^FeedEpisodeExtractionCompletionBlock)(CDEpisode* episode, NSError* error);

@interface FeedEpisodeExtraction : NSObject {
}

+ (void) extractEpisodeWithGuid:(NSString*)guid
                fromFeedWithURL:(NSURL*)feedURL
                     completion:(FeedEpisodeExtractionCompletionBlock)completion;

@end
