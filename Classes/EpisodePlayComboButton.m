//
//  EpisodePlayComboButton.m
//  Instacast
//
//  Created by Martin Hering on 16.07.13.
//
//

#import "EpisodePlayComboButton.h"
#import "ViewFunctions.h"

@interface EpisodePlayComboButton ()
@property (nonatomic, strong) NSTimer* animationTimer;
@end

@implementation EpisodePlayComboButton {
    double _animationProgress;
}

+ (instancetype) button
{
    EpisodePlayComboButton* button = [EpisodePlayComboButton buttonWithType:UIButtonTypeCustom];
    [button sizeToFit];
    button.contentMode = UIViewContentModeRedraw;
    return button;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return CGSizeMake(23, 23);
}

- (UIBezierPath*) _playBezierPath
{
    CGRect b = self.bounds;
    CGPoint topLeft = CGPointMake((CGRectGetWidth(b)-8)/2+1, (CGRectGetHeight(b)-9)/2);
    
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:topLeft];
    [path addLineToPoint:CGPointMake(topLeft.x, topLeft.y+9)];
    [path addLineToPoint:CGPointMake(topLeft.x+8, topLeft.y+4.5f)];
    [path closePath];
    
    return path;
}

- (CGRect) _stopRect
{
    CGRect b = self.bounds;
    return CGRectMake((CGRectGetWidth(b)-6)/2, (CGRectGetHeight(b)-6)/2, 6, 6);
}

- (void) _drawOutline:(CGRect)rect progress:(double)progress
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    

    UIBezierPath* bezierPath = BezierPathForRoundedRect(rect, 11);
    bezierPath.lineWidth = 1;
    [bezierPath stroke];
    
    if (progress < 1)
    {
        CGContextTranslateCTM(context, CGRectGetMidX(rect), CGRectGetMidY(rect));
        CGContextRotateCTM(context, 360.f*progress*M_PI/180.0);
        CGContextTranslateCTM(context, -CGRectGetMidX(rect), -CGRectGetMidY(rect));

        UIBezierPath* clipPath = [UIBezierPath bezierPath];
        [clipPath moveToPoint:CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect))];
        [clipPath addLineToPoint:CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect)-6)];
        [clipPath addLineToPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect)-6)];
        [clipPath closePath];
        [clipPath fillWithBlendMode:kCGBlendModeClear alpha:1.0f];
    }
    
    CGContextRestoreGState(context);
}

- (void) _drawPlayGlyph:(CGRect)rect
{
    UIBezierPath* playPath = [self _playBezierPath];
    [playPath fill];
}

- (void) _drawFill:(CGRect)rect progress:(double)fillProgress
{
    UIBezierPath* bezierPath = BezierPathForRoundedRect(rect, 11);
    
    if (fillProgress >= 1)
    {
        [bezierPath fill];
        
        UIBezierPath* playPath = [self _playBezierPath];
        [playPath fillWithBlendMode:kCGBlendModeClear alpha:1.0f];
    }
    else
    {
        UIBezierPath* fillPath = [UIBezierPath bezierPath];
        [fillPath moveToPoint:CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect))];
        
        CGFloat arcStart = M_PI*3/2;
        CGFloat arcEnd = arcStart + fillProgress*2*M_PI;
        
        [fillPath addArcWithCenter:CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect))
                            radius:11
                        startAngle:arcStart
                          endAngle:arcEnd
                         clockwise:YES];
        
        [fillPath addLineToPoint:CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect))];
        [fillPath closePath];
        [fillPath fill];

        bezierPath.lineWidth = 1;
        [bezierPath stroke];
        
        CGRect stopRect = [self _stopRect];
        CGRect stopOutlineRect = CGRectInset(stopRect, -1, -1);
        UIRectFillUsingBlendMode(stopOutlineRect, kCGBlendModeClear);
        UIRectFill(stopRect);
    }
}

- (void) setComboState:(EpisodePlayButtonComboState)comboState
{
    if (_comboState != comboState) {
        _comboState = comboState;
        
        
        [self.animationTimer invalidate];
        self.animationTimer = nil;
        
        if (comboState == kEpisodePlayButtonComboStateHolding) {
            self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.04f target:self selector:@selector(animateTimer:) userInfo:nil repeats:YES];
        }
        
        [self setNeedsDisplay];
    }
}

- (void) animateTimer:(NSTimer*)timer
{
    _animationProgress = _animationProgress + 0.04;
    if (_animationProgress > 1) {
        _animationProgress = 0;
    }
    [self setNeedsDisplay];
}


- (void) setFillingProgress:(double)fillingProgress
{
    if (_fillingProgress != fillingProgress) {
        _fillingProgress = fillingProgress;
        [self setNeedsDisplay];
    }
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
//    [[UIColor redColor] set];
//    UIRectFill(rect);
    
    [(self.highlighted || self.selected) ? [UIColor colorWithWhite:0.8f alpha:1.0f] : self.tintColor set];
    
    CGRect b = self.bounds;
    CGRect f = CGRectMake((CGRectGetWidth(b)-22)/2, (CGRectGetHeight(b)-22)/2, 22, 22);
    
    switch (self.comboState) {
        case kEpisodePlayButtonComboStateOutline:
            [self _drawOutline:f progress:1.f];
            [self _drawPlayGlyph:f];
            break;
        case kEpisodePlayButtonComboStateHolding:
            [self _drawOutline:f progress:_animationProgress];
            CGRect stopRect = [self _stopRect];
            UIRectFill(stopRect);
            break;
        case kEpisodePlayButtonComboStateFilling:
            [self _drawFill:f progress:self.fillingProgress];
            break;
        case kEpisodePlayButtonComboStateFilled:
            [self _drawFill:f progress:2];
            break;
        default:
            break;
    }
}

- (void) setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
    [self setNeedsDisplay];
}

- (void) setTintAdjustmentMode:(UIViewTintAdjustmentMode)tintAdjustmentMode
{
    [super setTintAdjustmentMode:tintAdjustmentMode];
    [self setNeedsDisplay];
}

- (void) tintColorDidChange
{
    [self setNeedsDisplay];
}

- (void) setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self setNeedsDisplay];
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self setNeedsDisplay];
    [super endTrackingWithTouch:touch withEvent:event];
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self setNeedsDisplay];
    return [super continueTrackingWithTouch:touch withEvent:event];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
    [self setNeedsDisplay];
    [super cancelTrackingWithEvent:event];
}

@end
