//
//  Base64.h
//  Instacast
//
//  Created by Martin Hering on 21.03.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Base64 : NSObject
+ (NSString *)encodeBase64WithData:(NSData *)objData;
+ (NSData *)decodeBase64WithString:(NSString *)strBase64;
@end
