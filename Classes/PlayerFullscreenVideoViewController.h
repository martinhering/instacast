//
//  PlayerFullscreenVideoViewController.h
//  Instacast
//
//  Created by Martin Hering on 06/08/14.
//
//

#import <UIKit/UIKit.h>

@interface PlayerFullscreenVideoViewController : UIViewController

+ (instancetype) viewController;

@property (nonatomic, weak) IBOutlet UIButton* doneButton;

@property (nonatomic) BOOL controlsVisible;
@end
