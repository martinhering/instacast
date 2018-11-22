//
//  CDBookmark.h
//  Instacast
//
//  Created by Martin Hering on 07.08.12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CDBase.h"

@interface CDBookmark : CDBase

@property (nonatomic, strong) NSString * episodeHash;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSURL * feedURL;
@property (nonatomic, strong) NSURL * imageURL;
@property (nonatomic, strong) NSString * episodeGuid;
@property (nonatomic, strong) NSString * feedTitle;
@property (nonatomic, strong) NSString * episodeTitle;
@property (nonatomic) double position;

@end
