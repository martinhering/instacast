//
//  ICFeed.m
//  ICFeedParser
//
//  Created by Martin Hering on 16.07.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//



#import "ICFeed.h"
#import "ICEpisode.h"

@implementation ICFeed

+ (id) feed
{
    return [[self alloc] init];
}

// as soon as this URL is changed, we also need to change all episode object hashes, because they depend on it

- (void) setSourceURL:(NSURL *)sourceURL
{
    if (_sourceURL != sourceURL) {
        _sourceURL = sourceURL;
        
        for(ICEpisode* episode in self.episodes) {
            episode.objectHash = [[NSString stringWithFormat:@"%@%@", [sourceURL absoluteString], episode.guid] MD5Hash];
        }
    }
}

@end
