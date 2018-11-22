//
//  MainSidebarPlayerControl.h
//  Instacast
//
//  Created by Martin Hering on 10.08.13.
//
//

#import <UIKit/UIKit.h>

@interface ICNowPlayingActivityControl : UIControl

@property (nonatomic, strong, readonly) UILabel* label1;
@property (nonatomic, strong, readonly) UILabel* label2;
@property (nonatomic, strong, readonly) UIButton* rightButton;
@property (nonatomic, strong, readonly) UIProgressView* progressView;

@property (nonatomic) BOOL marqueePaused;
@end
