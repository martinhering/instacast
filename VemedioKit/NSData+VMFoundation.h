//
//  NSData+VMFoundation.h
//  VMFoundation
//
//  Created by Martin Hering on 30.04.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (VMFoundation)

+ (NSData*) dataWithBase64EncodedString:(NSString*)string;
- (NSString*) stringFromBase64EncodedData;
- (NSString*) stringFromBase64EncodedDataWithLineLength:(NSInteger)lineLength;

- (NSString*) MD5Hash;
- (NSData*) MD5Data;
- (NSData*) SHA256Data;
- (NSData*) HMACSHA2HashUsingKey:(NSData*)key bitLength:(NSInteger)bitLength;

// only works when self is somewhat xml data
- (NSData*) sanatizedXMLData;
@end
