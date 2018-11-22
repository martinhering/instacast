//
//  BookmarkTableViewCell.h
//  Instacast
//
//  Created by Martin Hering on 04.01.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IOS8FixedSeparatorTableViewCell.h"

@interface PlayerBookmarksTableViewCell : IOS8FixedSeparatorTableViewCell

@property (nonatomic, readonly, strong) UILabel* timeLabel;

+ (CGFloat) proposedHeightWithTitle:(NSString*)title tableBounds:(CGRect)tableBounds;
@end
