//
//  AlertStylePopoverController.h
//  Instacast
//
//  Created by Martin Hering on 03.07.13.
//
//

#import <UIKit/UIKit.h>

@interface AlertStylePopoverController : UIViewController

+ (instancetype) controllerWithContentController:(UIViewController*)contentController;

@property (nonatomic, strong, readonly) UIViewController* contentController;
@property (nonatomic, strong, readonly) UIView* backdropView;


@end
