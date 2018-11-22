//
//  MainSidebarPlayerControl.m
//  Instacast
//
//  Created by Martin Hering on 10.08.13.
//
//

#import "ICNowPlayingActivityControl.h"
#import "MarqueeLabel2.h"

@interface ICNowPlayingActivityControl ()
@property (nonatomic, strong) UIImageView* imageView;
@property (nonatomic, strong, readwrite) UILabel* label1;
@property (nonatomic, strong, readwrite) UILabel* label2;
@property (nonatomic, strong, readwrite) UIButton* rightButton;
@property (nonatomic, strong, readwrite) UIProgressView* progressView;
@end


@implementation ICNowPlayingActivityControl

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.clipsToBounds = YES;
        
        _label1 = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, CGRectGetWidth(frame)-44-30, 15)];
        _label1.font = [UIFont systemFontOfSize:11.f];
        _label1.textColor = [UIColor whiteColor];
        _label1.text = @"Now Playing".ls;
        [self addSubview:_label1];
        
        MarqueeLabel2* label2 = [[MarqueeLabel2 alloc] initWithFrame:CGRectMake(15, 20, CGRectGetWidth(frame)-44-30, 15)];
        label2.marqueeType = MLContinuous;
        label2.rate = 20.0;
        label2.animationCurve = UIViewAnimationOptionCurveEaseInOut;
        label2.fadeLength = 10.0f;
        label2.continuousMarqueeExtraBuffer = 10.0f;
        label2.animationDelay = 5.f;
        _label2 = label2;
        _label2.font = [UIFont systemFontOfSize:11.f];
        _label2.textColor = [UIColor colorWithWhite:0.57f alpha:1.0f];
        //_label2.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addSubview:_label2];
        _marqueePaused = YES;
        
        
        _rightButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(frame)-44-5, 0, 44, 44)];
        [_rightButton setImage:[[UIImage imageNamed:@"Activity Button Play"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                      forState:UIControlStateNormal];
        _rightButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        _rightButton.tintColor = [UIColor whiteColor];
        [self addSubview:_rightButton];
        
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), 2)];
        [self addSubview:_progressView];
    }
    return self;
}

- (void) setMarqueePaused:(BOOL)marqueePaused
{
    if (_marqueePaused != marqueePaused) {
        _marqueePaused = marqueePaused;
        
        ((MarqueeLabel2*)self.label2).holdScrolling = marqueePaused;
        if (!marqueePaused) {
            [(MarqueeLabel2*)self.label2 restartLabel];
        }
    }
}

- (BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGFloat white, alpha;
    [ICDarkBackgroundColor getWhite:&white alpha:&alpha];
    white += 0.05f;
    
    UIColor* slightlyLighterColor = [UIColor colorWithWhite:white alpha:alpha];
    self.backgroundColor = slightlyLighterColor;
    
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    self.backgroundColor = ICDarkBackgroundColor;
    [super cancelTrackingWithEvent:event];
}

- (void) endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    self.backgroundColor = ICDarkBackgroundColor;
    [super endTrackingWithTouch:touch withEvent:event];
}

- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event
{
    [super sendAction:action to:target forEvent:event];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.backgroundColor = ICDarkBackgroundColor;
    });
}


- (void) layoutSubviews{
    [super layoutSubviews];
    
    CGRect b = self.bounds;
    
    //self.label1.backgroundColor = [UIColor redColor];
    //self.label2.backgroundColor = [UIColor greenColor];
    
    self.imageView.frame = CGRectMake(5, 0, 44, 44);
    self.label1.frame = CGRectMake(15, 7, CGRectGetWidth(b)-44-30, 15);
    self.label2.frame = CGRectMake(15, 22, CGRectGetWidth(b)-44-30, 15);
    
    self.rightButton.frame = CGRectMake(CGRectGetWidth(b)-44-5, 0, 44, 44);
    self.progressView.frame = CGRectMake(-2, 0, CGRectGetWidth(b)+2, 2);
}
@end
