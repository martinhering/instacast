//
//  ICAppearanceDaylightCalculator.h
//  Instacast
//
//  Created by Martin Hering on 29.07.14.
//
//



#import <Foundation/Foundation.h>

@class CLLocation;

@interface ICAppearanceDaylightCalculator : NSObject

@property (nonatomic, strong) NSDate* date;
@property (nonatomic, strong, readonly) NSDate* sunrise;
@property (nonatomic, strong, readonly) NSDate* sunset;

- (id) initWithWithLocation:(CLLocation*)location date:(NSDate*)date;

@end
