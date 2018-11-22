//
//  NumberAccessoryView.m
//  SnowMobile
//
//  Created by Martin Hering on 15.02.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "NumberAccessoryView.h"
#import "ViewFunctions.h"

@interface NumberAccessoryView ()
@end


@implementation NumberAccessoryView


- (id)initWithStyle:(NumberAccessoryViewStyle)aStyle
{
    if ((self = [super initWithFrame:CGRectZero]))
    {
        self.borderRadius = -1;
        self.style = aStyle;
    }
    return self;
}

- (void) setStyle:(NumberAccessoryViewStyle)aStyle
{
    if (_style != aStyle) {
        _style = aStyle;
        
        switch (_style) {
            case NumberAccessoryViewStyleNoOutline:
                self.minWidth = 20;
                self.showOutline = NO;
                self.font = [UIFont boldSystemFontOfSize:15.0f];
                self.outlineColor = [UIColor colorWithRed:121.f/255.f green:130.f/255.f blue:136.f/255.f alpha:1.0];
                self.insets = UIEdgeInsetsMake(1, 6, 1, 6);
                break;
            case NumberAccessoryViewStyleRoundedOutline:
                self.minWidth = 24;
                self.showOutline = YES;
                self.font = [UIFont boldSystemFontOfSize:12.0f];
                self.outlineColor = [UIColor colorWithWhite:0.65 alpha:1.0];
                self.insets = UIEdgeInsetsMake(1, 6, 1, 6);
                break;
            case NumberAccessoryViewStyleEdgyOutline:
                self.minWidth = 20;
                self.showOutline = YES;
                self.borderRadius = 3;
                self.font = [UIFont boldSystemFontOfSize:12.0f];
                self.outlineColor = [UIColor colorWithWhite:0.65 alpha:1.0];
                self.insets = UIEdgeInsetsMake(1, 3, 1, 3);
                break;
                
            default:
                break;
        }
    }
}

- (CGSize)sizeThatFits:(CGSize)size
{
	CGSize s;
	NSString* title = [[NSNumber numberWithUnsignedInteger:self.num] stringValue];
	
	CGSize textSize = [title sizeWithAttributes:[[self.font fontDescriptor] fontAttributes]];
    IC_SIZE_INTEGRAL(textSize);
	s.width = MAX(self.minWidth, textSize.width+self.insets.left+self.insets.right);
	s.height = textSize.height+self.insets.top+self.insets.bottom;
	
	return s;
}


- (void)drawRect:(CGRect)rect
{
	if (self.num > 0)
	{
		CGRect bounds = self.bounds;
		
		[self.backgroundColor set];
		UIRectFill(rect);
		
		if (self.showOutline)
		{
			if (self.highlighted) {
				[[UIColor whiteColor] set];
			} else {
				[self.outlineColor set];
			}

            CGFloat radius = (self.borderRadius >= 0) ? self.borderRadius : CGRectGetHeight(bounds)*0.5f;
            
			DrawRoundedRectangle(bounds, radius, NO);
		}
		
		NSString* s = [[NSNumber numberWithUnsignedInteger:self.num] stringValue];
		
		CGSize textSize = [s sizeWithAttributes:[[self.font fontDescriptor] fontAttributes]];
		
		CGRect rect = bounds;
		rect.size.height = textSize.height;
		rect.origin.y = floorf((CGRectGetHeight(bounds) - textSize.height)/2)-1.5;

		rect.origin.y++;
		
		if (!self.showOutline)
		{
			rect.origin.x -= 3;
		}
        
        NSMutableDictionary* attributes = [[[self.font fontDescriptor] fontAttributes] mutableCopy];
		
		if (self.showOutline)
		{
			if (!self.highlighted) {
                attributes[NSForegroundColorAttributeName] = [UIColor whiteColor];
			} else {
                attributes[NSForegroundColorAttributeName] = [UIColor colorWithRed:2.f/255.f green:114.f/255.f blue:237.f/255.f alpha:1.0];
			}
		}
		else
		{
			if (!self.highlighted) {
				attributes[NSForegroundColorAttributeName] = [UIColor colorWithRed:121.f/255.f green:130.f/255.f blue:136.f/255.f alpha:1.0];
			} else {
				attributes[NSForegroundColorAttributeName] = [UIColor whiteColor];
			}
		}
        
        NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        para.alignment = NSTextAlignmentCenter;
        attributes[NSParagraphStyleAttributeName] = para;
        
        [s drawInRect:rect withAttributes:attributes];
	}
}

- (void) setNum:(NSUInteger)num
{
    if (_num != num) {
        _num = num;
        [self setNeedsDisplay];
    }
}

@end
