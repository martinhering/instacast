//
//  NSString+VMFoundation.m
//  InstacastMac
//
//  Created by Martin Hering on 08.01.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>
#include <assert.h>


#import "NSString+VMFoundation.h"
#import "NSData+VMFoundation.h"

#import "GTMNSString+HTML.h"

NSString* kVMFoundationURLRegexPattern = @"\\b(([\\w-]+://?|www[.])[^\\s()<>]+(?:\\([\\w\\d]+\\)|([^[:punct:]\\s]|/)))";


@implementation NSString (VMFoundation)

+ (NSString *) uuid
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uString = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    return uString;
}



+ (NSString *) realHomeDirectory
{
    struct passwd *pw = getpwuid(getuid());
    assert(pw);
    return [NSString stringWithUTF8String:pw->pw_dir];
}

- (NSString*) stringByStrippingHTML
{
    NSMutableString* mutableCopy = [self mutableCopy];
    [mutableCopy replaceOccurrencesOfString:@"<p>" withString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableCopy length])];
    [mutableCopy replaceOccurrencesOfString:@"<br>" withString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableCopy length])];
    [mutableCopy replaceOccurrencesOfString:@"\n" withString:@"######" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableCopy length])];
    [mutableCopy replaceOccurrencesOfRegex:@"<.*?>" withString:@" " options:NSRegularExpressionCaseInsensitive];
    [mutableCopy replaceOccurrencesOfString:@"######" withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableCopy length])];
    [mutableCopy replaceOccurrencesOfRegex:@"\\s\\s+" withString:@" " options:NSRegularExpressionCaseInsensitive];
    
	NSString* strippedString = [mutableCopy stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	return [strippedString stringByDecodingHTMLEntities];
}

- (NSString *) stringByDecodingHTMLEntities
{
	return [self gtm_stringByUnescapingFromHTML];
}

- (NSString *) stringByEncodingHTMLEntities
{
	return [self gtm_stringByEscapingForHTML];
}

- (NSString *) stringByEncodingStandardHTMLEntities
{
    return [self stringByEncodingStandardHTMLEntitiesIncludingWhitespaces:NO];
}

- (NSString *) stringByEncodingStandardHTMLEntitiesIncludingWhitespaces:(BOOL)whitespaces
{
	NSMutableString* string = [self mutableCopy];
	NSMutableDictionary *entityMap = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							   @"&amp;", @"&",
							   @"&lt;", @"<",
							   @"&rt;", @">",
							   @"&apos;", @"'",
							   @"&apos;", @"’",
							   @"&quot;", @"\"",
							   nil];

	NSArray* keys = [NSArray arrayWithObjects:@"&", @"<", @">", @"'", @"’", @"\"", nil];
	for(NSString* key in keys) {
		[string replaceOccurrencesOfString:key withString:[entityMap objectForKey:key] options:0 range:NSMakeRange(0, [string length])];
	}
    
    if (whitespaces) {
        string = [[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] mutableCopy];
        [string replaceOccurrencesOfString:@"\n" withString:@"</br>" options:0 range:NSMakeRange(0, [string length])];
    }
    
	return string;
}

#pragma mark -

//static NSString* HexStringFromBytes(const UInt8* bytes, CFIndex len)
//{
//	NSMutableString *output = [NSMutableString string];
//	
//	unsigned char *input = (unsigned char *)bytes;
//	
//	NSUInteger i;
//	for (i = 0; i < len; i++)
//		[output appendFormat:@"%02x", input[i]];
//	return output;
//}

- (NSString *)MD5Hash
{
    NSData* inputData = [self dataUsingEncoding:NSUTF8StringEncoding];
	return [inputData MD5Hash];
}

- (NSString*) stringByReplacingOccurrencesOfRegex:(NSString*)pattern withString:(NSString*)replacement
{
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    return [regex stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, [self length]) withTemplate:replacement];
}

- (NSString*) stringByMatchingRegex:(NSString*)pattern capture:(NSUInteger)capture
{
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    NSTextCheckingResult* result = [regex firstMatchInString:self options:0 range:NSMakeRange(0, [self length])];
    
    if (!result || capture >= [result numberOfRanges]) {
        return nil;
    }
    
    NSRange range = [result rangeAtIndex:capture];
    return [self substringWithRange:range];
}

- (NSUInteger) numberOfMatchesUsingRegex:(NSString*)pattern
{
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    return [regex numberOfMatchesInString:self options:0 range:NSMakeRange(0, [self length])];
}

- (NSString*) tailTruncatedStringWithMaxLength:(NSInteger)length
{
    if ([self length] < length) {
        return self;
    }
    
    NSRange stringRange = NSMakeRange(0, length);
    stringRange = [self rangeOfComposedCharacterSequencesForRange:stringRange];
    NSString *shortString = [[self substringWithRange:stringRange] stringByAppendingString:@"…"];
    return shortString;
}

#pragma mark -

- (NSComparisonResult) naturalCaseInsensitiveCompare:(NSString*)aString
{
    NSArray* sortPrefixes = @[@"the ", @"a ", @"this ", @"that ", @"der ", @"die ", @"das ", @"le ", @"la ", @"l'", @"los ", @"las ", @"san "];
    
    NSString* (^naturlizedString)(NSString*) = ^(NSString* string) {
        
        NSString* str = [string lowercaseString];
        
        for(NSString* prefix in sortPrefixes) {
            if ([str hasPrefix:prefix]) {
                str = [str substringFromIndex:[prefix length]];
                break;
            }
        }
        
        return str;
    };
    
    return [naturlizedString(self) caseInsensitiveCompare:naturlizedString(aString)];
}

- (BOOL) caseInsensitiveEquals:(NSString*)string
{
    return ([self compare:string options:NSCaseInsensitiveSearch] == NSOrderedSame);
}

- (BOOL) containsString:(NSString*)string
{
    return ([self rangeOfString:string].location != NSNotFound);
}
@end




@implementation NSMutableString (VMFoundation)

- (NSUInteger) replaceOccurrencesOfRegex:(NSString*)pattern withString:(NSString*)replacement
{
    return [self replaceOccurrencesOfRegex:pattern withString:replacement options:0];
}

- (NSUInteger) replaceOccurrencesOfRegex:(NSString*)pattern withString:(NSString*)replacement options:(NSRegularExpressionOptions)options
{
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:options error:&error];
    NSUInteger numberOfMatches = [regex replaceMatchesInString:self options:0 range:NSMakeRange(0, [self length]) withTemplate:replacement];
    return numberOfMatches;
}

@end
