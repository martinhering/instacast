//
//  AlertStylePopoverController.h
//  Instacast
//
//  Created by Martin Hering on 03.07.13.
//
//

#import <UIKit/UIKit.h>

@interface VMAlertStylePopoverController : UIViewController

+ (instancetype) controllerWithContentController:(UIViewController*)contentController;

@property (nonatomic, strong, readonly) UIViewController* contentController;
@property (nonatomic, strong, readonly) UIView* backdropView;

@property (nonatomic) BOOL enableBackgroundDismiss;
@property (nonatomic, copy) void (^shouldDismiss)();

@property CGFloat cornerRadius;
@end
