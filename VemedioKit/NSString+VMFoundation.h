//
//  NSString+VMFoundation.h
//  InstacastMac
//
//  Created by Martin Hering on 08.01.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* kVMFoundationURLRegexPattern;

@interface NSString (VMFoundation)

+ (NSString*) uuid;
+ (NSString *) realHomeDirectory;

- (NSString*) MD5Hash;

- (NSString*) stringByStrippingHTML;
- (NSString *) stringByDecodingHTMLEntities;
- (NSString *) stringByEncodingHTMLEntities;
- (NSString *) stringByEncodingStandardHTMLEntities;
- (NSString *) stringByEncodingStandardHTMLEntitiesIncludingWhitespaces:(BOOL)whitespaces;

- (NSString*) stringByReplacingOccurrencesOfRegex:(NSString*)pattern withString:(NSString*)replacement;
- (NSString*) stringByMatchingRegex:(NSString*)pattern capture:(NSUInteger)capture;
- (NSUInteger) numberOfMatchesUsingRegex:(NSString*)pattern;

- (NSString*) tailTruncatedStringWithMaxLength:(NSInteger)length;

- (NSComparisonResult) naturalCaseInsensitiveCompare:(NSString*)aString;
- (BOOL) caseInsensitiveEquals:(NSString*)string;
- (BOOL) containsString:(NSString*)string;
@end


@interface NSMutableString (VMFoundation)
- (NSUInteger) replaceOccurrencesOfRegex:(NSString*)pattern withString:(NSString*)replacement;
- (NSUInteger) replaceOccurrencesOfRegex:(NSString*)pattern withString:(NSString*)replacement options:(NSRegularExpressionOptions)options;
@end
