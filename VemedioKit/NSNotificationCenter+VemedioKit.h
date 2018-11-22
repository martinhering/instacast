//
//  NSNotificationCenter+VemedioKit.h
//  VMFoundation
//
//  Created by Martin Hering on 15.09.11.
//  Copyright (c) 2011 Vemedio. All rights reserved.
//

typedef void (^VMNotificationBlock) (NSNotification* notification);

@interface NSNotificationCenter (VemedioKit)

- (void) addObserver:(id)observer name:(NSString*)name object:(id)object handler:(VMNotificationBlock)handler;
- (void) removeHandlerForObserver:(id)observer name:(NSString *)aName object:(id)anObject;

- (void) addObserver:(id)observer name:(NSString*)name object:(id)object seed:(NSString*)seed handler:(VMNotificationBlock)handler;
- (void) removeHandlerForObserver:(id)observer name:(NSString *)aName object:(id)anObject seed:(NSString*)seed;


@end
