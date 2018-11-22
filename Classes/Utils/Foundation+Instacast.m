//
//  NSArray+Instacast.m
//  Instacast
//
//  Created by Martin Hering on 13.09.11.
//  Copyright (c) 2011 Vemedio. All rights reserved.
//


#import "Foundation+Instacast.h"
//#if TARGET_OS_IPHONE
#import <CommonCrypto/CommonDigest.h>
//#else
//#import <Security/Security.h>
//#endif

#import "RegexKitLite.h"
#import "GTMNSString+HTML.h"


@implementation NSArray (Instacast)

- (NSArray *) arrayByReversingObjects
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self count]];
    NSEnumerator *enumerator = [self reverseObjectEnumerator];
    for (id element in enumerator) {
        [array addObject:element];
    }
    return array;
}
@end

#pragma mark -

static NSString* HexStringFromBytes(const UInt8* bytes, CFIndex len)
{
	NSMutableString *output = [NSMutableString string];
	
	unsigned char *input = (unsigned char *)bytes;
	
	NSUInteger i;
	for (i = 0; i < len; i++)
		[output appendFormat:@"%02x", input[i]];
	return output;
}

@implementation NSString (MD5Extension)

- (NSString *)MD5Hash
{
    NSString* md5Hash;
    
    
//if TARGET_OS_IPHONE
    const char *input = [self UTF8String];
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	CC_MD5(input, (CC_LONG)strlen(input), result);
	md5Hash = HexStringFromBytes(result, CC_MD5_DIGEST_LENGTH);
    
//#else
//    CFErrorRef error = NULL;
//    NSData* inputData = [self dataUsingEncoding:NSUTF8StringEncoding];
//    
//    SecTransformRef digestRef = SecDigestTransformCreate(kSecDigestMD5, 0, &error);
//    SecTransformSetAttribute(digestRef, kSecTransformInputAttributeName, (__bridge CFDataRef)inputData, &error);
//    CFDataRef resultData = SecTransformExecute(digestRef, &error);
//    md5Hash = HexStringFromBytes(CFDataGetBytePtr(resultData), CFDataGetLength(resultData));
//    
//    CFRelease(resultData);
//    CFRelease(digestRef);
//#endif
	return md5Hash;
}


- (NSString*) stringByStrippingHTML
{
    NSMutableString* mutableCopy = [self mutableCopy];
    [mutableCopy replaceOccurrencesOfString:@"<p>" withString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableCopy length])];
    [mutableCopy replaceOccurrencesOfString:@"<br>" withString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableCopy length])];
    [mutableCopy replaceOccurrencesOfRegex:@"<.*?>" withString:@"" options:RKLCaseless range:NSMakeRange(0, [mutableCopy length]) error:nil];
    [mutableCopy replaceOccurrencesOfRegex:@"\\s\\s+" withString:@" " options:RKLCaseless range:NSMakeRange(0, [mutableCopy length]) error:nil];

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
	NSMutableString* string = [self mutableCopy];
	NSDictionary *entityMap = [NSDictionary dictionaryWithObjectsAndKeys: 
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
	return string;
}

- (NSString *) stringByEscapingPath
{
	NSString* string = (__bridge_transfer  NSString*)CFURLCreateStringByAddingPercentEscapes (kCFAllocatorDefault,
                                                                           (__bridge CFStringRef)self,
                                                                           NULL,
                                                                           CFSTR(" "),
                                                                           kCFStringEncodingUTF8);
	return string;
}

@end

#pragma mark -

@implementation NSURL (Instacast)

// test cases
// [[NSURL URLWithString:@"http://user:pass@host.com/path/?test=1"] URLByDeletingUsernameAndPassword];
// [[NSURL URLWithString:@"http://user@host.com/path/?test=1"] URLByDeletingUsernameAndPassword];
// [[NSURL URLWithString:@"http://user@host.com/path?test=1"] URLByDeletingUsernameAndPassword];

- (NSURL*) URLByDeletingUsernameAndPassword
{
    NSString* host = [self host];
    NSString* scheme = [self scheme];
    NSString* user = [self user];
    NSString* password = [self password];
    
    if (!scheme || !host) {
        return self;
    }
    
    if (!user && !password) {
        return self;
    }
    
    NSString* credentials = (password) ? [NSString stringWithFormat:@"%@@%@:", user, password] : [NSString stringWithFormat:@"%@:", user];
    NSMutableString* urlString = [[self absoluteString] mutableCopy];
    
    [urlString deleteCharactersInRange:NSMakeRange([scheme length]+3, [credentials length])];
    
    NSURL* newURL = [NSURL URLWithString:urlString];
    return newURL;
}
@end


@implementation NSDictionary (Instacast)

- (NSDictionary *) dictionaryByRemovingNullValues {
    
    if (![self isKindOfClass:[NSDictionary class]]) {
        return self;
    }
    
    const NSMutableDictionary* replaced = [self mutableCopy];
    const id nul = [NSNull null];
    
    for(NSString *key in self) {
        const id object = [self objectForKey:key];
        if(object == nul) {
            [replaced removeObjectForKey:key];
        }
    }
    return (NSDictionary *)replaced;
}

@end
