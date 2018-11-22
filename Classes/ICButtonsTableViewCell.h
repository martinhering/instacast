//
//  ICButtonsTableViewCell.h
//  Instacast
//
//  Created by Martin Hering on 19.08.14.
//
//

#import <UIKit/UIKit.h>
#import "IOS8FixedSeparatorTableViewCell.h"

@interface ICButtonsTableViewCell : IOS8FixedSeparatorTableViewCell

+ (UIButton*) configuredButtonWithTitle:(NSString*)title imageNamed:(NSString*)imageName;

@property (nonatomic, strong) NSArray* buttons;
@property (nonatomic) BOOL allowsMultiSelection;
@property (nonatomic) BOOL allowsEmptySelection;

@property (nonatomic, copy) void(^buttonTappedAtIndex)(UIButton* sender, NSInteger index);

@property (nonatomic, strong, readonly) UIScrollView* contentScrollView;
@end
