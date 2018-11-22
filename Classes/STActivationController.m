//
//  STActivationController.m
//  Snowtape
//
//  Created by Martin Hering on 24.08.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import <WebKit/WebKit.h>

#import "STActivationController.h"
#import "STAuthorizationManager.h"


@implementation STActivationController

+ (id) windowController
{
	return [[self alloc] initWithWindowNibName:@"STActivation"];
}

- (void) windowDidLoad {
    [super windowDidLoad];
    
    NSButton* windowButton = [[self window] standardWindowButton:NSWindowCloseButton];
	
	NSRect windowFrame = [[windowButton superview] frame];
	NSImageView* imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(NSMaxX(windowFrame)-20, NSMaxY(windowFrame)-18, 10, 14)];
	[imageView setAutoresizingMask:(NSViewMinYMargin | NSViewMinXMargin)];
	[imageView setImage:[NSImage imageNamed:NSImageNameLockLockedTemplate]];
	
	[[windowButton superview] addSubview:imageView];
    
    [self.window localize];
}


- (void) dealloc
{
	[self.licenseView setUIDelegate:nil];
	[self.licenseView setFrameLoadDelegate:nil];
}

- (void) _openAuthorizationWindowWithName:(NSString*)name serial:(NSString*)serial
{
	[[self window] setTitle:@"Enter License".ls];
	[[self window] setFrame:NSMakeRect(0,0,600,422) display:NO];
	[[self window] center];
	[[self window] makeKeyAndOrderFront:self];
	
	
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:LicensingBase()]];
	NSMutableArray* parameters = [NSMutableArray array];
	NSString* hardwareKey = getHardwareKey();
	if (hardwareKey) {
		[parameters addObject:[NSString stringWithFormat:@"hardware=%@",hardwareKey]];
	}
	if (name) {
		[parameters addObject:[NSString stringWithFormat:@"name=%@",name]];
	}
	if (serial) {
		[parameters addObject:[NSString stringWithFormat:@"serial=%@",serial]];
	}
	AddInternalParameters(parameters);
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[[parameters componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[self.licenseView setApplicationNameForUserAgent:[NSString stringWithFormat:@"Instacast/%@ B/%@ H/%@", [NSBundle appVersion], [NSBundle buildVersion], hardwareKey]];
	[self.licenseView setUIDelegate:self];
	[self.licenseView setFrameLoadDelegate:self];
	[[self.licenseView mainFrame] loadRequest:request];
	
	[self.loadingIndicator startAnimation:self];
}

- (void) enterLicense
{
	[self _openAuthorizationWindowWithName:nil serial:nil];
}

- (void) enterLicenseFromURL:(NSURL*)url
{
	NSString* path = [url path];
	
	if ([path isEqualToString:@"/activate"])
	{
		NSString* query = [url query];
		NSArray* valuePairs = [query componentsSeparatedByString:@"&"];
		NSMutableDictionary* values = [NSMutableDictionary dictionary];
		for(NSString* valuePair in valuePairs)
		{
			NSRange range = [valuePair rangeOfString:@"="];
			if (range.location != NSNotFound && [valuePair length]>range.location) {
				NSString* value = [valuePair substringFromIndex:range.location+1];
				value = [value stringByReplacingOccurrencesOfString:@"+" withString:@"%20"];
				
				value = [value stringByReplacingPercentEscapesUsingEncoding:NSISOLatin1StringEncoding];
				NSString* key = [valuePair substringToIndex:range.location];
				[values setObject:value forKey:key];
			}
		}
		
		if ([values objectForKey:@"name"] && [values objectForKey:@"key"]) {
			[self _openAuthorizationWindowWithName:[values objectForKey:@"name"] serial:[values objectForKey:@"key"]];
		}
		else {
			NSLog(@"url not valid: %@", [url description]);
		}
	}
	else {
		NSLog(@"url not valid: %@", [url description]);
	}
}

- (void) showLicense
{
	[[self window] setTitle:@"Your Activated License".ls];
	[[self window] setFrame:NSMakeRect(0,0,600,422) display:NO];
	[[self window] center];
	
	NSString* urlString = [LicensingBase() stringByAppendingPathComponent:@"info"];
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
	NSMutableArray* parameters = [NSMutableArray array];
	NSString* hardwareKey = getHardwareKey();
	
	NSDictionary* license = [USER_DEFAULTS_CONTROLLER valueForKey:STLicense];
	
	if ([license objectForKey:STLicenseHardware]) {
		[parameters addObject:[NSString stringWithFormat:@"hardware=%@", [[license objectForKey:STLicenseHardware] stringByEscapingStandardCharacters]]];
	}
	
	if ([license objectForKey:STLicenseCode]) {
		[parameters addObject:[NSString stringWithFormat:@"code=%@", [[license objectForKey:STLicenseCode] stringByEscapingStandardCharacters]]];
	}
	
	if ([license objectForKey:STLicenseSignature]) {
		NSString* sigString = [[license objectForKey:STLicenseSignature] stringFromBase64EncodedData];
		[parameters addObject:[NSString stringWithFormat:@"signature=%@",[sigString stringByEscapingStandardCharacters]]];
	}
	
	if ([license objectForKey:STLicenseInfo]) {
		[parameters addObject:[NSString stringWithFormat:@"info=%@", [[license objectForKey:STLicenseInfo] stringByEscapingStandardCharacters]]];
	}

	AddInternalParameters(parameters);
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[[parameters componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding]];

	[self.licenseView setApplicationNameForUserAgent:[NSString stringWithFormat:@"Instacast/%@ B/%@ H/%@", [NSBundle appVersion], [NSBundle buildVersion], hardwareKey]];
	[self.licenseView setUIDelegate:self];
	[self.licenseView setFrameLoadDelegate:self];
	[[self.licenseView mainFrame] loadRequest:request];
	
	[self.loadingIndicator startAnimation:self];
    
    [self showWindow:nil];
    
    [self.window localize];
}

#pragma mark -

- (NSDictionary*) _parseQueryString:(NSString*)parameterList
{
	NSMutableDictionary* parameterDict = [NSMutableDictionary dictionary];
	NSArray* parameters = [parameterList componentsSeparatedByString:@"&"];
	for(NSString* parameterPair in parameters)
	{
		NSScanner* scanner = [NSScanner scannerWithString:parameterPair];
		NSString* key = nil;
		[scanner scanUpToString:@"=" intoString:&key];
		[scanner scanString:@"=" intoString:nil];
		
		NSString* value = nil;
		[scanner scanUpToString:@"&" intoString:&value];
		
		value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		if (key && value) {
			[parameterDict setObject:value forKey:key];
		}
	}
	
	return parameterDict;
}

- (void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WebFrame *)frame
{
	//DebugLog(@"alert: %@", message);
	
	NSScanner* messageScanner = [NSScanner scannerWithString:message];
	
	NSString* function = nil;
	[messageScanner scanUpToString:@"(" intoString:&function];
	[messageScanner scanString:@"(" intoString:nil];
	
	NSString* parameterList = nil;
	[messageScanner scanUpToString:@")" intoString:&parameterList];
	
	NSDictionary* parameterDict = [self _parseQueryString:parameterList];
	SEL selector = NSSelectorFromString([function stringByAppendingString:@":"]);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	if ([self respondsToSelector:selector]) {
		[self performSelector:selector withObject:parameterDict];
	}
#pragma clang diagnostic pop
}

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
	[self.loadingIndicator startAnimation:self];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	[self.loadingIndicator stopAnimation:self];
}

- (NSUInteger)webView:(WebView *)sender dragDestinationActionMaskForDraggingInfo:(id <NSDraggingInfo>)draggingInfo
{
	return WebDragSourceActionNone;
}

#ifndef DEBUG
- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
	return nil;
}
#endif

#pragma mark -
#pragma mark Window Delegate

- (void)windowWillClose:(NSNotification *)notification
{
	[[self.licenseView mainFrame] loadHTMLString:@"<html></html>" baseURL:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.windowDidCloseBlock) {
            self.windowDidCloseBlock();
        }
    });
}

#pragma mark -
#pragma mark WebView Actions

- (void) licenseActivated:(NSDictionary*)arguments
{	
	[self close];
	
	NSString* base64Signature = [arguments objectForKey:@"signature"];
	NSData* signature = [NSData dataWithBase64EncodedString:base64Signature];
	
	NSString* regName = [arguments objectForKey:@"reg_name"];
	NSString* regSerial = [arguments objectForKey:@"reg_serial"];
	NSInteger activations = [[arguments objectForKey:@"activations"] intValue];
	NSString* email = [arguments objectForKey:@"email"];
	NSString* info = [arguments objectForKey:@"info"];
	
	NSString* verificationKey = getVerificationKey(regSerial);
	NSString* signatureKey = [NSString stringWithFormat:@"%@%@", getVerificationKey(regSerial), info];
	
	if (SignatureIsValid(signature, signatureKey))
	{
		NSDictionary* activation = [NSDictionary dictionaryWithObjectsAndKeys:
									regName, STLicenseName,
									regSerial, STLicenseCode,
									verificationKey, STLicenseHardware,
									signature, STLicenseSignature,
									email, STLicenseEmail,
									info, STLicenseInfo,
									nil];
		
		ActivateAndShowSuccessDialog(activation, activations);
	}
	else
	{
		ShowAuthorizationFaildDialog(@"The server sent back an unexpected response. Please contact Vemedio Support.".ls);
	}
}

- (void) setPageHeight:(NSDictionary*)arguments
{
	NSInteger height = [[arguments objectForKey:@"height"] intValue];
	NSRect windowFrame = [[self window] frame];
	NSRect viewFrame = [self.licenseView frame];
	CGFloat extraH = NSHeight(windowFrame)-NSHeight(viewFrame);
	
	NSRect screenHeight = [[[self window] screen] frame];
	CGFloat h = MIN(height+extraH, NSHeight(screenHeight)-50);
	
	CGFloat mid = NSMidY(windowFrame);
	
	NSRect newWindowFrame = NSMakeRect(NSMinX(windowFrame), mid-h*0.5, NSWidth(windowFrame), h);
	[[self window] setFrame:newWindowFrame display:YES animate:YES];
}

- (void) webGoto:(NSDictionary*)arguments
{
	[[self window] close];
	
	NSString* key = [arguments objectForKey:@"key"];
	NSString* link = [@"http://vemedio.com/" stringByAppendingString:key];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:link]];
}

- (BOOL) licenseValid
{
    return IsLicensed() == STLicensedYes();
}

- (IBAction) deactivateLicense:(id)sender
{
    [USER_DEFAULTS_CONTROLLER setValue:nil forKey:STLicense];
    [self close];
}
@end
