//
//  ICPubdateValueTransformer.m
//  Instacast
//
//  Created by Martin Hering on 25.04.15.
//
//

#import "ICPubdateValueTransformer.h"

@interface ICPubdateValueTransformer ()
@property (readonly) NSDateFormatter* dateFormatter;
@property (readonly) NSDateFormatter* weekdayDateFormatter;
@end

@implementation ICPubdateValueTransformer

- (NSDateFormatter*) dateFormatter
{
    static NSDateFormatter* dateFormatter = nil;
    
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    });
    
    return dateFormatter;
}

- (NSDateFormatter*) weekdayDateFormatter
{
    static NSDateFormatter* weekdayDateFormatter = nil;
    
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        weekdayDateFormatter = [[NSDateFormatter alloc] init];
        [weekdayDateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US".ls]];
        [weekdayDateFormatter setDateFormat:@"EEEE"];
    });
    
    return weekdayDateFormatter;
}


+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (NSString*)transformedValue:(NSDate*)pubDate
{
    if (!pubDate) {
        return nil;
    }
    
    NSDate* today = [NSDate date];
    NSDate* yesterday = [today dateByAddingTimeInterval:-86400];
    
    NSCalendar* calendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
    NSDateComponents* pubDateComponents = [calendar components:unitFlags fromDate:pubDate];
    NSDateComponents* todayComponents = [calendar components:unitFlags fromDate:today];
    NSDateComponents* yesterdayComponents = [calendar components:unitFlags fromDate:yesterday];
    
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:pubDate];
    if ([pubDateComponents year] == [todayComponents year] && [pubDateComponents month] == [todayComponents month] && [pubDateComponents day] == [todayComponents day]) {
        return @"Today".ls;
    }
    else if ([pubDateComponents year] == [yesterdayComponents year] && [pubDateComponents month] == [yesterdayComponents month] && [pubDateComponents day] == [yesterdayComponents day]) {
        return @"Yesterday".ls;
    }
    else if (timeInterval < 86400*6) {
        return [self.weekdayDateFormatter stringFromDate:pubDate];
    }
    else {
        return [self.dateFormatter stringFromDate:pubDate];
    }
 
    return nil;
}

@end
