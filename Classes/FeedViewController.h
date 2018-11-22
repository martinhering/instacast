//
//  FeedViewController.h
//  Instacast
//
//  Created by Martin Hering on 10.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CDFeed;

@interface FeedViewController : UIViewController {

}

+ (FeedViewController*) feedViewController;

@property (nonatomic, strong) CDFeed* feed;

@end
