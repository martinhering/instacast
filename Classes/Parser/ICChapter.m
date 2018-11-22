//
//  ICChapter.m
//  InstacastFeedIndexer
//
//  Created by Martin Hering on 24.01.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import "ICChapter.h"

@implementation ICChapter

- (NSString*) description
{
    return [NSString stringWithFormat:@"<%@: 0x%lux, \n\ttitle='%@',\n\tstart=%lf,\n\tlinkURL=%@,\n\timageURL=%@>", NSStringFromClass([self class]), (unsigned long)self, self.title, self.time, self.linkURL, self.imageURL];
}
@end
