//
//  NSUndoManager+VMFoundation.h
//  VMFoundation
//
//  Created by Martin Hering on 15.02.14.
//  Copyright (c) 2014 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSUndoManager (VMFoundation)

- (void)registerUndoWithTarget:(id)target selector:(SEL)aSelector object:(id)anObject actionName:(NSString*)actionName;

@end
