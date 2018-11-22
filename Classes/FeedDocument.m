//
//  FeedDocument.m
//  Instacast
//
//  Created by Martin Hering on 30.08.11.
//  Copyright (c) 2011 Vemedio. All rights reserved.
//

#ifdef __IPHONE_5_0

#import "FeedDocument.h"
#import "Feed.h"

@implementation FeedDocument

@synthesize feed;

- (void) dealloc
{
    [super dealloc];
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError
{
    
}

- (id)contentsForType:(NSString *)typeName error:(NSError **)outError
{
    
}

@end


#endif