//
//  CDMedium.h
//  Instacast
//
//  Created by Martin Hering on 07.08.12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CDBase.h"

@class CDEpisode;

@interface CDMedium : CDBase

@property (nonatomic, strong) NSURL * fileURL;
@property (nonatomic, strong) NSString * mimeType;
@property (nonatomic) int64_t byteSize;
@property (nonatomic, strong) CDEpisode *episode;

@end
