//
//  ICCategory.m
//  ICFeedParser
//
//  Created by Martin Hering on 16.07.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import "ICCategory.h"

@implementation ICCategory

+ (id) category
{
    return [[self alloc] init];
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"<ICCategory: 0x%lux, title='%@', parent=%@>", (unsigned long)self, self.title, [self.parent description]];
}
@end
