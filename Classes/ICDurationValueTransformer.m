//
//  ICDurationValueTransformer.m
//  InstacastMac
//
//  Created by Martin Hering on 06.04.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import "ICDurationValueTransformer.h"

@implementation ICDurationValueTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)object
{
    if (!object) {
        return nil;
    }
    
    NSInteger duration = 0;
    
    if ([object isKindOfClass:[CDEpisode class]]) {
        duration = ((CDEpisode*)object).duration;
    }
    else if ([object isKindOfClass:[NSNumber class]]) {
        duration = [object integerValue];
    }
    
    NSString* formattedDuration = nil;
    if (duration > 0)
    {
        NSInteger h = duration/3600;
        NSInteger m = (duration/60)%60;
        NSInteger s = duration%60;
        
        if (duration > 3600) {
            if (m > 0) {
                formattedDuration = [NSString stringWithFormat:@"%d h %d min".ls, h, m];
            } else {
                formattedDuration = [NSString stringWithFormat:@"%d h".ls, h];
            }
        }
        else if (m > 0) {
            formattedDuration = [NSString stringWithFormat:@"%d min".ls, m];
        }
        else {
            formattedDuration = [NSString stringWithFormat:@"%d sec".ls, s];
        }
    }
    else {
        return @"~ min".ls;
    }
    return formattedDuration;
}


@end
