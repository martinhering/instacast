//
//  ICProgressSlider_iOS7.m
//  Instacast
//
//  Created by Martin Hering on 31.07.13.
//
//

#import "ICProgressSlider.h"
#import "ImageFunctions.h"

@interface ICProgressSlider ()
@property (nonatomic, assign) CGPoint trackingStartPoint;
@property (nonatomic, assign) CGRect trackingKnobStartRect;
@property (nonatomic, assign) CGRect trackingKnobRect;
@property (nonatomic, strong) UIButton* knobButton;
@property (nonatomic, strong) UIImageView* trackView;
@property (nonatomic, strong) UIImageView* backgroundView;
@property (nonatomic, strong) UIImageView* progressView;
@property (nonatomic, readwrite) ICProgressSliderScrubbingMode scrubbingMode;
@property (nonatomic, assign) double valueBeforeTracking;
@property (nonatomic, strong) NSTimer* valueChangedTimer;
@end


@implementation ICProgressSlider

- (void) _initStuff
{
    _progressColor = [UIColor colorWithWhite:0.0f alpha:0.1f];
    
    _backgroundView = [[UIImageView alloc] initWithImage:nil];
    _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:_backgroundView];
    
    _progressView = [[UIImageView alloc] initWithImage:nil];
    _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:_progressView];
    
    
    UIImage* trackImage = ICImageFromByDrawingInContext(CGSizeMake(7, 7), ^() {
        [self.tintColor set];
        UIRectFill(CGRectMake(0, 0, 10, 10));
    });
    
    _trackView = [[UIImageView alloc] initWithImage:trackImage];
    _trackView.hidden = YES;
    _trackView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:_trackView];

    
	_knobButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_knobButton.frame = CGRectMake(0, 0, 44, 44);
	[_knobButton setImage:[[UIImage imageNamed:@"Slider Knob"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
	_knobButton.opaque = NO;
	_knobButton.userInteractionEnabled = NO;
    _knobButton.accessibilityLabel = @"Slider Knob".ls;
    _knobButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	
	[self addSubview:_knobButton];
    
    self.scrubbingModesEnabled = YES;
    self.contentMode = UIViewContentModeRedraw;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code.
		[self _initStuff];
        [self _updateAppearance];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
		[self _initStuff];
        [self _updateAppearance];
    }
    return self;
}

- (void) _updateAppearance
{
    UIImage* backgroundImage = ICImageFromByDrawingInContext(CGSizeMake(7, 7), ^() {
        [self.progressColor set];
        UIRectFillUsingBlendMode(CGRectMake(0, 0, 10, 10), kCGBlendModeNormal);
    });
    
    _backgroundView.image = backgroundImage;
    
    UIImage* progressImage = ICImageFromByDrawingInContext(CGSizeMake(7, 7), ^() {
        [self.progressColor set];
        UIRectFillUsingBlendMode(CGRectMake(0, 0, 10, 10), kCGBlendModeNormal);
    });
    
    _progressView.image = progressImage;
}

- (void) setProgressColor:(UIColor *)progressColor
{
    if (_progressColor != progressColor) {
        _progressColor = progressColor;
        [self _updateAppearance];
    }
}

- (void) setAccessibilityLabel:(NSString *)accessibilityLabel
{
    [super setAccessibilityLabel:accessibilityLabel];
    self.knobButton.accessibilityHint = [NSString stringWithFormat:@"Swipe left or right to adjust %@.".ls, self.accessibilityLabel];
}

- (void) setProgress:(double)progress
{
	if (_progress != progress) {
		_progress = MIN(MAX(progress,0),1);
		[self setNeedsLayout];
	}
}

- (void) setValue:(double)value
{
	if (_value != value) {
		_value = MIN(MAX(value,0),1);
		self.knobButton.frame = [self _knobRect];
        self.trackView.frame = [self _trackRect];
        [self setNeedsLayout];
	}
}

- (CGRect) _knobRect
{
	CGRect bounds = self.bounds;
    CGFloat yOffset = floorf((CGRectGetHeight(bounds)-15)*0.5f);
    
	CGFloat maxKnobTrack = CGRectGetWidth(bounds)-15;
	CGFloat knobX = floorf(maxKnobTrack*self.value);
	return CGRectMake(knobX, yOffset, 15, 15);
}

- (CGRect) _trackRect
{
    CGRect bounds = self.bounds;
    CGFloat yOffset = floorf((CGRectGetHeight(bounds)-15)*0.5f);
    CGFloat trackMaxWidth = CGRectGetWidth(bounds)-14;
    CGFloat trackWidth = floorf(trackMaxWidth*self.value);
    
    return CGRectMake(7, yOffset+4, floorf(trackWidth), 7);
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (CGRect) _progressRect
{
    CGRect bounds = self.bounds;
    CGFloat yOffset = floorf((CGRectGetHeight(bounds)-15)*0.5f);
    CGFloat trackMaxWidth = CGRectGetWidth(bounds)-14;
    CGFloat trackWidth = floorf(trackMaxWidth*self.progress);
    
    return CGRectMake(7, yOffset+4, floorf(trackWidth), 7);
}

- (void) setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [self setNeedsLayout];
}

- (void) layoutSubviews
{
	[super layoutSubviews];
    
    CGRect bounds = self.bounds;
    CGFloat yOffset = floorf((CGRectGetHeight(bounds)-15)*0.5f);
    self.backgroundView.frame = CGRectMake(7, yOffset+4, CGRectGetWidth(bounds)-14, 7);
    
    self.progressView.frame = [self _progressRect];
    
	self.knobButton.frame = [self _knobRect];
	self.knobButton.enabled = self.enabled;
    
    self.trackView.frame = [self _trackRect];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	if (!self.enabled) {
		return NO;
	}
	
	NSSet* mytouches = [event touchesForView:self];
	
	if ([mytouches count] == 1) {
		CGPoint location = [touch locationInView:self];
        CGRect touchRect = CGRectInset([self _knobRect], -10, -10);
		if (CGRectContainsPoint(touchRect, location)) {
			self.knobButton.highlighted = YES;
			self.trackingStartPoint = location;
			self.trackingKnobStartRect = [self _knobRect];
			self.valueBeforeTracking = self.value;
			return YES;
		}
	}
	
	return NO;
}

- (CGFloat) deltaFromStartPoint:(CGPoint)startPoint currentPoint:(CGPoint)currentPoint reset:(BOOL*)reset
{
	if (!self.scrubbingModesEnabled || fabs(currentPoint.y - startPoint.y) < 30) {
		*reset = YES;
		self.scrubbingMode = kICProgressSliderScrubbingModeHiSpeed;
		return currentPoint.x - startPoint.x;
	}
	
	CGPoint delta = CGPointMake(currentPoint.x - startPoint.x, (currentPoint.y - startPoint.y) / 30.0f);
	if (delta.y == 0) {
		delta.y = (currentPoint.y > startPoint.y) ? 0.1 : -0.1;
	}
	delta.y = (delta.y > 0) ? delta.y : -delta.y;
	CGFloat r = delta.x / delta.y;
	
	if (delta.y < 4) {
		self.scrubbingMode = kICProgressSliderScrubbingModeHalf;
	}
	else if (delta.y < 8) {
		self.scrubbingMode = kICProgressSliderScrubbingModeQuarter;
	}
	else if (delta.y < 12) {
		self.scrubbingMode = kICProgressSliderScrubbingModeFine;
	}
	
	if (r < 0) {
		r = MAX(delta.x, r);
	} else {
		r = MIN(delta.x, r);
	}
	
	*reset = NO;
    
	return r;
}

- (void) _valueChangedTimer
{
    self.valueChangedTimer = nil;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	if (!self.enabled) {
		return NO;
	}
	
	NSSet* mytouches = [event touchesForView:self];
	
	if ([mytouches count] == 1) {
		CGPoint location = [touch locationInView:self];
		BOOL reset = NO;
		CGFloat delta = [self deltaFromStartPoint:self.trackingStartPoint currentPoint:location reset:&reset];
		CGRect knobRect = CGRectMake(CGRectGetMinX(self.trackingKnobStartRect)+delta,
                                     CGRectGetMinY(self.trackingKnobStartRect),
                                     CGRectGetWidth(self.trackingKnobStartRect),
                                     CGRectGetHeight(self.trackingKnobStartRect)
                                     );
		knobRect.origin.x = MAX(0,knobRect.origin.x);
		knobRect.origin.x = MIN(knobRect.origin.x, CGRectGetWidth(self.bounds)-15);
		self.trackingKnobRect = knobRect;
		
        double newValue = self.valueBeforeTracking + (delta / ((double)CGRectGetWidth(self.bounds)-15));
        self.value = newValue;
        
        if (!self.valueChangedTimer) {
            self.valueChangedTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_valueChangedTimer) userInfo:nil repeats:NO];
        }
        
		if (reset) {
			self.trackingStartPoint = CGPointMake(self.trackingStartPoint.x+ (CGRectGetMinX(self.trackingKnobRect)-CGRectGetMinX(self.trackingKnobStartRect)), self.trackingStartPoint.y);
			self.trackingKnobStartRect = knobRect;
			self.valueBeforeTracking = self.value;
		}
        
		[self setNeedsLayout];
		
		return YES;
	}
	
	return NO;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	self.trackingStartPoint = CGPointZero;
	self.trackingKnobRect = CGRectZero;
	self.knobButton.highlighted = NO;
	self.scrubbingMode = kICProgressSliderScrubbingModeNoScrubbing;
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
    self.trackingStartPoint = CGPointZero;
	self.trackingKnobRect = CGRectZero;
	self.knobButton.highlighted = NO;
	self.scrubbingMode = kICProgressSliderScrubbingModeNoScrubbing;
    [self sendActionsForControlEvents:UIControlEventTouchCancel];
}

@end
