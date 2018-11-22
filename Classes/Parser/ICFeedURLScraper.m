//
//  ICFeedURLScraper.m
//  ICFeedParser
//
//  Created by Martin Hering on 18.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import "ICFeedURLScraper.h"

@interface ICFeedURLScraper ()
@property (nonatomic, readwrite, strong) NSURL* url;
@end

@implementation ICFeedURLScraper

+ (ICFeedURLScraper*) feedURLScraperWithURL:(NSURL*)url
{
	ICFeedURLScraper* scraper = [[self alloc] init];
	scraper.url = url;
	return scraper;
}

- (void) cancel
{
	self.delegate = nil;
	[super cancel];
}

- (void) _sendDidScrapeFeedURLToDelegate:(NSURL*)resultURL
{
	if (![self isCancelled] && self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(feedURLScraper:didScrapeFeedURL:)]) {
		[self.delegate feedURLScraper:self didScrapeFeedURL:resultURL];
	}
}

- (void) _sendErrorToDelegate:(NSError*)error
{
	if (![self isCancelled] && self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(feedURLScraper:didEndWithError:)]) {
		[self.delegate feedURLScraper:self didEndWithError:error];
	}
}

- (NSURL*) _parseURL:(NSURL*)aURL async:(BOOL)async
{
	@autoreleasepool {

        NSURL* requestURL = aURL;
        NSError* error = nil;
        
        NSMutableDictionary* urlCache = [NSMutableDictionary dictionary];
		
		static NSString* staticKey = @"set";
		[urlCache setObject:staticKey forKey:[aURL absoluteString]];
        
        NSString* feedURLString = nil;

        do
        {
            NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0f];
            [request addValue:@"143441-1,12" forHTTPHeaderField:@"X-Apple-Store-Front"];
            [request addValue:@"iTunes/10.1.2 (Macintosh; Intel Mac OS X 10.6.6) AppleWebKit/533.19.4" forHTTPHeaderField:@"User-Agent"];
            
            NSURLResponse* response = nil;
            error = nil;
            NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            
            if ([self isCancelled]) {
                return nil;
            }
            
            if (!data || error) {
                break;
            }
            
        
            NSDictionary* header = [(NSHTTPURLResponse*)response allHeaderFields];
            NSString* result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            if ([[header objectForKey:@"Content-Type"] hasPrefix:@"text/xml"])
            {
                feedURLString =  [result stringByMatchingRegex:@"<key>feedURL<\\/key><string>(.*?)<\\/string>" capture:1];
                if (feedURLString) {
                    continue;
                }
                
                NSString* gotoURLString =  [result stringByMatchingRegex:@"<key>url<\\/key><string>(.*?)<\\/string>" capture:1];
                if (!gotoURLString) {
                    break;
                }
                gotoURLString = [gotoURLString stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
                
                if ([urlCache objectForKey:gotoURLString]) {
                    DebugLog(@"relocation loop");
                    break;
                }
                
                [urlCache setObject:staticKey forKey:gotoURLString];
                requestURL = [NSURL URLWithString:gotoURLString];
            }
            else
            {
                feedURLString =  [result stringByMatchingRegex:@"feed-url=\\\"(.*?)\\\"" capture:1];
                if (feedURLString) {
                    continue;
                }
                
                NSString* iTunesUSubscribePathURLString =  [result stringByMatchingRegex:@"subscribe-podcast-url=\\\"(.*?)\\\"" capture:1];
                if (iTunesUSubscribePathURLString)
                {                        
                    if ([urlCache objectForKey:iTunesUSubscribePathURLString]) {
                        DebugLog(@"relocation loop");
                        break;
                    }
                    
                    [urlCache setObject:staticKey forKey:iTunesUSubscribePathURLString];
                    requestURL = [NSURL URLWithString:iTunesUSubscribePathURLString];
                    continue;
                }
                
                // nothing to parse and nothing in there anymore
                break;
            }
        } while (!feedURLString);
		
        
		/*
		while ([[header objectForKey:@"Content-Type"] hasPrefix:@"text/xml"] && !feedURLString)
		{
            
			
			request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:gotoURLString] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0f];
			[request addValue:@"143441-1,12" forHTTPHeaderField:@"X-Apple-Store-Front"];
			[request addValue:@"iTunes/10.1.2 (Macintosh; Intel Mac OS X 10.6.6) AppleWebKit/533.19.4" forHTTPHeaderField:@"User-Agent"];
			
			data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
			
			if ([self isCancelled]) {
				return nil;
			}
			
			if (!data || error) {
				if (async) [self performSelectorOnMainThread:@selector(_sendErrorToDelegate:) withObject:error waitUntilDone:NO];
				return nil;
			}
			
			result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			header = [(NSHTTPURLResponse*)response allHeaderFields];
            
            
            }
		}
        */
        
		if (feedURLString) {
			feedURLString = [feedURLString stringByDecodingHTMLEntities];
			DebugLog(@"result %@", feedURLString);
			NSURL* resultURL = [NSURL URLWithString:feedURLString];
            
			if (async) {
				[self performSelectorOnMainThread:@selector(_sendDidScrapeFeedURLToDelegate:) withObject:resultURL waitUntilDone:NO];
			} else {
				return resultURL;
			}
		} else {
			if (async) [self performSelectorOnMainThread:@selector(_sendErrorToDelegate:) withObject:error waitUntilDone:NO];
		}
	
	
	}
	return nil;
}

- (void) main
{
	[self _parseURL:self.url async:YES];
}


+ (NSURL*) scrapedFeedURLWithiTunesURL:(NSURL*)url
{
	ICFeedURLScraper* scraper = [[ICFeedURLScraper alloc] init];
	NSURL* scrapedURL = [scraper _parseURL:url async:NO];
	return scrapedURL;
}

@end
