//
//  NSUndoManager+VMFoundation.m
//  VMFoundation
//
//  Created by Martin Hering on 15.02.14.
//  Copyright (c) 2014 Vemedio. All rights reserved.
//

#import "NSUndoManager+VMFoundation.h"

@implementation NSUndoManager (VMFoundation)

- (void)registerUndoWithTarget:(id)target selector:(SEL)aSelector object:(id)anObject actionName:(NSString*)actionName
{
    [self registerUndoWithTarget:target selector:aSelector object:anObject];
    if (![self isUndoing]) {
        [self setActionName:actionName];
    }
}
@end
