//
//  PlayerVideoSlider.m
//  Instacast
//
//  Created by Martin Hering on 07/08/14.
//
//

#import "PlayerVideoSlider.h"

@interface PlayerVideoSlider ()
@property (nonatomic, strong) UIView* leftLoadProgressView;
@property (nonatomic, strong) UIView* rightLoadProgressView;
@end

@implementation PlayerVideoSlider

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        _leftLoadProgressView = [[UIView alloc] initWithFrame:CGRectZero];
        _leftLoadProgressView.backgroundColor = [UIColor whiteColor];
        [self insertSubview:_leftLoadProgressView atIndex:0];
        
        _rightLoadProgressView = [[UIView alloc] initWithFrame:CGRectZero];
        _rightLoadProgressView.backgroundColor = [UIColor blackColor];
        [self insertSubview:_rightLoadProgressView atIndex:0];
    }
    return self;
}

- (void) setLoadValue:(float)loadValue
{
    if (_loadValue != loadValue) {
        _loadValue = loadValue;
        
        [self setNeedsLayout];
    }
}


- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value
{
    CGRect r;
    r.size.width = 19;
    r.size.height = 23;
    r.origin.y = 5;
    r.origin.x = floorf((CGRectGetWidth(rect)-19+4) * value) - 2;
    
    return r;
}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    return CGRectMake(0, 15, CGRectGetWidth(bounds), 3);
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    CGRect thumbRect = [self thumbRectForBounds:self.bounds trackRect:trackRect value:self.value];
    
    CGRect loadRect = CGRectInset(trackRect, 0, 1);
    loadRect.size.width = floorf(loadRect.size.width * self.loadValue);
    
    CGRect leftLoadRect = loadRect;
    leftLoadRect.size.width = MIN(leftLoadRect.size.width, floorf(CGRectGetMidX(thumbRect)));
    
    _leftLoadProgressView.frame = leftLoadRect;
    
    CGRect rightLoadRect = loadRect;
    rightLoadRect.origin.x = MAX(rightLoadRect.origin.x, floorf(CGRectGetMidX(thumbRect)));
    rightLoadRect.size.width = MAX(0, CGRectGetWidth(loadRect) - floorf(CGRectGetMinX(rightLoadRect)));
    
    _rightLoadProgressView.frame = rightLoadRect;
}
@end
