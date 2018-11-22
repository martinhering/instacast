//
//  SCOrderedSetToArrayValueTransformer.m
//  VMFoundation
//
//  Created by Martin Hering on 30.03.16.
//  Copyright © 2016 Vemedio. All rights reserved.
//

#import "VMOrderedSetToArrayValueTransformer.h"

@implementation VMOrderedSetToArrayValueTransformer

+ (Class)transformedValueClass {
    return [NSArray class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    return [(NSOrderedSet *)value array];
}

- (id)reverseTransformedValue:(id)value {
    return [NSOrderedSet orderedSetWithArray:value];
}


@end
