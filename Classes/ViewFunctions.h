//
//  ViewFunctions.h
//  Instacast
//
//  Created by Martin Hering on 29.12.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif
	
	void DrawRoundedRectangle(CGRect aRect, CGFloat radius, BOOL stroke);

    CGPathRef CreatePathForRoundedRect(CGRect rect, CGFloat radius);
    UIBezierPath* BezierPathForRoundedRect(CGRect rect, CGFloat radius);
    
#ifdef __cplusplus
}  // extern "C"
#endif