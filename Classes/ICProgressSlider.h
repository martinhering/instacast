//
//  ICProgressSlider.h
//  Instacast
//
//  Created by Martin Hering on 31.07.13.
//
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger, ICProgressSliderScrubbingMode) {
	kICProgressSliderScrubbingModeNoScrubbing,
	kICProgressSliderScrubbingModeHiSpeed,
	kICProgressSliderScrubbingModeHalf,
	kICProgressSliderScrubbingModeQuarter,
	kICProgressSliderScrubbingModeFine
};

@interface ICProgressSlider : UIControl

@property (nonatomic, assign) double progress;
@property (nonatomic, assign) double value;
@property (nonatomic, readonly) ICProgressSliderScrubbingMode scrubbingMode;
@property (nonatomic, assign, getter = isScrubbingModesEnabled) BOOL scrubbingModesEnabled;

@property (nonatomic, strong) UIColor* progressColor;
@end
