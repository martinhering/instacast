//
//  NSArray+VMFoundation.m
//  InstacastMac
//
//  Created by Martin Hering on 12.01.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import "NSArray+VMFoundation.h"

@implementation NSArray (VMFoundation)

- (BOOL) containsPrefixOfString:(NSString*)string
{
    for(NSString* element in self) {
        if ([string hasPrefix:element]) {
            return YES;
        }
    }
    
    return NO;
}

- (NSArray*) arrayByReversingOrder
{
    NSMutableArray* array = [NSMutableArray array];
    
    for(id object in [self reverseObjectEnumerator]) {
        [array addObject:object];
    }
    
    return array;
}
@end


@implementation NSMutableArray (VMFoundation)

- (void)moveObjectFromIndex:(NSUInteger)from toIndex:(NSUInteger)to
{
    if (to != from) {
        id obj = [self objectAtIndex:from];

        [self removeObjectAtIndex:from];
        
        if (to >= [self count]) {
            [self addObject:obj];
        } else {
            [self insertObject:obj atIndex:to];
        }
    }
}

@end