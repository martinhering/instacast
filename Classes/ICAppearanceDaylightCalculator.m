//
//  ICAppearanceDaylightCalculator.m
//  Instacast
//
//  Created by Martin Hering on 29.07.14.
//
//

#import <CoreLocation/CoreLocation.h>

#import "ICAppearanceDaylightCalculator.h"

#define DEGS (180.0/M_PI)
#define RADS (M_PI/180.0)
#define SUN_DIA 0.53
#define AIR_REFR (34.0/60.0)

@interface ICAppearanceDaylightCalculator ()
@property (nonatomic, strong, readwrite) CLLocation* location;
@property (nonatomic, strong, readwrite) NSDate* sunrise;
@property (nonatomic, strong, readwrite) NSDate* sunset;
@end


@implementation ICAppearanceDaylightCalculator

NS_INLINE double FNday (int y, int m, int d, float h) {
    long int luku = - 7 * (y + (m + 9)/12)/4 + 275*m/9 + d;
    // type casting necessary on PC DOS and TClite to avoid overflow
    luku+= (long int)y*367;
    return (double)luku - 730531.5 + h/24.0;
};

//   the function below returns an angle in the range
//   0 to 2*M_PI

NS_INLINE double FNrange (double x) {
    double b = 0.5*x / M_PI;
    double a = 2.0*M_PI * (b - (long)(b));
    if (a < 0) a = 2.0*M_PI + a;
    return a;
};

// Calculating the hourangle
//
NS_INLINE double f0(double lat, double declin) {
    double fo,dfo;
    // Correction: different sign at S HS
    dfo = RADS*(0.5*SUN_DIA + AIR_REFR); if (lat < 0.0) dfo = -dfo;
    fo = tan(declin + dfo) * tan(lat*RADS);
    if (fo>0.99999) fo=1.0; // to avoid overflow //
    fo = asin(fo) + M_PI/2.0;
    return fo;
};

// Calculating the hourangle for twilight times
//
NS_INLINE double f1(double lat, double declin) {
    double fi,df1;
    // Correction: different sign at S HS
    df1 = RADS * 6.0; if (lat < 0.0) df1 = -df1;
    fi = tan(declin + df1) * tan(lat*RADS);
    if (fi>0.99999) fi=1.0; // to avoid overflow //
    fi = asin(fi) + M_PI/2.0;
    return fi;
};

//   Find the ecliptic longitude of the Sun

NS_INLINE double FNMeanLong (double d)
{
    return FNrange(280.461 * RADS + .9856474 * RADS * d);
}

NS_INLINE double FNsun (double d)
{
    double L,g;
    //   mean longitude of the Sun
    L = FNMeanLong(d);
    
    //   mean anomaly of the Sun
    g = FNrange(357.528 * RADS + .9856003 * RADS * d);
    
    //   Ecliptic longitude of the Sun
    return FNrange(L + 1.915 * RADS * sin(g) + .02 * RADS * sin(2 * g));
};

- (id) initWithWithLocation:(CLLocation*)location date:(NSDate*)date
{
    if ((self = [self init])) {
        _location = location;
        _date = date;
        
        [self _calculate];
    }
    return self;
}

- (void) setDate:(NSDate *)date
{
    if (_date != date) {
        _date = date;
        [self _calculate];
    }
}

- (void) _calculate
{
    double y,m,day,h,latit,longit;
    double tzone,d,lambda;
    double obliq,alpha,delta,LL,equation,ha,hb,twx;
    double twam,altmax,noont,settm,riset,twpm;
    time_t sekunnit;
    struct tm *p;
    double L;
    double daylen;
    
    
    //  get the date and time from the user
    // read system date and extract the year
    
    /** First get time **/
    time(&sekunnit);
    
    /** Next get localtime **/
    
    p=localtime(&sekunnit);
    
    y = p->tm_year;
    // this is Y2K compliant method
    y+= 1900;
    m = p->tm_mon + 1;
    
    day = p->tm_mday;
    
    h = 12;
    
    latit = self.location.coordinate.latitude; longit = self.location.coordinate.longitude;
    tzone = [[NSTimeZone localTimeZone] secondsFromGMT] / 3600.0;
    
    // testing
    // m=6; day=10;
    
    d = FNday(y, m, day, h);
    
    //   Use FNsun to find the ecliptic longitude of the
    //   Sun
    
    lambda = FNsun(d);
    L = FNMeanLong(d);
    
    //   Obliquity of the ecliptic
    
    obliq = 23.439 * RADS - .0000004 * RADS * d;
    
    //   Find the RA and DEC of the Sun
    
    alpha = atan2(cos(obliq) * sin(lambda), cos(lambda));
    delta = asin(sin(obliq) * sin(lambda));
    
    // Find the Equation of Time
    // in minutes
    // Correction suggested by David Smith
    LL = L - alpha;
    if (L < M_PI) LL += 2.0*M_PI;
    equation = 1440.0 * (1.0 - LL / M_PI/2.0);
    ha = f0(latit,delta);
    hb = f1(latit,delta);
    twx = hb - ha;  // length of twilight in radians
    twx = 12.0*twx/M_PI;              // length of twilight in hours
    
    // Conversion of angle to hours and minutes //
    daylen = DEGS*ha/7.5;
    if (daylen<0.0001) {daylen = 0.0;}
    // arctic winter     //
    
    riset = 12.0 - 12.0 * ha/M_PI + tzone - longit/15.0 + equation/60.0;
    settm = 12.0 + 12.0 * ha/M_PI + tzone - longit/15.0 + equation/60.0;
    noont = riset + 12.0 * ha/M_PI;
    altmax = 90.0 + delta * DEGS - latit;
    // Correction for S HS suggested by David Smith
    // to express altitude as degrees from the N horizon
    if (latit < delta * DEGS) altmax = 180.0 - altmax;
    
    twam = riset - twx;     // morning twilight begin
    twpm = settm + twx;     // evening twilight end
    
    if (riset > 24.0) riset-= 24.0;
    if (settm > 24.0) settm-= 24.0;
    
    /*
     puts("\n Sunrise and set");
     puts("===============");
     
     printf("  year  : %d \n",(int)y);
     printf("  month : %d \n",(int)m);
     printf("  day   : %d \n\n",(int)day);
     printf("Days since Y2K :  %d \n",(int)d);
     
     printf("Latitude :  %3.1f, longitude: %3.1f, timezone: %3.1f \n",(float)latit,(float)longit,(float)tzone);
     printf("Declination   :  %.2f \n",delta * DEGS);

     printf("Daylength     : "); showhrmn(daylen); puts(" hours \n");
    printf("Civil twilight: ");
     showhrmn(twam); puts("");
     printf("Sunrise       : ");
     showhrmn(riset); puts("");

     printf("Sun altitude ");
     // Amendment by D. Smith
     printf(" %.2f degr",altmax);
     printf(latit>=0.0 ? " South" : " North");
     printf(" at noontime "); showhrmn(noont); puts("");
     printf("Sunset        : ");
     showhrmn(settm);  puts("");
     printf("Civil twilight: ");
     showhrmn(twpm);  puts("\n");
    */
    
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* coms = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay) fromDate:self.date];
    
    //sunrise
    [coms setHour:riset];
    [coms setMinute:(riset - (int)riset)*60];
    _sunrise = [calendar dateFromComponents:coms];
    
    //sunset
    [coms setHour:settm];
    [coms setMinute:(settm - (int)settm)*60];
    _sunset = [calendar dateFromComponents:coms];
    
    if (settm < riset) {
        _sunset = [_sunset dateByAddingTimeInterval:86400];
    }
}

@end
