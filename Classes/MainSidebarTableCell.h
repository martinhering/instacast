//
//  MainSidebarTableCell.h
//  Instacast
//
//  Created by Martin Hering on 19/07/13.
//
//

#import <UIKit/UIKit.h>
@class MainSidebarItem;

@interface MainSidebarTableCell : UITableViewCell

@property (nonatomic, strong) MainSidebarItem* objectValue;
@property (nonatomic, strong, readonly) UIButton* badgeButton;
@end
