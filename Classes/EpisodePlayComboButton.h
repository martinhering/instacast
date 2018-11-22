//
//  EpisodePlayComboButton.h
//  Instacast
//
//  Created by Martin Hering on 16.07.13.
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, EpisodePlayButtonComboState) {
    kEpisodePlayButtonComboStateOutline,
    kEpisodePlayButtonComboStateHolding,
    kEpisodePlayButtonComboStateFilling,
    kEpisodePlayButtonComboStateFilled
};

@interface EpisodePlayComboButton : UIButton

+ (instancetype) button;

@property (nonatomic) EpisodePlayButtonComboState comboState;
@property (nonatomic) double fillingProgress;
@property (nonatomic, strong) id userInfo;

@end
