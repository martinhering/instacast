//
//  STActivationController.h
//  Snowtape
//
//  Created by Martin Hering on 24.08.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WebView;

@interface STActivationController : NSWindowController

+ (id) windowController;

@property (nonatomic, copy) void (^windowDidCloseBlock)();

@property (weak) IBOutlet WebView* licenseView;
@property (weak) IBOutlet NSProgressIndicator* loadingIndicator;


- (void) enterLicense;
- (void) enterLicenseFromURL:(NSURL*)url;

- (void) showLicense;

- (IBAction) deactivateLicense:(id)sender;

@property (nonatomic, readonly) BOOL licenseValid;
@end
