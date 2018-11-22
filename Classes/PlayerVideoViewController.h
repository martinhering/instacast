//
//  PlayerVideoFullscreenViewController.h
//  Instacast
//
//  Created by Martin Hering on 06/08/14.
//
//

#import <UIKit/UIKit.h>

@class PlayerView;

@interface PlayerVideoViewController : UIViewController

+ (instancetype) viewController;

@property (nonatomic, strong) PlayerView* playerView;
@property (nonatomic) CGSize videoSize;

@property (nonatomic, readonly) BOOL fullscreen;

- (void) setFullscreen:(BOOL)fullscreen animated:(BOOL)animated completion:(void (^)(void))completion;
@end
