//
//  ICSidebarPanGestureRecognizer.m
//  Instacast
//
//  Created by Martin Hering on 21.08.13.
//
//

#import <UIKit/UIGestureRecognizerSubclass.h>

#import "ICSidebarPanGestureRecognizer.h"

@interface ICSidebarPanGestureRecognizer ()
@property (nonatomic, readwrite) CGPoint firstTouchLocation;
@end


@implementation ICSidebarPanGestureRecognizer

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    self.firstTouchLocation = [[touches anyObject] locationInView:self.viewOfLocationCoordinateSystem];
}

@end
