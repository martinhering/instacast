//
//  FeedDocument.h
//  Instacast
//
//  Created by Martin Hering on 30.08.11.
//  Copyright (c) 2011 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifdef __IPHONE_5_0

@class SQFeed;

@interface FeedDocument : UIDocument

@property (nonatomic, assign) SQFeed* feed;

@end

#endif