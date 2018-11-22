//
//  VDModalInfo.h
//  SnowMobile
//
//  Created by Andreas Zimmermann on 24.03.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, VDModalInfoAnimation) {
	VDModalInfoAnimationFade,
	VDModalInfoAnimationScaleDown,
	VDModalInfoAnimationScaleUp,
    VDModalInfoAnimationMoveDown,
};

typedef NS_ENUM(NSInteger, VDModalInfoAlignment) {
	VDModalInfoAlignmentCenter,
	VDModalInfoAlignmentTop,
    VDModalInfoAlignmentPhonePlayer,
    VDModalInfoAlignmentTabletPlayer,
    VDModalInfoAlignmentBottomToolbar,
};


@interface VDModalInfo : UIView

+ (instancetype) modalInfo;
+ (instancetype) modalInfoWithScreenRect:(CGRect)rect;

+ (instancetype) modalInfoWithProgressLabel:(NSString*)progressLabel;

@property (readonly, strong) UILabel* textLabel;
@property (readonly, strong) UIImageView* imageView;

@property (getter=isClosableByTap) BOOL closableByTap;
@property (getter=canTapThrough) BOOL tapThrough;
@property CGSize size;
@property VDModalInfoAnimation animation;
@property VDModalInfoAlignment alignment;
@property (getter=isShowingProgress) BOOL showingProgress;
@property (getter=isNavigationAndToolbarEnabled) BOOL navigationAndToolbarEnabled;
@property (nonatomic, strong) UIView* contextView;
@property (nonatomic) double progress;


- (void) show;
- (void) close;

- (void) showWithCompletion:(void (^)(void))completion;
- (void) closeWithCompletion:(void (^)(void))completion;

- (void) updateAppearance;
@end
