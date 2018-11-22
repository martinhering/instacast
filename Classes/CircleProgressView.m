//
//  CircleProgressView.m
//  Instacast
//
//  Created by Martin Hering on 21.12.12.
//
//

#import "CircleProgressView.h"
#import "ViewFunctions.h"

@interface CircleProgressView ()
@property (nonatomic, strong) NSTimer* animationTimer;
@property (nonatomic) IBInspectable double animationProgress;
@end

@implementation CircleProgressView

- (id) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        
        [self startAnimation];
    }
    
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        
        [self startAnimation];
    }
    return self;
}

- (void) startAnimation
{
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.04f target:self selector:@selector(animationTimer:) userInfo:nil repeats:YES];
}

- (void) animationTimer:(NSTimer*)timer
{
    _animationProgress = _animationProgress + 0.04;
    if (_animationProgress > 1) {
        _animationProgress = 0;
    }
    [self setNeedsDisplay];
}

- (void) setProgress:(double)progress {
    if (_progress != progress) {
        _progress = progress;
        
        
        [self.animationTimer invalidate];
        self.animationTimer = nil;
        
        if (progress <= 0)
        {
            [self startAnimation];
        }
        
        [self setNeedsDisplay];
    }
}

- (void) tintColorDidChange {
    [self setNeedsDisplay];
}

- (void) _drawOutline:(CGRect)rect progress:(double)progress
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    float radius = CGRectGetWidth(rect)*0.5;
    
    UIBezierPath* bezierPath = BezierPathForRoundedRect(rect, radius);
    bezierPath.lineWidth = 2;
    [bezierPath strokeWithBlendMode:kCGBlendModeDestinationAtop alpha:1.f];
    
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

- (void) _drawFillingOutline:(CGRect)rect progress:(double)progress
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    float radius = CGRectGetWidth(rect)*0.5;
    
    UIBezierPath* bezierPath = BezierPathForRoundedRect(rect, radius);
    bezierPath.lineWidth = 2;
    [bezierPath strokeWithBlendMode:kCGBlendModeDestinationAtop alpha:1.f];

    UIBezierPath* clipPath = [UIBezierPath bezierPath];
    [clipPath moveToPoint:CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect))];
    
    CGFloat arcStart = M_PI*3/2;
    CGFloat arcEnd = arcStart + progress*2*M_PI;
    
    [clipPath addArcWithCenter:CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect))
                        radius:radius+2
                    startAngle:arcStart
                      endAngle:arcEnd
                     clockwise:NO];
    
    [clipPath addLineToPoint:CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect))];
    [clipPath closePath];
    [clipPath fillWithBlendMode:kCGBlendModeClear alpha:1.0f];

    
    CGContextRestoreGState(context);
}

- (void) _drawFill:(CGRect)rect progress:(double)fillProgress
{
    float radius = CGRectGetWidth(rect)*0.5;
    UIBezierPath* bezierPath = BezierPathForRoundedRect(rect, radius);
    

    UIBezierPath* fillPath = [UIBezierPath bezierPath];
    [fillPath moveToPoint:CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect))];
    
    CGFloat arcStart = M_PI*3/2;
    CGFloat arcEnd = arcStart + fillProgress*2*M_PI;
    
    [fillPath addArcWithCenter:CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect))
                        radius:radius
                    startAngle:arcStart
                      endAngle:arcEnd
                     clockwise:YES];
    
    [fillPath addLineToPoint:CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect))];
    [fillPath closePath];
    [fillPath fill];
    
    bezierPath.lineWidth = 2;
    [bezierPath strokeWithBlendMode:kCGBlendModeDestinationAtop alpha:1.f];
}

- (void) drawRect:(CGRect)rect
{
    CGRect b = self.bounds;
    CGRect insetRect = CGRectInset(b, 2, 2);
    
    [self.tintColor set];
    
    if (self.style == CircleProgressStyleStandard)
    {
        if (self.progress <= 0) {
            [self _drawOutline:insetRect progress:_animationProgress];
        } else {
            [self _drawFill:insetRect progress:self.progress];
        }
    }
    else if (self.style == CircleProgressStyleFillingOutline)
    {
        [self _drawFillingOutline:insetRect progress:self.progress];
    }
}

@end
