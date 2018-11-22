//
//  Foundation+Localization.h
//  VMFoundation
//
//  Created by Martin Hering on 18.05.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBundle (Localization)
- (NSString*) preflightTokenOfLocalizationKey:(NSString**)localizationKey;
- (NSString*) localizedStringForKey:(NSString*)key value:(NSString *)value preflightToken:(NSString*)preflightToken;
- (NSString*) localizedStringForKey:(NSString*)key value:(NSString *)value prefix:(NSString*)prefix preflightToken:(NSString*)preflightToken;

- (NSArray<NSString*>*) vm_preferredLocalization;
- (void) vm_setPreferredLocalizations:(NSArray<NSString*>*)preferredLocalizations;
- (NSString *) vm_localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName;
- (NSLocale *) vm_currentLocale;
@end

@interface NSString (Localization)
@property (nonatomic, readonly) NSString* ls;
- (NSString*) localizedString:(NSBundle*)bundle;
@end

#define ls_plugin localizedString:[NSBundle bundleForClass:[self class]]