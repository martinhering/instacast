//
//  NSString+ICParser.m
//  Instacast
//
//  Created by Martin Hering on 11.11.12.
//
//

#import "NSString+ICParser.h"

@implementation NSString (ICParser)

- (BOOL) isSetToTrue
{
    return ([self caseInsensitiveEquals:@"yes"] || [self caseInsensitiveEquals:@"true"]|| [self caseInsensitiveEquals:@"1"]);
}

- (BOOL) caseInsensitiveContainsStringInArray:(NSArray*)array
{
    for (NSString* testString in array) {
        if ([self rangeOfString:testString options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return YES;
        }
    }
    
    return NO;
}
@end
