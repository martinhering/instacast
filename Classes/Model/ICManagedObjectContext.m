//
//  ICManagedObjectContext.m
//  Instacast
//
//  Created by Martin Hering on 24.01.13.
//
//

#import "ICManagedObjectContext.h"

@implementation ICManagedObjectContext

-(NSString *)cacheKeyForEntityName:(NSString *)entityName andUID:(NSString *)theUID
{
    return [entityName stringByAppendingString:theUID];
}

@end
