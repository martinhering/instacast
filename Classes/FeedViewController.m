    //
//  FeedViewController.m
//  Instacast
//
//  Created by Martin Hering on 10.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <QuartzCore/QuartzCore.h>

#import "FeedViewController.h"

#import "UIViewController+ShowNotes.h"
#import "STITunesStore.h"
#import "VDModalInfo.h"
#import "FeedSettingsViewController.h"
#import "CDModel.h"
#import "CDFeed+Helper.h"
#import "PortraitNavigationController.h"
#import "ICFeedHeaderViewController.h"

#import "SubscriptionManager.h"

@interface FeedViewController () <UIWebViewDelegate>
@property (nonatomic, strong) UIWebView* webView;
@property (nonatomic, strong) VDModalInfo* modalInfo;
@property (nonatomic, strong) UIBarButtonItem* actionItem;
@property (nonatomic, strong) UIBarButtonItem* reloadItem;
@property (nonatomic, strong) ICFeedHeaderViewController* headerViewController;
@end


@implementation FeedViewController


+ (FeedViewController*) feedViewController
{
	return [[self alloc] initWithNibName:nil bundle:nil];
}

- (void) _loadContent
{
    // load webview content
    NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US".ls];
    
    NSString* description = ([self.feed.summary length] > [self.feed.fulltext length]) ? self.feed.summary : self.feed.fulltext;
    
    NSMutableString* content = [NSMutableString string];
    [content appendString:@"<style type=\"text/css\" scoped>"];
    NSString* appearanceCssPath = [[NSBundle mainBundle] pathForResource:[ICAppearanceManager sharedManager].appearance.cssFile ofType:@"css"];
    NSString* appearanceCss = [NSString stringWithContentsOfFile:appearanceCssPath encoding:NSUTF8StringEncoding error:nil];
    [content appendString:appearanceCss];
    [content appendString:@"</style>"];
    [content appendString:@"<div id=\"description\">"];
    if (description) {
        [content appendString:description];
    }
    [content appendString:@"<table>"];
    
    if ([self.feed.title length] > 0) {
        [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\">%@</td></tr>", @"Title".ls, self.feed.title];
    }
    
    if ([self.feed.subtitle length] > 0 && ![self.feed.subtitle isEqualToString:self.feed.title] && ![self.feed.subtitle isEqualToString:description]) {
        [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\">%@</td></tr>", @"Subtitle".ls, self.feed.subtitle];
    }
    
    NSSet* categories = self.feed.categories;
    if ([categories count] > 0)
    {
        NSInteger catNum = 0;
        for(CDCategory* category in categories) {
            NSString* catString = nil;
            CDCategory* parentCategory = category.parent;
            if (parentCategory) {
                catString = [NSString stringWithFormat:@"%@ <div class=\"category_arrow\">\u203A</div> %@", parentCategory.title.ls, category.title.ls];
            } else {
                catString = category.title.ls;
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
    if (self.feed.linkURL) {
        [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\"><a href=\"%@\">%@</a></td></tr>", @"Website".ls, [self.feed.linkURL absoluteString], [self.feed.linkURL absoluteString]];
    }
    
    if ([self.feed.copyright length] > 0) {
        [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\">%@</td></tr>", @"Copyright".ls, self.feed.copyright];
    }
    if ([self.feed.owner length] > 0 && [self.feed.ownerEmail length] > 0) {
        [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\"><a href=\"mailto:%@\">%@</a></td></tr>", @"Owner".ls, self.feed.ownerEmail, self.feed.owner];
    }
#ifdef DEBUG
    if (self.feed.sourceURL) {
        [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">Feed</td><td valign=\"top\">%@</td></tr>", [self.feed.sourceURL absoluteString]];
    }
#endif
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterLongStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    NSString* lastUpdate = [formatter stringFromDate:self.feed.lastUpdate];
    [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\">%@</td></tr>", @"Updated".ls, lastUpdate];
    
    
    [content appendString:@"</table></div>"];
    
    NSString* templatePath = [[NSBundle mainBundle] pathForResource:@"InfoDescriptionTemplateIPhone" ofType:@"html"];
    NSString* infoHTMLTemplate = [NSString stringWithContentsOfFile:templatePath encoding:NSUTF8StringEncoding error:nil];
    
    NSString* htmlContent = [infoHTMLTemplate stringByReplacingOccurrencesOfString:@"###CONTENT###" withString:content];
    htmlContent = [htmlContent stringByReplacingOccurrencesOfString:@"###BUTTONS###" withString:@""];
    
    [self.webView loadHTMLString:htmlContent baseURL:nil];
}

- (void) _updateToolbarAnimated:(BOOL)animated
{
    UIBarButtonItem* flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    
    
    // reload item
    self.reloadItem = [[UIBarButtonItem alloc] initWithTitle:@"Reload".ls
                                                       style:UIBarButtonItemStylePlain target:self action:@selector(reloadAction:)];
    
    // settings item
    self.actionItem = [[UIBarButtonItem alloc] initWithTitle:@"Share".ls
                                                       style:UIBarButtonItemStylePlain target:self action:@selector(actionAction:)];

    
    UIBarButtonItem* settingsItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings".ls
                                                                     style:UIBarButtonItemStylePlain target:self action:@selector(settingsAction:)];
    
    
    UIBarButtonItem* fixItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixItem.width = -1;
    
    [self setToolbarItems:@[fixItem, self.reloadItem, flexSpace, self.actionItem, flexSpace, settingsItem, fixItem] animated:animated];

}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	
	self.navigationItem.title = @"Podcast Info".ls;
    

	if (self.feed)
	{
        CGRect b = self.view.bounds;
		UIWebView* webView = [[UIWebView alloc] initWithFrame:b];
        webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		webView.delegate = self;
		[self.view addSubview:webView];
        self.webView = webView;

        self.headerViewController = [ICFeedHeaderViewController viewController];
        self.headerViewController.view.frame = CGRectMake(0, 44, CGRectGetWidth(b), 93);
        self.headerViewController.titleLabel.text = self.feed.title;
        self.headerViewController.subtitleLabel.text = self.feed.author;
        
        __weak FeedViewController* weakSelf = self;
        ImageCacheManager* iman = [ImageCacheManager sharedImageCacheManager];
        [iman imageForURL:self.feed.imageURL size:72 grayscale:NO sender:self completion:^(UIImage *image) {
            if (image) {
                weakSelf.headerViewController.imageView.image = image;
            }
        }];
        
        [self addChildViewController:self.headerViewController];
        [self.view addSubview:self.headerViewController.view];
        [self.headerViewController didMoveToParentViewController:self];
	}
}



- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setScrollView:self.webView.scrollView contentInsets:UIEdgeInsetsMake(93, 0, 0, 0) byAdjustingForStandardBars:YES];
    
    self.view.backgroundColor = ICBackgroundColor;
    self.webView.backgroundColor = ICBackgroundColor;
    
    [self _loadContent];
    
    [self _updateToolbarAnimated:YES];
    [self.navigationController setToolbarHidden:NO animated:YES];
}


#pragma mark -


- (void) unsubscribeAction:(id)sender
{
    WEAK_SELF
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Are you sure you want to unsubscribe '%@'?".ls, self.feed.title]
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Unsubscribe".ls style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              STRONG_SELF
                                                              
                                                              [self perform:^(id sender) {
                                                                  if ([[AudioSession sharedAudioSession].episode.feed isEqual:self.feed]) {
                                                                      [[AudioSession sharedAudioSession] stop];
                                                                  }
                                                                  
                                                                  [[CacheManager sharedCacheManager] removeCacheForFeed:self.feed automatic:NO];
                                                                  [DMANAGER unsubscribeFeed:self.feed];
                                                                  
                                                                  [self.navigationController popToRootViewControllerAnimated:YES];
                                                              } afterDelay:0.3];
                                                              
                                                              self.alertController = nil;
                                                          }];
    [alert addAction:defaultAction];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel".ls style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {
                                                              STRONG_SELF
                                                              self.alertController = nil;
                                                          }];
    [alert addAction:cancelAction];
    
    self.alertController = alert;
    [self presentAlertControllerAnimated:YES completion:NULL];
}

- (void) actionAction:(id)sender
{
    NSURL* feedURL = [self.feed sourceURLAsPcastURL];
    
    UIActivityViewController* shareController = [[UIActivityViewController alloc] initWithActivityItems:@[feedURL] applicationActivities:nil];
    if ([shareController respondsToSelector:@selector(popoverPresentationController)]) {
        shareController.popoverPresentationController.barButtonItem = sender;
    }
    [self presentViewController:shareController animated:YES completion:NULL];
}

#pragma mark -


- (void) settingsAction:(id)sender
{
    FeedSettingsViewController* viewController = [FeedSettingsViewController feedSettingsViewControllerWithFeed:self.feed];
    PortraitNavigationController* navController = [[PortraitNavigationController alloc] initWithRootViewController:viewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:^{
        
    }];
}

- (void) _reloadAndRecover:(BOOL)recover
{
    self.modalInfo = [VDModalInfo modalInfoWithProgressLabel:@"Reloading…".ls];
    [self.modalInfo show];
    
    [[SubscriptionManager sharedSubscriptionManager] reloadContentOfFeed:self.feed recoverArchivedEpisodes:recover completion:^(BOOL success, NSArray* newEpisodes, NSError* error) {
        
        if (error) {
            [self presentError:error];
        }
        
        if (App.networkAccessTechnology > kICNetworkAccessTechnlogyGPRS) {
            [[ImageCacheManager sharedImageCacheManager] clearCachedImagesOfFeed:self.feed];
        }
        
        [self.modalInfo close];
        self.modalInfo = nil;
    }];
}

- (void) reloadAction:(id)sender
{
    [self _reloadAndRecover:YES];
}

#pragma mark -

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSURL *url = request.URL;
	NSString *urlString = [url absoluteString];
	
	if ([[url scheme] isEqualToString:@"delegate"]) {
		return YES;
	}
    
    // do not allow iframes
	if (navigationType == UIWebViewNavigationTypeOther && ![urlString isEqualToString:@"about:blank"]) {
		return NO;
	}
    
    return [self handleShowNotesURL:url];
}

@end
