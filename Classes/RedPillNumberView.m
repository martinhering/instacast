//
//  RedPillNumberView.m
//  Instacast
//
//  Created by Martin Hering on 19.10.12.
//
//

#import "RedPillNumberView.h"
#import "ViewFunctions.h"

@interface RedPillNumberView ()
@property (nonatomic, strong) UIImageView* backgroundView;
@property (nonatomic, strong) UILabel* textLabel;
@end

@implementation RedPillNumberView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.contentMode = UIViewContentModeRedraw;
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        
        _textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), 18)];
        _textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.font = [UIFont systemFontOfSize:13];
        _textLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:_textLabel];
        
        self.backgroundView.hidden = YES;
        self.textLabel.hidden = YES;
    }
    return self;
}

- (void) setNumber:(NSInteger)number
{
    if (_number != number) {
        _number = number;
        
        _textLabel.text = [@(number) stringValue];
        
        [self setNeedsLayout];
        [self setNeedsDisplay];
    }
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    if (self.number == 0) {
        self.backgroundView.hidden = YES;
        self.textLabel.hidden = YES;
    }
    else
    {
        self.backgroundView.hidden = NO;
        self.textLabel.hidden = NO;
    }
}

- (CGSize) sizeThatFits:(CGSize)size
{
    CGSize textSize = [_textLabel.attributedText size];
    textSize.width += 10;
    textSize.width = MAX(21, textSize.width);
    textSize.height = 18;
    return textSize;
}


- (void) drawRect:(CGRect)rect
{
    if (self.number > 0)
    {
        [self.tintColor set];
        
        CGPathRef path = CreatePathForRoundedRect(self.bounds, 9);
        UIBezierPath* uiPath = [UIBezierPath bezierPathWithCGPath:path];
        CFRelease(path);
        
        [uiPath fill];
    }
}

- (void) tintColorDidChange
{
    [self setNeedsDisplay];
}

@end
