//
//  NSSplitView+DMAdditions.h
//
//  Created by Daniele Margutti on 12/21/12.
//

#import <Cocoa/Cocoa.h>

@protocol NSSplitViewAnimatableDelegate <NSSplitViewDelegate>
/** Inform delegate about the status of the animation (if set). 
	@param	splitView	target splitview
	@param	animating	YES if animating is started, NO if animation is ended
 */
- (void) splitView:(NSSplitView *)splitView splitViewIsAnimating:(BOOL)animating;
@end

/** This is an extension of NSSplitView category. It allows to animate divider position (one at time or more than one at time). It also provide a simple method to get an n-th divider position. */

@interface NSSplitView (DMAdditions) {}

/** Set the new position of a divider at index.
    @param  position            the new divider position
    @param  dividerIndex        target divider index in this splitview
	@param	 animated				use animated transitions?
	@return                     YES if you can animate your transitions
*/
- (BOOL) setPosition:(CGFloat)position ofDividerAtIndex:(NSInteger)dividerIndex animated:(BOOL) animated;

/** Set more than one divider position at the same time using animated transitions
 @param  newPositions           an array of the new divider positions (pass it as NSNumber)
 @param  dividerIndexes         divider indexes array (set of NSNumber)
 @return                        YES if you can animate your transitions
*/
- (BOOL) setPositions:(NSArray *)newPositions ofDividersAtIndexes:(NSArray *)dividerIndexes;

/** Set the new position of a divider at index.
 @param  position               the new divider position
 @param  dividerIndex           target divider index in this splitview
 @return                        target divider position
*/
- (CGFloat) positionOfDividerAtIndex:(NSInteger)dividerIndex;

@end
