//
//  Application.h
//  Instacast
//
//  Created by Martin Hering on 03.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GTMLogger;

extern NSString* ApplicationDidRegisterTouchNotification;

// sorted by network speed: important!
typedef NS_ENUM(NSInteger, ICNetworkAccessTechnlogy) {
    kICNetworkAccessTechnlogyUnknown,
    kICNetworkAccessTechnlogyNone,
    kICNetworkAccessTechnlogyGPRS,
    kICNetworkAccessTechnlogyEDGE,
    kICNetworkAccessTechnlogy3G,
    kICNetworkAccessTechnlogyLTE,
    kICNetworkAccessTechnlogyWIFI
};



#define App ((Application*)[Application sharedApplication])

@interface Application : UIApplication

@property (nonatomic, strong, readonly) NSOperationQueue* mainQueue;
@property (nonatomic, strong, readonly) GTMLogger* applicationLogger;
@property (nonatomic, assign) UIStatusBarStyle defaultStatusBarStyle;
@property (nonatomic) ICNetworkAccessTechnlogy networkAccessTechnology;


- (void) initializeLoggers;

- (void) retainNetworkActivity;
- (void) releaseNetworkActivity;

- (void) handleNoInternetConnection;

- (void) showBackgroundErrorWithTitle:(NSString*)title message:(NSString*)message;
- (void) showBackgroundErrorWithTitle:(NSString*)title message:(NSString*)message duration:(NSTimeInterval)duration;


- (NSString*) errorLog;

@end


#pragma mark -

NS_INLINE NSString* DecodedRot9String(NSString* rot9String)
{
	NSMutableString* string = [NSMutableString string];
	NSUInteger i;
	for(i=0; i<[rot9String length]; i++)
	{
		unichar c = [rot9String characterAtIndex:i];
		c += 9;
		[string appendString:[NSString stringWithFormat:@"%c",c]];
	}
	
	return string;
}

NS_INLINE BOOL HasBeenCracked()
{
    return NO;
}
