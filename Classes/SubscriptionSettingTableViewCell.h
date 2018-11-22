//
//  SubscriptionSettingTableViewCell.h
//  Instacast
//
//  Created by Martin Hering on 02.09.13.
//
//

#import <UIKit/UIKit.h>

@interface SubscriptionSettingTableViewCell : UITableViewCell

@property (nonatomic, strong, readonly) UISwitch* switchControl;
@property (nonatomic, strong, readonly) UIImageView* disclosureView;
@end
