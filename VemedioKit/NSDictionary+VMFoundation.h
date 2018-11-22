//
//  NSDictionary+VMFoundation.h
//  Instacast
//
//  Created by Martin Hering on 21.01.13.
//
//

#import <Foundation/Foundation.h>

@interface NSDictionary (VMFoundation)

- (NSDictionary *) dictionaryByRemovingNullValues;

@end
