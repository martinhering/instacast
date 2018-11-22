//
//  CDCategory.h
//  Instacast
//
//  Created by Martin Hering on 08.08.12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CDBase.h"

@class CDCategory, CDFeed;

@interface CDCategory : CDBase

@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) CDFeed *feed;
@property (nonatomic, strong) CDCategory *parent;
@property (nonatomic, strong) NSSet *children;
@end

@interface CDCategory (CoreDataGeneratedAccessors)

- (void)addChildrenObject:(CDCategory *)value;
- (void)removeChildrenObject:(CDCategory *)value;
- (void)addChildren:(NSSet *)values;
- (void)removeChildren:(NSSet *)values;

@end
