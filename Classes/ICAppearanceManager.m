//
//  ICAppearanceManager.m
//  Instacast
//
//  Created by Martin Hering on 26.07.14.
//
//

#import <CoreLocation/CoreLocation.h>

#import "ICAppearanceManager.h"
#import "ImageFunctions.h"
#import "InstacastAppDelegate.h"
#import "ICAppearanceDaylightCalculator.h"

NSString* ICAppearanceManagerDidUpdateAppearanceNotification = @"ICAppearanceManagerDidUpdateAppearanceNotification";

@interface ICAppearanceManager () <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, strong) CLLocation* location;
@property (nonatomic, strong) NSDate* nextSwitchDate;
@end

@implementation ICAppearanceManager

+ (instancetype) sharedManager
{
    static dispatch_once_t once;
    static ICAppearanceManager *sharedManager;
    dispatch_once(&once, ^ {
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}


- (UIImage*) _navigationBarImageWithSize:(CGSize)size appearance:(id<ICAppearance>)appearance topToBottom:(BOOL)topToBottom
{
    return ICImageFromByDrawingInContext(size, ^() {
                
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        //// Color Declarations
        UIColor* topColor = appearance.backgroundColor;
        CGFloat red, green, blue, alpha;
        [topColor getRed:&red green:&green blue:&blue alpha:&alpha];
        
        alpha *= 0.9f;
        UIColor* bottomColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
        
        //// Gradient Declarations
        CGFloat gradientLocations[] = {0, 1};
        CGGradientRef gradient = (topToBottom) ? CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)@[(id)topColor.CGColor, (id)bottomColor.CGColor], gradientLocations) : CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)@[(id)bottomColor.CGColor, (id)topColor.CGColor], gradientLocations);
        
        //// Rectangle Drawing
        UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 0, size.width, size.height)];
        CGContextSaveGState(context);
        [rectanglePath addClip];
        CGContextDrawLinearGradient(context, gradient, CGPointMake(size.width/2, 0), CGPointMake(size.width/2, size.height), 0);
        CGContextRestoreGState(context);
        
        //// Cleanup
        CGGradientRelease(gradient);
        CGColorSpaceRelease(colorSpace);
    });
}

- (void) setAppearance:(id<ICAppearance>)appearance
{
    if (_appearance != appearance) {
        _appearance = appearance;
        
        [[UINavigationBar appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : appearance.textColor }];
        
        [[UINavigationBar appearance] setBackgroundImage:[self _navigationBarImageWithSize:CGSizeMake(44, 64) appearance:appearance topToBottom:YES] forBarMetrics:UIBarMetricsDefault];
        [[UINavigationBar appearance] setBackgroundImage:[self _navigationBarImageWithSize:CGSizeMake(44, 94) appearance:appearance topToBottom:YES] forBarMetrics:UIBarMetricsDefaultPrompt];
        [[UINavigationBar appearance] setShadowImage:[[UIImage alloc] init]];
        
        [[UIToolbar appearance] setBackgroundImage:[self _navigationBarImageWithSize:CGSizeMake(44, 44) appearance:appearance topToBottom:NO] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        [[UIToolbar appearance] setShadowImage:[[UIImage alloc] init] forToolbarPosition:UIBarPositionAny];
    
        [[UIScrollView appearance] setIndicatorStyle:appearance.scrollIndicatorStyle];
        
        [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];
        
        [[UITabBar appearance] setBackgroundImage:[self _navigationBarImageWithSize:CGSizeMake(50, 50) appearance:appearance topToBottom:NO]];
        
        [[UITextField appearance] setKeyboardAppearance:appearance.keyboardAppearance];
        
        [[UISwitch appearance] setTintColor:ICTintColor];
        [[UISwitch appearance] setOnTintColor:ICTintColor];
        
        UIWindow* rootWindow = [(InstacastAppDelegate*)App.delegate window];
        
        UIView* subview = [rootWindow.subviews lastObject];
        [subview removeFromSuperview];
        [rootWindow addSubview:subview];
        
        // workaround a bug in iOS where presented view controllers don't get appearance methods
        
        UIViewController* presentedViewController = rootWindow.rootViewController.presentedViewController;
//        
//        // xxx: iPad does not update view controller behind a form sheet
//        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//            presentedViewController = rootWindow.rootViewController;
//        }
        
        do {
            [presentedViewController beginAppearanceTransition:NO animated:NO];
            [presentedViewController endAppearanceTransition];
        
            [presentedViewController beginAppearanceTransition:YES animated:NO];
            [presentedViewController endAppearanceTransition];
            
            presentedViewController = presentedViewController.presentedViewController;
        } while (presentedViewController);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ICAppearanceManagerDidUpdateAppearanceNotification object:self];
    }
}

- (BOOL) switchesNightModeAutomatically {
    return [USER_DEFAULTS boolForKey:kDefaultSwitchNightModeAutomatically];
}

- (void) setSwitchesNightModeAutomatically:(BOOL)switchesNightModeAutomatically
{
    if (!switchesNightModeAutomatically) {
        _location = nil;
    }
    
    [USER_DEFAULTS setBool:switchesNightModeAutomatically forKey:kDefaultSwitchNightModeAutomatically];
}

- (BOOL) nightMode {
    return [USER_DEFAULTS boolForKey:kDefaultNightMode];
}

- (void) setNightMode:(BOOL)nightMode {
    [USER_DEFAULTS setBool:nightMode forKey:kDefaultNightMode];
    [self updateAppearance];
}

- (BOOL) switchNightModeAutomaticallyNow
{
    if (self.switchesNightModeAutomatically && ![self updateLocation]) {
        ErrLog(@"night mode could not be switched");
        self.switchesNightModeAutomatically = NO;
        return NO;
    }
    return YES;
}

- (void) updateAppearance
{
    if (self.nightMode) {
        self.appearance = [[ICNightAppearance alloc] init];
    } else {
        self.appearance = [[ICDaylightAppearance alloc] init];
    }
}

#pragma mark -


- (BOOL) updateLocation
{
    if (![CLLocationManager locationServicesEnabled]) {
        return NO;
    }
    
    if (!self.locationManager)
    {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        self.locationManager.delegate = self;
    }
    

    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    else if ([CLLocationManager authorizationStatus] < kCLAuthorizationStatusAuthorizedAlways) {
        return NO;
    }
    else {
        CLLocation* location = self.locationManager.location;
        //DebugLog(@"location time interval: %f", [location.timestamp timeIntervalSinceNow]);
        if (!location) {
            [self.locationManager startUpdatingLocation];
        } else {
            self.location = location;
        }
    }

    return YES;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status >= kCLAuthorizationStatusAuthorizedAlways)
    {
        CLLocation* location = self.locationManager.location;
        //DebugLog(@"location time interval: %f", [location.timestamp timeIntervalSinceNow]);
        if (!location) {
            [self.locationManager startUpdatingLocation];
        } else {
            self.location = location;
        }
    }
    else if (status == kCLAuthorizationStatusDenied) {
        self.switchesNightModeAutomatically = NO;
        [self updateAppearance];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.location = [locations firstObject];
    //DebugLog(@"new location %@", self.location);
    
    [self perform:^(id sender) {
        //DebugLog(@"deactivating location updating");
        [manager stopUpdatingLocation];
    } afterDelay:1.0];
}

- (void) setLocation:(CLLocation *)location
{
    if (_location != location) {
        _location = location;
        
        BOOL isNight = [self _updateSwitchSchedule];
        if (self.switchesNightModeAutomatically && self.nightMode != isNight) {
            self.nightMode = isNight;
        }
    }
}

- (BOOL) _updateSwitchSchedule
{
    BOOL isNight = NO;
    
    ICAppearanceDaylightCalculator* calculator = [[ICAppearanceDaylightCalculator alloc] initWithWithLocation:self.location date:[NSDate date]];
    NSTimeInterval sunriseInterval = [[NSDate date] timeIntervalSinceDate:calculator.sunrise];
	NSTimeInterval sunsetInterval = [[NSDate date] timeIntervalSinceDate:calculator.sunset];
	
	if ( sunriseInterval < 0 && sunsetInterval < 0 )
    {
		isNight = YES;
		self.nextSwitchDate = calculator.sunrise;
	}
    else if (sunriseInterval >= 0 && sunsetInterval < 0)
    {
		isNight = NO;
		self.nextSwitchDate = calculator.sunset;
	}
    else if (sunriseInterval >= 0 && sunsetInterval >= 0)
    {
        calculator.date = [NSDate dateWithTimeIntervalSinceNow:86400];
		NSTimeInterval tomorrowSunriseInterval = [[NSDate date] timeIntervalSinceDate:calculator.sunrise];
		NSTimeInterval tomorrowSunsetInterval = [[NSDate date] timeIntervalSinceDate:calculator.sunset];
		if ( tomorrowSunriseInterval < 0 && tomorrowSunsetInterval < 0 ) {
			isNight = YES;
			self.nextSwitchDate = calculator.sunrise;
		} else if (tomorrowSunriseInterval >= 0 && tomorrowSunsetInterval < 0) {
			isNight = NO;
			self.nextSwitchDate = calculator.sunset;
		}
	}
    
    //DebugLog(@"next appearance switch date: %@", [self.nextSwitchDate descriptionWithLocale:[NSLocale currentLocale]]);
    //isNight = YES;
    return isNight;
}

@end


@implementation ICDaylightAppearance

-(UIColor*) tintColor {
    return [UIColor colorWithRed:1.f green:83/255.f blue:0 alpha:1.f];
}

-(UIColor*) textColor {
    return [UIColor colorWithRed:51/255.f green:51/255.f blue:51/255.f alpha:1.f];
}

- (UIColor*) mutedTextColor {
    return [UIColor colorWithWhite:0.5 alpha:1.0];
}

- (UIColor*) placeholderTextColor {
    return [UIColor colorWithWhite:0.75 alpha:1.0];
}

-(UIColor*) backgroundColor {
    return [UIColor colorWithWhite:244/255.f alpha:1.f];
}

-(UIColor*) darkBackgroundColor {
    return [UIColor colorWithWhite:0.13f alpha:1.f];
}

-(UIColor*) lightBackgroundColor {
    return [UIColor colorWithWhite:0.9f alpha:1.f];
}

-(UIColor*) transparentBackdropColor {
    return [UIColor colorWithWhite:244/255.f alpha:0.9f];
}

-(UIColor*) tableSeparatorColor {
    return [UIColor colorWithWhite:0.88f alpha:1.f];
}

-(UIColor*) tableSelectedBackgroundColor {
    return [UIColor colorWithWhite:0.9f alpha:1.0f];
}

- (UIColor*) groupCellBackgroundColor {
    return [UIColor whiteColor];
}

- (UIColor*) groupCellSelectedBackgroundColor {
    return [UIColor colorWithWhite:0.8f alpha:1.0f];
}

- (UIStatusBarStyle) statusBarStyle {
    return UIStatusBarStyleDefault;
}

- (UIScrollViewIndicatorStyle) scrollIndicatorStyle {
    return UIScrollViewIndicatorStyleDefault;
}

- (NSString*) cssFile {
    return @"ShowNotesDaylightAppearance";
}

- (UIKeyboardAppearance) keyboardAppearance {
    return UIKeyboardAppearanceLight;
}

- (UIActivityIndicatorViewStyle) activityIndicatorStyle {
    return UIActivityIndicatorViewStyleGray;
}

@end


@implementation ICNightAppearance

-(UIColor*) tintColor {
    return [UIColor colorWithRed:1.f green:83/255.f blue:0 alpha:1.f];
}

-(UIColor*) textColor {
    return [UIColor colorWithWhite:0.88 alpha:1.f];
}

- (UIColor*) mutedTextColor {
    return [UIColor colorWithWhite:0.5 alpha:1.0];
}

- (UIColor*) placeholderTextColor {
    return [UIColor colorWithWhite:0.3 alpha:1.0];
}

-(UIColor*) backgroundColor {
    return [UIColor colorWithWhite:0.13f alpha:1.f];
}

-(UIColor*) darkBackgroundColor {
    return [UIColor blackColor];
}


-(UIColor*) lightBackgroundColor {
    return [UIColor colorWithWhite:0.3f alpha:1.f];
}

-(UIColor*) transparentBackdropColor {
    return [UIColor colorWithWhite:0.13f alpha:0.9];
}

-(UIColor*) tableSeparatorColor {
    return [UIColor colorWithWhite:0.2f alpha:1.f];
}

-(UIColor*) tableSelectedBackgroundColor {
    return [UIColor colorWithWhite:0.2f alpha:1.0f];
}

- (UIColor*) groupCellBackgroundColor {
    return [UIColor colorWithWhite:0.2f alpha:1.0f];
}

- (UIColor*) groupCellSelectedBackgroundColor {
    return [UIColor colorWithWhite:0.3f alpha:1.0f];
}

- (UIStatusBarStyle) statusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIScrollViewIndicatorStyle) scrollIndicatorStyle {
    return UIScrollViewIndicatorStyleWhite;
}

- (NSString*) cssFile {
    return @"ShowNotesNightAppearance";
}

- (UIKeyboardAppearance) keyboardAppearance {
    return UIKeyboardAppearanceDark;
}

- (UIActivityIndicatorViewStyle) activityIndicatorStyle {
    return UIActivityIndicatorViewStyleWhite;
}

@end
