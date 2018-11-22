//
//  ICChapter.h
//  InstacastFeedIndexer
//
//  Created by Martin Hering on 24.01.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ICEpisode;

@interface ICChapter : NSObject

@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSURL* linkURL;
@property (nonatomic, strong) NSURL* imageURL;
@property (nonatomic) NSTimeInterval time;
@property (nonatomic) NSTimeInterval duration;

@property (nonatomic, weak) ICEpisode* episode;

@end
