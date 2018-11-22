//
//  VPTDrawing.h
//  Footage
//
//  Created by Martin Hering on 20.02.17.
//  Copyright © 2017 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_INLINE CGFloat VMDistanceBetweenPoints(CGPoint p1, CGPoint p2) {
    CGFloat xDistance = p1.x - p2.x;
    CGFloat yDistance = p1.y - p2.y;
    return sqrt(xDistance * xDistance + yDistance * yDistance);
}

NS_INLINE CGFloat VMRetinaRound(CGFloat value, CGFloat scaleFactor) {
    scaleFactor = MAX(scaleFactor, 1);
    return round(value * scaleFactor) / scaleFactor;
}

NS_INLINE CGFloat VMRetinaCeil(CGFloat value, CGFloat scaleFactor) {
    scaleFactor = MAX(scaleFactor, 1);
    return ceil(value * scaleFactor) / scaleFactor;
}

NS_INLINE CGFloat VMRetinaFloor(CGFloat value, CGFloat scaleFactor) {
    scaleFactor = MAX(scaleFactor, 1);
    return floor(value * scaleFactor) / scaleFactor;
}

