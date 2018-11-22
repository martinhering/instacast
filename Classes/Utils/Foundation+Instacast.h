//
//  Foundation+Instacast.h
//  Instacast
//
//  Created by Martin Hering on 13.09.11.
//  Copyright (c) 2011 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Instacast)
- (NSArray *) arrayByReversingObjects;
@end


@interface NSString (Instacast)
- (NSString*) MD5Hash;
- (NSString*) stringByStrippingHTML;
- (NSString *) stringByDecodingHTMLEntities;
- (NSString *) stringByEncodingHTMLEntities;
- (NSString *) stringByEncodingStandardHTMLEntities;
- (NSString *) stringByEscapingPath;
@end

@interface NSURL (Instacast)
- (NSURL*) URLByDeletingUsernameAndPassword;
@end

@interface NSDictionary (Instacast)
- (NSDictionary *) dictionaryByRemovingNullValues;
@end