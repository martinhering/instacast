//
//  SubscriptionTableViewCell.h
//  Instacast
//
//  Created by Martin Hering on 29.12.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IOS8FixedSeparatorTableViewCell.h"

@class CDFeed;

@interface SubscriptionTableViewCell : IOS8FixedSeparatorTableViewCell

@property (nonatomic, readonly, strong) UILabel* detailTextLabel2;
@property (nonatomic, readonly, strong) UILabel* numberLabel;
@property (nonatomic, strong) UIColor* tableViewBackgroundColor;

@property (nonatomic, strong) CDFeed* objectValue;
@end
