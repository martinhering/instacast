//
//  Foundation+Localization.m
//  VMFoundation
//
//  Created by Martin Hering on 18.05.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import "Foundation+Localization.h"
#import "NSObject+VMFoundation.h"

@implementation NSBundle (Localization)
- (NSString*) preflightTokenOfLocalizationKey:(NSString**)localizationKey
{
    if (!localizationKey || !*localizationKey) {
        return nil;
    }
    
    NSArray* possibleTokens = @[@"…", @":"];
    for (NSString* token in possibleTokens) {
        if ([*localizationKey hasSuffix:token]) {
            *localizationKey = [*localizationKey substringToIndex:([*localizationKey length]-[token length])];
            return token;
        }
    }
    
    return nil;
}

- (NSString*) localizedStringForKey:(NSString*)key value:(NSString *)value preflightToken:(NSString*)preflightToken
{
//    NSString* localizedString = NSLocalizedStringFromTableInBundle(key, @"Localizable", self, 0);
    NSString* localizedString = [self vm_localizedStringForKey:key value:value table:@"Localizable"];
    if (preflightToken && ![localizedString hasSuffix:preflightToken]) {
        localizedString = [localizedString stringByAppendingString:preflightToken];
    }
    return (localizedString) ? localizedString : value;
}

- (NSString*) localizedStringForKey:(NSString*)key value:(NSString *)value prefix:(NSString*)prefix preflightToken:(NSString*)preflightToken
{
    NSString* compositeKey = ([prefix length] > 0) ? [NSString stringWithFormat:@"%@_%@", prefix, key] : nil;
    NSString* compositeKeyWithPreflightToken = (preflightToken) ? [compositeKey stringByAppendingString:preflightToken] : compositeKey;
    
    if (compositeKey) {
        NSString* localizedString = [self localizedStringForKey:compositeKey value:value preflightToken:preflightToken];
        if (![localizedString isEqualToString:compositeKeyWithPreflightToken]) {
            return localizedString;
        }
    }
    
    return [self localizedStringForKey:key value:value preflightToken:preflightToken];
}

- (NSArray<NSString*>*) vm_preferredLocalization {
    return [self associatedObjectForKey:@"vm_preferredLocalizations"];
}
- (void) vm_setPreferredLocalizations:(NSArray<NSString*>*)preferredLocalizations
{
    [self setAssociatedObjectCopy:preferredLocalizations forKey:@"vm_preferredLocalizations"];
    [self setAssociatedObject:nil forKey:@"vm_localizableStringsDictionary"];
}

- (NSString *) vm_localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName {
    NSArray<NSString*>* vm_preferredLocalization = [self vm_preferredLocalization];
    if (!vm_preferredLocalization) {
        return [self localizedStringForKey:key value:value table:tableName];
    }

    if (!tableName) {
        tableName = @"Localizable";
    }

    NSMutableDictionary<NSString*, NSDictionary*>* cachedLocalizedStrings = [self associatedObjectForKey:@"vm_localizableStringsDictionary"];
    if (!cachedLocalizedStrings) {
        cachedLocalizedStrings = [[NSMutableDictionary alloc] init];
        [self setAssociatedObject:cachedLocalizedStrings  forKey:@"vm_localizableStringsDictionary"];
    }

    NSDictionary* content = cachedLocalizedStrings[tableName];
    if (!content) {
        for(NSString* localization in vm_preferredLocalization) {
            NSURL* fileURL = [self URLForResource:tableName withExtension:@"strings" subdirectory:nil localization:localization];
            if (fileURL) {
                content = [NSDictionary dictionaryWithContentsOfURL:fileURL];
                cachedLocalizedStrings[tableName] = content;
                break;
            }

        }
    }

    NSString* localizedString = content[key];
    return (localizedString) ? localizedString : key;
}

- (NSLocale *) vm_currentLocale {
    NSArray<NSString*>* vm_preferredLocalization = [self vm_preferredLocalization];
    if (!vm_preferredLocalization) {
        return [NSLocale currentLocale];
    }

    return [NSLocale localeWithLocaleIdentifier:vm_preferredLocalization.firstObject];
}

@end

@implementation NSString (Localization)

- (NSString*) ls
{
    return [self localizedString:[NSBundle mainBundle]];
}

- (NSString*) localizedString:(NSBundle*)bundle
{
    NSString* string = self;
    NSString* preflightToken = [bundle preflightTokenOfLocalizationKey:&string];
    
    NSString* localizedString = [bundle localizedStringForKey:string value:self preflightToken:preflightToken];
    if (!localizedString) {
        return self;
    }
    return localizedString;
}
@end
