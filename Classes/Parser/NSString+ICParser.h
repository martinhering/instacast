//
//  NSString+ICParser.h
//  Instacast
//
//  Created by Martin Hering on 11.11.12.
//
//

#import <Foundation/Foundation.h>

@interface NSString (ICParser)
- (BOOL) isSetToTrue;
- (BOOL) caseInsensitiveContainsStringInArray:(NSArray*)array;
@end
