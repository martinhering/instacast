//
//  JConnection.m
//  Instacast
//
//  Created by Martin Hering on 22.12.10.
//  Copyright 2010 Vemedio. All rights reserved.
//


#import "JCommand.h"

NSString* API1PopularAudioPodcastsCommand = @"api/v1/podcasts/popular/audio";
NSString* API1PopularVideoPodcastsCommand = @"api/v1/podcasts/popular/video";
NSString* API1EnhancedAudioPodcastsCommand = @"api/v1/podcasts/enhanced/audio";
NSString* API1EnhancedVideoPodcastsCommand = @"api/v1/podcasts/enhanced/video";
NSString* API1EnhancedPodcastsCommand = @"api/v1/podcasts/enhanced";
NSString* API1CategoriesCommand = @"api/v1/categories";
NSString* API1AuthorsCommand = @"api/v1/authors";
NSString* API1AuthorPodcastsCommand = @"api/v1/podcasts/author";


@interface JCommand()
@property (nonatomic, readwrite, weak) id delegate;
@property (nonatomic, readwrite, strong) NSString* command;
@property (nonatomic, readwrite, strong) NSDictionary* arguments;
@end

@implementation JCommand

+ (NSString*) baseForCommand:(NSString*)command
{
    
    
//#warning changed
	//return @"http://127.0.0.1:3000";
    //return @"http://api.pcast.me";
#ifdef DEBUG
    return @"https://crossbucket-dev.vemedio.com";
#else
    return @"https://instacastcloud.com";
#endif
}

#pragma mark -

- (id) initWithCommand:(NSString*)command arguments:(NSDictionary*)arguments
{
    return [self initWithCommand:command arguments:arguments delegate:nil];
}

- (id) initWithCommand:(NSString*)command arguments:(NSDictionary*)arguments delegate:(id)theDelegate
{
	if ((self = [self init]))
	{
		_delegate = theDelegate;
		_command = command;
		_arguments = arguments;
	}
	
	return self;
}

#pragma mark -

- (void) main
{
    @autoreleasepool {
        
        NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
        NSString* bundleVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
        NSString* bundleName = [infoDict objectForKey:@"CFBundleName"];
        
        
        NSArray* postCommands = @[  ];
        BOOL isPOST = [postCommands containsObject:self.command];
        
        NSArray* jsonCommands = @[  ];
        BOOL isJson = [jsonCommands containsObject:self.command];
        
        
        
        NSMutableDictionary* myArguments = [self.arguments mutableCopy];
        
        NSString* queryString = nil;
        
        if (!isPOST || !isJson)
        {
            NSMutableArray* partials = [[NSMutableArray alloc] init];
            
            // convert arguments to url string
            for(NSString* key in [myArguments allKeys])
            {
                NSObject* obj = [myArguments objectForKey:key];
                NSString* str = @"";
                if ([obj isKindOfClass:[NSString class]]) {
                    str = (NSString*)obj;
                }
                else if ([obj isKindOfClass:[NSNumber class]]) {
                    str = [(NSNumber*)obj stringValue];
                }
                else {
                    str = [obj description];
                }

                NSCharacterSet* queryCharacterSet = [NSCharacterSet URLQueryAllowedCharacterSet];
                NSString* partial = [NSString stringWithFormat:@"%@=%@", key, [str stringByAddingPercentEncodingWithAllowedCharacters:queryCharacterSet]];
                [partials addObject:partial];
            }
            
            queryString = [partials componentsJoinedByString:@"&"];
        }
        
        // add query to GET URL
        NSString* urlString = [[JCommand baseForCommand:self.command] stringByAppendingFormat:@"/%@", self.command];
        if (queryString && !isPOST) {
            urlString = [urlString stringByAppendingFormat:@"?%@", queryString];
        }
        
        // make request
        NSURL* url = [NSURL URLWithString:urlString];
        DebugLog(@"jcommand: %@", [url description]);
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0f];
        
        // add POST data
        if (isPOST && isJson)
        {
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPMethod:@"POST"];
            
            NSError* jsonError = nil;
            NSData* bodyData = [NSJSONSerialization dataWithJSONObject:myArguments options:0 error:&jsonError];
            if (bodyData) {
                [request setHTTPBody:bodyData];
            }
        }
        else if (isPOST)
        {
            [request setHTTPMethod:@"POST"];
            NSData* bodyData = [queryString dataUsingEncoding:NSUTF8StringEncoding];
            [request setHTTPBody:bodyData];
        }
        
        // add user agent
#if TARGET_OS_IPHONE
        NSString* userAgent = [NSString stringWithFormat:@"%@/%@", bundleName, bundleVersion];
#else
        NSString* userAgent = [NSString stringWithFormat:@"%@-Mac/%@", bundleName, bundleVersion];
#endif
        [request addValue:userAgent forHTTPHeaderField:@"User-Agent"];
        [request addValue:userAgent forHTTPHeaderField:@"X-AppInfo"];
        
        NSString* deviceInfo = [NSString stringWithFormat:@"%@/%@", [NSBundle platform], [NSBundle systemVersionString]];
        [request addValue:deviceInfo forHTTPHeaderField:@"X-DeviceInfo"];
        
        [App retainNetworkActivity];
        
        NSHTTPURLResponse* response = nil;
        NSError* error = nil;
        NSData* resultData = [self sendSynchronousRequest:request returningResponse:&response error:&error];
        
        [App releaseNetworkActivity];

        
        if (!resultData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.didReturnWithErrorBlock) {
                    self.didReturnWithErrorBlock(error);
                }
                
                else if (self.delegate && [self.delegate respondsToSelector:@selector(command:didReturnWithError:)]) {
                    [self.delegate command:self didReturnWithError:error];
                }
            });
        }
        else
        {
            id object = [NSJSONSerialization JSONObjectWithData:resultData options:0 error:nil];
            
            if (![object isKindOfClass:[NSDictionary class]]) {
                DebugLog(@"error parsing JCommand (%@) response: %@", self.command, object);
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.didReturnWithObjectBlock) {
                    self.didReturnWithObjectBlock(object);
                }
                
                else if (self.delegate && [self.delegate respondsToSelector:@selector(command:didReturnWithObject:)]) {
                    [self.delegate command:self didReturnWithObject:object];
                }
            });
        }
    }
}

- (void) start
{
    [super start];
}


@end

