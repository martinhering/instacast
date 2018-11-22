//
//  BookmarksTableViewCell.h
//  Instacast
//
//  Created by Martin Hering on 13.04.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IOS8FixedSeparatorTableViewCell.h"

@interface BookmarksTableViewCell : IOS8FixedSeparatorTableViewCell

@property (nonatomic, readonly, strong) UILabel* numberLabel;
@property (nonatomic, readonly, strong) UILabel* timeLabel;
@property (nonatomic, assign) BOOL accessoryIndented;
@end
