//
//  ICNowPlayingActivityViewController.h
//  Instacast
//
//  Created by Martin Hering on 26.08.14.
//
//

#import <UIKit/UIKit.h>

@class ICNowPlayingActivityControl;

@interface ICNowPlayingActivityViewController : UIViewController

@property (nonatomic, strong, readonly) ICNowPlayingActivityControl* nowPlayingControl;
@property (nonatomic, readonly) BOOL visible;

@end
