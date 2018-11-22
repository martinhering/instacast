//
//  ICFeedHeaderViewController.h
//  Instacast
//
//  Created by Martin Hering on 01/06/14.
//
//

#import <UIKit/UIKit.h>

@interface ICFeedHeaderViewController : UIViewController

+ (instancetype) viewController;

@property (nonatomic, strong, readonly) UIImageView* imageView;
@property (nonatomic, strong, readonly) UILabel* titleLabel;
@property (nonatomic, strong, readonly) UILabel* subtitleLabel;

@property (nonatomic, copy) void(^action)();

- (void) deselectAnimated:(BOOL)animated;
@end
