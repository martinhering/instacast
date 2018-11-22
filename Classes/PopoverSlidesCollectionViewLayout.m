//
//  PopoverSlidesCollectionViewLayout.m
//  Instacast
//
//  Created by Martin Hering on 29.08.12.
//
//

#import "PopoverSlidesCollectionViewLayout.h"

@implementation PopoverSlidesCollectionViewLayout

- (CGSize)collectionViewContentSize
{
    CGSize itemSize = self.itemSize;
    CGRect collectionViewSize = self.collectionView.bounds;
    CGFloat collectionViewWidth = CGRectGetWidth(self.collectionView.frame);
    CGFloat hMargin = (collectionViewWidth-itemSize.width)/2;
    
    NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:0];
    CGFloat width = hMargin + numberOfItems*itemSize.width + (numberOfItems-1)*self.minimumLineSpacing + hMargin;
    
    return CGSizeMake(width, CGRectGetHeight(collectionViewSize));
}

- (void) _updateAttributes:(UICollectionViewLayoutAttributes *)attributes
{
    CGFloat width = CGRectGetWidth(self.collectionView.frame);
    CGFloat hMargin = (width-attributes.size.width)/2;
    
    //attributes.transform3D = CATransform3DIdentity;
    
    CGRect frame = attributes.frame;
    frame.origin.x = 5+hMargin + frame.origin.x;
    attributes.frame = frame;
    
    /*
    CGRect visibleRect;
    visibleRect.origin = self.collectionView.contentOffset;
    visibleRect.origin.x += 5;
    visibleRect.size = self.collectionView.bounds.size;
    
    CGFloat distance = CGRectGetMidX(visibleRect) - CGRectGetMidX(frame) - 5;
    
    DebugLog(@"%d, %f %f %f", attributes.indexPath.row, CGRectGetMidX(visibleRect), CGRectGetMidX(frame), distance);
    
    
    CGFloat normalizedDistance = distance / 200;
    
    CGFloat rotation = normalizedDistance * M_PI * 0.25f;
    rotation = MAX(rotation, -M_PI*0.25f);
    rotation = MIN(rotation, M_PI*0.25f);
    
    CATransform3D t = CATransform3DIdentity;
    t.m34 = 1.0f / -2000;
    t = CATransform3DRotate(t, rotation, 0, 1, 0);
    
    attributes.transform3D = t;
     */
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes* attribute = [super layoutAttributesForItemAtIndexPath:indexPath];
    
    [self _updateAttributes:attribute];

    return attribute;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray* attributes = [super layoutAttributesForElementsInRect:rect];
    
    for(UICollectionViewLayoutAttributes* attribute in attributes) {
        [self _updateAttributes:attribute];
    }
    
    return attributes;
}


- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

- (void)finalizeAnimatedBoundsChange
{
    if (self.scrolledIndexPath) {
        [self.collectionView scrollToItemAtIndexPath:self.scrolledIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
}
/*
- (CGPoint) targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    CGFloat offsetAdjustment = MAXFLOAT;
    CGFloat horizontalCenter = proposedContentOffset.x + (CGRectGetWidth(self.collectionView.bounds) / 2.0);
    
    CGRect targetRect = CGRectMake(proposedContentOffset.x, 0.0, CGRectGetWidth(self.collectionView.bounds), CGRectGetHeight(self.collectionView.bounds));
    NSArray* array = [super layoutAttributesForElementsInRect:targetRect];
    
    for(UICollectionViewLayoutAttributes* attributes in array) {
        CGFloat itemHorizontalCenter = attributes.center.x;
        if (ABS(itemHorizontalCenter - horizontalCenter) < ABS(offsetAdjustment)) {
            offsetAdjustment = itemHorizontalCenter - horizontalCenter;
        }
    }
    
    return CGPointMake(proposedContentOffset.x + offsetAdjustment, proposedContentOffset.y);
}
*/
@end
