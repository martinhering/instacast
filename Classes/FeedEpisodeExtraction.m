//
//  FeedEpisodeExtraction.m
//  Instacast
//
//  Created by Martin Hering on 07.12.11.
//  Copyright (c) 2011 Vemedio. All rights reserved.
//

#import "FeedEpisodeExtraction.h"

#import "ICFeedParser.h"
#import "ICFeed.h"
#import "ICEpisode.h"

@implementation FeedEpisodeExtraction


+ (void) extractEpisodeWithGuid:(NSString*)guid fromFeedWithURL:(NSURL*)aFeedURL completion:(FeedEpisodeExtractionCompletionBlock)completionBlock
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSError* error = nil;
        ICFeed* feed = [ICFeedParser parsedFeedWithURL:aFeedURL error:&error];

        ICEpisode* extractedEpisode = nil;
        for(ICEpisode* episode in feed.episodes) {
            if ([episode.guid isEqualToString:guid]) {
                extractedEpisode = episode;
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            
            CDEpisode* persistentEpisode = [DMANAGER addUnsubscribedFeed:feed andEpisode:extractedEpisode];
            [DMANAGER save];
            
            if (!error) {
                if (completionBlock) {
                    completionBlock(persistentEpisode, nil);
                }
            }
            else {
                if (completionBlock) {
                    completionBlock(nil, nil);
                }
            }
            
            
        });
    });
}

@end
