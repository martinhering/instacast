//
//  Application.m
//  Instacast
//
//  Created by Martin Hering on 03.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#include <asl.h>
#include <sys/sysctl.h>

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "VDModalInfo.h"
#import "Reachability.h"
#import "ICErrorSheet.h"

NSString* UniqueDeviceId = @"UniqueDeviceId";
NSString* ApplicationDidRegisterTouchNotification = @"ApplicationDidRegisterTouchNotification";

@interface Application ()
@property (nonatomic, readwrite, strong) UIAlertController* errorAlertController;
@property (nonatomic, readwrite, strong) NSOperationQueue* mainQueue;
@property (nonatomic, readwrite, strong) CTTelephonyNetworkInfo* telephonyInfo;
@property (nonatomic, strong) Reachability* reachability;
@property (nonatomic, strong) ICErrorSheet* backgroundErrorSheet;
@property (nonatomic, readwrite, strong) GTMLogger* applicationLogger;
@end

@implementation Application {
@protected
	NSInteger	_networkActivityRetainCount;
	BOOL		_errorShown;
    BOOL        _sendTouchNotifications;
}

- (id) init
{
	if ((self = [super init]))
	{
		_mainQueue = [[NSOperationQueue alloc] init];
        
        _telephonyInfo = [CTTelephonyNetworkInfo new];
        _reachability = [Reachability reachabilityForInternetConnection]; //reachabilityWithHostName:@"apple.com"];
        [_reachability startNotifier];
        
        [self updateNetworkAccessTechnology];
        
        [NSNotificationCenter.defaultCenter addObserverForName:CTRadioAccessTechnologyDidChangeNotification
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:^(NSNotification *note) {
                                                        [self updateNetworkAccessTechnology];
                                                    }];
        
        [NSNotificationCenter.defaultCenter addObserverForName:kReachabilityChangedNotification
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:^(NSNotification *note) {
                                                        [self updateNetworkAccessTechnology];
                                                    }];
        
	}
	return self;
}


- (GTMLogger*) _initializeLoggerAtPath:(NSString*)path
{
    
#ifdef DEBUG
    
    @try {
        GTMLogBasicFormatter *formatter = [[GTMLogBasicFormatter alloc] init];
        
        GTMLogger *stdoutLogger =
        [GTMLogger loggerWithWriter:[NSFileHandle fileHandleWithStandardOutput]
                     formatter:formatter
                        filter:[[GTMLogMaximumLevelFilter alloc] initWithMaximumLevel:kGTMLoggerLevelInfo]];
        
        GTMLogger *stderrLogger =
        [GTMLogger loggerWithWriter:[NSFileHandle fileHandleWithStandardError]
                     formatter:formatter
                        filter:[[GTMLogMininumLevelFilter alloc] initWithMinimumLevel:kGTMLoggerLevelError]];
        
        
        GTMLogger* fileLogger = [GTMLogger standardLoggerWithPath:path];
        [fileLogger setFilter:[[GTMLogNoFilter alloc] init]];
        
        NSURL* url = [NSURL fileURLWithPath:path];
        NSError *error = nil;
        [url setResourceValue:@(YES) forKey: NSURLIsExcludedFromBackupKey error:&error];
        
        GTMLogger *compositeWriter =
        [GTMLogger loggerWithWriter:@[stdoutLogger, stderrLogger, fileLogger]
                          formatter:formatter
                             filter:[[GTMLogNoFilter alloc] init]];
        
        GTMLogger *outerLogger = [GTMLogger standardLogger];
        [outerLogger setWriter:compositeWriter];
        return outerLogger;
    }
    @catch (id e) {
        // Ignored
    }
    
    
    GTMLogger* logger = [GTMLogger standardLoggerWithStdoutAndStderr];
    return logger;
#else
    GTMLogger* logger = [GTMLogger standardLoggerWithPath:path];
    [logger setFilter:[[GTMLogLevelFilter alloc] init]];
    
    NSURL* url = [NSURL fileURLWithPath:path];
    
    NSError *error = nil;
    [url setResourceValue:@(YES) forKey: NSURLIsExcludedFromBackupKey error:&error];
    
    return logger;
#endif
}

- (void) initializeLoggers
{
    NSString* appLogsPath = [[NSBundle pathToLogsDirectory] stringByAppendingPathComponent:@"Application.Log"];
    _applicationLogger = [self _initializeLoggerAtPath:appLogsPath];
}

#pragma mark - Network Info

- (void) updateNetworkAccessTechnology
{
    if (self.reachability.currentReachabilityStatus == ReachableViaWiFi) {
        self.networkAccessTechnology = kICNetworkAccessTechnlogyWIFI;
    }
    else if (self.reachability.currentReachabilityStatus == NotReachable) {
        self.networkAccessTechnology = kICNetworkAccessTechnlogyNone;
    }
    else
    {
        NSString* currentRadioAccessTechnology = self.telephonyInfo.currentRadioAccessTechnology;
        if (currentRadioAccessTechnology == CTRadioAccessTechnologyGPRS) {
            self.networkAccessTechnology = kICNetworkAccessTechnlogyGPRS;
        }
        else if (currentRadioAccessTechnology == CTRadioAccessTechnologyEdge) {
            self.networkAccessTechnology = kICNetworkAccessTechnlogyEDGE;
        }
        else if (currentRadioAccessTechnology == CTRadioAccessTechnologyLTE) {
            self.networkAccessTechnology = kICNetworkAccessTechnlogyLTE;
        }
        else {
            self.networkAccessTechnology = kICNetworkAccessTechnlogy3G;
        }
    }
    
    DebugLog(@"network changed: %ld", (long)self.networkAccessTechnology);
    
}

- (void) retainNetworkActivity
{
	dispatch_async(dispatch_get_main_queue(), ^{
        if (_networkActivityRetainCount == 0) {
            self.networkActivityIndicatorVisible = YES;
        }
        _networkActivityRetainCount++;
    });
}

- (void) releaseNetworkActivity
{
	dispatch_async(dispatch_get_main_queue(), ^{
        _networkActivityRetainCount = MAX(_networkActivityRetainCount-1,0);
        
        if (_networkActivityRetainCount == 0) {
            self.networkActivityIndicatorVisible = NO;
        }
    });
}

#pragma mark - Global Error Handling

- (void) handleNoInternetConnection
{
    [self showBackgroundErrorWithTitle:@"No internet connection.".ls message:@"Please make sure you are connected to a cellular or WiFi network.".ls];
}

- (void) showBackgroundErrorWithTitle:(NSString*)title message:(NSString*)message
{
    [self showBackgroundErrorWithTitle:title message:message duration:4.0f];
}

- (void) showBackgroundErrorWithTitle:(NSString*)title message:(NSString*)message duration:(NSTimeInterval)duration
{
    PlaySoundFile(@"Tink", NO);
    
    if (self.backgroundErrorSheet) {
        self.backgroundErrorSheet.title = title;
        self.backgroundErrorSheet.message = message;
        [self.backgroundErrorSheet extendDismissingAfterDelay:duration];
        return;
    }
    
    self.backgroundErrorSheet = [ICErrorSheet sheet];
    self.backgroundErrorSheet.title = title;
    self.backgroundErrorSheet.message = message;
    
    __weak Application* weakSelf = self;
    [self.backgroundErrorSheet showAnimated:YES dismissAfterDelay:duration completion:^{
        weakSelf.backgroundErrorSheet = nil;
    }];
}


#pragma mark -


- (NSString*) errorLog
{
    NSString* logsPath = [[NSBundle pathToLogsDirectory] stringByAppendingPathComponent:@"Application.Log"];
    return [[NSString alloc] initWithContentsOfFile:logsPath encoding:NSUTF8StringEncoding error:nil];
}

@end

