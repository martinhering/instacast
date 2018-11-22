//
//  CDBase.h
//  Instacast
//
//  Created by Martin Hering on 05.09.12.
//
//

#import <CoreData/CoreData.h>



@interface CDBase : NSManagedObject

@property (nonatomic, strong) NSString* uid;

- (BOOL)isNew;

@end
