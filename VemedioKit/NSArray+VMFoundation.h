//
//  NSArray+VMFoundation.h
//  InstacastMac
//
//  Created by Martin Hering on 12.01.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (VMFoundation)
- (BOOL) containsPrefixOfString:(NSString*)string;
- (NSArray*) arrayByReversingOrder;
@end

@interface NSMutableArray (VMFoundation)
- (void)moveObjectFromIndex:(NSUInteger)from toIndex:(NSUInteger)to;
@end