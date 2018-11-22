//
//  ArbitraryDateParser.m
//  ArbitraryDateParser
//
//  Created by Martin Hering on 01.12.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import "ArbitraryDateParser.h"

enum {
    kTokenTypeUnknown,
    kTokenTypeTimezoneString,
    kTokenTypeTimezoneValue,
    kTokenTypeTimeString,
    kTokenTypeEuropeanDateString,
    kTokenTypeAmericanDateString,
    kTokenTypeDotDateString,
    kTokenTypeISO8601String,
    kTokenTypePostMeridiemIndicatorString,
    kTokenTypeMonthToken,
    kTokenTypeDayToken,
    kTokenTypeDecimalString,
};
typedef NSInteger TokenType;

@interface ArbitraryDateParser ()
@property (nonatomic, strong) NSDictionary* timezoneValues;
@property (nonatomic, strong) NSCharacterSet* timeValueCharacterSet;
@property (nonatomic, strong) NSCharacterSet* europeanDateValueCharacterSet;
@property (nonatomic, strong) NSCharacterSet* americanDateValueCharacterSet;
@property (nonatomic, strong) NSCharacterSet* dotDateValueCharacterSet;
@property (nonatomic, strong) NSCharacterSet* iso8601CharacterSet;
@property (nonatomic, strong) NSCharacterSet* iso8601TimeAndTimezoneValueCharacterSet;
@property (nonatomic, strong) NSArray* postMeridiemTokens;
@property (nonatomic, strong) NSDictionary* monthTokens;
@property (nonatomic, strong) NSArray* dayTokens;
@property (nonatomic, strong) NSCharacterSet* decimalCharacterSet;
@property (nonatomic, strong) NSCalendar* calendar;
@end

@implementation ArbitraryDateParser

- (id) init
{
    if ((self = [super init]))
    {
        self.timezoneValues = @{
                                @"CHADT" : @(49500),
                                @"OMST" : @(21600),
                                @"HNR" : @(-25200),
                                @"PYT" : @(-14400),
                                @"NCT" : @(39600),
                                @"KUYT" : @(14400),
                                @"HLV" : @(-14400),
                                @"PT" : @(-28800),
                                @"AKDT" : @(-28800),
                                @"EASST" : @(-18000),
                                @"CVT" : @(-3600),
                                @"MAGT" : @(39600),
                                @"EST" : @(-18000),
                                @"HNT" : @(-10800),
                                @"NDT" : @(-7200),
                                @"AZT" : @(14400),
                                @"MAGST" : @(43200),
                                @"IRKST" : @(32400),
                                @"HAA" : @(-10800),
                                @"LHDT" : @(39600),
                                @"ET" : @(-18000),
                                @"CXT" : @(25200),
                                @"NOVT" : @(21600),
                                @"NFT" : @(39600),
                                @"AKST" : @(-32400),
                                @"HAC" : @(-18000),
                                @"MHT" : @(43200),
                                @"TVT" : @(43200),
                                @"CHAST" : @(45900),
                                @"IOT" : @(21600),
                                @"HNY" : @(-32400),
                                @"GST" : @(14400),
                                @"PDT" : @(-25200),
                                @"HAE" : @(-14400),
                                @"MSD" : @(14400),
                                @"ADT" : @(-10800),
                                @"KRAT" : @(25200),
                                @"EAST" : @(-21600),
                                @"NOVST" : @(25200),
                                @"LHST" : @(0),
                                @"CAT" : @(7200),
                                @"PET" : @(-18000),
                                @"WST" : @(3600),
                                @"VUT" : @(39600),
                                @"VLAT" : @(0),
                                @"YAKT" : @(32400),
                                @"NZDT" : @(46800),
                                @"SAMT" : @(14400),
                                @"CAST" : @(28800),
                                @"AFT" : @(16200),
                                @"EGST" : @(0),
                                @"GALT" : @(-21600),
                                @"WEST" : @(3600),
                                @"YAPT" : @(0),
                                @"CCT" : @(21600),
                                @"PGT" : @(0),
                                @"SBT" : @(39600),
                                @"IST" : @(7200),
                                @"AZST" : @(18000),
                                @"HOVT" : @(25200),
                                @"UYT" : @(-10800),
                                @"CDT" : @(-14400),
                                @"MMT" : @(21600),
                                @"PHT" : @(28800),
                                @"SCT" : @(14400),
                                @"EAT" : @(10800),
                                @"IRKT" : @(28800),
                                @"RET" : @(14400),
                                @"BRST" : @(-7200),
                                @"PMDT" : @(-7200),
                                @"MSK" : @(10800),
                                @"NZST" : @(43200),
                                @"UZT" : @(18000),
                                @"ALMT" : @(21600),
                                @"CET" : @(3600),
                                @"JST" : @(32400),
                                @"WIB" : @(25200),
                                @"GYT" : @(-14400),
                                @"ECT" : @(-18000),
                                @"PETST" : @(43200),
                                @"KST" : @(32400),
                                @"PETT" : @(43200),
                                @"HAP" : @(-25200),
                                @"PHOT" : @(46800),
                                @"PKT" : @(18000),
                                @"FKST" : @(-10800),
                                @"EDT" : @(-14400),
                                @"PMST" : @(-10800),
                                @"HADT" : @(-32400),
                                @"AMST" : @(-10800),
                                @"HAR" : @(-21600),
                                @"IRDT" : @(14400),
                                @"EET" : @(7200),
                                @"KRAST" : @(28800),
                                @"SGT" : @(28800),
                                @"WT" : @(0),
                                @"A" : @(3600),
                                @"MART" : @(-32400),
                                @"NPT" : @(20700),
                                @"B" : @(7200),
                                @"TFT" : @(18000),
                                @"WAT" : @(3600),
                                @"C" : @(10800),
                                @"AZOST" : @(0),
                                @"D" : @(14400),
                                @"HAT" : @(-7200),
                                @"OMSST" : @(25200),
                                @"E" : @(18000),
                                @"AMT" : @(-14400),
                                @"F" : @(21600),
                                @"MAWT" : @(18000),
                                @"VLAST" : @(39600),
                                @"G" : @(25200),
                                @"WITA" : @(28800),
                                @"YAKST" : @(0),
                                @"H" : @(28800),
                                @"MST" : @(-25200),
                                @"WAST" : @(7200),
                                @"EGT" : @(-3600),
                                @"I" : @(32400),
                                @"K" : @(0),
                                @"HAST" : @(0),
                                @"HNA" : @(-14400),
                                @"CKT" : @(0),
                                @"IRST" : @(10800),
                                @"L" : @(39600),
                                @"M" : @(43200),
                                @"AQTT" : @(18000),
                                @"N" : @(-3600),
                                @"PYST" : @(-10800),
                                @"VET" : @(-14400),
                                @"O" : @(-7200),
                                @"GET" : @(14400),
                                @"P" : @(-10800),
                                @"NST" : @(-10800),
                                @"WDT" : @(32400),
                                @"Q" : @(-14400),
                                @"CLT" : @(-14400),
                                @"WGST" : @(-7200),
                                @"HNC" : @(-21600),
                                @"MUT" : @(14400),
                                @"R" : @(-18000),
                                @"BNT" : @(28800),
                                @"HAY" : @(-28800),
                                @"S" : @(-21600),
                                @"T" : @(-25200),
                                @"GFT" : @(-10800),
                                @"U" : @(-28800),
                                @"TJT" : @(18000),
                                @"WET" : @(0),
                                @"V" : @(-32400),
                                @"ICT" : @(25200),
                                @"AZOT" : @(-3600),
                                @"GAMT" : @(-32400),
                                @"MVT" : @(18000),
                                @"BOT" : @(-14400),
                                @"HNE" : @(-18000),
                                @"TAHT" : @(0),
                                @"W" : @(0),
                                @"X" : @(-39600),
                                @"Y" : @(-43200),
                                @"SAST" : @(7200),
                                @"GILT" : @(43200),
                                @"NUT" : @(-39600),
                                @"TKT" : @(0),
                                @"IDT" : @(10800),
                                @"WFT" : @(43200),
                                @"Z" : @(0),
                                @"ANAST" : @(43200),
                                @"CLST" : @(-10800),
                                @"ART" : @(-10800),
                                @"ChST" : @(0),
                                @"TLT" : @(32400),
                                @"WGT" : @(-10800),
                                @"COT" : @(-18000),
                                @"FJT" : @(43200),
                                @"PST" : @(-28800),
                                @"ULAT" : @(28800),
                                @"FJST" : @(46800),
                                @"PONT" : @(39600),
                                @"AST" : @(-14400),
                                @"TMT" : @(18000),
                                @"FKT" : @(-14400),
                                @"MYT" : @(28800),
                                @"BRT" : @(-10800),
                                @"WIT" : @(32400),
                                @"ANAT" : @(43200),
                                @"BST" : @(3600),
                                @"LINT" : @(50400),
                                @"BTT" : @(21600),
                                @"CST" : @(-21600),
                                @"EEST" : @(10800),
                                @"FNT" : @(-7200),
                                @"PWT" : @(32400),
                                @"SRT" : @(-10800),
                                @"HKT" : @(28800),
                                @"UYST" : @(-7200),
                                @"YEKST" : @(21600),
                                @"GMT" : @(0),
                                @"HNP" : @(-28800),
                                @"YEKT" : @(18000),
                                @"DAVT" : @(25200),
                                @"SST" : @(-39600),
                                @"KGT" : @(21600),
                                @"MDT" : @(-21600),
                                @"CEST" : @(7200)
                                };
        
        self.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        
        self.decimalCharacterSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
        
        NSMutableCharacterSet* timeValueCharacterSet = [NSMutableCharacterSet decimalDigitCharacterSet];
        [timeValueCharacterSet addCharactersInString:@":."]; //rizzi: add '.' for YYYY-MM-DDThh:mm:ss.sTZD (eg 1997-07-16T19:20:30.45+01:00)
        self.timeValueCharacterSet = [timeValueCharacterSet invertedSet];
        
        NSMutableCharacterSet* europeanDateValueCharacterSet = [NSMutableCharacterSet decimalDigitCharacterSet];
        [europeanDateValueCharacterSet addCharactersInString:@"-"];
        self.europeanDateValueCharacterSet = [europeanDateValueCharacterSet invertedSet];
        
        NSMutableCharacterSet* dotDateValueCharacterSet = [NSMutableCharacterSet decimalDigitCharacterSet];
        [dotDateValueCharacterSet addCharactersInString:@"."];
        self.dotDateValueCharacterSet = [dotDateValueCharacterSet invertedSet];
        
        NSMutableCharacterSet* americanDateValueCharacterSet = [NSMutableCharacterSet decimalDigitCharacterSet];
        [americanDateValueCharacterSet addCharactersInString:@"/"];
        self.americanDateValueCharacterSet = [americanDateValueCharacterSet invertedSet];
        
        NSMutableCharacterSet* iso8601CharacterSet = [NSMutableCharacterSet decimalDigitCharacterSet];
        [iso8601CharacterSet addCharactersInString:@"-:+-T."]; //rizzi: add '.' for YYYY-MM-DDThh:mm:ss.sTZD (eg 1997-07-16T19:20:30.45+01:00)
        self.iso8601CharacterSet = [iso8601CharacterSet invertedSet];
        
        NSMutableCharacterSet* iso8601TimeAndTimezoneValueCharacterSet = [NSMutableCharacterSet decimalDigitCharacterSet];
        [iso8601TimeAndTimezoneValueCharacterSet addCharactersInString:@":+-."]; //rizzi: add '.' for YYYY-MM-DDThh:mm:ss.sTZD (eg 1997-07-16T19:20:30.45+01:00)
        self.iso8601TimeAndTimezoneValueCharacterSet = [iso8601TimeAndTimezoneValueCharacterSet invertedSet];
        
        self.postMeridiemTokens = @[ @"pm", @"p.m."];
        
        self.monthTokens = @{
                             @"jan" : @(1), @"feb" : @(2), @"mar" : @(3), @"apr" : @(4), @"may" : @(5), @"jun" : @(6), @"jul" : @(7), @"aug" : @(8), @"sep" : @(9), @"oct" : @(10), @"nov" : @(11), @"dec" : @(12),
                             @"january" : @(1), @"february" : @(2), @"march" : @(3), @"april" : @(4), @"may" : @(5), @"june" : @(6), @"july" : @(7), @"august" : @(8), @"september" : @(9), @"october" : @(10), @"november" : @(11), @"december" : @(12),
                             
                             @"mär": @(3), @"mrz": @(3), @"sept" : @(9), @"okt" : @(10), @"dez" : @(12),
                             @"januar" : @(1), @"februar" : @(2), @"märz" : @(3), @"mai" : @(5), @"juni" : @(6), @"juli" : @(7), @"oktober" : @(10), @"dezember" : @(12),
                             
                             @"fév" : @(2), @"avr" : @(4), @"jui" : @(6), @"juil" : @(7), @"août" : @(8), @"déc" : @(12),
                             @"janvier" : @(1), @"février" : @(2), @"mars" : @(3), @"avril" : @(4), @"mai" : @(5), @"juin" : @(6), @"juillet" : @(7), @"août" : @(8), @"septembre" : @(92), @"octobre" : @(10), @"novembre" : @(11), @"décembre" : @(12),
                             
                             @"enero" : @(1), @"marzo" : @(3), @"abr" : @(4), @"mayo" : @(5), @"agosto" : @(8), @"set" : @(9), @"dic" : @(12),
                             
                             @"1月" : @(1), @"2月" : @(2), @"3月" : @(3), @"4月" : @(4), @"5月" : @(5), @"6月" : @(6), @"7月" : @(7), @"8月" : @(8), @"9月" : @(92), @"10月" : @(10), @"11月" : @(11), @"12月" : @(12),
                             
                             // found fails
                             @"ju1" : @(7), @"febuary" : @(2), @"mrt" : @(3),
                             };
        
        self.dayTokens = @[@"1st", @"2nd", @"3rd", @"4th", @"5th", @"6th", @"7th", @"8th", @"9th", @"10th", @"11th", @"12th", @"13th", @"14th", @"15th", @"16th", @"17th", @"18th", @"19th", @"20th", @"21st", @"22nd", @"23rd", @"24th", @"25th", @"26th", @"27th", @"28th", @"29th", @"30th", @"31st"];
    }
    
    
    return self;
}

- (NSTimeInterval) timeIntervalForTimezoneString:(NSString*)timezone
{
    return [[self.timezoneValues objectForKey:[timezone uppercaseString]] floatValue];
}

- (NSTimeInterval) timeIntervalForTimezoneValue:(NSString*)timezone
{
    timezone = [timezone stringByReplacingOccurrencesOfString:@":" withString:@""];
    
    NSInteger v = [timezone integerValue];
    NSInteger h = v / 100;
    NSTimeInterval t = 0;
    
    if (labs(h) <= 12) {
        NSInteger m = (v - h*100);
        t = h*3600 + m*60;
    } else {
        t = v;
    }
    
    return t;
}

- (NSTimeInterval) timeIntervalForTimeValue:(NSString*)timeValue
{
    //rizzi NSArray* values = [timeValue componentsSeparatedByString:@":"];
    NSArray *values = [timeValue componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":."]];
    
    NSTimeInterval t = 0;
    
    if ([values count] == 2) {
        t = [(NSString*)[values objectAtIndex:0] integerValue] * 3600 + [(NSString*)[values objectAtIndex:1] integerValue] * 60;
    }
    else if ([values count] > 2) {
        t = [(NSString*)[values objectAtIndex:0] integerValue] * 3600 + [(NSString*)[values objectAtIndex:1] integerValue] * 60 + [(NSString*)[values objectAtIndex:2] integerValue];
        if ([values count] > 3) { //rizzi
            t += [[NSString stringWithFormat:@"0.%@",(NSString*)[values objectAtIndex:3]] floatValue];
        }
    }
    
    if (t >= 86400) {
        t -= 86400;
    }
    
    return t;
}

- (NSTimeInterval) dateIntervalSince1970ForEuropeanDateString:(NSString*)dateValue separator:(NSString*)separator inverseNotation:(BOOL)inverseNotation
{
    NSArray* values = [dateValue componentsSeparatedByString:separator];
    NSTimeInterval t = 0;
    NSInteger year=0;
    NSInteger month=0;
    NSInteger day=0;
    
    if ([values count] == 3) {
        if ([[values objectAtIndex:0] length] == 4) {
            year = [(NSString*)[values objectAtIndex:0] integerValue];
            month = [(NSString*)[values objectAtIndex:1] integerValue];
            day = [(NSString*)[values objectAtIndex:2] integerValue];
        }
        else if ([[values objectAtIndex:2] length] == 4) {
            day = [(NSString*)[values objectAtIndex:0] integerValue];
            month = [(NSString*)[values objectAtIndex:1] integerValue];
            year = [(NSString*)[values objectAtIndex:2]integerValue];
        }
        else if ([[values objectAtIndex:2] length] == 2) {
            day = [(NSString*)[values objectAtIndex:0] integerValue];
            month = [(NSString*)[values objectAtIndex:1] integerValue];
            year = [(NSString*)[values objectAtIndex:2] integerValue];
            if (year < 32) {
                year += 2000;
            } else {
                year += 1900;
            }
        }
    }
    if ([values count] == 2) {
        day = [(NSString*)[values objectAtIndex:0] integerValue];
        month = [(NSString*)[values objectAtIndex:1] integerValue];
        
        NSDateComponents *comps = [self.calendar components:NSCalendarUnitYear fromDate:[NSDate date]];
        year = [comps year];
    }
    
    // switch month and day, in case the value is not plausible
    if (inverseNotation || (month > 12 && day < 12)) {
        NSInteger temp = day;
        day = month;
        month = temp;
    }
    
    //NSLog(@"%@: %ld %ld %ld", dateValue, day, month, year);
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear:year];
    [comps setMonth:month];
    [comps setDay:day];
    [comps setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    NSDate* date = [self.calendar dateFromComponents:comps];
    t = [date timeIntervalSince1970];
    
    return t;
}

// 2011-01-20, 20-01-2011, 20-01-11, 20-01 (current year)
- (NSTimeInterval) dateIntervalSince1970ForEuropeanDateString:(NSString*)dateValue
{
    return [self dateIntervalSince1970ForEuropeanDateString:dateValue separator:@"-" inverseNotation:NO];
}

// 2011/11/20, 11/20/2011
- (NSTimeInterval) dateIntervalSince1970ForAmericanDateString:(NSString*)dateValue
{
    return [self dateIntervalSince1970ForEuropeanDateString:dateValue separator:@"/" inverseNotation:NO];
}

- (NSTimeInterval) dateIntervalSince1970ForDotDateString:(NSString*)dateValue
{
    return [self dateIntervalSince1970ForEuropeanDateString:dateValue separator:@"." inverseNotation:NO];
}


- (TokenType) typeForToken:(NSString*)token
{
    if ([[self.timezoneValues allKeys] containsObject:[token uppercaseString]]) {
        return kTokenTypeTimezoneString;
    }
    
    if ([token hasPrefix:@"+"] || [token hasPrefix:@"-"]) {
        return kTokenTypeTimezoneValue;
    }
    
    // check for time value
    if ([token rangeOfCharacterFromSet:self.timeValueCharacterSet].location == NSNotFound && [token rangeOfString:@":"].location != NSNotFound) {
        return kTokenTypeTimeString;
    }
    
    // check for european date
    if ([token rangeOfCharacterFromSet:self.europeanDateValueCharacterSet].location == NSNotFound && [token rangeOfString:@"-"].location != NSNotFound) {
        return kTokenTypeEuropeanDateString;
    }
    
    // check for european date
    if ([token rangeOfCharacterFromSet:self.americanDateValueCharacterSet].location == NSNotFound && [token rangeOfString:@"/"].location != NSNotFound) {
        return kTokenTypeAmericanDateString;
    }
    
    // check for date with dot notation
    if ([token rangeOfCharacterFromSet:self.dotDateValueCharacterSet].location == NSNotFound && [token rangeOfString:@"."].location != NSNotFound) {
        return kTokenTypeDotDateString;
    }
    
    if ([token rangeOfCharacterFromSet:self.iso8601CharacterSet].location == NSNotFound && [token rangeOfString:@"T"].location != NSNotFound) {
        return kTokenTypeISO8601String;
    }
    
    if ([self.postMeridiemTokens containsObject:[token lowercaseString]]) {
        return kTokenTypePostMeridiemIndicatorString;
    }
    
    if ([[self.monthTokens allKeys] containsObject:[token lowercaseString]]) {
        return kTokenTypeMonthToken;
    }
    
    if ([self.dayTokens containsObject:[token lowercaseString]]) {
        return kTokenTypeDayToken;
    }
    
    if ([token rangeOfCharacterFromSet:self.decimalCharacterSet].location == NSNotFound) {
        return kTokenTypeDecimalString;
    }
    
    return kTokenTypeUnknown;
}

- (NSTimeInterval) timeIntervalSince1970ForTokens:(NSArray*)tokens
{
    NSTimeInterval timezoneInterval = 0; // UTC
    NSTimeInterval timeValue = 0;
    NSTimeInterval dateSince1970 = 0;
    NSInteger month=0;
    NSMutableArray* dateDecimals = [NSMutableArray array];
    
    for(NSString* dirtyToken in tokens) {
        NSString* token = [dirtyToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",.;\""]];
        if ([token length] == 0) {
            continue;
        }
        //NSLog(@"token %@", token);
        
        TokenType type = [self typeForToken:token];
        
        switch (type) {
            case kTokenTypeTimezoneString:
            {
                timezoneInterval = [self timeIntervalForTimezoneString:token];
                break;
            }
            case kTokenTypeTimezoneValue:
            {
                timezoneInterval = [self timeIntervalForTimezoneValue:token];
                break;
            }
            case kTokenTypeTimeString:
            {
                timeValue = [self timeIntervalForTimeValue:token];
                break;
            }
            case kTokenTypeEuropeanDateString:
            {
                dateSince1970 = [self dateIntervalSince1970ForEuropeanDateString:token];
                break;
            }
            case kTokenTypeAmericanDateString:
            {
                dateSince1970 = [self dateIntervalSince1970ForAmericanDateString:token];
                break;
            }
            case kTokenTypeDotDateString:
            {
                dateSince1970 = [self dateIntervalSince1970ForDotDateString:token];
                break;
            }
            case kTokenTypeISO8601String:
            {
                NSArray* iso8601Tokens = [token componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"TZ"]];
                NSMutableArray* newTokens = [NSMutableArray array];
                for(NSString* iso8601Token in iso8601Tokens)
                {
                    if ([iso8601Token rangeOfCharacterFromSet:self.iso8601TimeAndTimezoneValueCharacterSet].location == NSNotFound && [iso8601Token rangeOfString:@":"].location != NSNotFound && ([iso8601Token rangeOfString:@"+"].location != NSNotFound || [iso8601Token rangeOfString:@"-"].location != NSNotFound))
                    {
                        NSRange r = [iso8601Token rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"+-"] options:0];
                        if (r.location != NSNotFound) {
                            NSString* time = [iso8601Token substringToIndex:r.location];
                            NSString* timezone = [iso8601Token substringFromIndex:r.location];
                            
                            [newTokens addObject:time];
                            [newTokens addObject:timezone];
                        }
                        
                    }
                    else
                    {
                        [newTokens addObject:iso8601Token];
                    }
                }
                
                dateSince1970 = [self timeIntervalSince1970ForTokens:newTokens];
                break;
            }
            case kTokenTypePostMeridiemIndicatorString:
            {
                timeValue += 43200;
                break;
            }
            case kTokenTypeMonthToken:
            {
                month = [(NSString*)[self.monthTokens objectForKey:[token lowercaseString]] integerValue];
                break;
            }
            case kTokenTypeDayToken:
            {
                NSInteger day = [self.dayTokens indexOfObject:token]+1;
                [dateDecimals addObject:[NSNumber numberWithInteger:day]];
                break;
            }
            case kTokenTypeDecimalString:
            {
                [dateDecimals addObject:[NSNumber numberWithInteger:[token integerValue]]];
                break;
            }
                
            default:
            {
                // token is unknown, try to separate timezone values from token
                NSMutableArray* newTokens = [NSMutableArray array];
                
                for (NSString* timezone in self.timezoneValues) {
                    if ([[dirtyToken uppercaseString] hasSuffix:timezone]) {
                        
                        [newTokens addObject:[dirtyToken substringToIndex:[dirtyToken length]-[timezone length]]];
                        [newTokens addObject:timezone];
                        break;
                    }
                }
                
                NSTimeInterval val = [self timeIntervalSince1970ForTokens:newTokens];
                if (val >= 0) {
                    dateSince1970 = val;
                }
                
            }
                //DebugLog(@"unknown token: %@",token);
                break;
        }
    }
    
    if (dateSince1970 == 0)
    {
        if (month > 0 && [dateDecimals count] >= 1) {
            NSDateComponents* comps = [[NSDateComponents alloc] init];
            [comps setMonth:month];
            NSInteger day = [(NSString*)[dateDecimals objectAtIndex:0] integerValue];
            
            NSDateComponents* defaultComponents = [self.calendar components:NSCalendarUnitYear fromDate:[NSDate date]];
            NSInteger year = [defaultComponents year];
            
            if ([dateDecimals count] >= 2) {
                year = [(NSString*)[dateDecimals objectAtIndex:1] integerValue];
                
                // swap day and year if necessary
                if (day > 31) {
                    NSInteger temp = day;
                    day = year;
                    year = temp;
                }
                
                if (year < 32) {
                    year += 2000;
                } else if (year < 100) {
                    year += 1900;
                }
            }
            
            [comps setDay:day];
            [comps setYear:year];
            
            [comps setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
            
            NSDate* date = [self.calendar dateFromComponents:comps];
            dateSince1970 = [date timeIntervalSince1970];
        }
        
        else if (month == 0 && [dateDecimals count] >= 3) {
            NSInteger day = [(NSString*)[dateDecimals objectAtIndex:0] integerValue];
            NSInteger month = [(NSString*)[dateDecimals objectAtIndex:1] integerValue];
            NSInteger year = [(NSString*)[dateDecimals objectAtIndex:2] integerValue];
            
            NSDateComponents* comps = [[NSDateComponents alloc] init];
            [comps setDay:day];
            [comps setMonth:month];
            [comps setYear:year];
            
            [comps setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
            
            NSDate* date = [self.calendar dateFromComponents:comps];
            dateSince1970 = [date timeIntervalSince1970];
        }
        
        else if (timeValue == 0) {
            NSInteger hour=0;
            NSInteger minute=0;
            NSInteger second=0;
            
            if (month > 0 && [dateDecimals count] >= 3) {
                hour = [(NSString*)[dateDecimals objectAtIndex:2] integerValue];
            }
            
            if (month > 0 && [dateDecimals count] >= 4) {
                minute = [(NSString*)[dateDecimals objectAtIndex:3] integerValue];
            }
            
            if (month > 0 && [dateDecimals count] >= 5) {
                second = [(NSString*)[dateDecimals objectAtIndex:4] integerValue];
            }
            
            timeValue = hour * 3600 + minute * 60 + second;
        }
    }
    
    if (dateSince1970 == 0) {
        return -1;
    }
    
    //    DebugLog(@"-> date:           %f", dateSince1970);
    //    DebugLog(@"-> month:          %ld", month);
    //    DebugLog(@"-> decimals:       %@", dateDecimals);
    //    DebugLog(@"-> time:           %f", timeValue);
    //    DebugLog(@"-> timezone:       %f", timezoneInterval);
    
    return dateSince1970+timeValue-timezoneInterval;
}

- (NSDate*) dateFromString:(NSString*)string
{
    @synchronized(self) {
        //DebugLog(@"input: %@", string);
        NSMutableCharacterSet* c = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
        [c addCharactersInString:@","];
        
        string = [string stringByTrimmingCharactersInSet:c];
        NSArray* tokens = [string componentsSeparatedByCharactersInSet:c];
        NSTimeInterval t = [self timeIntervalSince1970ForTokens:tokens];
        if (t <= 0) {
            return nil;
        }
        return [NSDate dateWithTimeIntervalSince1970:t];
    }
}
@end
