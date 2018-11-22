//
//  DownloadsTableViewCell.h
//  Instacast
//
//  Created by Martin Hering on 04.09.12.
//
//

#import <UIKit/UIKit.h>


@class EpisodePlayComboButton;

@interface DownloadsTableViewCell : UITableViewCell

@property (nonatomic, readonly, strong) UIProgressView* progressView;
@property (nonatomic, readonly, strong) UILabel* sizeLabel;
@property (nonatomic, readonly, strong) UILabel* timeLabel;
@property (nonatomic, strong, readonly) EpisodePlayComboButton* playAccessoryButton;
@end
