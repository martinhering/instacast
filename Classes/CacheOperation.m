//
//  CacheOperation.m
//  Instacast
//
//  Created by Martin Hering on 03.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import "CacheOperation.h"
#import "HTTPAuthentication.h"
#import "UtilityFunctions.h"
#import "CacheManager+FileDetector.h"

static NSString* kUserDefaultsResumeInfoKey = @"DownloadResumeInfos";

@interface CacheOperation ()
@property (readwrite, copy) NSURL* remoteURL;
@property (readwrite, copy) NSURL* localURL;
@property (readwrite, copy) NSURL* tempURL;
@property (readwrite, strong) NSFileHandle* fileHandle;
@property (readwrite, strong) NSDate* startDate;
@property BOOL authDone;
@property BOOL authCancel;
@property BOOL finishedLoading;
@property BOOL mainCanceled;
@property BOOL tryAgain;
@property (strong) NSMutableSet* reflectors;
@property (strong) id currentReflector;

@property (strong) NSURLConnection* mainConnection;
@property (strong) HTTPAuthentication* authentication;
@property (readwrite, strong) NSString* identifier;
@end


@implementation CacheOperation {
	long long			_expectedContentLength;
	long long			_loadedContentLength;
    long long           _restartedAtContentLength;
    NSMutableData*      _temporaryData;
}

@dynamic progress;

- (id) initWithURL:(NSURL*)aRemoteURL localURL:(NSURL*)aLocalURL tempURL:(NSURL*)aTempURL identifier:(NSString*)identifier
{
	if ((self = [self init]))
	{
        // workaround for a bug in the feed parser up to version 3.0.2
        NSString* remoteURLString = [aRemoteURL absoluteString];
        if ([remoteURLString rangeOfString:@"%25"].location != NSNotFound) {
            remoteURLString = [remoteURLString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            aRemoteURL = [NSURL URLWithString:remoteURLString];
        }
        
		_remoteURL = [aRemoteURL copy];
		_localURL = [aLocalURL copy];
		_tempURL = [aTempURL copy];
        _identifier = [identifier copy];
        _expectedContentLength = 0;
        
        _temporaryData = [[NSMutableData alloc] initWithCapacity:1024*1024*2];

        _reflectors = [[[CacheManager sharedCacheManager] fileReflectors] mutableCopy];
	}
	
	return self;
}



+ (void) removeCacheForRemoteURL:(NSURL*)remoteURL atLocalURL:(NSURL*)url tempURL:(NSURL*)tempURL
{
	NSFileManager* fman = [NSFileManager defaultManager];
	
	NSString* path = [url path];
    [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:[path stringByDeletingLastPathComponent] destination:@"" files:@[[path lastPathComponent]] tag:NULL];
	[fman removeItemAtPath:path error:nil];
	
	NSString* tempPath = [tempURL path];
	[fman removeItemAtPath:tempPath error:nil];
    
    [self deleteResumeInfoForRemoteURL:remoteURL];
}

- (void) cancel
{
    if (![self isExecuting]) {
        self.failed = YES;
        if (self.delegate && [self.delegate respondsToSelector:@selector(cacheOperationDidEnd:)]) {
            [self.delegate cacheOperationDidEnd:self];
        }
    }
    
    [super cancel];
}

- (double) progress
{
	if (_expectedContentLength == 0 || _expectedContentLength < _loadedContentLength) {
		return 0.0;
	}
	return (double)_loadedContentLength / (double)_expectedContentLength;
}

- (NSTimeInterval) estimatedTimeLeft
{
    if (_expectedContentLength - _restartedAtContentLength <= 0) {
        return 0;
    }
    
    double progress = (double)(_loadedContentLength - _restartedAtContentLength) / (double)(_expectedContentLength - _restartedAtContentLength);
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

- (BOOL) _initializeDownload
{
    NSFileManager* fman = [NSFileManager defaultManager];
	NSString* tempPath = [self.tempURL path];
    
    NSDictionary* resumeInfo = [self _resumeInfo];
    _expectedContentLength = [resumeInfo[@"Content-Length"] longLongValue];
	
	// create file if not already exists from a former canceled download
	if (![fman fileExistsAtPath:tempPath]) {
		[fman createFileAtPath:tempPath contents:[NSData data] attributes:nil];
		_loadedContentLength = 0LL;
	}
	else {
		NSError* error = nil;
		NSDictionary* fileAttributes = [fman attributesOfItemAtPath:tempPath error:&error];
		_loadedContentLength = [[fileAttributes objectForKey:NSFileSize] longLongValue];
	}
    
    // remove the partial file, when there is no resume data
    if (_loadedContentLength > 0 && _expectedContentLength == 0) {
        [fman removeItemAtURL:self.tempURL error:nil];
        [fman createFileAtPath:tempPath contents:[NSData data] attributes:nil];
        _loadedContentLength = 0;
    }
	
	self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:tempPath];
	if (!self.fileHandle) {
		ErrLog(@"error creating file handle");
		self.failed = YES;
		return NO;
	}
	[self.fileHandle seekToEndOfFile];
	
    
	self.startDate = [NSDate date];

    
    NSURL* requestURL = self.remoteURL;
    if ([self.reflectors count] > 0) {
        id fileReflector = [self.reflectors anyObject];
        requestURL = [[CacheManager sharedCacheManager] remoteURLWithLocalURL:self.localURL forFileReflector:fileReflector];
        self.currentReflector = fileReflector;
    }

    
    BOOL enabled3G = (self.overwriteCellularLock || [USER_DEFAULTS boolForKey:EnableCachingOver3G]);
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.f];
    [request setAllowsCellularAccess:enabled3G];
    [request setNetworkServiceType:NSURLNetworkServiceTypeVoice];
    
    // make sure to send fake iTunes Header when content is hosted on iTunes
    if ([[requestURL host] rangeOfString:@"apple.com" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        [request addValue:@"143441-1,12" forHTTPHeaderField:@"X-Apple-Store-Front"];
        [request addValue:@"iTunes/10.1.2 (Macintosh; Intel Mac OS X 10.6.6) AppleWebKit/533.19.4" forHTTPHeaderField:@"User-Agent"];
    }
    
    if (_expectedContentLength > 0 && _loadedContentLength > 0) {
        NSString* rangeString = [NSString stringWithFormat:@"bytes=%lld-%lld", _loadedContentLength, _expectedContentLength-1];
        [request addValue:rangeString forHTTPHeaderField:@"Range"];
        [request addValue:@"" forHTTPHeaderField:@"Accept-Encoding"]; // make sure we not accept Gzip to get a valid expectedContentLength
        _restartedAtContentLength = _loadedContentLength;
    }
    
	self.mainConnection = [NSURLConnection connectionWithRequest:request delegate:self];

    return YES;
}

- (void) _runDownload
{    
    // if the partial download failed, start from the beginning
    if (self.mainCanceled && self.mainConnection) {
        self.mainConnection = nil;
        self.mainCanceled = NO;
        
        [self.fileHandle closeFile];
        self.fileHandle = nil;
        [[NSFileManager defaultManager] removeItemAtURL:self.tempURL error:nil];
        _restartedAtContentLength = 0;
        
        [self _initializeDownload];
    }
    
    // we got suspended, but have a connection, kill the connection
    if (self.suspended && self.mainConnection) {
        DebugLog(@"kill the connection");
        [self.mainConnection cancel];
        self.mainConnection = nil;
        
        if ([_temporaryData length] > 0) {
            [self.fileHandle writeData:_temporaryData];
            [_temporaryData setData:[NSData data]];
        }
        
        [self.fileHandle closeFile];
        self.fileHandle = nil;
        _restartedAtContentLength = 0;
    }
    
    // we got resumed, but have no connection yet, start a new one with range parameters
    else if (!self.suspended && !self.mainConnection) {
        [self _initializeDownload];
    }
}

- (void) _finishDownload
{
    if (self.mainConnection)
    {
        [self.mainConnection cancel];
        self.mainConnection = nil;
                
        // close the temporary file
        [self.fileHandle closeFile];
        self.fileHandle = nil;
        
        // move the temporary file to its final destination, if everything ended well
        if (![self isCancelled] && !self.failed)
        {
            NSError* error = nil;
            if (![[NSFileManager defaultManager] moveItemAtPath:[self.tempURL path] toPath:[self.localURL path] error:&error]) {
                ErrLog(@"error moving temporary file %@", [error description]);
                self.failed = YES;
            } else {
                AddSkipBackupAttributeToFile([self.localURL path]);
            }
            // remove the temporary file
            [[NSFileManager defaultManager] removeItemAtPath:[self.tempURL path] error:nil];
        }
//        else if (self.tryAgain) {
//            // remove the temporary file
//            [[NSFileManager defaultManager] removeItemAtPath:[self.tempURL path] error:nil];
//        }
    }
    
    if (self.finishedLoading) {
        [self _deleteResumeInfo];
    }
    
    if (!self.tryAgain && self.delegate && [self.delegate respondsToSelector:@selector(cacheOperationDidEnd:)]) {
		[self.delegate cacheOperationDidEnd:self];
	}
}


- (void) main
{
	@autoreleasepool
    {
        while (self.suspended && ![self isCancelled]) {
            [NSThread sleepForTimeInterval:0.5];
        }
        
        if ([self isCancelled]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self _finishDownload];
            });
            return;
        }
        
        do
        {
            self.tryAgain = NO;
            self.failed = NO;
            self.finishedLoading = NO;
            
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (![self _initializeDownload]) {
                    [self _finishDownload];
                    [self cancel];
                }
            });
            
            
            while (![self isCancelled] && (!self.failed || self.suspended))
            {
                @autoreleasepool {
                    [NSThread sleepForTimeInterval:0.5];
                    
                    if (self.finishedLoading) {
                        break;
                    }
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self _runDownload];
                    });
                }
            }
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                if ([_temporaryData length] > 0) {
                    [self.fileHandle writeData:_temporaryData];
                    [_temporaryData setData:[NSData data]];
                }
                
                [self _finishDownload];
            });
            
        } while (self.tryAgain);
        
    }
}

#pragma mark -
#pragma mark Connection Delegate

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
    
	if (statusCode == 401) {
		ErrLog(@"authorization required");
		self.failed = (!self.suspended);
		return;
	}
    
    if (statusCode < 200 || statusCode > 299 )
    {
        if (self.currentReflector) {
            [self.reflectors removeObject:self.currentReflector];
            self.currentReflector = nil;
            self.tryAgain = YES;
            ErrLog(@"status code: %ld, try again", (long)statusCode);
        }
        else {
            ErrLog(@"media download failed. status code: %ld", (long)statusCode);
            
        }
        self.failed = (!self.suspended);
		return;
	}
    
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    DebugLog(@"response: %@, status: %ld", [[httpResponse allHeaderFields] description], (long)[httpResponse statusCode]);
    
	if (connection == self.mainConnection)
	{
		if (_expectedContentLength == 0LLU && [response expectedContentLength] > 0) {
			_expectedContentLength = [response expectedContentLength] + _restartedAtContentLength;
            
            NSDictionary* allHeaders = [httpResponse allHeaderFields];
            [self _saveResumeInfo:allHeaders];
		}
        
        // check etag if resume is still valid
        if (_restartedAtContentLength > 0) {
            NSString* currentEtag = [httpResponse allHeaderFields][@"Etag"];
            NSString* savedEtag = [self _resumeInfo][@"Etag"];
            
            if (currentEtag != savedEtag && ![currentEtag isEqualToString:savedEtag]) {
                ErrLog(@"can't resume, 'Etag' changed.");
                [self.mainConnection cancel];
                self.mainCanceled = YES;
            }
        }
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	// in case we can use the username and password stored in the feed
	if (self.username && self.password && [challenge previousFailureCount] == 0)
	{
		NSURLCredential* credentials = [NSURLCredential credentialWithUser:self.username password:self.password persistence:NSURLCredentialPersistenceNone];
		[[challenge sender] useCredential:credentials forAuthenticationChallenge:challenge];
		return;
	}
	
    self.authentication = [[HTTPAuthentication alloc] init];
    self.authentication.url = self.remoteURL;
    self.authentication.username = (self.username) ? self.username : [[challenge proposedCredential] user];
    self.authentication.userInfo = challenge;
    self.authentication.failedBefore = ([challenge previousFailureCount] > 0);
    [self.authentication showAuthenticationDialogCompletion:^(BOOL success, NSString *username, NSString *password)
    {
        BOOL authCancel = NO;
        if (!success) {
            authCancel = YES;
        } else {
            self.username = username;
            self.password = password;
        }
        
        if (authCancel) {
            [[challenge sender] cancelAuthenticationChallenge:challenge];
        } else {
            NSURLCredential* credentials = [NSURLCredential credentialWithUser:self.username password:self.password persistence:NSURLCredentialPersistenceNone];
            [[challenge sender] useCredential:credentials forAuthenticationChallenge:challenge];
        }
    }];

}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_temporaryData appendData:data];
    
    if ([_temporaryData length] > 1024*1024) {
        [self.fileHandle writeData:_temporaryData];
        [_temporaryData setData:[NSData data]];
    }
    
	_loadedContentLength += [data length];
    
    //DebugLog(@"_loadedContentLength %ld", _loadedContentLength);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(cacheOperation:didLoadNumberOfBytes:)]) {
        [self.delegate cacheOperation:self didLoadNumberOfBytes:[data length]];
    }
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (_expectedContentLength== 0LL || _loadedContentLength == _expectedContentLength) {
		self.finishedLoading = YES;
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    DebugLog(@"could not cache episode: %@", error);

    if (self.currentReflector) {
        [self.reflectors removeObject:self.currentReflector];
        self.currentReflector = nil;
        self.tryAgain = YES;
    }
    
    
    self.failed = YES;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(cacheOperationDidEnd:)]) {
        [self.delegate cacheOperationDidEnd:self];
    }
    
    
    
}

#pragma mark - Handling Resume Information

- (NSString*) _resourceHash
{
    return [[self.remoteURL absoluteString] MD5Hash];
}

- (void) _saveResumeInfo:(NSDictionary*)resumeInfo
{
    NSMutableDictionary* resumeInfos = [[USER_DEFAULTS objectForKey:kUserDefaultsResumeInfoKey] mutableCopy];
    if (!resumeInfos) {
        resumeInfos = [[NSMutableDictionary alloc] init];
    }
    
    NSString* resourceHash = [self _resourceHash];
    NSData* resumeData = [NSKeyedArchiver archivedDataWithRootObject:resumeInfo];
    if (resourceHash && resumeData) {
        [resumeInfos setObject:resumeData forKey:resourceHash];
        [USER_DEFAULTS setObject:resumeInfos forKey:kUserDefaultsResumeInfoKey];
        [USER_DEFAULTS synchronize];
    }
}

+ (void) deleteResumeInfoForRemoteURL:(NSURL*)url
{
    NSString* resourceHash = [[url absoluteString] MD5Hash];
    
    NSMutableDictionary* resumeInfos = [[USER_DEFAULTS objectForKey:kUserDefaultsResumeInfoKey] mutableCopy];
    
    if (resumeInfos[resourceHash]) {
        [resumeInfos removeObjectForKey:resourceHash];
        [USER_DEFAULTS setObject:resumeInfos forKey:kUserDefaultsResumeInfoKey];
        [USER_DEFAULTS synchronize];
    }
}

- (void) _deleteResumeInfo
{
    [CacheOperation deleteResumeInfoForRemoteURL:self.remoteURL];
}

- (NSDictionary*) _resumeInfo
{
    NSString* resourceHash = [self _resourceHash];
    NSData* resumeData = [USER_DEFAULTS objectForKey:kUserDefaultsResumeInfoKey][resourceHash];
    if (resumeData) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:resumeData];
    }
    return nil;
}
@end
