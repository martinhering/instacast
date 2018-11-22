//
//  ICEpisodeConsumeIndicaor.m
//  Instacast
//
//  Created by Martin Hering on 05.08.14.
//
//

#import "ICEpisodeConsumeIndicator.h"

@implementation ICEpisodeConsumeIndicator

- (void) setConsumed:(BOOL)consumed
{
    if (_consumed != consumed) {
        _consumed = consumed;
        [self setNeedsDisplay];
    }
}

- (void) setProgress:(double)progress
{
    if (_progress != progress) {
        _progress = progress;
        [self setNeedsDisplay];
    }
}

- (CGFloat) _progress {
    if (!self.consumed && self.progress == 0) {
        return 0;
    }
    
    if (self.consumed) {
        return 1;
    }
    
    return self.progress;
}

- (void) setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setNeedsDisplay];
}

- (void) drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);

    [self.tintColor setFill];
    [self.tintColor setStroke];
    
    UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(0.5, 0.5, 9, 9)];
    [ovalPath fill];

    [self.backgroundColor setFill];
    
    CGFloat fillProgress = (NSInteger)([self _progress]*12)*1.0/12;
    if ([self _progress] > 0) {
        fillProgress = MAX(1.0/12.0, fillProgress);
    }
    
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
    [fillPath fillWithBlendMode:kCGBlendModeSourceIn alpha:1.0];
    
    UIBezierPath* strokePath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(0.5, 0.5, 9, 9)];
    [strokePath stroke];

    CGContextRestoreGState(context);
}

- (void) tintColorDidChange {
    [self setNeedsDisplay];
}
@end
