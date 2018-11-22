//
//  ViewFunctions.m
//  Instacast
//
//  Created by Martin Hering on 29.12.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import "ViewFunctions.h"

void DrawRoundedRectangle(CGRect aRect, CGFloat radius, BOOL stroke)
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
	
	CGContextBeginPath(context);
    CGPoint topMid = CGPointMake(CGRectGetMidX(aRect), CGRectGetMaxY(aRect));
	CGPoint bottomLeft = CGPointMake(CGRectGetMinX(aRect), CGRectGetMinY(aRect));
    CGPoint topLeft = CGPointMake(CGRectGetMinX(aRect), CGRectGetMaxY(aRect));
    CGPoint topRight = CGPointMake(CGRectGetMaxX(aRect), CGRectGetMaxY(aRect));
    CGPoint bottomRight = CGPointMake(CGRectGetMaxX(aRect), CGRectGetMinY(aRect));
    
    CGContextMoveToPoint(context, topMid.x, topMid.y);
    CGContextAddArcToPoint(context, topLeft.x, topLeft.y, bottomLeft.x, bottomLeft.y, radius);
    CGContextAddArcToPoint(context, bottomLeft.x, bottomLeft.y, bottomRight.x, bottomRight.y, radius);
    CGContextAddArcToPoint(context, bottomRight.x, bottomRight.y, topRight.x, topRight.y, radius);
    CGContextAddArcToPoint(context, topRight.x, topRight.y, topLeft.x, topLeft.y, radius);
    
    CGContextClosePath(context);
    
    if (stroke) {
        CGContextStrokePath(context);
    } else {
        CGContextFillPath(context);
    }
    
    CGContextRestoreGState(context);
}

CGPathRef CreatePathForRoundedRect(CGRect rect, CGFloat radius)
{
	CGMutablePathRef retPath = CGPathCreateMutable();
    
	CGRect innerRect = CGRectInset(rect, radius, radius);
    
	CGFloat inside_right = innerRect.origin.x + innerRect.size.width;
	CGFloat outside_right = rect.origin.x + rect.size.width;
	CGFloat inside_bottom = innerRect.origin.y + innerRect.size.height;
	CGFloat outside_bottom = rect.origin.y + rect.size.height;
    
	CGFloat inside_top = innerRect.origin.y;
	CGFloat outside_top = rect.origin.y;
	CGFloat outside_left = rect.origin.x;
    
	CGPathMoveToPoint(retPath, NULL, innerRect.origin.x, outside_top);
    
	CGPathAddLineToPoint(retPath, NULL, inside_right, outside_top);
	CGPathAddArcToPoint(retPath, NULL, outside_right, outside_top, outside_right, inside_top, radius);
	CGPathAddLineToPoint(retPath, NULL, outside_right, inside_bottom);
	CGPathAddArcToPoint(retPath, NULL,  outside_right, outside_bottom, inside_right, outside_bottom, radius);
    
	CGPathAddLineToPoint(retPath, NULL, innerRect.origin.x, outside_bottom);
	CGPathAddArcToPoint(retPath, NULL,  outside_left, outside_bottom, outside_left, inside_bottom, radius);
	CGPathAddLineToPoint(retPath, NULL, outside_left, inside_top);
	CGPathAddArcToPoint(retPath, NULL,  outside_left, outside_top, innerRect.origin.x, outside_top, radius);
    
	CGPathCloseSubpath(retPath);
    
	return retPath;
}

UIBezierPath* BezierPathForRoundedRect(CGRect rect, CGFloat radius)
{
    CGPathRef path = CreatePathForRoundedRect(rect, radius);
    UIBezierPath* bezierPath = [UIBezierPath bezierPathWithCGPath:path];
    CFRelease(path);
    
    return bezierPath;
}