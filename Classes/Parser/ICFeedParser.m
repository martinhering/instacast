//
//  ICFeedParser.m
//  ICFeedParser
//
//  Created by Martin Hering on 23.12.10.
//  Copyright 2010 Vemedio. All rights reserved.
//


#import "ICFeedParser.h"
#import "ICFeed.h"
#import "ICCategory.h"
#import "ICEpisode.h"
#import "ICMedia.h"
#import "ICChapter.h"
#import "NSString+ICParser.h"


#import "HTTPAuthentication.h"
#import "ArbitraryDateParser.h"

enum {
    kFeedParserElementContextNone,
    kFeedParserElementContextFeed,
    kFeedParserElementContextFeedImage,
    kFeedParserElementContextItem,
    kFeedParserElementContextSimpleChapter,
};
typedef NSInteger FeedParserElementContext;

enum {
    kFeedParserFeedFormatUnknown,
    kFeedParserFeedFormatRSS,
    kFeedParserFeedFormatAtom
};
typedef NSInteger FeedParserFeedFormat;

static NSString* kPodcastFeedParserErrorDomain = @"kPodcastFeedParserErrorDomain";

static ArbitraryDateParser* gDateParser = nil;

@interface ICFeedParser ()
@property (nonatomic, strong) NSString* xmlPath;
@property BOOL elementOpen;
@property BOOL abortedNormally;
@property (nonatomic, readonly) ICFeed* feed;
@property (strong) NSURL* selfURL;
@property (strong) HTTPAuthentication* authentication;
@end


@implementation ICFeedParser {
@protected
	NSMutableString*            _elementContent;
	NSMutableDictionary*        _elementAttributes;
	ICFeed*                     _feed;
	ICCategory*                 _category;
	ICEpisode*                  _episode;
    NSMutableString*            _xhtmlBody;
    FeedParserElementContext    _elementContext;
    FeedParserFeedFormat        _format;
    NSMutableArray*             _alternateFeeds;
    NSMutableArray*             _categories;
    NSMutableArray*             _episodes;
    NSMutableArray*             _chapters;
    
    NSDateFormatter*            _rssDateFormatter;
    NSDateFormatter*            _tidyDateFormatter;
    NSDateFormatter*            _dcDateFormatter;
    NSDateFormatter*            _dcDateFormatter2;
    
    BOOL                        _tryProposedCredential;
    BOOL                        _categoryOpen;
    NSMutableString*            _contentHashString;
    BOOL                        _resultIsHTML;
}

@dynamic alternatives;

- (NSArray*) alternatives
{
    return _alternateFeeds;
}

+ (ICFeedParser*) feedParser
{
	return [[self alloc] init];
}

- (id) init
{
	if ((self = [super init])) {
        _presentAlternateFeeds = YES;
        _allowsCellularAccess = YES;
        
        static dispatch_once_t onceToken = 0;
        dispatch_once(&onceToken, ^{
            gDateParser = [[ArbitraryDateParser alloc] init];
        });
	}
	return self;
}


- (void) start
{
	@autoreleasepool {
	//DebugLog(@"parsing feed: %@ credentials: %@/%@", self.url, self.username, self.password);
	}
	[super start];
}

- (void) cancel
{
	self.delegate = nil;
	[super cancel];
}

- (void) _sendWillParseFeedToDelegate:(NSURL*)anUrl
{
	if (![self isCancelled] && self.delegate && [self.delegate respondsToSelector:@selector(feedParser:willParseFeedWithURL:)]) {
		[self.delegate feedParser:self willParseFeedWithURL:anUrl];
	}
}

- (void) _sendDidParseFeedToDelegate:(ICFeed*)feed
{
    if (![self isCancelled])
    {
        if (self.didParseFeedBlock) {
            self.didParseFeedBlock(feed);
        }
        else if (self.delegate && [self.delegate respondsToSelector:@selector(feedParser:didParseFeed:)]) {
            [self.delegate feedParser:self didParseFeed:feed];
        }
    }
}

- (void) _sendErrorToDelegate:(NSError*)error
{
    if (![self isCancelled])
    {
        if (self.didEndWithError) {
            self.didEndWithError(error);
        }
        else if (![self isCancelled] && self.delegate && [self.delegate respondsToSelector:@selector(feedParser:didEndWithError:)]) {
            [self.delegate feedParser:self didEndWithError:error];
        }
    }
}


#pragma mark -
#pragma mark Authentication Delegate


- (BOOL) _parseAsync:(BOOL)async error:(NSError**)outError
{
	if (async) {
		[self performSelectorOnMainThread:@selector(_sendWillParseFeedToDelegate:) withObject:self.url waitUntilDone:NO];
	}
    
start:
    
    if (!self.username && [self.url user]) {
        self.username = [self.url user];
    }
    
    if (!self.password && [self.url password]) {
        self.password = [self.url password];
    }
	

	NSURL* requestURL = [self.url URLByDeletingUsernameAndPassword];
    DebugLog(@"parse %@", [requestURL absoluteString]);
    
    // make sure we have http urls
    if (![[requestURL scheme] caseInsensitiveEquals:@"http"] && ![[requestURL scheme] caseInsensitiveEquals:@"https"]) {
		NSString* scheme = [requestURL scheme];
		NSString* urlString = [requestURL absoluteString];
		urlString = [urlString stringByReplacingCharactersInRange:NSMakeRange(0, [scheme length]) withString:@"http"];
		requestURL = [NSURL URLWithInsecureString:urlString];
	}
    
    
    
    
    // create the request
    NSString* appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString* appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:self.timeout];
#if TARGET_OS_IPHONE
    [request setValue:[NSString stringWithFormat:@"%@/%@ (like iTunes/10.1.2)", appName, appVersion] forHTTPHeaderField:@"User-Agent"];
#else
    [request setValue:[NSString stringWithFormat:@"%@-Mac/%@ (like iTunes/10.1.2)", appName, appVersion] forHTTPHeaderField:@"User-Agent"];
#endif
    
    
    
    // make sure to send fake iTunes Header when content is hosted on iTunes
    if ([[requestURL host] rangeOfString:@"apple.com" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        [request addValue:@"143441-1,12" forHTTPHeaderField:@"X-Apple-Store-Front"];
        [request addValue:@"iTunes/10.1.2 (Macintosh; Intel Mac OS X 10.6.6) AppleWebKit/533.19.4" forHTTPHeaderField:@"User-Agent"];
    }
    
    if (self.etag) {
        [request setValue:self.etag forHTTPHeaderField:@"If-None-Match"];
    }
    
    [request setAllowsCellularAccess:self.allowsCellularAccess];

    
    NSHTTPURLResponse* response;
    NSError* error = nil;
    NSData* feedData = [self sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (!feedData || error || [response statusCode] == 401)
    {
        if ([error code] == kCFURLErrorUserCancelledAuthentication || [error code] == kCFURLErrorUserAuthenticationRequired)
        {
            if (!self.dontAskForCredentials)
            {
                __block BOOL authDone = NO;
                __block BOOL authCancel = NO;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    self.authentication = [[HTTPAuthentication alloc] init];
                    self.authentication.url = self.url;
                    self.authentication.username = self.username;
                    self.authentication.failedBefore = NO;
                    [self.authentication showAuthenticationDialogCompletion:^(BOOL success, NSString *username, NSString *password) {
                        if (!success) {
                            authCancel = YES;
                        } else {
                            self.username = username;
                            self.password = password;
                        }
                        
                        authDone = YES;
                    }];
                });
                
                
                while (!authDone) {
                    [NSThread sleepForTimeInterval:1.0];
                }
            
                if (authCancel) {
                    error = [NSError errorWithDomain:NSURLErrorDomain
                                                code:[error code]
                                            userInfo:@{NSLocalizedDescriptionKey: @"Authentication failed.".ls, NSLocalizedRecoverySuggestionErrorKey : @"The feed could not be read because the username or password is incorrect.".ls }];
                }
                else {
                    goto start;
                }
            }
            else
            {
                error = [NSError errorWithDomain:NSURLErrorDomain
                                            code:[error code]
                                        userInfo:@{NSLocalizedDescriptionKey: @"Authentication failed.".ls, NSLocalizedRecoverySuggestionErrorKey : @"The feed could not be read because the username or password is incorrect.".ls }];
            }
        }
    }
    
    if ([response statusCode] == 304 || [self isCancelled]) {
        if (async) {
            [self performSelectorOnMainThread:@selector(_sendDidParseFeedToDelegate:) withObject:nil waitUntilDone:NO];
        }
        return NO;
    }
    
    
	
    NSString* dataHash = [feedData MD5Hash];
    //DebugLog(@"%@ %@", self.dataHash, dataHash);
    
    if (self.dataHash && [self.dataHash isEqualToString:dataHash])
    {
        DebugLog(@"same data hash: %@", self.url);
        if (async) {
            [self performSelectorOnMainThread:@selector(_sendDidParseFeedToDelegate:) withObject:nil waitUntilDone:NO];
        }
        return NO;
    }
    self.dataHash = dataHash;
    
    if (feedData)
    {
        //DebugLog(@"process xml");
        
        self.xmlPath = @"/";
        _elementAttributes = [[NSMutableDictionary alloc] init];
        
        _elementContent = [[NSMutableString alloc] init];
        [_elementContent setString:@""];
        

        BOOL convertDataToLossy = NO;
        

parse:
        if (convertDataToLossy) {
            NSString *str = [[NSString alloc] initWithData:feedData encoding:NSASCIIStringEncoding];
            
            NSString* str1 = [str stringByReplacingOccurrencesOfString:@"& " withString:@"&amp; "];
            
            if ([str1 rangeOfString:@"encoding=\"windows-1251\""].location != NSNotFound)
            {
                NSString* str2 = [[NSString alloc] initWithData:feedData encoding:NSWindowsCP1251StringEncoding];
                NSString* str3 = [str2 stringByReplacingOccurrencesOfString:@"encoding=\"windows-1251\"" withString:@""];
                
                feedData = [str3 dataUsingEncoding:NSUTF8StringEncoding];
            }
            else
            {
                NSMutableString *asciiCharacters = [NSMutableString string];
                for (NSInteger i = 32; i < 127; i++)  {
                    [asciiCharacters appendFormat:@"%c", (char)i];
                }
                
                NSMutableCharacterSet* allowedCharacterSet = [NSMutableCharacterSet characterSetWithCharactersInString:asciiCharacters];
                [allowedCharacterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                NSCharacterSet *nonAsciiCharacterSet = [allowedCharacterSet invertedSet];
                NSString* str2 = [[str1 componentsSeparatedByCharactersInSet:nonAsciiCharacterSet] componentsJoinedByString:@""];

                feedData = [str2 dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
            }
        }


        _feedLength = [feedData length];
        
        NSXMLParser* parser = [[NSXMLParser alloc] initWithData:feedData];
        
        [parser setDelegate:self];
        @autoreleasepool {
            [parser parse];
        }
        
        if (!error) {
            error = [parser parserError];
        }
        
        if (_resultIsHTML) {
            if ([response statusCode] == 404) {
                error = [NSError errorWithDomain:NSURLErrorDomain
                                            code:[error code]
                                        userInfo:@{
                       NSLocalizedDescriptionKey:@"Error reading podcast.".ls,
          NSLocalizedRecoverySuggestionErrorKey :@"The podcast feed can not be found.".ls
                         }];

            } else {
                error = [NSError errorWithDomain:NSURLErrorDomain
                                            code:[error code]
                                        userInfo:@{
                       NSLocalizedDescriptionKey:@"Error reading podcast.".ls,
          NSLocalizedRecoverySuggestionErrorKey :@"Returned content is a website and not a podcast feed.".ls
                         }];
            }
            goto end;
        }
	
        if (!self.abortedNormally && ([_episodes count] == 0 || [error code] == NSXMLParserInvalidCharacterError) && !convertDataToLossy)
        {
            //ErrLog(@"error parsing feed. Trying again with lossy text conversion");
             _feed = nil;
             _category = nil;
             _episode = nil;
            [_episodes removeAllObjects];
            convertDataToLossy = YES;
            self.xmlPath = @"/";
            [_elementAttributes removeAllObjects];
            [_elementContent setString:@""];
            error = nil;
            goto parse;
        }

        
        _feed.categories = _categories;
        _categories = nil;
        
        _feed.episodes = _episodes;
        _episodes = nil;
        
        
        // parse alternative feeds and present an option to parse a different feed
        if (_presentAlternateFeeds && [_alternateFeeds count] > 1)
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(feedParser:shouldSwitchOneOfTheAlternativeFeeds:feed:)]) {
                NSUInteger newIndex = [self.delegate feedParser:self shouldSwitchOneOfTheAlternativeFeeds:_alternateFeeds feed:_feed];
                
                if (newIndex != NSNotFound)
                {
                    NSDictionary* alternate = [_alternateFeeds objectAtIndex:newIndex];
                    NSString* rel = [alternate objectForKey:@"rel"];
                    if ([rel caseInsensitiveEquals:@"alternate"]) {
                        NSURL* alternateURL = [NSURL URLWithInsecureString:[alternate objectForKey:@"href"]];
                        
                        DebugLog(@"parse alternate %@", alternateURL);
                        
                        self.xmlPath = @"/";
                        [_elementAttributes removeAllObjects];
                        [_elementContent setString:@""];
                        
                        self.url = alternateURL;
                        _presentAlternateFeeds = NO;
                        
                        goto start;
                    }
                }
            }
        }
        
        // repair everything that looks weird
        
        // set etag
        _feed.etag = [[response allHeaderFields] objectForKey:@"ETag"];
        
        // if no subtitle, use the summary
        if ([_feed.title length] == 0) {
            _feed.title = @"Untitled".ls;
        }
        
        // in case subtitle is appended to title
        if (_feed.subtitle && [_feed.title length] > [_feed.subtitle length] && [_feed.title hasSuffix:_feed.subtitle]) {
            NSString* fixedTitle = [_feed.title stringByReplacingOccurrencesOfString:_feed.subtitle withString:@""];
            fixedTitle = [fixedTitle stringByTrimmingCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];
            if (![fixedTitle isEqualToString:_feed.owner]) {
                _feed.title = fixedTitle;
            } else {
                _feed.title = _feed.subtitle;
            }
        }
        
        // if no subtitle, try splitting the title
    //	if ([_feed.subtitle length] == 0)
    //    {
    //        NSArray* splitters = @[@" - ", @" – "];
    //        for(NSString* splitter in splitters) {
    //            NSArray* components = [_feed.title componentsSeparatedByString:splitter];
    //            if ([components count] > 1) {
    //                _feed.title = components[0];
    //                _feed.summary = components[1];
    //                break;
    //            }
    //        }
    //	}
        
        if ([_feed.summary length] == 0) {
            _feed.summary = [_feed.textDescription stringByStrippingHTML];
        }
        
        NSDateFormatter* guidDateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [guidDateFormatter setLocale:locale];
        [guidDateFormatter setDateFormat:@"yyyyMMddHHmmss"];
        
        
        for(ICEpisode* episode in _feed.episodes)
        {
            // if no guids, try to constuct some
            if ([episode.guid length] == 0) {
                NSString* label1 = [episode.title stringByReplacingOccurrencesOfString:@" " withString:@"_"];
                NSString* label2 = [guidDateFormatter stringFromDate:episode.pubDate];
                NSString* constructedGuid = [NSString stringWithFormat:@"%@#%@",label1, label2];
                episode.guid = constructedGuid;
                episode.objectHash = [[NSString stringWithFormat:@"%@%@", [_feed.sourceURL absoluteString], constructedGuid] MD5Hash];
            }
            
            if ([episode.title length] == 0) {
                episode.title = @"Untitled".ls;
            }
            
            // if no subtitle, try to construct some
            if ([episode.subtitle length] == 0) {
                NSString* strippedDescription = [episode.textDescription stringByStrippingHTML];
                NSInteger maxLength = MIN(140, [strippedDescription length]);
                if ([strippedDescription length] > maxLength) {
                    episode.subtitle = [NSString stringWithFormat:@"%@…",[strippedDescription substringWithRange:NSMakeRange(0, maxLength)]];
                } else {
                    episode.subtitle = strippedDescription;
                }
            }
            
            // if no pubdate, use the current date
            if (!episode.pubDate) {
                episode.pubDate = [NSDate date];
            }
        }
        
        
        // if no titles, try to use the text
        for(ICEpisode* episode in _feed.episodes) {
            if ([episode.title length] == 0) {
                episode.title = episode.subtitle;
            }
        }
        
        // make sure the client knows that the URL has changed!
        if (!_feed.changedSourceURL && self.permanentRedirectURL && ![_feed.sourceURL isEqual:self.permanentRedirectURL]) {
            _feed.changedSourceURL = self.permanentRedirectURL;
        }
        
        _feed.contentHash = [_contentHashString MD5Hash];
    }
    
end:
	if (async)
	{
        if (!_feed && !error) {
            error = [NSError errorWithDomain:kPodcastFeedParserErrorDomain
                                        code:0
                                    userInfo:@{
                   NSLocalizedDescriptionKey:@"Error reading podcast.".ls,
      NSLocalizedRecoverySuggestionErrorKey :@"The podcast could not be read, either because the feed does not exist or because the feed format is not supported.".ls
                     }];
        }
        
		if (!self.abortedNormally && error && [_feed.episodes count] == 0) {
			[self performSelectorOnMainThread:@selector(_sendErrorToDelegate:) withObject:error waitUntilDone:NO];
		}
		else {
			[self performSelectorOnMainThread:@selector(_sendDidParseFeedToDelegate:) withObject:_feed waitUntilDone:NO];
		}
	} 
    else
    {
        if ((!self.abortedNormally && error) || !_feed) {
            if (outError) {
                *outError = (error) ? error : [NSError errorWithDomain:kPodcastFeedParserErrorDomain
                                                                  code:0
                                                              userInfo:@{
                                             NSLocalizedDescriptionKey:@"Error reading podcast.".ls,
                                NSLocalizedRecoverySuggestionErrorKey :@"The podcast could not be read, either because the feed does not exist or because the feed format is not supported.".ls
                                               }];
            }
		}
    }
	
	
	_elementContent = nil;
	_elementAttributes = nil;
    
    return (outError == nil || *outError == nil);
}

+ (ICFeed*) parsedFeedWithURL:(NSURL*)url
{
    return [self parsedFeedWithURL:url error:NULL];
}

+ (ICFeed*) parsedFeedWithURL:(NSURL*)url error:(NSError**)error
{
    ICFeedParser* parser = [[self alloc] init];
    parser.url = url;
    parser.presentAlternateFeeds = NO;
    parser.dontAskForCredentials = YES;
    [parser _parseAsync:NO error:error];
    
    ICFeed* feed = parser.feed;
    
    return feed;
}

- (ICFeed*) parsedFeedReturningError:(NSError**)error
{
    [self _parseAsync:NO error:error];
    return self.feed;
}

- (void) main
{
	@autoreleasepool {
	
		[self _parseAsync:YES error:NULL];
	
	}
}

#pragma mark XMLParser Delegate

static NSTimeInterval ParsedPodloveTime(NSString* time)
{
    NSString* timeWithoutMilliseconds = nil;
    
    NSString* hours = nil;
    NSString* minutes = nil;
    NSString* seconds = nil;
    NSString* milliseconds = nil;
    
    // split up milliseconds
    NSArray* timeComponents1 = [time componentsSeparatedByString:@"."];
    
    if ([timeComponents1 count] == 1) {
        timeWithoutMilliseconds = time;
    }
    else if ([timeComponents1 count] > 1) {
        timeWithoutMilliseconds = [timeComponents1 objectAtIndex:0];
        milliseconds = [timeComponents1 objectAtIndex:0];
    }
    
    NSArray* timeComponents2 = [timeWithoutMilliseconds componentsSeparatedByString:@":"];
    if ([timeComponents2 count] == 1) {
        seconds = timeWithoutMilliseconds;
    }
    else if ([timeComponents2 count] == 2) {
        minutes = [timeComponents2 objectAtIndex:0];
        seconds = [timeComponents2 objectAtIndex:1];
    }
    else if ([timeComponents2 count] > 2) {
        hours = [timeComponents2 objectAtIndex:0];
        minutes = [timeComponents2 objectAtIndex:1];
        seconds = [timeComponents2 objectAtIndex:2];
    }
    
    NSInteger h = [hours integerValue];
    NSInteger m = [minutes integerValue];
    NSInteger s = [seconds integerValue];
    NSInteger ms = [milliseconds integerValue];
    
    return h*3600+m*60+s+ms/1000.f;
}

#define TYPE_ATTRIBUTE [[attributes objectForKey:@"type"] lowercaseString]
#define REL_ATTRIBUTE [[attributes objectForKey:@"rel"] lowercaseString]

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributes
{
	if ([self isCancelled]) {
		[parser abortParsing];
		return;
	}
    
    elementName = [elementName lowercaseString];
    
	self.xmlPath = [self.xmlPath stringByAppendingPathComponent:elementName];
	if (attributes) {
		[_elementAttributes setObject:attributes forKey:self.xmlPath];
	}
    
    //DebugLog(@"open %@", self.xmlPath);
	
	self.elementOpen = YES;
	[_elementContent setString:@""];
    
    if ([self.xmlPath isEqualToString:@"/html"]) {
        _resultIsHTML = YES;
        [parser abortParsing];
		return;
    }
	
	if ([self.xmlPath isEqualToString:@"/rss/channel"] || [self.xmlPath isEqualToString:@"/feed"])
    {
        _elementContext = kFeedParserElementContextFeed;
        
        if ([self.xmlPath isEqualToString:@"/rss/channel"]) {
            _format = kFeedParserFeedFormatRSS;
        } else if ([self.xmlPath isEqualToString:@"/feed"]) {
            _format = kFeedParserFeedFormatAtom;
        }
        
		_feed = [[ICFeed alloc] init];
		_feed.sourceURL = [self.url URLByDeletingUsernameAndPassword];
		_feed.lastUpdate = [NSDate date];
        _feed.username = self.username;
        _feed.password = self.password;
	}
    
    else if (_elementContext == kFeedParserElementContextFeed)
    {
        if ([elementName isEqualToString:@"itunes:category"] || [elementName isEqualToString:@"category"])
        {
            // create category on top entry
            ICCategory* category = [[ICCategory alloc] init];
            category.parent = _category;
            _category = category;
            _categoryOpen = YES;
        }
        
        else if ([elementName isEqualToString:@"item"] || [elementName isEqualToString:@"entry"])
        {
            _elementContext = kFeedParserElementContextItem;
            
            if (!_episodes) {
                _episodes = [NSMutableArray array];
            }
            
            _episode = [[ICEpisode alloc] init];
            _episode.feed = _feed;
        }
        
        else if ([elementName isEqualToString:@"image"])
        {
            _elementContext = kFeedParserElementContextFeedImage;
        }
    }
    
    else if (_elementContext == kFeedParserElementContextItem)
    {
        if ([elementName isEqualToString:@"xhtml:body"] || ([elementName isEqualToString:@"content"] && [TYPE_ATTRIBUTE isEqualToString:@"xhtml"]))
        {
            _xhtmlBody = [[NSMutableString alloc] init];
        }
        
        else if (_xhtmlBody)
        {
            NSMutableString* elementAttributes = [[NSMutableString alloc] init];
            for (NSString* key in attributes) {
                [elementAttributes appendFormat:@"%@=\"%@\" ",key, [attributes objectForKey:key]];
            }
            
            [_xhtmlBody appendFormat:@"<%@ %@>", elementName, elementAttributes];
        }
        
        else if ([elementName isEqualToString:@"psc:chapters"])
        {
            _elementContext = kFeedParserElementContextSimpleChapter;
            
            if (!_chapters) {
                _chapters = [NSMutableArray array];
            }
        }
    }
    //DebugLog(@"start: %@   content: %d", self.xmlPath, _elementContext);
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	//DebugLog(@"close %@ %@", self.xmlPath, _elementContent);
    
    /*
    NSString* namespace = nil;
    
    NSRange colonRange = [elementName rangeOfString:@":"];
    if (colonRange.location != NSNotFound) {
        NSString* myElementName = [elementName substringFromIndex:colonRange.location+1];
        namespace = [elementName substringToIndex:colonRange.location];
        elementName = myElementName;
    }
    */
	NSString* elementContent = [_elementContent copy];
	NSDictionary* attributes = [_elementAttributes objectForKey:self.xmlPath];
    elementName = [elementName lowercaseString];
    
    if (_elementContext == kFeedParserElementContextFeed)
    {
        if ([elementName isEqualToString:@"title"]) {
            _feed.title = [elementContent stringByStrippingHTML];
        }
        
        if ([elementName isEqualToString:@"generator"]) {
            _feed.generator = [elementContent stringByStrippingHTML];
        }
        
        else if ([elementName isEqualToString:@"link"] || [elementName isEqualToString:@"atom:link"] || [elementName isEqualToString:@"atom10:link"])
        {
            NSString* relAttr = [[attributes objectForKey:@"rel"] lowercaseString];
            NSString* typeAttr = [[attributes objectForKey:@"type"] lowercaseString];
            NSString* hrefAttr = [attributes objectForKey:@"href"];
            NSString* titleAttr = [attributes objectForKey:@"title"];
            
            // RSS Link
            if (!relAttr && !hrefAttr) {
                _feed.linkURL = [NSURL URLWithInsecureString:elementContent];
            }
            
            // Atom Link
            else if ([relAttr isEqualToString:@"alternate"] && [hrefAttr length] > 0)
            {
                if ([typeAttr isEqualToString:@"text/html"]) {
                    _feed.linkURL = [NSURL URLWithInsecureString:hrefAttr];
                }
            }
            
            // Atom Link
            else if ([relAttr isEqualToString:@"self"] && [hrefAttr length] > 0)
            {
                self.selfURL = [NSURL URLWithInsecureString:hrefAttr];
            }
            
            else if ([relAttr isEqualToString:@"payment"] && [hrefAttr length] > 0) {
                _feed.paymentURL = [NSURL URLWithInsecureString:hrefAttr];
            }
            else if ([relAttr isEqualToString:@"first"] && [hrefAttr length] > 0) {
                _feed.firstPageURL = [NSURL URLWithInsecureString:hrefAttr];
            }
            else if ([relAttr isEqualToString:@"last"] && [hrefAttr length] > 0) {
                _feed.lastPageURL = [NSURL URLWithInsecureString:hrefAttr];
            }
            else if ([relAttr isEqualToString:@"prev"] && [hrefAttr length] > 0) {
                _feed.prevPageURL = [NSURL URLWithInsecureString:hrefAttr];
            }
            else if ([relAttr isEqualToString:@"next"] && [hrefAttr length] > 0) {
                _feed.nextPageURL = [NSURL URLWithInsecureString:hrefAttr];
            }
            
            
            if ([relAttr isEqualToString:@"related"] && [typeAttr isEqualToString:@"text/html"] && hrefAttr &&  titleAttr)
            {
                if (!_alternateFeeds) {
                    _alternateFeeds = [[NSMutableArray alloc] init];
                }
                [_alternateFeeds addObject:attributes];
            }
            
            else if (([relAttr isEqualToString:@"alternate"] || [relAttr isEqualToString:@"self"]) &&
                ([typeAttr isEqualToString:@"application/rss+xml"] || [typeAttr isEqualToString:@"application/atom+xml"]) &&
                hrefAttr &&
                titleAttr)
            {
                if (!_alternateFeeds) {
                    _alternateFeeds = [[NSMutableArray alloc] init];
                }
                [_alternateFeeds addObject:attributes];
            }
        }
        
        else if ([elementName isEqualToString:@"copyright"] || [elementName isEqualToString:@"rights"]) {
            _feed.copyright = elementContent;
        }
     
        else if ([elementName isEqualToString:@"pubdate"] || [elementName isEqualToString:@"updated"] || [elementName isEqualToString:@"lastbuilddate"]) {
            _feed.pubDate = [gDateParser dateFromString:elementContent];
            
            if ([elementContent length] > 0 && !_feed.pubDate) {
                ErrLog(@"error parsing channel pubdate: %@ at %@", elementContent, [self.url absoluteString]);
            }
        }
        
        else if ([elementName isEqualToString:@"description"]) {
            _feed.textDescription = elementContent;
        }
        
        else if ([elementName isEqualToString:@"logo"] && !_feed.imageURL) {
            if ([elementContent length] > 0) {
                NSURL* baseURL = (_feed.linkURL) ? _feed.linkURL : self.url;
                _feed.imageURL = [NSURL URLWithInsecureString:elementContent relativeToURL:baseURL];
            }
        }
        
        else if ([elementName isEqualToString:@"language"] || [elementName isEqualToString:@"feed"])
        {
            NSString* feedXMLLangAttribute = [attributes objectForKey:@"xml:lang"];
            NSString* lang = (feedXMLLangAttribute.length > 1) ? feedXMLLangAttribute : elementContent;
            
            NSArray* comps = [lang componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-_"]];
            if ([comps count] == 1) {
                _feed.language = [[comps objectAtIndex:0] lowercaseString];
            }
            if ([comps count] == 2) {
                _feed.language = [[comps objectAtIndex:0] lowercaseString];
                _feed.country = [[comps objectAtIndex:1] uppercaseString];
            }
        }
        
        else if ([elementName isEqualToString:@"itunes:completed"]) {
            _feed.completed = [elementContent isSetToTrue];
        }
        
        else if ([elementName isEqualToString:@"itunes:subtitle"] || (!_feed.subtitle && [elementName isEqualToString:@"subtitle"])) {
            _feed.subtitle = [[elementContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByStrippingHTML];
        }
        
        else if ([elementName isEqualToString:@"itunes:author"] || (!_feed.author && [self.xmlPath hasSuffix:@"/author/name"])) {
            _feed.author = elementContent;
        }
        
        else if ([elementName isEqualToString:@"itunes:summary"]) {
            _feed.summary = [[elementContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByStrippingHTML];
        }
        
        else if ([elementName isEqualToString:@"itunes:image"] || [elementName isEqualToString:@"icon"])
        {
            NSString* urlString = [attributes objectForKey:@"href"];
            if (!urlString) {
                urlString = elementContent;
            }
            
            if ([urlString length] > 0 ) {
                NSURL* baseURL = (_feed.linkURL) ? _feed.linkURL : self.url;
                _feed.imageURL = [NSURL URLWithInsecureString:urlString relativeToURL:baseURL];
            }
        }
        
        else if ([elementName isEqualToString:@"itunes:explicit"]) {
            _feed.explicitContent = [elementContent isSetToTrue];
        }
        
        else if ([elementName isEqualToString:@"itunes:block"]) {
            _feed.blocked = [elementContent isSetToTrue];
        }
        
        else if ([self.xmlPath hasSuffix:@"/itunes:owner/itunes:name"]) {
            _feed.owner = elementContent;
        }
        
        else if ([self.xmlPath hasSuffix:@"/itunes:owner/itunes:email"]) {
            _feed.ownerEmail = elementContent;
        }
        
        else if (_category && ([elementName isEqualToString:@"itunes:category"] || [elementName isEqualToString:@"category"]))
        {
            // fulfill bottom most entry
            NSString* title = [attributes objectForKey:@"text"];
            if ([title length] > 0)
            {
                ICCategory* category = _category;
                category.title = [attributes objectForKey:@"text"];
                
                if (_categoryOpen && category.title && ![_categories containsObject:category]) {
                    if (!_categories) {
                        _categories = [[NSMutableArray alloc] init];
                    }
                    [_categories addObject:category];
                }
            }
            
            _categoryOpen = NO;
            _category = _category.parent;
        }
        
        else if ([elementName isEqualToString:@"itunes:new-feed-url"] && [elementContent length] > 0) {
            _feed.changedSourceURL = [NSURL URLWithInsecureString:elementContent];
        }
        
    }
    else if (_elementContext == kFeedParserElementContextFeedImage)
    {
        if ([elementName isEqualToString:@"url"] && !_feed.imageURL) {
            if ([elementContent length] > 0 ) {
                NSURL* baseURL = (_feed.linkURL) ? _feed.linkURL : self.url;
                _feed.imageURL = [NSURL URLWithInsecureString:elementContent relativeToURL:baseURL];
            }
        }
        else if ([elementName isEqualToString:@"image"]) {
            _elementContext = kFeedParserElementContextFeed;
        }
    }
    else if (_elementContext == kFeedParserElementContextItem)
    {
        if ([elementName isEqualToString:@"item"] || [elementName isEqualToString:@"entry"])
        {
            if ([_episode.subtitle length] == 0) {
                _episode.subtitle = _episode.summary;
            }
            
            // check if a paymentURL can be extracted from a flattr button
            if (!_episode.paymentURL)
            {
                NSString* showNotes = _episode.textDescription;
                NSRange range = [showNotes rangeOfString:@"flattr-badge-large.png" options:NSCaseInsensitiveSearch];
                if (range.location == NSNotFound) {
                    range = [showNotes rangeOfString:@"flattr_logo_16.png" options:NSCaseInsensitiveSearch];
                }
                
                if (range.location != NSNotFound)
                {
                    NSRange beginRange = [showNotes rangeOfString:@"<a"
                                                          options:(NSCaseInsensitiveSearch|NSBackwardsSearch)
                                                            range:NSMakeRange(0, range.location)];
                    
                    if (beginRange.location != NSNotFound)
                    {
                        NSRange endRange = [showNotes rangeOfString:@"</a>"
                                                            options:(NSCaseInsensitiveSearch)
                                                              range:NSMakeRange(beginRange.location, [showNotes length]-beginRange.location)];
                        
                        
                        NSString* substr = [showNotes substringWithRange:NSMakeRange(beginRange.location, endRange.location-beginRange.location+endRange.length)];
                        substr = [substr stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                        NSString* flattrLink = [substr stringByMatchingRegex:@"<a.*?href=\"(.*?)\"" capture:1];
                        flattrLink = [flattrLink stringByReplacingOccurrencesOfString:@" " withString:@""];
                        
                        if (flattrLink) {
                            flattrLink = [flattrLink stringByDecodingHTMLEntities];
                            _episode.paymentURL = [NSURL URLWithInsecureString:flattrLink];
                        }
                    }
                }
            }
            
            if ([_episode preferedMedium] != nil) {
                [_episodes addObject:_episode];
            }
            
            _episode = nil;
            
            _elementContext = kFeedParserElementContextFeed;
        }
        
        else if ([self.xmlPath isEqualToString:@"/rss/channel/item/title"] || [self.xmlPath isEqualToString:@"/feed/entry/title"]) {
            _episode.title = [elementContent stringByStrippingHTML];
        }
        
        // links, but not enclosure links
        else if (([elementName isEqualToString:@"link"] || [elementName isEqualToString:@"atom:link"]) && ![REL_ATTRIBUTE isEqualToString:@"enclosure"])
        {
            NSString* relAttr = [[attributes objectForKey:@"rel"] lowercaseString];
            NSString* typeAttr = [[attributes objectForKey:@"type"] lowercaseString];
            NSString* hrefAttr = [attributes objectForKey:@"href"];
            
            // RSS Link
            if (!relAttr && !hrefAttr) {
                _episode.link = [NSURL URLWithInsecureString:elementContent];
            }
            
            // Atom Link
            else if ([relAttr isEqualToString:@"alternate"] && hrefAttr) {
                if ([typeAttr isEqualToString:@"text/html"]) {
                    _episode.link = [NSURL URLWithInsecureString:hrefAttr];
                }
            }
            
            else if ([relAttr isEqualToString:@"payment"] && hrefAttr) {
                _episode.paymentURL = [NSURL URLWithInsecureString:hrefAttr];
            }
            
            else if ([relAttr isEqualToString:@"http://podlove.org/deep-link"] && hrefAttr) {
                _episode.deeplink = [NSURL URLWithInsecureString:hrefAttr];
            }
            else if ([relAttr isEqualToString:@"http://podlove.org/simple-chapters"] && hrefAttr) {
                _episode.pscLink = [NSURL URLWithInsecureString:hrefAttr];
            }
        }
        
        else if ([elementName isEqualToString:@"guid"] || [elementName isEqualToString:@"id"])
        {
            _episode.guid = elementContent;
            if (_episode.guid) {
                // need both source url and episode guid to avoid collision
                _episode.objectHash = [[NSString stringWithFormat:@"%@%@", [_feed.sourceURL absoluteString], _episode.guid] MD5Hash];
                //DebugLog(@"%@ %@ %@ %@", _episode.title, _episode.objectHash, _episode.guid, _feed.sourceURL);
            }
        }
        
        else if ([elementName isEqualToString:@"pubdate"] || (([elementName isEqualToString:@"published"] || [elementName isEqualToString:@"updated"]) && _format == kFeedParserFeedFormatAtom))
        {
            _episode.pubDate = [gDateParser dateFromString:elementContent];
            
            if ([elementContent length] > 0 && !_episode.pubDate) {
                ErrLog(@"error parsing item pubdate: %@ at %@", elementContent, [self.url absoluteString]);
            }
        }
        
        else if (!_episode.pubDate && [elementName isEqualToString:@"dc:date"])
        {
            _episode.pubDate = [gDateParser dateFromString:elementContent];
            
            if ([elementContent length] > 0 && !_episode.pubDate) {
                ErrLog(@"error parsing item dc:date: %@ at %@", elementContent, [self.url absoluteString]);
            }
        }
        

        else if ([elementName isEqualToString:@"itunes:author"] || (!_episode.author && [self.xmlPath hasSuffix:@"/author/name"])) {
            _episode.author = elementContent;
        }
        
        else if ([elementName isEqualToString:@"content:encoded"]) {
            _episode.textDescription = elementContent;
        }
        
        else if ([elementName isEqualToString:@"content"] && ([TYPE_ATTRIBUTE isEqualToString:@"html"] || [TYPE_ATTRIBUTE isEqualToString:@"text"])) {
            _episode.textDescription = elementContent;
        }
        
        else if ([elementName isEqualToString:@"xhtml:body"] || ([elementName isEqualToString:@"content"] && [TYPE_ATTRIBUTE isEqualToString:@"xhtml"])) {
            _episode.textDescription = [_xhtmlBody stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            _xhtmlBody = nil;
        }
        
        else if ([_episode.textDescription length] < [elementContent length] && [elementName isEqualToString:@"itunes:description"]) {
            _episode.textDescription = elementContent;
        }
        
        else if ([_episode.textDescription length] < [elementContent length] && [elementName isEqualToString:@"description"]) {
            if ([elementContent rangeOfString:@"<"].location == NSNotFound) {
                _episode.textDescription = [elementContent stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>\n"];
            } else {
                _episode.textDescription = elementContent;
            }
        }
        
        else if ([elementName isEqualToString:@"itunes:summary"] || [elementName isEqualToString:@"summary"]) {
            _episode.summary = [[elementContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByStrippingHTML];
        }
        
        else if ([elementName isEqualToString:@"itunes:subtitle"]) {
            _episode.subtitle = [[elementContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByStrippingHTML];
        }
        
        else if ([elementName isEqualToString:@"itunes:explicit"]) {
            _episode.explicitContent = [elementContent isSetToTrue];
        }
        
        else if ([elementName isEqualToString:@"itunes:block"]) {
            _episode.blocked = [elementContent isSetToTrue];
        }
        
        else if ([elementName isEqualToString:@"itunes:duration"]) {
            NSArray* c = [elementContent componentsSeparatedByString:@":"];
            NSInteger secs = ([c count] > 0) ? [(NSString*)[c objectAtIndex:[c count]-1] integerValue] : 0;
            NSInteger mins = ([c count] > 1) ? [(NSString*)[c objectAtIndex:[c count]-2] integerValue] : 0;
            NSInteger hours = ([c count] > 2) ? [(NSString*)[c objectAtIndex:[c count]-3] integerValue] : 0;
            
            _episode.duration = hours*3600 + mins*60 + secs;
        }
        
        else if ([elementName isEqualToString:@"itunes:image"])
        {
            NSString* urlString = [attributes objectForKey:@"href"];
            if (!urlString) {
                urlString = elementContent;
            }
            if ([urlString length] > 0) {
                _episode.imageURL = [NSURL URLWithInsecureString:urlString];
            }
        }
        
        else if ([elementName isEqualToString:@"enclosure"] || ([elementName isEqualToString:@"link"] && [REL_ATTRIBUTE isEqualToString:@"enclosure"]))
        {
            ICMedia* media = [ICMedia media];
            media.mimeType = [[attributes objectForKey:@"type"] lowercaseString];
            media.byteSize = [(NSString*)[attributes objectForKey:@"length"] integerValue];
            
            NSString* urlString = [attributes objectForKey:@"url"];
    
            if ([urlString length] == 0) {
                urlString = [attributes objectForKey:@"href"];
            }
            if ([urlString length] > 0)
            {
                media.fileURL = [NSURL URLWithInsecureString:urlString];
                
                // compensate for spaces in URLs
                if (!media.fileURL) {
                    urlString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@""];
                    media.fileURL = [NSURL URLWithInsecureString:urlString];
                }
                
                if (!_contentHashString) {
                    _contentHashString = [[NSMutableString alloc] init];
                }
                
                [_contentHashString appendFormat:@"%@%ld", [[media.fileURL path] lastPathComponent], (long)media.byteSize];
            }

            
            if (!_episode.media) {
                _episode.media = [NSArray array];
            }
            
            _episode.media = [_episode.media arrayByAddingObject:media];
            
            if ([media.mimeType length] > 0)
            {
                NSDictionary* iTunesDefinedMimeTypes = [NSDictionary dictionaryWithObjectsAndKeys:
                                                        @"audio/mpeg",@"mp3",
                                                        @"audio/x-m4a",@"m4a",
                                                        @"video/mp4",@"mp4",
                                                        @"video/x-m4v",@"m4v",
                                                        @"video/quicktime",@"mov",
                                                        @"application/pdf",@"pdf",
                                                        @"document/x-epub",@"epub",
                                                        nil];
                
                NSString* pathExtension = [[media.fileURL path] pathExtension];
                NSString* detectedMimeType = [iTunesDefinedMimeTypes objectForKey:[pathExtension lowercaseString]];
                
                if (!media.mimeType || [media.mimeType length] == 0 ) {
                    media.mimeType = detectedMimeType;
                }
                
                if ([media.mimeType rangeOfString:@"video"].location == NSNotFound && [media.mimeType rangeOfString:@"audio"].location == NSNotFound) {
                    if (detectedMimeType && ![detectedMimeType caseInsensitiveEquals:media.mimeType]) {
                        //DebugLog(@"feed might have declared wrong mime type %@ != %@. working around it.", media.mimeType, detectedMimeType);
                        media.mimeType = detectedMimeType;
                    }
                }
                
                if ([media.mimeType rangeOfString:@"video"].location != NSNotFound) {
                    _feed.video = YES;
                    _episode.video = YES;
                }
            }
        }
    }
    else if (_elementContext == kFeedParserElementContextSimpleChapter)
    {
        if ([elementName isEqualToString:@"psc:chapters"]) {
            _elementContext = kFeedParserElementContextItem;
            _episode.chapters = _chapters;
            _chapters = nil;
        }
        
        else if ([elementName isEqualToString:@"psc:chapter"])
        {
            NSString* startAttribute = [attributes objectForKey:@"start"];
            NSString* titleAttribute = [attributes objectForKey:@"title"];
            NSString* hrefAttribute = [attributes objectForKey:@"href"];
            NSString* imageAttribute = [attributes objectForKey:@"image"];
            
            ICChapter* chapter = [[ICChapter alloc] init];
            chapter.episode = _episode;
            
            chapter.title = titleAttribute;
            chapter.time = ParsedPodloveTime(startAttribute);
            
            if (hrefAttribute) {
                chapter.linkURL = [NSURL URLWithInsecureString:hrefAttribute];
            }
            if (imageAttribute) {
                chapter.linkURL = [NSURL URLWithInsecureString:imageAttribute];
            }
            
            [_chapters addObject:chapter];
        }
    }

    if (_xhtmlBody)
    {
        [_xhtmlBody appendFormat:@"</%@>", elementName];
    }
    
    //DebugLog(@"close %@", self.xmlPath);
    
	self.elementOpen = NO;
	[_elementAttributes removeObjectForKey:self.xmlPath];
	self.xmlPath = [self.xmlPath stringByDeletingLastPathComponent];
	
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if (self.elementOpen) {
		[_elementContent appendString:string];
	}
    
    if (_xhtmlBody) {
        [_xhtmlBody appendString:string];
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{

}
                                     
@end
