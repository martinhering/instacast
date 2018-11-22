//
//  VMUppercaseValueTransformer.m
//  Pittoresque
//
//  Created by Martin Hering on 17.02.14.
//  Copyright (c) 2014 Vemedio. All rights reserved.
//

#import "VMUppercaseValueTransformer.h"

@implementation VMUppercaseValueTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(NSString*)value
{
    return [value uppercaseString];
}


@end
