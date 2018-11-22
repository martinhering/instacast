    //
//  DirectoryFeedViewController.m
//  Instacast
//
//  Created by Martin Hering on 17.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>

#import "ICFeedURLScraper.h"
#import "NSString+ICParser.h"
#import "ICFeedParser.h"
#import "ICPagedFeedParser.h"

#import "DirectoryFeedViewController.h"
#import "UIImageView+BorderedImage.h"

#import "VDModalInfo.h"
#import "JCommand.h"
#import "PlaybackViewController.h"
#import "PlayerController.h"
#import "STITunesStore.h"
#import "UIViewController+ShowNotes.h"
#import "JCommand.h"
#import "ICImageCacheOperation.h"

static NSString* kDefaultImportedEpisodesHintShown = @"DefaultImportedEpisodesHintShown";


@interface DirectoryFeedViewController () <ICFeedURLScraperDelegate>
@property (nonatomic, strong) ICFeed* feed;
@property (nonatomic, strong) UIWebView* webView;
@property (nonatomic, strong) UIImageView* backgroundImageView;
@property (nonatomic, strong) VDModalInfo* loadingInfo;
@property (nonatomic, strong) ICFeedURLScraper* scraper;
@property (nonatomic, strong) ICFeedParser* feedParser;
@property (nonatomic, strong) UIButton* updateButton;
@property (nonatomic, strong) UIImageView* feedImageView;
@property (nonatomic, strong) NSArray* otherPodcasts;
@property (nonatomic) BOOL loaded;
@property (nonatomic) NSInteger initialScrollPosition;
@property (nonatomic, strong) UIView* webShadowView;
@property (nonatomic, strong) UILabel* titleLabel;
@property (nonatomic, strong) UILabel* authorLabel;
@end


@implementation DirectoryFeedViewController


+ (DirectoryFeedViewController*) directoryFeedViewController
{
	return [[self alloc] initWithNibName:nil bundle:nil];
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {

    }
    return self;
}

- (void)dealloc
{
    _webView.delegate = nil;
    [_scraper cancel];
    [_feedParser cancel];
}

- (void) _loadWebViewContent
{
    // load webview content
    NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US".ls];
    
    NSString* description = ([self.feed.summary length] > [self.feed.textDescription length]) ? self.feed.summary : self.feed.textDescription;
    
    NSMutableString* content = [NSMutableString string];
    [content appendString:@"<style type=\"text/css\" scoped>"];
    NSString* appearanceCssPath = [[NSBundle mainBundle] pathForResource:[ICAppearanceManager sharedManager].appearance.cssFile ofType:@"css"];
    NSString* appearanceCss = [NSString stringWithContentsOfFile:appearanceCssPath encoding:NSUTF8StringEncoding error:nil];
    [content appendString:appearanceCss];
    [content appendString:@"</style>"];
    
    [content appendString:@"<div id=\"description\">"];
    if ( ([description length] > 0)) {
        [content appendString:description];
    }
    [content appendString:@"<table>"];
    
    if (self.feed.title) {
        [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\">%@</td></tr>", @"Title".ls, self.feed.title];
    }
    
    if (self.feed.subtitle && ![self.feed.subtitle isEqualToString:self.feed.title] && ![self.feed.subtitle isEqualToString:description]) {
        [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\">%@</td></tr>", @"Subtitle".ls, self.feed.subtitle];
    }
    
    
    NSArray* categories = self.feed.categories;
    if ([categories count] > 0)
    {
        NSInteger catNum = 0;
        for(ICCategory* category in categories) {
            NSString* catString = nil;
            ICCategory* parentCategory = category.parent;
            if (parentCategory) {
                catString = [NSString stringWithFormat:@"%@ <div class=\"category_arrow\">\u203A</div> %@", parentCategory.title, category.title];
            } else {
                catString = category.title;
            }
            
            [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\">%@</td></tr>", (catNum==0) ? @"Genre".ls : @"", catString];
            catNum++;
        }
    }
    
    if ([self.feed.language length] > 0) {
        [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\">%@</td></tr>", @"Language".ls, [locale displayNameForKey:NSLocaleLanguageCode value:self.feed.language]];
    }
    if ([self.feed.country length] > 0) {
        [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\">%@</td></tr>", @"Country".ls, [locale displayNameForKey:NSLocaleCountryCode value:self.feed.country]];
    }
    if ([self.feed.copyright length] > 0) {
        [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\">%@</td></tr>", @"Copyright".ls, self.feed.copyright];
    }
    if ([self.feed.owner length] > 0 && [self.feed.ownerEmail length] > 0) {
        [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\"><a href=\"mailto:%@\">%@</a></td></tr>", @"Owner".ls, self.feed.ownerEmail, self.feed.owner];
    }
    
    [content appendString:@"</table>"];
    [content appendString:@"</div>"];
    
    [content appendString:@"<div id=\"other_podcasts_container\" style=\"display: none;\">"];
    [content appendFormat:@"<div class=\"label\">%@</div>", [NSString stringWithFormat:@"Other Podcasts by %@".ls, self.feed.author]];
    [content appendString:@"<div id=\"other_podcasts\">"];
    [content appendString:@"</div>"];
    [content appendString:@"</div>"];
    
    [content appendString:@"<div id=\"episodes_list\">"];
    [content appendFormat:@"<div class=\"label\">%@</div>", [NSString stringWithFormat:@"%d Episodes".ls, [self.feed.episodes count]]];
    [content appendString:@"</div>"];
    
    NSArray* sortedEpisodes = [self.feed.episodes sortedArrayUsingSelector:@selector(compare:)];
    if ([sortedEpisodes count] > 0) {
        [content appendString:@"<table id=\"episodes\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\">"];
    }
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    NSInteger thisYear = [[[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]] year];
    
    [sortedEpisodes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         ICEpisode* episode = (ICEpisode*)obj;
         NSString* cleanTitle = [episode cleanTitleUsingFeedTitle:self.feed.title];
         
         NSInteger pubYear = [[[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:episode.pubDate] year];
         
         if (pubYear == thisYear) {
             [formatter setDateFormat:@"MMM d".ls];
         } else {
             [formatter setDateFormat:@"MMM d, yy".ls];
         }
         
         [content appendFormat:@"<tr><td><a href=\"delegate://play-episode/%lu\"><div id=\"episodes-row-%ld\" class=\"row %@\"><div class=\"%@\">%@</div><div class=\"%@\">%@</div></div></a></td></tr>",
          (unsigned long)idx,
          (unsigned long)idx,
          (idx % 2 == 0) ? @"even" : @"odd",
          (episode.video) ? @"title_video": @"title_audio",
          cleanTitle,
          (episode.video) ? @"date_video": @"date",
          [formatter stringFromDate:episode.pubDate]
          ];
     }];
    
    [content appendString:@"</table>"];
    
    if (self.feed.firstPageURL != self.feed.lastPageURL) {
        [content appendFormat:@"<div id=\"load_more\" ontouchstart=""><a href=\"delegate://load-more-episodes\">%@</a></div>", @"Load older episodes…".ls];
    }
    
    if ([sortedEpisodes count] > 0) {
        [content appendString:@"<script>"];
        [content appendString:@"var ctr = document.getElementById('episodes');"];
        [content appendString:@"ctr.addEventListener('touchstart', onTouchStartTable, false);"];
        [content appendString:@"ctr.addEventListener('touchend', onTouchEndTable, false);"];
        [content appendString:@"ctr.addEventListener('touchmove', onTouchMoveTable, false);"];
        [content appendString:@"ctr.addEventListener('touchcancel', onTouchCancelTable, false);"];
        [content appendString:@"</script>"];
    }
    
    
    
    NSString* templateName = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? @"InfoDescriptionTemplateIPad" : @"InfoDescriptionTemplateIPhone";
    
    NSString* templatePath = [[NSBundle mainBundle] pathForResource:templateName ofType:@"html"];
    NSString* infoHTMLTemplate = [NSString stringWithContentsOfFile:templatePath encoding:NSUTF8StringEncoding error:nil];
    
    NSString* htmlContent = [infoHTMLTemplate stringByReplacingOccurrencesOfString:@"###CONTENT###" withString:content];
    
    NSString* buttons = @"";
    htmlContent = [htmlContent stringByReplacingOccurrencesOfString:@"###BUTTONS###" withString:buttons];
    
    BOOL retina = ([[[self.view window] screen] scale] > 1);
    
    NSString* videoPath = [[NSBundle mainBundle] pathForResource:(retina)?@"tv@2x":@"tv" ofType:@"png"];
    NSURL* videoURL = (videoPath) ? [NSURL fileURLWithPath:videoPath] : nil;
    htmlContent = [htmlContent stringByReplacingOccurrencesOfString:@"###VIDEO_IMAGE_URL###" withString:[videoURL absoluteString]];
    
    NSString* importImagePath = [[NSBundle mainBundle] pathForResource:(retina)?@"import-episode@2x":@"import-episode" ofType:@"png"];
    NSURL* importImageURL = (importImagePath) ? [NSURL fileURLWithPath:importImagePath] : nil;
    htmlContent = [htmlContent stringByReplacingOccurrencesOfString:@"###IMPORT_EPISODE_IMAGE_URL###" withString:[importImageURL absoluteString]];
    
    NSString* videoPathH = [[NSBundle mainBundle] pathForResource:(retina)?@"tv@2x":@"tv" ofType:@"png"];
    NSURL* videoURLH = (videoPathH) ? [NSURL fileURLWithPath:videoPathH] : nil;
    htmlContent = [htmlContent stringByReplacingOccurrencesOfString:@"###VIDEO_SELECTED_IMAGE_URL###" withString:[videoURLH absoluteString]];
    
    [self.webView loadHTMLString:htmlContent baseURL:nil];
}

- (void) _prepareViewWhenFeedLoaded
{
    UIBarButtonItem* subscribeBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Toolbar Add"]
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(subscribeAction:)];
    
    CDFeed* feed = [DMANAGER feedWithSourceURL:self.feed.sourceURL];
    if (!feed) {
        feed = [DMANAGER feedWithSourceURL:self.feed.changedSourceURL];
    }
    
	if (feed && !feed.parked)
    {
        subscribeBarButtonItem.enabled = NO;
	}
    [self.navigationItem setRightBarButtonItem:subscribeBarButtonItem animated:YES];
    
	if (self.feed)
	{
        CGRect bounds = self.view.bounds;
        CGFloat contentWidth = CGRectGetWidth(bounds);
        CGFloat barHeight = CGRectGetMinY(self.navigationController.navigationBar.frame);
        
        if (!self.webView)
        {
            UIWebView* webView = [[UIWebView alloc] initWithFrame:bounds];
            webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            webView.delegate = self;
            webView.hidden = YES;
            
            UIEdgeInsets safeAreaInsets = UIEdgeInsetsMake(20, 0, 0, 0);
            if (@available(iOS 11.0, *)) {
                safeAreaInsets = self.view.safeAreaInsets;
            }
            
            [self setScrollView:webView.scrollView contentInsets:UIEdgeInsetsMake(72+15, 0, safeAreaInsets.bottom, 0) byAdjustingForStandardBars:YES];
            
            [self.view addSubview:webView];
            self.webView = webView;
            
            UIView* webShadowView = [[UIView alloc] initWithFrame:CGRectMake(0, barHeight+44, contentWidth, 72+15)];
            webShadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
            [self.view addSubview:webShadowView];
            self.webShadowView = webShadowView;

            
            self.feedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 0, 74, 74)];
            [webShadowView addSubview:self.feedImageView];
            
            self.feedImageView.image = [UIImage imageNamed:@"Podcast Placeholder 72"];
            
            ImageCacheManager* iman = [ImageCacheManager sharedImageCacheManager];
            [iman imageForURL:self.feed.imageURL size:72 grayscale:NO sender:self completion:^(UIImage *image) {
                if (image) {
                    self.feedImageView.image = image;
                }
            }];
            
            // create title label
            UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            titleLabel.numberOfLines = 2;
            titleLabel.text = self.feed.title;
            titleLabel.font = [UIFont systemFontOfSize:17.0f];
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            [webShadowView addSubview:titleLabel];
            self.titleLabel = titleLabel;
            
            // create author label
            UILabel* authorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            authorLabel.numberOfLines = 2;
            authorLabel.text = self.feed.author;
            authorLabel.font = [UIFont systemFontOfSize:13.0f];
            authorLabel.backgroundColor = [UIColor clearColor];
            authorLabel.lineBreakMode = NSLineBreakByWordWrapping;
            
            CGSize titleSize = [titleLabel.attributedText boundingRectWithSize:CGSizeMake(contentWidth-72-45, 100) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
            IC_SIZE_INTEGRAL(titleSize);
            
            CGSize authorSize = [authorLabel.attributedText boundingRectWithSize:CGSizeMake(contentWidth-72-45, 100) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
            IC_SIZE_INTEGRAL(authorSize);
            
            CGFloat labelsHeight = titleSize.height + authorSize.height + 2;
            CGFloat yOffset = floorf((72-labelsHeight)/2);
            
            titleLabel.frame = CGRectMake(72+15+15, yOffset, contentWidth-72-30-15, titleSize.height);
            authorLabel.frame = CGRectMake(72+15+15, CGRectGetMaxY(titleLabel.frame)+2, contentWidth-72-30-15, authorSize.height);
            
            [webShadowView addSubview:authorLabel];
            self.authorLabel = authorLabel;
            
            // create toolbar items
            UIBarButtonItem* flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            UIBarButtonItem* actionItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                         target:self 
                                                                                         action:@selector(actionAction:)];
            
            [self setToolbarItems:[NSArray arrayWithObjects:flexSpace, actionItem, nil] animated:YES];
            
            self.view.backgroundColor = ICBackgroundColor;
            self.webView.backgroundColor = ICBackgroundColor;
            self.webView.scrollView.backgroundColor = ICBackgroundColor;
            self.webShadowView.backgroundColor = ICTransparentBackdropColor;
            self.titleLabel.textColor = ICTextColor;
            self.authorLabel.textColor = ICMutedTextColor;
		}
        
        [self _loadWebViewContent];
	}
}


- (void) _showLoadingDialog:(BOOL)show
{
    if (show)
    {
        VDModalInfo* loadingInfo = [VDModalInfo modalInfoWithProgressLabel:@"Loading…".ls];
		loadingInfo.navigationAndToolbarEnabled = YES;
		[loadingInfo show];
        self.loadingInfo = loadingInfo;
    }
    else
    {
        [self.loadingInfo close];
        self.loadingInfo = nil;
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.canBeCanceled) {
        UIBarButtonItem* subscribeBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
        self.navigationItem.leftBarButtonItem = subscribeBarButtonItem;
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = ICBackgroundColor;
    self.webView.backgroundColor = ICBackgroundColor;
    self.webView.scrollView.backgroundColor = ICBackgroundColor;
    self.webShadowView.backgroundColor = ICTransparentBackdropColor;
    self.titleLabel.textColor = ICTextColor;
    self.authorLabel.textColor = ICMutedTextColor;

    [self _loadWebViewContent];
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	if (self.scraper) {
		[App releaseNetworkActivity];
		[self.scraper cancel];
	}
	
	if (self.feedParser) {
		[App releaseNetworkActivity];
		[self.feedParser cancel];
	}
	
	[self.loadingInfo close];
	self.loadingInfo = nil;
	    
    [[ImageCacheManager sharedImageCacheManager] cancelImageCacheOperationsWithSender:self];
}


#pragma mark - Loading

- (void) startLoading
{
    if (self.feed) {
		[self _prepareViewWhenFeedLoaded];
	}
	
	else if (self.itunesURL)
	{
        [self _showLoadingDialog:YES];
		[self performSelector:@selector(_startParsingITunesURL:) withObject:self.itunesURL afterDelay:0.3];
	}
	
	else if (self.feedURL)
	{
		[self _showLoadingDialog:YES];
		[self performSelector:@selector(_startParsingFeedURL:) withObject:self.feedURL afterDelay:0.3];
	}
}

- (void) _presentParserError:(NSError*)error
{
    return;
    
    if (error) {
        [self presentError:error];
    }
    
    [self perform:^(id sender) {
        [self.navigationController popViewControllerAnimated:YES];
    } afterDelay:0.2];
}

- (void) _startParsingITunesURL:(NSURL*)url
{
	[App retainNetworkActivity];
	DebugLog(@"parse iTunes URL");
	self.scraper = [ICFeedURLScraper feedURLScraperWithURL:url];
	self.scraper.delegate = self;
	[[App mainQueue] addOperation:self.scraper];
}

- (void) _startParsingFeedURL:(NSURL*)url
{
	[App retainNetworkActivity];
	DebugLog(@"parse Feed URL");
    
    ICFeedParser* parser = [[ICFeedParser alloc] init];
    parser.url = url;
    parser.didParseFeedBlock = ^(ICFeed* feed) {
        [App releaseNetworkActivity];
        
        DebugLog(@"feed parser finished");
        self.feedParser = nil;
        
        [self _showLoadingDialog:NO];
        
        self.feed = feed;
        
        [self _prepareViewWhenFeedLoaded];
        
        if (self.didLoadFeed) {
            self.didLoadFeed(YES, nil);
        }

    };
    parser.didEndWithError = ^(NSError* error) {

        [App releaseNetworkActivity];
        
        ErrLog(@"feed could not be parsed: %@", [error description]);
        self.feedParser = nil;
        
        [self _showLoadingDialog:NO];
        
        if (self.didLoadFeed) {
            self.didLoadFeed(NO, error);
        }
        
        [self _presentParserError:error];
    };
    
    self.feedParser = parser;
	[[App mainQueue] addOperation:self.feedParser];
}

- (NSUInteger) feedParser:(ICFeedParser*)feedParser shouldSwitchOneOfTheAlternativeFeeds:(NSArray*)alternativeFeeds feed:(ICFeed*)feed;
{
    return NSNotFound;
}

- (void) feedURLScraper:(ICFeedURLScraper*)scraper didScrapeFeedURL:(NSURL*)url
{
	[App releaseNetworkActivity];
    self.feedURL = url;
	DebugLog(@"scraper finished: %@", [url absoluteString]);
    
    [self _startParsingFeedURL:url];
}

- (void) feedURLScraper:(ICFeedURLScraper*)scraper didEndWithError:(NSError*)error
{
	[App releaseNetworkActivity];
	
	ErrLog(@"feedURLScraper error %@", [error description]);
	[self _showLoadingDialog:NO];
	
    if (self.didLoadFeed) {
        self.didLoadFeed(NO, error);
    }
    
    [self _presentParserError:error];
}

/*
- (void) _presentAlternateFeedInfos:(NSDictionary*)alternateFeedData
{
    NSMutableArray* filteredFeedData = [[NSMutableArray alloc] init];
    
    for(NSDictionary* feedData in [alternateFeedData allValues])
    {
        if (feedData[@"related:apple-itunes-app"]) {
            [filteredFeedData addObject:feedData];
        }
    }
    
    if ([filteredFeedData count] > 0) {
        
        UIAlertView* alertView = [UIAlertView alertWithTitle:self.feed.title
                                                     message:@"This podcast offers alternative media. Please select to check it out or cancel to continue.".ls];
        
        for(NSDictionary* alternateFeed in filteredFeedData)
        {
            [alertView addButtonWithTitle:alternateFeed[@"title"] handler:^{
                
                if (alternateFeed[@"related:apple-itunes-app"])
                {
                    NSMutableDictionary* argumentsDict = [NSMutableDictionary dictionaryWithCapacity:3];
                    
                    NSArray* arguments = [alternateFeed[@"related:apple-itunes-app"] componentsSeparatedByString:@","];
                    for(NSString* argument in arguments) {
                        NSString* myArgument = [argument stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        NSArray* kvPair = [myArgument componentsSeparatedByString:@"="];
                        NSString* key = ([kvPair count] > 0) ? kvPair[0] : nil;
                        key = [[key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
                        NSString* value = ([kvPair count] > 1) ? kvPair[1] : nil;
                        value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        
                        if (key && value) {
                            [argumentsDict setObject:value forKey:key];
                        }
                    }
                    
                    NSString* appArgument = argumentsDict[@"app-argument"];
                    NSString* appId = argumentsDict[@"app-id"];
                    
                    NSURL* appArgumentURL = (appArgument) ? [NSURL URLWithString:appArgument] : nil;
                    
                    if (appArgumentURL && [App canOpenURL:appArgumentURL]) {
                        [App openURL:appArgumentURL];
                    }
                    else if (appId)
                    {
                        STITunesStore* store = [[STITunesStore alloc] init];
                        NSString* affiliateURLString = [store affiliateLinkForStoreLink:[NSString stringWithFormat:@"https://itunes.apple.com/app/id%@?mt=8",appId]];
                        NSURL* affiliateURL = [NSURL URLWithString:affiliateURLString];
                        if (affiliateURL) {
                            [self handleShowNotesURL:affiliateURL];
                        }
                    }
                }
                else if ([alternateFeed[@"type"] isEqualToString:@"text/html"] && alternateFeed[@"href"])
                {
                    NSURL* url = [NSURL URLWithString:alternateFeed[@"href"]];
                    if (url) {
                        [App openURL:url];
                    }
                }

            }];

        }
        
        [alertView setCancelButtonWithTitle:@"Cancel".ls handler:^{}];
        
        [alertView show];
    }
}
*/



#pragma mark -


- (void) actionAction:(id)sender
{
	if (self.feed.linkURL) {
		[[UIApplication sharedApplication] openURL:self.feed.linkURL];
	}
}

- (void) subscribeFeed:(ICFeed*)feed andDismissViewController:(UIViewController*)viewController byPopping:(BOOL)popping
{
    VDModalInfo* subscribingModelInfo = [VDModalInfo modalInfoWithProgressLabel:@"Subscribing…"];
    [subscribingModelInfo showWithCompletion:^{
        
        if (feed.changedSourceURL) {
            feed.sourceURL = feed.changedSourceURL;
        }
        
        CDFeed* subscribedFeed = [DMANAGER feedWithSourceURL:feed.sourceURL];
        
        if (subscribedFeed) {
            subscribedFeed.parked = NO;
            [[SubscriptionManager sharedSubscriptionManager] reloadContentOfFeed:subscribedFeed recoverArchivedEpisodes:YES completion:^(BOOL success, NSArray* newEpisodes, NSError* error) {
                
                if (error) {
                    [self presentError:error];
                }
                
                [subscribingModelInfo closeWithCompletion:^{
                    
                    if (!viewController) {
                        return;
                    }
                    
                    if (popping) {
                        [viewController.navigationController popViewControllerAnimated:YES];
                    } else {
                        [viewController dismissViewControllerAnimated:YES completion:^{ }];
                    }
                }];
                
            }];
        }
        else
        {
            CDFeed* subscribedFeed = [[SubscriptionManager sharedSubscriptionManager] subscribeParserFeed:feed autodownload:YES options:kSubscribeOptionNone];
            subscribedFeed.parked = NO;
            
            [subscribingModelInfo closeWithCompletion:^{
                
                if (!viewController) {
                    return;
                }
                
                if (popping) {
                    [viewController.navigationController popViewControllerAnimated:YES];
                } else {
                    [viewController dismissViewControllerAnimated:YES completion:^{ }];
                }
            }];
        }
    }];
}


- (void) subscribeAction:(id)sender
{
	self.navigationItem.rightBarButtonItem.enabled = NO;
    [self subscribeFeed:self.feed andDismissViewController:self byPopping:self.shouldPopBackToList];
}

- (void) cancelAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NO];
}

#pragma mark WebView Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSURL* url = [request URL];
	
	if ([[url scheme] isEqualToString:@"delegate"])
	{
        DebugLog(@"%@", url);
		NSString* command = [url host];
        
        
        if ([command isEqualToString:@"load-more-episodes"])
        {
            self.initialScrollPosition = [[self.webView stringByEvaluatingJavaScriptFromString:@"scrollY"] integerValue];
            
            [self _showLoadingDialog:YES];
            
            ICPagedFeedParser* parser = [[ICPagedFeedParser alloc] init];
            parser.url = self.feed.sourceURL;
            parser.username = self.feed.username;
            parser.password = self.feed.password;
            parser.allowsCellularAccess = [USER_DEFAULTS boolForKey:EnableRefreshingOver3G];
            
            parser.didParsePage = ^(NSInteger page) {
                self.loadingInfo.textLabel.text = [NSString stringWithFormat:@"Page %ld".ls, page];
            };
            
            parser.didParseFeedBlock = ^(ICFeed* parserFeed) {
                
                DebugLog(@"a");
                self.feed = parserFeed;
                [self _prepareViewWhenFeedLoaded];
                [self _showLoadingDialog:NO];
            };
            
            parser.didEndWithError = ^(NSError* error) {
                DebugLog(@"a");
                [self _showLoadingDialog:NO];
            };
            
            [[App mainQueue] addOperation:parser];
        }
        
        else if ([command isEqualToString:@"play-episode"])
        {
            NSInteger index = [[[url path] lastPathComponent] integerValue];
            NSArray* sortedEpisodes = [self.feed.episodes sortedArrayUsingSelector:@selector(compare:)];
            ICEpisode* episode = [sortedEpisodes objectAtIndex:index];

            CDEpisode* persistentEpisode = [DMANAGER addUnsubscribedFeed:self.feed andEpisode:episode];
            
            PlaybackViewController* playbackController = [PlaybackViewController playbackViewControllerWithEpisode:persistentEpisode];
            PlayerController* playerController = [playbackController.viewControllers objectAtIndex:0];
            playerController.backgroundPlayback = NO;
            [playbackController presentFromParentViewController:self];
            
            [[AudioSession sharedAudioSession] disableContinuousPlaybackForCurrentEpisode];
        }
	}
	
	return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.loaded = YES;
    
    if (self.initialScrollPosition != 0) {
        [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat: @"window.scrollTo(0, %ld);", (long)self.initialScrollPosition]];
        self.initialScrollPosition = 0;
    }
    
    [self perform:^(id sender) {
        for(UIView* subview in self.view.subviews) {
            subview.hidden = NO;
        }
    } afterDelay:0.2];
    
}

@end
