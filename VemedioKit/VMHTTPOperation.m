//
//  VMHTTPOperation.m
//  InstacastMac
//
//  Created by Martin Hering on 08.01.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import "VMHTTPOperation.h"
#import "NSString+VMFoundation.h"
#import "NSData+VMFoundation.h"

#if TARGET_OS_IPHONE==0
#import <Security/Security.h>
#endif

@interface VMHTTPOperation ()
@property (strong) NSMutableData* connectionData;
@property (strong) NSURLConnection* connection;
@property (strong) NSURLResponse* connectionResponse;
@property (strong) NSError* connectionError;
@end

@implementation VMHTTPOperation {
    dispatch_semaphore_t _connectionSemaphore;
    long long _loadedBytes;
    long long _totalBytes;
}

- (id) init
{
	if ((self = [super init])) {
        // don't change, this timeout cancels request after 30 secs, even if traffic is slow
        _timeout = 0;
	}
	return self;
}

- (NSData*) sendSynchronousRequest:(NSMutableURLRequest*)request returningResponse:(__autoreleasing NSHTTPURLResponse**)outResponse error:(__autoreleasing NSError**)outError
{
    _connectionSemaphore = dispatch_semaphore_create(0);
    _loadedBytes = 0;
    
    NSInteger internalErrors = 0;
    NSData* data = nil;
    NSMutableSet* queriedURLs = [[NSMutableSet alloc] init];
    
    if (self.forceBasicAuth && self.username && self.password)
    {
        NSString* auth = [NSString stringWithFormat:@"%@:%@", self.username, self.password];
        NSString* base64 = [[auth dataUsingEncoding:NSUTF8StringEncoding] stringFromBase64EncodedData];
        [request addValue:[NSString stringWithFormat:@"Basic %@", base64] forHTTPHeaderField:@"Authorization"];
    }
    else if (self.forceBearerAuth && self.bearerToken)
    {
        [request addValue:[NSString stringWithFormat:@"Bearer %@", self.bearerToken] forHTTPHeaderField:@"Authorization"];
    }
    
    while (!data)
    {
#ifndef DEBUG // DEBUG should throw and exception
        if (!request.URL) {
            break;
        }
#endif
        
        if([queriedURLs containsObject:request.URL]) {
            self.connectionError = [NSError errorWithDomain:NSURLErrorDomain
                                                       code:kCFURLErrorHTTPTooManyRedirects
                                                   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             @"Redirection Loop", NSLocalizedDescriptionKey,
                                                             @"URLs are redirecting to each other forming a loop.", NSLocalizedRecoverySuggestionErrorKey, nil]];
            break;
        }
        [queriedURLs addObject:request.URL];
        
        
        self.connectionResponse = nil;
        self.connectionError = nil;
        
        //DebugLog(@"%@", request.URL);
        
        self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        [self.connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [self.connection start];
        
        // wait some seconds timeout
        
        dispatch_time_t timeout = (self.timeout > 0) ? dispatch_time(DISPATCH_TIME_NOW, self.timeout*2*1000000000LL) : DISPATCH_TIME_FOREVER;
        if (dispatch_semaphore_wait(_connectionSemaphore, timeout) != 0) {
            [self.connection cancel];
            
            self.connectionError = [NSError errorWithDomain:NSURLErrorDomain
                                                       code:kCFURLErrorTimedOut
                                                   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             @"Connection Timeout", NSLocalizedDescriptionKey,
                                                             @"Connection timed out.", NSLocalizedRecoverySuggestionErrorKey, nil]];
            self.connectionData = nil;
            self.connection = nil;
            break;
        }
        
        NSHTTPURLResponse* response = (NSHTTPURLResponse*)self.connectionResponse;
        NSInteger statusCode = [response statusCode];
        
        if (statusCode == 0 && !self.connectionError) {
            //ErrLog(@"internal error: %@ (%@)", self.connectionError, [request URL]);
            self.connectionData = nil;
            self.connection = nil;
            [queriedURLs removeObject:request.URL];
            internalErrors++;
            
            if (internalErrors > 5) {
                self.connectionData = nil;
                self.connection = nil;
                break;
            }
        }
        
        else if (statusCode == 301 || statusCode == 302 || statusCode == 307) {
            NSString* redirectLocation = [[response allHeaderFields] objectForKey:@"Location"];
            NSURL* originalURL = request.URL;
            NSURL* newURL = [NSURL URLWithString:redirectLocation relativeToURL:originalURL];
            if (!newURL) {
                newURL = [NSURL URLWithString:redirectLocation relativeToURL:originalURL];
            }
            request.URL = newURL;
            //DebugLog(@"redirected from %@ to %@", originalURL, request.URL);
            if (statusCode == 301) {
                self.permanentRedirectURL = request.URL;
            }
            else if (statusCode == 302 || statusCode == 307) {
                self.temporaryRedirectURL = request.URL;
            }
            
            self.connectionData = nil;
            self.connection = nil;
        }
        
        else if (statusCode == 401) {
            self.connectionError = [NSError errorWithDomain:NSURLErrorDomain
                                                       code:kCFURLErrorUserAuthenticationRequired
                                                   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             @"Authentication required", NSLocalizedDescriptionKey,
                                                             @"Please provide username and password.", NSLocalizedRecoverySuggestionErrorKey, nil]];
            self.connectionData = nil;
            self.connection = nil;
            break;
        }
        
        else
        {
#ifdef DEBUG
            if (statusCode == 404) {
                DebugLog(@"status code >= 300 (%ld): %@", (long)statusCode, [request.URL absoluteString]);
            }
            
            else if (statusCode >= 300) {
                NSString* content = [[NSString alloc] initWithData:self.connectionData encoding:NSUTF8StringEncoding];
                DebugLog(@"status code >= 300 (%ld)\n%@:\n%@\n", (long)statusCode, [request.URL absoluteString], content);
            }
#endif
            data = self.connectionData;
            self.connectionData = nil;
            self.connection = nil;
            break;
        }
    }
    
    
    if (outResponse) {
        *outResponse = (NSHTTPURLResponse*)self.connectionResponse;
    }
    
    if (outError) {
        *outError = self.connectionError;
    }
    
    // iOS >= 6.0 and OS X >= 10.8 apparently no longer need explicit dispatch_release calls when using ARC
#if TARGET_OS_IPHONE
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000 // Compiling for iOS < 6.0
    dispatch_release(_connectionSemaphore);
#endif
#else
#if MAC_OS_X_VERSION_MIN_REQUIRED < 1080 // Compiling for OS X < 10.8
    dispatch_release(_connectionSemaphore);
#endif
#endif
    
    return data;
}

#pragma mark -

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    id <NSURLAuthenticationChallengeSender> sender = challenge.sender;
    NSURLProtectionSpace *protectionSpace = challenge.protectionSpace;
    if (protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust)
    {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:protectionSpace.serverTrust];
        [sender useCredential:credential forAuthenticationChallenge:challenge];
    }
    
    else if (protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate) {
        [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
    
    // in case we can use the username and password stored in the feed
	else if ([challenge previousFailureCount] == 0 && self.username && self.password)
	{
		NSURLCredential* credentials = [NSURLCredential credentialWithUser:self.username
                                                                  password:self.password
                                                               persistence:NSURLCredentialPersistenceNone];
        
		[[challenge sender] useCredential:credentials forAuthenticationChallenge:challenge];
	}
    
    else
    {
        [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
}


- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    if (redirectResponse) {
        return nil;
    }
    return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.connectionResponse = response;
    _totalBytes = [response expectedContentLength];
    
    NSNumber* contentLength = [(NSHTTPURLResponse*)response allHeaderFields][@"Content-Length"];
    if (_totalBytes <= 0 && contentLength) {
        _totalBytes = [contentLength longLongValue];
    }
    
    if (self.limitSize > 0 && [response expectedContentLength] != NSURLResponseUnknownLength && [response expectedContentLength] > self.limitSize) {
        ErrLog(@"feed limitation exceeded: %lld", [response expectedContentLength]);
        [connection cancel];
        dispatch_semaphore_signal(_connectionSemaphore);
        
        self.connectionError = [NSError errorWithDomain:NSURLErrorDomain
                                                   code:NSURLErrorDataLengthExceedsMaximum
                                               userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                         @"Data length exceeded", NSLocalizedDescriptionKey,
                                                         @"Resource data exceeds the maximum allowed.", NSLocalizedRecoverySuggestionErrorKey, nil]];
        return;
    }
    
    self.connectionData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.connectionData appendData:data];
    
    _loadedBytes += [data length];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.didLoadBytes) {
            self.didLoadBytes(_loadedBytes, _totalBytes);
        }
    });
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    dispatch_semaphore_signal(_connectionSemaphore);
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.connectionError = error;
    dispatch_semaphore_signal(_connectionSemaphore);
}

- (void) cancel
{
    [super cancel];
    [self.connection cancel];
    if (_connectionSemaphore) {
    	dispatch_semaphore_signal(_connectionSemaphore);
    }
}

- (void) main
{
    @autoreleasepool {
        [NSException raise:NSInternalInconsistencyException format:@"abstract class must be subsclassed"];
    }
}

@end
