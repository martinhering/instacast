//
//  CDChapter.h
//  Instacast
//
//  Created by Martin Hering on 07.08.12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CDBase.h"

@class CDEpisode;

@interface CDChapter : CDBase

@property (nonatomic) int32_t index;
@property (nonatomic, strong) NSString * title;
@property (nonatomic) double duration;
@property (nonatomic) double timecode;
@property (nonatomic, strong) NSURL * linkURL;
@property (nonatomic, weak) CDEpisode *episode;

@end
