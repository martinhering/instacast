//
//  PlaybackControlViewController.h
//  Instacast
//
//  Created by Martin Hering on 09.10.12.
//
//

#import <UIKit/UIKit.h>

@class ICProgressSlider;

@interface PlaybackControlsViewController : UIViewController

+ (id) playbackControlViewController;

@property (nonatomic, weak) IBOutlet UIImageView* backgroundView;
@property (nonatomic, weak) IBOutlet UIView* controllerButtonGroup;
@property (nonatomic, weak) IBOutlet UILabel* elapsedTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel* remainingTimeLabel;
@property (nonatomic, weak) IBOutlet UIButton* playButton;
@property (nonatomic, weak) IBOutlet UIButton* backButton;
@property (nonatomic, weak) IBOutlet UIButton* forwardButton;
@property (nonatomic, weak) IBOutlet ICProgressSlider* timeSlider;

@property (nonatomic, weak) IBOutlet UIButton* volumeMinButton;
@property (nonatomic, weak) IBOutlet UIButton* volumeMaxButton;
@property (nonatomic, weak) IBOutlet UIButton* actionButton;
@property (nonatomic, weak) IBOutlet UIButton* bookmarkButton;

@property (nonatomic, weak) IBOutlet UIView* controllerView;
@property (nonatomic, weak) IBOutlet UIView* toolsView;

@property (nonatomic, readonly, getter = isMuted) BOOL muted;
@property (nonatomic, assign) float volume;
@property (nonatomic, assign) BOOL shown;

@property (nonatomic, strong) UIColor* tintColor;

@property (nonatomic, strong) MPVolumeView* volumeView;
@property (nonatomic, strong) MPVolumeView* routeButton;


- (void) createVolumeViews;

- (IBAction) beginBackwardAction:(id)sender;
- (IBAction) endBackwardAction:(id)sender;
- (IBAction) cancelBackwardAction:(id)sender;
- (IBAction) beginForwardAction:(id)sender;
- (IBAction) endForwardAction:(id)sender;
- (IBAction) cancelForwardAction:(id)sender;

- (IBAction) beganChangingProgress:(id)sender;
- (IBAction) progress:(id)sender;
- (IBAction) endChangingProgress:(id)sender;

- (IBAction) togglePlay:(id)sender;

- (IBAction) addBookmark:(id)sender;

- (void) updateTimeUI;
- (void) updateTimeUIDuringSliding;
- (void) updateTimeWhenLoading;
- (void) updateControlsUI;
- (void) resetControlUI;
@end
