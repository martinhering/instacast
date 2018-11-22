//
//  ICErrorSheetViewController.h
//  Instacast
//
//  Created by Martin Hering on 15.05.14.
//
//

#import <UIKit/UIKit.h>

@interface ICErrorSheetViewController : UIViewController

+ (instancetype) sheet;

@property (nonatomic, weak, readonly) UILabel* titleLabel;
@property (nonatomic, weak, readonly) UILabel* messageLabel;

- (void) updateViewLayout;

- (CGFloat) boundingWidthWithMaxWidth:(CGFloat)maxWidth;
@end
