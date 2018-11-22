//
//  PlayInfoViewController2.h
//  Instacast
//
//  Created by Martin Hering on 02.08.14.
//
//

#import <UIKit/UIKit.h>

@class PlayerVideoViewController;

@interface PlayerInfoViewController_v5 : UITableViewController

+ (instancetype) viewController;

@property (nonatomic, strong) PlayerVideoViewController* videoViewController;

@property (nonatomic, strong) UIImage* image;
@property (nonatomic) CGFloat bottomScrollInset;

- (void) layoutHeaderView;
- (void) reload;
@end
