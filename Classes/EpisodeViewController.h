//
//  EpisodeViewController.h
//  Instacast
//
//  Created by Martin Hering on 12.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>


@class CDEpisode;
@interface EpisodeViewController : UIViewController <UIWebViewDelegate>

+ (EpisodeViewController*) episodeViewController;

@property (nonatomic, strong) CDEpisode* episode;

@property (nonatomic, copy) void(^didFinishLoading)();

@end
