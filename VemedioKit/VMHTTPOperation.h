//
//  VMHTTPOperation.h
//  InstacastMac
//
//  Created by Martin Hering on 08.01.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VMHTTPOperation : NSOperation

@property (copy) NSString* username;
@property (copy) NSString* password;
@property (copy) NSString* bearerToken;
@property NSTimeInterval timeout;
@property NSUInteger limitSize;
@property (copy) NSURL* temporaryRedirectURL;
@property (copy) NSURL* permanentRedirectURL;
@property BOOL forceBasicAuth;
@property BOOL forceBearerAuth;
@property (copy) NSString* pinSSLCertificateToCommonName;

- (NSData*) sendSynchronousRequest:(NSMutableURLRequest*)request returningResponse:(__autoreleasing NSHTTPURLResponse**)outResponse error:(__autoreleasing NSError**)outError;

@property (copy) void (^didLoadBytes)(long long loadedBytes, long long totalBytes);
@end
