//
//  CacheOperation_iOS7.m
//  Instacast
//
//  Created by Martin Hering on 22/07/13.
//
//

#import "CacheOperation_iOS7.h"
#import "CacheManager+FileDetector.h"
#import "HTTPAuthentication.h"
#import "UtilityFunctions.h"

NSString* kUserDefaultsResumeInfoKey = @"DownloadResumeInfos_NSURLSession";


@interface CacheOperation_iOS7 () <NSURLSessionDelegate, NSURLSessionDownloadDelegate>
@property (strong) NSMutableSet* reflectors;
@property (strong) id currentReflector;

@property (strong) NSURLSession* session;
@property (strong) NSURLSessionDownloadTask* downloadTask;

@property (readwrite, strong) NSString* identifier;
@property (readwrite) long long expectedContentLength;
@property (readwrite) long long loadedContentLength;
@property (readwrite) long long restartedAtContentLength;
@property (readwrite, strong) NSDate* startDate;
@property (strong) HTTPAuthentication* authentication;
@property (readwrite, strong) GTMLogger* logger;
@end


@implementation CacheOperation_iOS7 {
    BOOL _shouldBeSuspended;
}

- (id) initWithURL:(NSURL*)aRemoteURL localURL:(NSURL*)aLocalURL identifier:(NSString*)identifier expectedContentLength:(long long)expectedContentLength
{
	if ((self = [self init]))
	{
        if (!aRemoteURL || !aLocalURL || !identifier) {
            return nil;
        }
        
        // workaround for a bug in the feed parser up to version 3.0.2
        NSString* remoteURLString = [aRemoteURL absoluteString];
        if ([remoteURLString rangeOfString:@"%25"].location != NSNotFound) {
            remoteURLString = [remoteURLString stringByRemovingPercentEncoding];
            aRemoteURL = [NSURL URLWithString:remoteURLString];
        }
        
        // workaround for urls with whitespace
        // has been fixed in the feed parser
        if ([remoteURLString rangeOfString:@"%20"].location == 0) {
            remoteURLString = [[remoteURLString stringByRemovingPercentEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            aRemoteURL = [NSURL URLWithString:remoteURLString];
        }


        // make sure we have http urls
        if (![[aRemoteURL scheme] caseInsensitiveEquals:@"http"] && ![[aRemoteURL scheme] caseInsensitiveEquals:@"https"]) {
            NSString* scheme = [aRemoteURL scheme];
            NSString* urlString = [aRemoteURL absoluteString];
            urlString = [urlString stringByReplacingCharactersInRange:NSMakeRange(0, [scheme length]) withString:@"http"];
            if (urlString) {
                aRemoteURL = [NSURL URLWithString:urlString];
            }
        }

		_remoteURL = [aRemoteURL copy];
		_localURL = [aLocalURL copy];
        _identifier = [identifier copy];
        _expectedContentLength = expectedContentLength;
        
        _reflectors = [[[CacheManager sharedCacheManager] fileReflectors] mutableCopy];
        
        
        
        NSString* logsPath = [[NSBundle pathToLogsDirectory] stringByAppendingPathComponent:@"MediaFileImporter.log"];
        
        _logger = [GTMLogger standardLoggerWithPath:logsPath];
        [_logger setFilter:[[GTMLogLevelFilter alloc] init]];
        
        VMLoggerInfo(@"remote url: %@, local url: %@, identifier: %@", aRemoteURL, aLocalURL, identifier);
	}
	
	return self;
}

+ (void) removeCacheForRemoteURL:(NSURL*)remoteURL atLocalURL:(NSURL*)url
{
	NSFileManager* fman = [NSFileManager defaultManager];
	
	NSString* path = [url path];
	[fman removeItemAtPath:path error:nil];
}

#pragma mark -

- (double) progress
{
    long long expectedContentLength = self.expectedContentLength;
    long long loadedContentLength = self.loadedContentLength;
    
	if (expectedContentLength == 0 || expectedContentLength < loadedContentLength) {
		return 0.0;
	}
	return (double)loadedContentLength / (double)expectedContentLength;
}

- (NSTimeInterval) estimatedTimeLeft
{
    long long expectedContentLength = self.expectedContentLength;
    long long loadedContentLength = self.loadedContentLength;
    long long restartedAtContentLength = self.restartedAtContentLength;
    
    if (expectedContentLength - restartedAtContentLength <= 0) {
        return 0;
    }
    
    double progress = (double)(loadedContentLength - restartedAtContentLength) / (double)(expectedContentLength - restartedAtContentLength);
    if (progress == 0) {
        return 0;
    }
    
    NSTimeInterval timeLoaded = [[NSDate date] timeIntervalSinceDate:self.startDate];
    if (timeLoaded > 3) {
        NSTimeInterval estimated = (timeLoaded / progress)-timeLoaded;
        return estimated;
    }
    
    return 0;
}


#pragma mark -


- (void) cancel
{
    [super cancel];
}

- (BOOL) suspended {
    return (self.downloadTask.state == NSURLSessionTaskStateSuspended);
}

- (void) setSuspended:(BOOL)suspended
{
    if (suspended != (self.downloadTask.state == NSURLSessionTaskStateSuspended))
    {
        _shouldBeSuspended = suspended;
        
        if (suspended)
        {
            if (self.downloadTask.state != NSURLSessionTaskStateSuspended) {
                [self.downloadTask suspend];
            }
        }
        else
        {
            if (self.downloadTask.state == NSURLSessionTaskStateSuspended) {
                [self.downloadTask resume];
            }
            
            self.restartedAtContentLength = self.loadedContentLength;
            self.startDate = [NSDate date];
        }
    }
}

- (void) main
{
	@autoreleasepool
    {
        NSURL* remoteURL = self.remoteURL;
        
        // iterate over all reflectors and check for a corresponding of in the local network
        for(id fileReflectors in self.reflectors) {
            NSURL* fileIndexURL = [NSURL fileURLWithPath:@"/FileIndex.plist"];
            NSURL* reflectorFileIndexURL = [[CacheManager sharedCacheManager] remoteURLWithLocalURL:fileIndexURL forFileReflector:fileReflectors];
            
            NSArray* fileIndex = [[NSArray alloc] initWithContentsOfURL:reflectorFileIndexURL];
            for(NSDictionary* entry in fileIndex) {
                if ([entry[@"remoteURL"] isEqualToString:[remoteURL absoluteString]]) {
                    NSURL* localFile = [NSURL fileURLWithPath:[NSString stringWithFormat:@"/%@", entry[@"localFile"]]];
                    remoteURL = [[CacheManager sharedCacheManager] remoteURLWithLocalURL:localFile forFileReflector:fileReflectors];
                    break;
                }
            }
        }
        

        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            BOOL enabled3G = (self.overwriteCellularLock || [USER_DEFAULTS boolForKey:EnableCachingOver3G]);
            
            NSURLSessionConfiguration* config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:self.identifier];
            config.discretionary = NO;
            config.allowsCellularAccess = enabled3G;

            NSURLSession* session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
            self.session = session;
            
            [session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
                
                DebugLog(@"download tasks %lu", (unsigned long)[downloadTasks count]);
                
                if ([downloadTasks count] > 0) {
                    self.downloadTask = [downloadTasks firstObject];
                }
                else
                {
                    NSData* resumeData = [self _resumeData];
                    
                    if (resumeData)
                    {
                        // case there's bogus data in the resume data, it seems to throw and exception
                        @try {
                            self.downloadTask = [session downloadTaskWithResumeData:resumeData];
                        }
                        @catch (NSException *exception) {
                            ErrLog(@"downloadTaskWithResumeData exception: %@", [exception description]);
                            self.downloadTask = nil;
                        }
                        @finally {
                            
                        }

                        [self _deleteResumeInfo];
                        
                        if (!self.downloadTask) {
                            // we need a new session, because this session is invalid
                            [self.session invalidateAndCancel];
                            self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
                        }
                    }
                    
                    if (!self.downloadTask)
                    {
                        @try {
                            NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:remoteURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.f];
                            self.downloadTask = [session downloadTaskWithRequest:request];
                        }
                        @catch (NSException *exception) {
                            ErrLog(@"downloadTaskWithRequest exception: %@", [exception description]);
                            self.downloadTask = nil;
                            [self cancel];
                        }
                        @finally {
                            
                        }
                    }
                    
                    if (!_shouldBeSuspended) {
                        [self.downloadTask resume];
                    }
                    self.startDate = [NSDate date];
                }
            }];
        });
        
        while ((!self.downloadTask || self.downloadTask.state != NSURLSessionTaskStateCompleted) && ![self isCancelled]) {
            @autoreleasepool {
                [NSThread sleepForTimeInterval:1];
            }
            
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            if ([self isCancelled])
            {
                [self.downloadTask cancelByProducingResumeData:^(NSData *resumeData) {

                    if (resumeData) {
                        [self _saveResumeData:resumeData];
                    }
                }];
                
                [self.session invalidateAndCancel];
            } else {
                [self.session finishTasksAndInvalidate];
            }
        });
        
        NSInteger i=0;
        while (self.session && ![self isCancelled]) {
            [NSThread sleepForTimeInterval:1];
            DebugLog(@"loadedContentLength: %llu", self.loadedContentLength);
            i++;
            
            if (i>=20 && self.loadedContentLength == 0) {
                [self.session finishTasksAndInvalidate];
                self.session = nil;
                self.failed = YES;
            }
        }
        
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(cacheOperationDidEnd:)]) {
                [self.delegate cacheOperationDidEnd:self];
            }
        });
    }
}

#pragma mark - NSURLSession Delegate

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    if (!error) {
        DebugLog(@"didBecomeInvalidWithError %@ for: %@", error, session.configuration.identifier);
    }
    self.session = nil;
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    DebugLog(@"URLSessionDidFinishEventsForBackgroundURLSession for: %@", session.configuration.identifier);
}



#pragma mark NSURLSessionDownloadDelegate Delegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    DebugLog(@"%lx: didReceiveChallenge for: %@  auth: %lx", (long)self, session.configuration.identifier, (long)self.authentication);
    
    NSURLProtectionSpace* space = [challenge protectionSpace];
    
    // in case there is
    if ([space authenticationMethod] == NSURLAuthenticationMethodServerTrust || [space authenticationMethod] == NSURLAuthenticationMethodClientCertificate) {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        return;
    }
    
    // in case we can use the username and password stored in the feed
	if (self.username && self.password && [challenge previousFailureCount] == 0)
	{
		NSURLCredential* credentials = [NSURLCredential credentialWithUser:self.username password:self.password persistence:NSURLCredentialPersistenceNone];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credentials);
		return;
	}
    
    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
#warning removed HTTP Authentication support
//	if (self.authentication) {
//        [self.authentication dismissAnimated:NO];
//        self.authentication = nil;
//    }
//    
//#if TARGET_OS_IPHONE
//    if (App.applicationState == UIApplicationStateBackground) {
//        UILocalNotification* finishedNotification = [[UILocalNotification alloc] init];
//        finishedNotification.alertBody = @"Authentication required to download a file.".ls;
//        finishedNotification.soundName = UILocalNotificationDefaultSoundName;
//        [App presentLocalNotificationNow:finishedNotification];
//    }
//#endif
//    
//    self.authentication = [[HTTPAuthentication alloc] init];
//    self.authentication.url = self.remoteURL;
//    self.authentication.username = (self.username) ? self.username : [[challenge proposedCredential] user];
//    self.authentication.userInfo = challenge;
//    self.authentication.failedBefore = ([challenge previousFailureCount] > 0);
//    [self.authentication showAuthenticationDialogCompletion:^(BOOL success, NSString *username, NSString *password) {
//
//         if (success) {
//             self.username = username;
//             self.password = password;
//         }
//        
//        self.authentication = nil;
//         
//         if (!success) {
//             completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
//         } else {
//             NSURLCredential* credentials = [NSURLCredential credentialWithUser:self.username password:self.password persistence:NSURLCredentialPersistenceNone];
//             completionHandler(NSURLSessionAuthChallengeUseCredential, credentials);
//         }
//    }];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    DebugLog(@"task didCompleteWithError %@", error);
    
    if (error) {
        [self cancel];
        
        NSData* resumeData = [error userInfo][NSURLSessionDownloadTaskResumeData];
        if (resumeData) {
            [self _saveResumeData:resumeData];
        }
    }
    
    self.session = nil;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    DebugLog(@"didFinishDownloadingToURL %@, %@ for: %@", location, self.localURL, session.configuration.identifier);
    
    NSFileManager* fman = [[NSFileManager alloc] init];
    [fman removeItemAtURL:self.localURL error:nil];
    
    NSError* error = nil;
    NSDictionary* info = [fman attributesOfItemAtPath:location.path error:&error];
    if (error) {
        ErrLog(@"could not get file attributes for downloaded file: %@", location);
        self.failed = YES;
        return;
    }
    
    unsigned long long fileSize = [info[NSFileSize] unsignedLongLongValue];
    if (fileSize < 100*1024) {
        ErrLog(@"file is too small, maybe DNS error");
        self.failed = YES;
        return;
    }
    
    error = nil;
    if (![fman moveItemAtURL:location toURL:self.localURL error:&error]) {
        self.failed = YES;
        ErrLog(@"could not move file: %@", error);
    }
    else {
        AddSkipBackupAttributeToFile([self.localURL path]);
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    //DebugLog(@"didWriteData bytesWritten=%lld, totalBytesWritten=%lld, totalBytesExpectedToWrite=%lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    
    self.loadedContentLength = totalBytesWritten;
    if (self.expectedContentLength == 0) {
        self.expectedContentLength = totalBytesExpectedToWrite;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(cacheOperation:didLoadNumberOfBytes:)]) {
        [self.delegate cacheOperation:self didLoadNumberOfBytes:bytesWritten];
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    self.expectedContentLength = expectedTotalBytes;
    self.restartedAtContentLength = fileOffset;
}

#pragma mark - Handling Resume Information


- (void) _saveResumeData:(NSData*)resumeData
{
    NSMutableDictionary* resumeInfos = [[USER_DEFAULTS objectForKey:kUserDefaultsResumeInfoKey] mutableCopy];
    if (!resumeInfos) {
        resumeInfos = [[NSMutableDictionary alloc] init];
    }
    
    if (resumeData) {
        [resumeInfos setObject:resumeData forKey:self.identifier];
        [USER_DEFAULTS setObject:resumeInfos forKey:kUserDefaultsResumeInfoKey];
        [USER_DEFAULTS synchronize];
    }
}

+ (void) deleteResumeInfoForIdentifier:(NSString*)identifier
{
    NSMutableDictionary* resumeInfos = [[USER_DEFAULTS objectForKey:kUserDefaultsResumeInfoKey] mutableCopy];
    
    if (resumeInfos[identifier]) {
        [resumeInfos removeObjectForKey:identifier];
        [USER_DEFAULTS setObject:resumeInfos forKey:kUserDefaultsResumeInfoKey];
        [USER_DEFAULTS synchronize];
    }
}

- (void) _deleteResumeInfo
{
    [[self class] deleteResumeInfoForIdentifier:self.identifier];
}

- (NSData*) _resumeData
{
    NSDictionary* resumeInfos = [USER_DEFAULTS objectForKey:kUserDefaultsResumeInfoKey];
    NSData* resumeData = resumeInfos[self.identifier];
    
    if (!resumeData || [resumeData length] < 1) {
        return nil;
    }
        
    NSError *error;
    NSDictionary *resumeDictionary = [NSPropertyListSerialization propertyListWithData:resumeData
                                                                               options:NSPropertyListImmutable
                                                                                format:NULL
                                                                                 error:&error];
    if (!resumeDictionary || error) {
        return nil;
    }
    
    NSString *localFilePath = [resumeDictionary objectForKey:@"NSURLSessionResumeInfoLocalPath"];
    if ([localFilePath length] < 1) {
        return nil;
    }
        
    return ([[NSFileManager defaultManager] fileExistsAtPath:localFilePath]) ? resumeData : nil;
}

@end
