//
//  EpisodesTableViewCell.h
//  Instacast
//
//  Created by Martin Hering on 29.12.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IOS8FixedSeparatorTableViewCell.h"

@class EpisodePlayComboButton;

@interface EpisodesTableViewCell : IOS8FixedSeparatorTableViewCell {

}

@property (nonatomic, strong) id objectValue;
@property (nonatomic, strong, readonly) EpisodePlayComboButton* playAccessoryButton;
@property (nonatomic, strong, readonly) UIImageView* iconView;

@property (nonatomic) BOOL canDelete;
@property (nonatomic, readonly) BOOL showsDeleteControl;

@property (nonatomic) BOOL embedded;
@property (nonatomic, strong, readonly) UIPanGestureRecognizer* panRecognizer;
@property (nonatomic) BOOL topSeparator;

- (void) updatePlayComboButtonState;
- (void) updatePlayedAndStarredState;

+ (CGFloat) proposedHeightWithObjectValue:(id)objectValue tableSize:(CGSize)tableSize imageSize:(CGSize)size embedded:(BOOL)embedded editing:(BOOL)editing;

@property (nonatomic, copy) void (^panDidBegin)(NSIndexPath* cellIndexPath);
@property (nonatomic, copy) void (^didPanRight)(NSIndexPath* cellIndexPath);
@property (nonatomic, copy) void (^shouldDelete)(NSIndexPath* cellIndexPath);
@property (nonatomic, copy) void (^shouldShowMore)(NSIndexPath* cellIndexPath);

- (void) cancelDelete:(id)sender;

@end
