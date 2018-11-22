//
//  ICTimecodeValueTransformer.m
//  InstacastMac
//
//  Created by Martin Hering on 09.04.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import "ICTimecodeValueTransformer.h"

@implementation ICTimecodeValueTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(NSNumber*)value
{
    NSInteger cur = MAX(0, [value integerValue]);
    return [NSString stringWithFormat:@"%ld:%02ld:%02ld", (long)(cur/3600), (long)((cur/60)%60), (long)(cur%60)];
}

@end
