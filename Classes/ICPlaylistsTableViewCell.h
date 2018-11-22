//
//  ICPlaylistsTableViewCell.h
//  Instacast
//
//  Created by Martin Hering on 10.08.13.
//
//

#import <UIKit/UIKit.h>
#import "IOS8FixedSeparatorTableViewCell.h"

@interface ICPlaylistsTableViewCell : IOS8FixedSeparatorTableViewCell
@property (nonatomic, readonly, strong) UILabel* numberLabel;
@property (nonatomic) CGFloat imageYOffset;

@property (nonatomic, strong) CDList* objectValue;
@end
