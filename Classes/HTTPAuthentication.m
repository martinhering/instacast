//
//  HTTPAuthentication.m
//  Instacast
//
//  Created by Martin Hering on 15.03.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import "HTTPAuthentication.h"

#if TARGET_OS_IPHONE

@interface HTTPAuthentication () <UITextFieldDelegate>
@property (nonatomic, strong) UIAlertController* alertController;
@end

@implementation HTTPAuthentication

- (UIAlertController*) showAuthenticationDialogCompletion:(AuthenticationCompletionBlock)completion;
{
    NSString* title = ((!self.failedBefore) ? @"Authentication".ls : @"Authentication failed.".ls);
    return [self showAuthenticationDialogWithTitle:title host:[self.url host] completion:completion];
}

- (UIAlertController*) showAuthenticationDialogWithTitle:(NSString*)title host:(NSString*)host completion:(AuthenticationCompletionBlock)completionBlock
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:host
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.clearButtonMode = UITextFieldViewModeAlways;
        textField.text = self.username;
        textField.placeholder = @"Enter username".ls;
    }];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.clearButtonMode = UITextFieldViewModeAlways;
        textField.placeholder = @"Enter password".ls;
        textField.secureTextEntry = YES;
    }];
    
    UIAlertAction* authenticateAction = [UIAlertAction actionWithTitle:@"Authenticate".ls style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                              NSString* username = [alert.textFields[0].text copy];
                                                              NSString* password = [alert.textFields[1].text copy];
                                                              
                                                              completionBlock(YES, username, password);
                                                              
                                                              //self.actionSheetController = nil;
                                                          }];
    [alert addAction:authenticateAction];
    
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Cancel".ls style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                              completionBlock(NO, nil, nil);
                                                              //self.actionSheetController = nil;
                                                          }];
    [alert addAction:defaultAction];
    return alert;
}


@end

#else

@implementation ICAuthenticationWindowController

- (void) windowDidLoad
{
    [super windowDidLoad];
    
    [self.window localize];
}

- (IBAction) cancel:(id)sender
{
    [NSApp stopModalWithCode:1];
    [self.window close];
}

- (IBAction) authenticate:(id)sender
{
    [NSApp stopModalWithCode:0];
    [self.window close];
}

- (BOOL) canAuthenticate
{
    return ([self.username length] > 0);
}

+ (NSSet*) keyPathsForValuesAffectingCanAuthenticate
{
    return [NSSet setWithObject:@"username"];
}

@end

@interface HTTPAuthentication ()
@property (nonatomic, strong) ICAuthenticationWindowController* windowController;
@end


@implementation HTTPAuthentication

#pragma mark -

- (void) showAuthenticationDialogCompletion:(AuthenticationCompletionBlock)completion;
{
    NSString* title = ((!self.failedBefore) ? @"Authentication".ls : @"Authentication failed.".ls);
    [self showAuthenticationDialogWithTitle:title host:[self.url host] completion:completion];
}

- (void) showAuthenticationDialogWithTitle:(NSString*)title host:(NSString*)host completion:(AuthenticationCompletionBlock)completion;
{
    self.windowController = [[ICAuthenticationWindowController alloc] initWithWindowNibName:@"HTTPAuthenticationView"];
    self.windowController.host = host;
    self.windowController.window.title = title;
    
    NSBeep();
    NSInteger result = [NSApp runModalForWindow:self.windowController.window];
    
    DebugLog(@"auth result %ld", result);
    
    if (result == 1) {
        if (completion) {
            completion(NO, nil, nil);
        }
    }
    else
    {
        if (completion) {
            completion(YES, self.windowController.username, self.windowController.password);
        }
    }
}

- (void) dismissAnimated:(BOOL)animated
{
    [self.windowController cancel:nil];
}

@end
#endif
