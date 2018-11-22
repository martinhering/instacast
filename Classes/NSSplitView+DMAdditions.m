//
//  NSSplitView+DMAdditions.m
//
//  Created by Daniele Margutti on 12/21/12.
//

#import "NSSplitView+DMAdditions.h"
#import <Quartz/Quartz.h>

@implementation NSSplitView (DMAdditions)

- (CGFloat)positionOfDividerAtIndex:(NSInteger)dividerIndex {
    // It looks like NSSplitView relies on its subviews being ordered left->right or top->bottom so we can too.
    // It also raises w/ array bounds exception if you use its API with dividerIndex > count of subviews.
    while (dividerIndex >= 0 && [self isSubviewCollapsed:[[self subviews] objectAtIndex:dividerIndex]])
        dividerIndex--;
    if (dividerIndex < 0)
        return 0.0f;
    
    NSRect priorViewFrame = [[[self subviews] objectAtIndex:dividerIndex] frame];
    return [self isVertical] ? NSMaxX(priorViewFrame) : NSMaxY(priorViewFrame);
}

- (BOOL) setPositions:(NSArray *)newPositions ofDividersAtIndexes:(NSArray *)indexes {
    NSUInteger numberOfSubviews = self.subviews.count;
    
    // indexes and newPositions arrays must have the same object count
    if (indexes.count == newPositions.count == NO) return NO;
    // trying to move too many dividers
    if (indexes.count < numberOfSubviews == NO) return NO;
   
    NSRect newRect[numberOfSubviews];
    
    for (NSUInteger i = 0; i < numberOfSubviews; i++)
        newRect[i] = [[self.subviews objectAtIndex:i] frame];
    
    for (NSNumber *indexObject in indexes) {
        NSInteger index = [indexObject integerValue];
        CGFloat  newPosition = [[newPositions objectAtIndex:[indexes indexOfObject:indexObject]] doubleValue];
        if (self.isVertical) {
            CGFloat oldMaxXOfRightHandView = NSMaxX(newRect[index + 1]);
            newRect[index].size.width = newPosition - NSMinX(newRect[index]);
            CGFloat dividerAdjustment = (newPosition < NSWidth(self.bounds)) ? self.dividerThickness : 0.0;
            newRect[index + 1].origin.x = newPosition + dividerAdjustment;
            newRect[index + 1].size.width = oldMaxXOfRightHandView - newPosition - dividerAdjustment;
        } else {
            CGFloat oldMaxYOfBottomView = NSMaxY(newRect[index + 1]);
            newRect[index].size.height = newPosition - NSMinY(newRect[index]);
            CGFloat dividerAdjustment = (newPosition < NSHeight(self.bounds)) ? self.dividerThickness : 0.0;
            newRect[index + 1].origin.y = newPosition + dividerAdjustment;
            newRect[index + 1].size.height = oldMaxYOfBottomView - newPosition - dividerAdjustment;
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(splitView:splitViewIsAnimating:)])
        [((id <NSSplitViewAnimatableDelegate>)self.delegate) splitView:self splitViewIsAnimating:YES];

    [NSAnimationContext beginGrouping];
    
    [NSAnimationContext currentContext].duration = 0.2;
    [NSAnimationContext currentContext].timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [NSAnimationContext currentContext].completionHandler = ^{

        if ([self.delegate respondsToSelector:@selector(splitView:splitViewIsAnimating:)])
            [((id <NSSplitViewAnimatableDelegate>)self.delegate) splitView:self splitViewIsAnimating:NO];

    };
    
    for (NSUInteger i = 0; i < numberOfSubviews; i++) {
        [[[self.subviews objectAtIndex:i] animator] setFrame:newRect[i]];
    }
    
    [NSAnimationContext endGrouping];
    return YES;
}

- (BOOL) setPosition:(CGFloat)position ofDividerAtIndex:(NSInteger)dividerIndex animated:(BOOL) animated {
	if (!animated) [self setPosition:position ofDividerAtIndex:dividerIndex];
	else {
		NSUInteger numberOfSubviews = self.subviews.count;
		if (dividerIndex >= numberOfSubviews) return NO;
		[self setPositions:@[@(position)] ofDividersAtIndexes:@[@(dividerIndex)]];
    }
	return YES;
}


@end
