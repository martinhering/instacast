//
//  CDBase.m
//  Instacast
//
//  Created by Martin Hering on 05.09.12.
//
//

#import "CDBase.h"

@implementation CDBase

@dynamic uid;

- (void) awakeFromInsert {
    self.uid = [[[NSUUID alloc] init] UUIDString];
}

- (void) awakeFromFetch {
    if (!self.uid) {
        self.uid = [[[NSUUID alloc] init] UUIDString];
    }
}


- (BOOL)isNew {
    NSDictionary *vals = [self committedValuesForKeys:nil];
    return [vals count] == 0;
}

@end
