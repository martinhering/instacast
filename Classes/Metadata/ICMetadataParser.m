//
//  ICMetadataParser.m
//  InstacastMac
//
//  Created by Martin Hering on 26.06.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "ICMetadataParser.h"
#import "_ICMetadataPSCParser.h"
#import "_ICMetadataAssetParser.h"


@interface ICMetadataAsset (Private)
@property (nonatomic, strong) AVAsset* asset;
@end

@interface ICMetadataParser ()
@property (nonatomic, strong) NSURL* assetURL;
@property (nonatomic, strong, readwrite) AVAsset* asset;
@property (nonatomic, strong) NSURL* pscURL;
@property (nonatomic, strong) NSData* pscData;
@property (nonatomic, strong, readwrite) ICMetadataAsset* metadataAsset;
@end


@implementation ICMetadataParser

+ (NSArray*) _URLBlacklist
{
    return @[ @"http://zwei-schnacker.podspot.de/files/Schnack%20Nr37a.mp3",
              @"http://feedproxy.google.com/~r/matrixmasters/iGAG/",
              @"http://www.medienkuh.de/media/podcast/"];
}

- (id) initWithAssetURL:(NSURL*)url
{
    if (self = [self init]) {
        _assetURL = url;
    }
    return self;
}

- (id) initWithAsset:(AVAsset*)asset
{
    if (self = [self init]) {
        _asset = asset;
    }
    return self;
}

- (id) initWithPSCURL:(NSURL*)url
{
    if (self = [self init]) {
        _pscURL = url;
    }
    return self;
}

- (id) initWithPSCData:(NSData*)data
{
    if (self = [self init]) {
        _pscData = data;
    }
    return self;
}

#pragma mark -

- (void) _loadPSCData:(NSData*)data completionHandler:(ICMetadataCompletionHandler)completionHandler
{
    ICMetadataAsset* metadataAsset = [[ICMetadataAsset alloc] init];
    
    _ICMetadataPSCParser* parser = [[_ICMetadataPSCParser alloc] initWithData:data metadataAsset:metadataAsset];
    [parser loadAsynchronouslyWithCompletionHandler:^(BOOL success, NSError *error) {
        
        if (success)
        {
            [self _postFlightMetadataItems:metadataAsset.chapters];
            [self _postFlightMetadataItems:metadataAsset.images];
            
            self.metadataAsset = metadataAsset;
        }
        
        completionHandler(success, error);
    }];
}

- (void) _loadPSCURL:(NSURL*)url completionHandler:(ICMetadataCompletionHandler)completionHandler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSData* data = [NSData dataWithContentsOfURL:url];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _loadPSCData:data completionHandler:completionHandler];
        });
    });
}

- (void) _loadAsset:(AVAsset*)asset completionHandler:(ICMetadataCompletionHandler)completionHandler
{
    NSArray* blackList = [[self class] _URLBlacklist];
    
    DebugLog(@"loading metadata: %@", [((AVURLAsset*)asset).URL absoluteString]);
    
    for(NSString* blackListedPrefix in blackList) {
        if ([[((AVURLAsset*)asset).URL absoluteString] hasPrefix:blackListedPrefix]) {
            completionHandler(NO, nil);
            return;
        }
    }
    
    ICMetadataAsset* metadataAsset = [[ICMetadataAsset alloc] init];
    metadataAsset.asset = asset;
    
    _ICMetadataAssetParser* parser = [[_ICMetadataAssetParser alloc] initWithAVAsset:asset metadataAsset:metadataAsset];
    [parser loadAsynchronouslyWithCompletionHandler:^(BOOL success, NSError *error) {
        
        if (success)
        {
            [self _postFlightMetadataItems:metadataAsset.chapters];
            [self _postFlightMetadataItems:metadataAsset.images];
            
            self.metadataAsset = metadataAsset;
        }
        
        completionHandler(success, error);
    }];
}


- (void) loadAsynchronouslyWithCompletionHandler:(ICMetadataCompletionHandler)completionHandler
{
    if (self.pscData) {
        [self _loadPSCData:self.pscData completionHandler:completionHandler];
    }
    else if (self.pscURL)
    {
        [self _loadPSCURL:self.pscURL completionHandler:completionHandler];
    }
    else if (self.asset) {
        [self _loadAsset:self.asset completionHandler:completionHandler];
    }
    else if (self.assetURL) {
        self.asset = [AVURLAsset URLAssetWithURL:self.assetURL options:nil];
        [self _loadAsset:self.asset completionHandler:completionHandler];
    }
    else {
        completionHandler(NO, nil);
    }
}

#pragma mark -

- (void) _postFlightMetadataItems:(NSArray*)metadataItems
{
    NSInteger c = [metadataItems count];
    NSInteger i = 0;
    
    for(ICMetadataItem* item in metadataItems)
    {
        ICMetadataChapter* chapter = (ICMetadataChapter*)item;
        
        if ([item isKindOfClass:[ICMetadataChapter class]])
        {
            NSString* title = chapter.title;
            NSURL* link = chapter.link;
            
            NSUInteger numberOfMatches = [title numberOfMatchesUsingRegex:kVMFoundationURLRegexPattern];
            NSString* titleHref = [title stringByMatchingRegex:kVMFoundationURLRegexPattern capture:1];
            if (!link && numberOfMatches == 1 && titleHref && ![[NSURL URLWithString:titleHref] isFileURL])
            {
                chapter.link = [NSURL URLWithString:titleHref];

                NSRange range = [title rangeOfString:titleHref];
                title = [title stringByReplacingCharactersInRange:range withString:@""];
                title = [title stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -–.,:;&"]];
                
                chapter.title = title;
            }


            if ([chapter.title length] == 0)
            {
                long t = (long)CMTimeGetSeconds(item.start);
                if (t < 3600) {
                    chapter.title = [NSString stringWithFormat:@"%02ld:%02ld", (long)((t/60)%60), (long)(t%60)];
                } else {
                    chapter.title = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)(t/3600), (long)((t/60)%60), (long)(t%60)];
                }
            }
        }

        if (item.end.value != 0) {
            continue;
        }
        
        ICMetadataItem* nextItem = (i+1<c) ? metadataItems[i+1] : nil;
        
        if (nextItem) {
            item.end = nextItem.start;
        }
        else {
            CMTime t = CMTimeMake(0, 1000);
            t.flags &= ~kCMTimeFlags_Valid;
            t.flags |= kCMTimeFlags_PositiveInfinity;
            item.end = t;
        }
        
        i++;
    }
}

@end
