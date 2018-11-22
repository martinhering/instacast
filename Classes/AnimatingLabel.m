//
//  ScrollUpLabel.m
//  Instacast
//
//  Created by Martin Hering on 15.02.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import "AnimatingLabel.h"

@interface AnimatingLabel ()
@property (nonatomic, assign) BOOL firstText;
@property (nonatomic, assign) BOOL animating;
@end


@implementation AnimatingLabel

- (Class) labelClass
{
    return [UILabel class];
}

- (void) _init
{
    self.animationDuration = 0.2f;
    
    CGRect bounds = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    
    _labels[0] = [[[self labelClass] alloc] initWithFrame:bounds];
    _labels[0].autoresizingMask = (UIViewAutoresizingFlexibleWidth);
    [self addSubview:_labels[0]];
    
    bounds.origin.y += bounds.size.height;
    _labels[1] = [[[self labelClass] alloc] initWithFrame:bounds];
    _labels[1].autoresizingMask = (UIViewAutoresizingFlexibleWidth);
    [self addSubview:_labels[1]];
    
    self.firstText = YES;
    self.clipsToBounds = YES;
    
    [self setOpaque:YES];
    [self setBackgroundColor:[UIColor clearColor]];
    
    _queue = [[NSMutableArray alloc] init];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self _init];
    }
    
    return self;
}


- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self)
	{
        [self _init];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (void) setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    if (!self.animating) {
        CGRect frame0 = _labels[0].frame;
        CGRect frame1 = _labels[1].frame;
        
        UILabel* topLabel = (frame0.origin.y < frame1.origin.y) ? _labels[0] : _labels[1];
        UILabel* bottomLabel = (frame0.origin.y < frame1.origin.y) ? _labels[1] : _labels[0];
        
        CGRect bounds = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
        topLabel.frame = bounds;
        bounds.origin.y += bounds.size.height;
        bottomLabel.frame = bounds;
    }
}


- (UIFont*) font
{
	return _labels[0].font;
}

- (void) setFont:(UIFont *)font
{
	_labels[0].font = font;
	_labels[1].font = font;
}

- (UIColor*) textColor
{
	return _labels[0].textColor;
}

- (void) setTextColor:(UIColor *)textColor
{
	_labels[0].textColor = textColor;
	_labels[1].textColor = textColor;
}

- (UIColor*) shadowColor
{
	return _labels[0].shadowColor;
}

- (void) setShadowColor:(UIColor *)shadowColor
{
	_labels[0].shadowColor = shadowColor;
	_labels[1].shadowColor = shadowColor;
}

- (CGSize) shadowOffset
{
	return _labels[0].shadowOffset;
}

- (void) setShadowOffset:(CGSize)shadowOffset
{
	_labels[0].shadowOffset = shadowOffset;
	_labels[1].shadowOffset = shadowOffset;
}

- (NSTextAlignment) textAlignment
{
	return _labels[0].textAlignment;
}

- (void) setTextAlignment:(NSTextAlignment)textAlignment
{
	_labels[0].textAlignment = textAlignment;
	_labels[1].textAlignment = textAlignment;
}

- (UIColor*) backgroundColor
{
	return _labels[0].backgroundColor;
}

- (void) setBackgroundColor:(UIColor *)backgroundColor
{
	_labels[0].backgroundColor = backgroundColor;
	_labels[1].backgroundColor = backgroundColor;
}


#pragma mark -

- (void) _scrollUp
{
	if ([_queue count] == 0) {
        self.animating = NO;
		return;
	}
	
	self.animating = YES;
    
    CGRect frame0 = _labels[0].frame;
    CGRect frame1 = _labels[1].frame;
    
    UILabel* nextLabel = (frame0.origin.y < frame1.origin.y) ? _labels[1] : _labels[0];
    
    id obj = [_queue objectAtIndex:0];
    if (obj == [NSNull null]) obj = @"";
    nextLabel.text = obj;
    [_queue removeObjectAtIndex:0];
    
    
    [UIView animateWithDuration:self.animationDuration
                     animations:^{

                         CGRect frame0 = _labels[0].frame;
                         CGRect frame1 = _labels[1].frame;
                         
                         frame0.origin.y -= frame0.size.height;
                         frame1.origin.y -= frame1.size.height;
                         
                         _labels[0].frame = frame0;
                         _labels[1].frame = frame1;

                     }
                     completion:^(BOOL finished) {
                         
                         CGRect frame0 = _labels[0].frame;
                         CGRect frame1 = _labels[1].frame;
                         
                         if (frame0.origin.y < frame1.origin.y) {
                             frame0.origin.y = CGRectGetMaxY(frame1);
                             _labels[0].frame = frame0;
                         }
                         else {
                             frame1.origin.y = CGRectGetMaxY(frame0);
                             _labels[1].frame = frame1;
                         }
                         
                         
                         
                         if ([_queue count] > 0) {
                             [self performSelector:@selector(_scrollUp) withObject:nil afterDelay:0.1];
                         }
                         else {
                             self.animating = NO;
                         }
                     }];
}


- (void) setText:(NSString*)aText
{
	[self setText:aText animate:YES];
}

- (void) setText:(NSString *)aText animate:(BOOL)animate
{
    if (!animate) {
        [_queue removeAllObjects];
    }
    
    if (![_text isEqualToString:aText])
	{
		_text = aText;

        if (animate)
        {
            if (self.firstText)
            {
                _labels[0].text = aText;
                self.firstText = NO;
            }
            else
            {
                [_queue addObject:((aText) ? (id)aText : (id)[NSNull null])];
                
                if (!self.animating) {
                    [self _scrollUp];
                }
            }
        }
        else
        {
            _labels[0].text = aText;
            _labels[1].text = aText;
        }
	}
}

@end
