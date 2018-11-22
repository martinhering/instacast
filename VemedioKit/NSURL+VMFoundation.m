//
//  NSURL+VMFoundation.m
//  InstacastSearchIndexer
//
//  Created by Martin Hering on 16.01.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import "NSURL+VMFoundation.h"
#import "NSString+VMFoundation.h"

@implementation NSURL (VMFoundation)
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

- (NSDictionary*) queryParameters
{
	NSString* query = [self query];
	NSArray* valuePairs = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary* values = [NSMutableDictionary dictionary];
	for(NSString* valuePair in valuePairs)
	{
		NSRange range = [valuePair rangeOfString:@"="];
		if (range.location != NSNotFound && [valuePair length]>range.location) {
			NSString* value = [valuePair substringFromIndex:range.location+1];
			value = [value stringByReplacingOccurrencesOfString:@"+" withString:@"%20"];

			NSString* decodedValue = [value stringByRemovingPercentEncoding];
            
			NSString* key = [valuePair substringToIndex:range.location];
            if (key && decodedValue) {
                [values setObject:decodedValue forKey:[key lowercaseString]];
            }
		}
	}
	return values;
}

- (NSURL*) URLByDeletingQuery
{
    if ([self query]) {
        NSString* query = [NSString stringWithFormat:@"?%@",[self query]];
        NSString* URLString = [[self absoluteString] stringByReplacingOccurrencesOfString:query withString:@""];
        return [NSURL URLWithString:URLString];
    }
    return self;
}

- (NSURL*) URLByAddingQueryParameters:(NSDictionary*)dictionary
{
    if ([dictionary count] == 0) {
        return self;
    }
    
    NSMutableString* query = [[NSMutableString alloc] init];
    for (NSString* key in dictionary) {
        
    
        
        NSString* keyValuePair = [NSString stringWithFormat:@"%@=%@", key, [[dictionary objectForKey:key] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
        
        if ([query length] > 0) {
            [query appendString:@"&"];
        }
        
        [query appendString:keyValuePair];
    }
    
    NSString* URLString = [[self absoluteString] stringByAppendingFormat:@"?%@", query];
    return [NSURL URLWithString:URLString];
}

- (NSString*) prettyString
{
    NSString* schemePrefix = [[self scheme] stringByAppendingString:@":"];
    NSString* wwwPrefix = @"www.";
    
    NSString* urlString = [[self absoluteString] substringFromIndex:[schemePrefix length]];
    urlString = [urlString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    if ([urlString hasPrefix:wwwPrefix]) {
        urlString = [urlString substringFromIndex:[wwwPrefix length]];
    }
    return urlString;
}

+ (NSURL*) URLWithInsecureString:(NSString*)string
{
    return [self URLWithInsecureString:string relativeToURL:nil];
}

+ (id) URLWithInsecureString:(NSString *)string relativeToURL:(NSURL *)baseURL
{
    if (!string) {
        return nil;
    }
    
    // fix broken white spaces
    string = [[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    return [self URLWithString:string];
}

- (BOOL)isEquivalent:(NSURL *)aURL
{
    if ([self isEqual:aURL]) return YES;
    if ([[self scheme] caseInsensitiveCompare:[aURL scheme]] != NSOrderedSame) return NO;
    if ([[self host] caseInsensitiveCompare:[aURL host]] != NSOrderedSame) return NO;
    
    // NSURL path is smart about trimming trailing slashes
    // note case-sensitivty check

    NSNumber *caseSensitiveFS;
    BOOL hasCaseSensitiveResource = [self getResourceValue:&caseSensitiveFS forKey:NSURLVolumeSupportsCaseSensitiveNamesKey error:NULL];
    
    if (hasCaseSensitiveResource && ![caseSensitiveFS boolValue]) {
        if ([[self path] caseInsensitiveCompare:[aURL path]] != NSOrderedSame) return NO;
    }
    else
    {
        if ([[self path] compare:[aURL path]] != NSOrderedSame) return NO;
    }
    
    // at this point, we've established that the urls are equivalent according to the rfc
    // insofar as scheme, host, and paths match
    
    // according to rfc2616, port's can weakly match if one is missing and the
    // other is default for the scheme, but for now, let's insist on an explicit match
    if ([[self port] compare:[aURL port]] != NSOrderedSame) return NO;
    
    if ([[self query] compare:[aURL query]] != NSOrderedSame) return NO;
    
    // for things like user/pw, fragment, etc., seems sensible to be
    // permissive about these.  (plus, I'm tired :-))
    return YES;
}

- (NSComparisonResult)compare:(NSURL *)otherURL
{
    return [[self absoluteString] compare:[otherURL absoluteString]];
}
@end
