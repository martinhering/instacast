//
//  VDModalInfo.m
//  SnowMobile
//
//  Created by Andreas Zimmermann on 24.03.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "VDModalInfo.h"
#import "CircleProgressView.h"

static NSMutableSet* gModelInfos = nil;

@interface VDModalInfo ()

@property (readwrite, strong) UILabel* textLabel;
@property (readwrite, strong) UIImageView* imageView;

@property (strong) UIView* messageView;
@property (strong) UIButton* closeButton;
@property (strong) CircleProgressView* progressIndicator;
@property (strong) UIWindow* parentWindow;
@property (strong) NSTimer* closeTimer;
@end

@implementation VDModalInfo {
    BOOL _closableByTap;
    CGSize _size;
}

+ (VDModalInfo*) modalInfoWithScreenRect:(CGRect)rect
{
    return [[self alloc] initWithFrame:rect];
}

+ (VDModalInfo*) modalInfo
{
	return [[self alloc] initWithFrame:[UIScreen mainScreen].bounds];
}

+ (VDModalInfo*) modalInfoWithProgressLabel:(NSString*)progressLabel
{
    VDModalInfo* modelInfo = [VDModalInfo modalInfo];
    modelInfo.closableByTap = NO;
    modelInfo.tapThrough = NO;
    modelInfo.textLabel.text = progressLabel;
    modelInfo.showingProgress = YES;
    modelInfo.animation = VDModalInfoAnimationScaleUp;
    modelInfo.size = CGSizeMake(125, 125);
    
    return modelInfo;
}

- (id) initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
        if (!gModelInfos) {
            gModelInfos = [[NSMutableSet alloc] init];
        }
        
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.layer.zPosition = 10000;
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
		self.userInteractionEnabled = YES;

		[self flipViewAccordingToStatusBarOrientation:nil];
		
		_messageView = [[UIView alloc] initWithFrame:CGRectZero];
        _messageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		_messageView.autoresizesSubviews = YES;
        _messageView.clipsToBounds = YES;
		CALayer* messageViewLayer = _messageView.layer;
		messageViewLayer.cornerRadius = 10.0f;
		[self addSubview:_messageView];
        
        UIInterpolatingMotionEffect *xAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        xAxis.minimumRelativeValue = [NSNumber numberWithFloat:-15.0];
        xAxis.maximumRelativeValue = [NSNumber numberWithFloat:15.0];
        
        UIInterpolatingMotionEffect *yAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        yAxis.minimumRelativeValue = [NSNumber numberWithFloat:-15.0];
        yAxis.maximumRelativeValue = [NSNumber numberWithFloat:15.0];
        
        UIMotionEffectGroup *group = [[UIMotionEffectGroup alloc] init];
        group.motionEffects = @[xAxis, yAxis];
        [_messageView addMotionEffect:group];
        
		
		_textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_textLabel.backgroundColor = [UIColor clearColor];
		_textLabel.adjustsFontSizeToFitWidth = YES;
		_textLabel.opaque = NO;
		_textLabel.font = [UIFont systemFontOfSize:17.0f];
		_textLabel.textAlignment = NSTextAlignmentCenter;
		[_messageView addSubview:_textLabel];
		
		_imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
		_imageView.contentMode = UIViewContentModeScaleToFill;
		_imageView.opaque = NO;
		_imageView.backgroundColor = [UIColor clearColor];
		[_messageView addSubview:_imageView];
		
		_closeButton = [[UIButton alloc] initWithFrame:frame];
		_closeButton.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		_closeButton.backgroundColor = [UIColor clearColor];
		[_closeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:_closeButton];
        
        _progressIndicator = [[CircleProgressView alloc] initWithFrame:CGRectMake(0, 0, 37, 37)];
		_progressIndicator.hidden = YES;
        _progressIndicator.tintColor = ICTintColor;
		[_messageView addSubview:_progressIndicator];
        
        _progress = -1;
		
		_closableByTap = YES;
		[self setSize:CGSizeMake(120, 120)];
        
        [self updateAppearance];
	}
	
	return self;
}

- (void) updateAppearance
{
    _messageView.backgroundColor = (![ICAppearanceManager sharedManager].nightMode) ? [UIColor colorWithWhite:1 alpha:0.9] : [UIColor colorWithWhite:0 alpha:0.93];
    _textLabel.textColor = ICTextColor;
}

- (void)flipViewAccordingToStatusBarOrientation:(NSNotification *)notification
{
    if (!IS_IOS8)
    {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        
        CGFloat angle = 0.0;
        
        switch (orientation) { 
            case UIInterfaceOrientationPortraitUpsideDown:
                angle = M_PI; 
                break;
            case UIInterfaceOrientationLandscapeLeft:
                angle = - M_PI / 2.0f;
                break;
            case UIInterfaceOrientationLandscapeRight:
                angle = M_PI / 2.0f;
                break;
            default: // as UIInterfaceOrientationPortrait
                angle = 0.0;
                break;
        } 
        
        self.transform = CGAffineTransformMakeRotation(angle);
        self.frame = self.bounds;
    }
}

#pragma mark -

- (BOOL) isClosableByTap
{
    return _closableByTap;
}

- (void) setClosableByTap:(BOOL)flag
{
	if (_closableByTap != flag) {
		_closableByTap = flag;
		
		self.closeButton.hidden = !_closableByTap;
	}
}

- (CGSize) size
{
    return _size;
}

- (void) setSize:(CGSize)value
{
	if (!CGSizeEqualToSize(_size, value)) {
		_size = value;
	}
	
	CGRect frame = self.frame;
	
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	if (!IS_IOS8 && UIInterfaceOrientationIsLandscape(orientation)) {
		CGFloat tmp = frame.size.height;
		frame.size.height = frame.size.width;
		frame.size.width = tmp;
	}
	
    CGRect messageViewRect = CGRectMake(floorf((CGRectGetWidth(frame)-_size.width)*0.5f), floorf((CGRectGetHeight(frame)-_size.height)*0.4f), _size.width, _size.height);
    
    void (^applyConstrains)(CGRect*) = ^(CGRect* sourceRect) {
        
        CGRect intersectionRect = CGRectIntersection(frame, *sourceRect);
        if (CGRectGetWidth(intersectionRect) != CGRectGetWidth(*sourceRect)) {
            if (CGRectGetMinX(intersectionRect) != CGRectGetMinX(*sourceRect)) {
                // nach rechts schieben
                (*sourceRect).origin.x += (CGRectGetWidth(*sourceRect) - CGRectGetWidth(intersectionRect));
            } else {
                // nach links schieben
                (*sourceRect).origin.x -= (CGRectGetWidth(*sourceRect) - CGRectGetWidth(intersectionRect));
            }
        }
    };
    
    
    if (self.contextView) {
        CGRect viewRectInWindow = [self.contextView convertRect:self.contextView.bounds toView:nil];
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        switch (orientation) {
            case UIInterfaceOrientationPortraitUpsideDown:
                messageViewRect = CGRectMake(floorf(CGRectGetWidth(frame)-CGRectGetMidX(viewRectInWindow) - _size.width*0.5f), CGRectGetHeight(frame)-CGRectGetMinY(viewRectInWindow)-CGRectGetHeight(viewRectInWindow)-_size.height-10, _size.width, _size.height);
                break;
            case UIInterfaceOrientationLandscapeLeft:
                messageViewRect = CGRectMake(floorf(CGRectGetWidth(frame)-CGRectGetMidY(viewRectInWindow) - _size.width*0.5f), CGRectGetMinX(viewRectInWindow)-_size.height-10-20, _size.width, _size.height);
                break;
            case UIInterfaceOrientationLandscapeRight:
                messageViewRect = CGRectMake(floorf(CGRectGetMidY(viewRectInWindow) - _size.width*0.5f), CGRectGetHeight(frame)-CGRectGetMinX(viewRectInWindow)-CGRectGetHeight(viewRectInWindow)-_size.height - 10, _size.width, _size.height);
                break;
            default: // as UIInterfaceOrientationPortrait
                messageViewRect = CGRectMake(floorf(CGRectGetMidX(viewRectInWindow)-_size.width*0.5f), CGRectGetMinY(viewRectInWindow) - _size.height - 10-20, _size.width, _size.height);
                break;
        }
        applyConstrains(&messageViewRect);
    }
    
    else if (self.alignment == VDModalInfoAlignmentTop) {
        CGFloat top = 10;
        messageViewRect = CGRectMake(floorf((CGRectGetWidth(frame)-_size.width)*0.5f), top, _size.width, _size.height);
    }
    
    else if (self.alignment == VDModalInfoAlignmentPhonePlayer) {
        messageViewRect = CGRectMake(floorf((CGRectGetWidth(frame)-_size.width)*0.5f), 44+15, _size.width, _size.height);
    }
    
    else if (self.alignment == VDModalInfoAlignmentTabletPlayer) {
        messageViewRect = CGRectMake(floorf((CGRectGetWidth(frame)-_size.width)*0.5f), CGRectGetHeight(frame)-73-_size.height-10, _size.width, _size.height);
    }
    
    else if (self.alignment == VDModalInfoAlignmentBottomToolbar) {
        messageViewRect = CGRectMake(floorf((CGRectGetWidth(frame)-_size.width)*0.5f), CGRectGetHeight(frame)-44-_size.height-10, _size.width, _size.height);
    }
    
    
    
    self.messageView.frame = messageViewRect;
	
	if (self.showingProgress)
    {
		self.imageView.hidden = YES;
        
        self.progressIndicator.hidden = NO;
        self.progressIndicator.frame = CGRectMake(floorf((CGRectGetWidth(messageViewRect)-50)*0.5f), floorf((CGRectGetHeight(messageViewRect)-50)*0.5f)-10, 50, 50);

		self.textLabel.frame = CGRectMake(10, CGRectGetHeight(messageViewRect)-21-10, _size.width-20, 21);
	}
	
	else if (!self.imageView.image)
    {
		self.imageView.hidden = YES;
        self.progressIndicator.hidden = YES;
		self.textLabel.frame = CGRectMake(10, floorf((CGRectGetHeight(messageViewRect)-21)*0.5f), _size.width-20, 21);
	}
	else {
		self.imageView.hidden = NO;
        self.progressIndicator.hidden = YES;
		CGSize imageSize = self.imageView.image.size;
		self.imageView.frame = CGRectMake(floorf((CGRectGetWidth(messageViewRect)-imageSize.width)*0.5f), floorf((CGRectGetHeight(messageViewRect)-imageSize.height)*0.5f)-5, imageSize.width, imageSize.height);
		self.textLabel.frame = CGRectMake(10, CGRectGetHeight(messageViewRect)-21-10, _size.width-20, 21);
	}
	
	
}

#pragma mark -

- (void) setProgress:(double)progress
{
    if (_progress != progress) {
        _progress = progress;
        
        self.progressIndicator.progress = progress;
    }
}

- (void) show
{
    [self showWithCompletion:nil];
}

- (void) showWithCompletion:(void (^)(void))completion
{
    [gModelInfos addObject:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateAppearance)
                                                 name:ICAppearanceManagerDidUpdateAppearanceNotification
                                               object:nil];

    
	BOOL navAndToolbar = (self.navigationAndToolbarEnabled && UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad);
	
	if (!navAndToolbar && !self.tapThrough) {
		self.parentWindow = [UIApplication sharedApplication].keyWindow;
		self.parentWindow.userInteractionEnabled = NO;
	}
    
    self.userInteractionEnabled = !self.tapThrough;

	if (navAndToolbar) {
		CGRect appFrame = [UIScreen mainScreen].bounds;
		UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
		if (UIInterfaceOrientationIsPortrait(orientation)) {
			self.frame = CGRectMake(0, 20+44, CGRectGetWidth(appFrame), CGRectGetHeight(appFrame)-44-50);
		} else {
			self.frame = CGRectMake(20+44, 0, CGRectGetHeight(appFrame)-44-50, CGRectGetWidth(appFrame));
		}
		[self setSize:self.size];
	}
	
	if (self.animation == VDModalInfoAnimationScaleDown) {
		self.messageView.transform = CGAffineTransformMakeScale(1.33, 1.33f);
	} 
	else if (self.animation == VDModalInfoAnimationScaleUp) {
		self.messageView.transform = CGAffineTransformMakeScale(0.66f, 0.66f);
	}
    else if (self.animation == VDModalInfoAnimationMoveDown) {
		self.messageView.transform = CGAffineTransformMakeTranslation(0, -10);
	}
	
	self.messageView.alpha = 0.0f;
	self.hidden = NO;
    
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.messageView.alpha = 1.0f;
                         self.messageView.transform = CGAffineTransformIdentity;
                     } completion:^(BOOL finished) {
                         if (completion) {
                             completion();
                         }
                     }];
}

- (void) showAndCloseAfterTimeout:(NSTimeInterval)closeTime
{
	[self show];
    
    [self perform:^(id sender) {
        [self close];
    } afterDelay:closeTime];
}



- (void) showAndCloseAfterTimeout:(NSTimeInterval)closeTime completion:(void (^)())completion
{
	[self show];
    
    
    self.closeTimer = [NSTimer scheduledTimerWithTimeInterval:closeTime target:self selector:@selector(closeTimer:) userInfo:[completion copy] repeats:NO];
}

- (void) closeTimer:(NSTimer*)timer
{
    typedef void (^CompletionBlock)();
    CompletionBlock completionBlock = [timer userInfo];
    
    self.closeTimer = nil;
    
    [self close];
    completionBlock();
}

- (void) postponeCloseForTime:(NSTimeInterval)closeTime
{
    [self.closeTimer setFireDate:[[NSDate date] dateByAddingTimeInterval:closeTime]];
}

- (void) close
{
    [self closeWithCompletion:nil];
}

- (void) closeWithCompletion:(void (^)(void))completion;
{
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.messageView.alpha = 0.0f;
                         
                         if (self.animation == VDModalInfoAnimationScaleDown) {
                             self.messageView.transform = CGAffineTransformMakeScale(0.66f, 0.66f);
                         } 
                         else if (self.animation == VDModalInfoAnimationScaleUp) {
                             self.messageView.transform = CGAffineTransformMakeScale(1.33f, 1.33f);
                         }
                         else if (self.animation == VDModalInfoAnimationMoveDown) {
                             self.messageView.transform = CGAffineTransformMakeTranslation(0, 10);
                         }
                     } completion:^(BOOL finished) {
                         self.hidden = YES;
                         
                         self.parentWindow.userInteractionEnabled = YES;
                         self.parentWindow = nil;
                         
                         [self removeFromSuperview];
                         
                         if (completion) {
                             completion();
                         }
                         
                         [gModelInfos removeObject:self];
                     }];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
