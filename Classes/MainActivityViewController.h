//
//  MainActivityViewController.h
//  Instacast
//
//  Created by Martin Hering on 25.07.14.
//
//

#import <UIKit/UIKit.h>

@interface MainActivityViewController : UIViewController

+ (instancetype) viewController;

@property (nonatomic, readonly) BOOL visible;

@property (nonatomic, strong, readonly) UIControl* nowPlayingControl;
@end
