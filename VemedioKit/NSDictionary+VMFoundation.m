//
//  NSDictionary+VMFoundation.m
//  Instacast
//
//  Created by Martin Hering on 21.01.13.
//
//

#import "NSDictionary+VMFoundation.h"

@implementation NSDictionary (VMFoundation)

- (NSDictionary *) dictionaryByRemovingNullValues {
    
    if (![self isKindOfClass:[NSDictionary class]]) {
        return self;
    }
    
    const NSMutableDictionary* replaced = [self mutableCopy];
    const id nul = [NSNull null];
    
    for(NSString *key in self) {
        const id object = [self objectForKey:key];
        if(object == nul) {
            [replaced removeObjectForKey:key];
        }
    }
    return (NSDictionary *)replaced;
}


@end
