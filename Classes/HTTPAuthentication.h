//
//  HTTPAuthentication.h
//  Instacast
//
//  Created by Martin Hering on 15.03.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^AuthenticationCompletionBlock)(BOOL success, NSString* username, NSString* password);

@interface HTTPAuthentication : NSObject

@property (nonatomic, strong) NSURL* url;
@property (nonatomic, strong) NSString* username;
@property (nonatomic, strong) id userInfo;
@property (nonatomic, assign) BOOL failedBefore;

- (UIAlertController*) showAuthenticationDialogCompletion:(AuthenticationCompletionBlock)completion;
- (UIAlertController*) showAuthenticationDialogWithTitle:(NSString*)title host:(NSString*)host completion:(AuthenticationCompletionBlock)completion;
@end

#if !TARGET_OS_IPHONE

@interface ICAuthenticationWindowController : NSWindowController

@property (nonatomic, strong) NSString* host;
@property (nonatomic, strong) NSString* username;
@property (nonatomic, strong) NSString* password;

@property (nonatomic, readonly) BOOL canAuthenticate;

- (IBAction) cancel:(id)sender;
- (IBAction) authenticate:(id)sender;

@end


#endif