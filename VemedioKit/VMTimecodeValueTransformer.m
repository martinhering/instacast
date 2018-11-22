//
//  VMTimecodeValueTransformer.m
//  VMFoundation
//
//  Created by Martin Hering on 11.03.14.
//  Copyright (c) 2014 Vemedio. All rights reserved.
//

#import "VMTimecodeValueTransformer.h"

@implementation VMTimecodeValueTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(NSNumber*)value
{
    NSInteger cur = [value integerValue];
    
    if (cur < 3600) {
        return [NSString stringWithFormat:@"%ld:%02ld", (long)(cur/60), (long)(cur%60)];
    }
    
    return [NSString stringWithFormat:@"%ld:%02ld:%02ld", (long)(cur/3600), (long)((cur/60)%60), (long)(cur%60)];
}


@end
