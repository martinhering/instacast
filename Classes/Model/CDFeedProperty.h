//
//  CDFeedProperty.h
//  Instacast
//
//  Created by Martin Hering on 08.08.12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CDBase.h"

@class CDFeed;

@interface CDFeedProperty : CDBase

@property (nonatomic) BOOL boolValue;
@property (nonatomic) NSTimeInterval dateValue;
@property (nonatomic) double doubleValue;
@property (nonatomic) int32_t int32Value;
@property (nonatomic, strong) NSString * key;
@property (nonatomic, strong) NSString * stringValue;
@property (nonatomic, strong) CDFeed *feed;

@end
