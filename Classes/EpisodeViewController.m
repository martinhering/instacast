    //
//  EpisodeViewController.m
//  Instacast
//
//  Created by Martin Hering on 12.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import "EpisodeViewController.h"
#import "UIManager.h"

#import "InstacastAppDelegate.h"
#import "PlaybackViewController.h"
#import "VDModalInfo.h"

#import "STITunesStore.h"
#import "UtilityFunctions.h"
#import "CDModel.h"
#import "CDEpisode+ShowNotes.h"

#import "UIViewController+ShowNotes.h"
#import "UtilityFunctions.h"
#import "UIImageView+BorderedImage.h"
#import "EpisodePlayComboButton.h"
#import "ICEpisodeConsumeIndicator.h"
#import "OpenInSafariActivity.h"

@interface EpisodeViewController () <UIGestureRecognizerDelegate, UIScrollViewDelegate, UIWebViewDelegate>
@property (nonatomic, strong) CDFeed* feed;
@property (nonatomic, strong) VDModalInfo* modalInfo;

// added as subviews to self.view
@property (nonatomic, strong) UIView* headerView;
@property (nonatomic, strong) UIImageView* imageView;

@property (nonatomic, strong) UILabel* titleLabel;
@property (nonatomic, strong) UILabel* feedTitleLabel;
@property (nonatomic, strong) ICEpisodeConsumeIndicator* consumeIndicator;
@property (nonatomic, strong) UILabel* timeLabel;
@property (nonatomic, strong) UIButton* cacheButton;
@property (nonatomic, strong) UIBarButtonItem* cacheButtonItem;
@property (nonatomic, strong) UIImageView* videoIndicator;
@property (nonatomic, strong) UIView* starredIndicator;

@property (nonatomic, strong) EpisodePlayComboButton* playButton;
@property (nonatomic, strong) UILongPressGestureRecognizer* longPressRecognizer;
@property (nonatomic, strong) id<ICAppearance> appearance;
@end

@implementation EpisodeViewController {
    BOOL _observing;
    BOOL _observingScrollView;
    BOOL _dontReleaseSharedContent;
    CGPoint _scrollOffset;
    BOOL    _dontSaveScrollOffset;
}


+ (EpisodeViewController*) episodeViewController
{
	return [[self alloc] initWithNibName:nil bundle:nil];
}

- (void)dealloc
{
    [self _releaseSharedContent];
    self.episode = nil;
    [self _setObserving:NO];
	[_modalInfo close];
}

+ (UIWebView*) sharedWebView
{
    static UIWebView* sharedWebView = nil;
    
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
        sharedWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        NSString* templatePath = [[NSBundle mainBundle] pathForResource:@"ShowNotesTemplateIPhone" ofType:@"html"];
        NSString* infoHTMLTemplate = [NSString stringWithContentsOfFile:templatePath encoding:NSUTF8StringEncoding error:nil];
        [sharedWebView loadHTMLString:infoHTMLTemplate baseURL:nil];
    });
    
	return sharedWebView;
}

#pragma mark -

- (NSString*) showNotesAsHTMLIncludingAttributes:(BOOL)attributes
{
    CDFeed* feed = self.episode.feed;
    
	// load webview content
	NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US".ls];
	NSString* description = [self.episode cleanedShowNotes];
	
	NSMutableString* content = [NSMutableString string];
    [content appendString:@"<style type=\"text/css\" scoped>"];
    NSString* appearanceCssPath = [[NSBundle mainBundle] pathForResource:[ICAppearanceManager sharedManager].appearance.cssFile ofType:@"css"];
    NSString* appearanceCss = [NSString stringWithContentsOfFile:appearanceCssPath encoding:NSUTF8StringEncoding error:nil];
    [content appendString:appearanceCss];
    [content appendString:@"</style>"];

    [content appendString:@"<div id=\"description\">"];
	if (description)
    {
        // find time codes and replace them with links
        if ([self.episode preferedMedium] && [description length] > 7) {
            @try {
                
                //description = [NSString stringWithFormat:@"<span>%@</span>",description];
                
                NSUInteger l = [description length];

                description = [description stringByReplacingOccurrencesOfRegex:@"(\\d{1,2}:\\d{2}:\\d{2})(?=[^>]*(<|$))" withString:@"<a href=\"delegate://play-chapter-timecode/$1\">$1</a>"];
                
                // if pattern failed
                if ([description length] == l) {
                    // matches 00:00
                    description = [description stringByReplacingOccurrencesOfRegex:@"(\\d{2}:\\d{2})(?=[^>]*(<|$))" withString:@"<a href=\"delegate://play-chapter-timecode/00:$1\">$1</a>"];
                }
                
                description = [description stringByReplacingOccurrencesOfRegex:@"(?!<a.*?>)(\\s)@([\\w\\d]+)(?!</a>)" withString:@"$1<a href=\"http://twitter.com/$2\">@$2</a>"];
                
            }
            @catch (NSException *exception) {
                ErrLog(@"%@", [exception description])
            }
        }
        if (description) {
            [content appendString:description];
        }
	}
	[content appendString:@"<table>"];
	
    if (attributes)
    {
        if ([self.episode.title length] > 0) {
            [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\">%@</td></tr>", @"Title".ls, self.episode.title];
        }
        
        if ([self.episode.author length] > 0) {
            [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\">%@</td></tr>", @"Author".ls, self.episode.author];
        }
        
        if (self.episode.pubDate) {
            NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
            [formatter setLocale:locale];
            [formatter setDateStyle:NSDateFormatterLongStyle];
            [formatter setTimeStyle:NSDateFormatterShortStyle];
            NSString* pubdate = [formatter stringFromDate:self.episode.pubDate];
            [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\">%@</td></tr>", @"Published".ls, pubdate];
        }
        
        if ([feed.language length] > 0) {
            [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\">%@</td></tr>", @"Language".ls, [locale displayNameForKey:NSLocaleLanguageCode value:feed.language]];
        }
        if ([feed.country length] > 0) {
            [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\">%@</td></tr>", @"Country".ls, [locale displayNameForKey:NSLocaleCountryCode value:feed.country]];
        }
        if ([feed.copyright length] > 0) {
            [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\">%@</td></tr>", @"Copyright".ls, feed.copyright];
        }
        if ([feed.owner length] > 0 && [feed.ownerEmail length] > 0) {
            [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\"><a href=\"mailto:%@\">%@</a></td></tr>", @"Owner".ls, feed.ownerEmail, feed.owner];
        }
        
    //#ifdef DEBUG
    //    if (self.episode.feed.sourceURL) {
    //        [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">Feed</td><td valign=\"top\">%@</td></tr>", [self.episode.feed.sourceURL absoluteString]];
    //    }
    //    
    //    if (self.episode.objectHash) {
    //        [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">Hash</td><td valign=\"top\">%@</td></tr>", self.episode.objectHash];
    //    }
    //    
    //    if (self.episode.guid) {
    //        [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">Guid</td><td valign=\"top\">%@</td></tr>", self.episode.guid];
    //    }
    //#endif
        
        if (self.episode.duration >= 1) {
            
            NSInteger duration = self.episode.duration;
            NSValueTransformer* durationTransformer = [NSValueTransformer valueTransformerForName:kICDurationValueTransformer];
            NSString* time = [durationTransformer transformedValue:@(duration)];
            
            [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\">%@</td></tr>", @"Duration".ls, time];
        }
        
        // add cached file size
        unsigned long long fileSize = [self.episode preferedMedium].byteSize;
        
        if ([[CacheManager sharedCacheManager] episodeIsCached:self.episode]) {
            NSURL* fileURL = [[CacheManager sharedCacheManager] URLForCachedEpisode:self.episode];
            NSError* error = nil;
            NSDictionary* fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[fileURL path] error:&error];
            
            if (!error) {
                fileSize = [fileAttributes fileSize];
            }
        }

        if (fileSize > 0)
        {
            NSString* sizeString = [NSByteCountFormatter stringFromByteCount:fileSize countStyle:NSByteCountFormatterCountStyleMemory];
            if (sizeString) {
                [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">%@</td><td valign=\"top\">%@</td></tr>", @"File".ls, sizeString];
            }
        }
        
    #ifdef DEBUG
        
        [content appendFormat:@"<tr><td class=\"label\" valign=\"top\">UID</td><td valign=\"top\">%@</td></tr>", self.episode.objectHash];
    #endif
        
        [content appendString:@"</table></div>"];
    }
	
	return content;
}


- (void) _loadWebContent
{
    NSString* content = [self showNotesAsHTMLIncludingAttributes:YES];
    content = [content stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
    content = [content stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    content = [content stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    
    UIWebView* webView = [EpisodeViewController sharedWebView];
    NSString* result = [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setContent('%@')", content]];
    
    if (![result isEqualToString:@"ok"]) {
        ErrLog(@"javascript error");
    }
    
    if (!CGPointEqualToPoint(_scrollOffset, CGPointZero)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            webView.scrollView.contentOffset = _scrollOffset;
        });
    }
    
    self.appearance = [ICAppearanceManager sharedManager].appearance;
    
}

- (void) _deleteWebContent
{
    UIWebView* webView = [EpisodeViewController sharedWebView];
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setContent('')"]];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Show Notes";
    
    
	CGRect viewBounds = self.view.bounds;
	
	if (!self.episode) {
        return;
    }

    CGFloat masterWidth = CGRectGetWidth(viewBounds);
    
    
    UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 44, masterWidth, 10+72+10)];
    headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:headerView];
    self.headerView = headerView;
    
    
    UIImageView* imageView = [[UIImageView alloc] initWithFrame:CGRectMake(masterWidth-15-72, 10, 72, 72)];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [headerView addSubview:imageView];
    
    imageView.image = [UIImage imageNamed:@"Podcast Placeholder 72"];
    
    NSURL* url = (self.episode.imageURL) ? self.episode.imageURL : self.episode.feed.imageURL;
    ImageCacheManager* iman = [ImageCacheManager sharedImageCacheManager];
    [iman imageForURL:url size:72 grayscale:NO sender:self completion:^(UIImage* image) {
        imageView.image = image;
    }];
    
    // create title label
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, masterWidth-72-45, 72)];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    titleLabel.text = [self.episode cleanTitleUsingFeedTitle:self.episode.feed.title];
    titleLabel.font = [UIFont systemFontOfSize:15];
    titleLabel.numberOfLines = 20;
    titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    //titleLabel.backgroundColor = [UIColor redColor];

    CGSize titleBoundingSize = [[titleLabel attributedText] boundingRectWithSize:CGSizeMake(masterWidth-72-45, 72) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    IC_SIZE_INTEGRAL(titleBoundingSize);
    titleLabel.frame = CGRectMake(15, 10, masterWidth-72-45, titleBoundingSize.height);
    
    [headerView addSubview:titleLabel];
    self.titleLabel = titleLabel;
    
    UILabel* feedTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, CGRectGetMaxY(titleLabel.frame), masterWidth-72-45, 300)];
    feedTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    feedTitleLabel.text = self.episode.feed.title;
    feedTitleLabel.font = [UIFont systemFontOfSize:15];
    feedTitleLabel.numberOfLines = 1;
    feedTitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    //feedTitleLabel.backgroundColor = [UIColor blueColor];
    
    CGSize feedTitleBoundinSize = [[feedTitleLabel attributedText] boundingRectWithSize:CGSizeMake(masterWidth-72-45, 72) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    IC_SIZE_INTEGRAL(feedTitleBoundinSize);
    feedTitleLabel.frame = CGRectMake(15, CGRectGetMaxY(titleLabel.frame), masterWidth-72-45, feedTitleBoundinSize.height);
    [headerView addSubview:feedTitleLabel];
    self.feedTitleLabel = feedTitleLabel;
    
    UILabel* timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    timeLabel.font = [UIFont systemFontOfSize:11.0f];
    [headerView addSubview:timeLabel];
    self.timeLabel = timeLabel;
    
    self.consumeIndicator = [[ICEpisodeConsumeIndicator alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    self.consumeIndicator.backgroundColor = [UIColor clearColor];
    self.consumeIndicator.opaque = NO;
    self.consumeIndicator.tintColor = (self.episode.consumed) ? ICMutedTextColor : self.view.tintColor;
    [headerView addSubview:self.consumeIndicator];
    
    UIImageView* videoIndicator = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"Episode Video"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    videoIndicator.tintColor = ICMutedTextColor;
    videoIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    videoIndicator.hidden = !self.episode.video;
    [headerView addSubview:videoIndicator];
    self.videoIndicator = videoIndicator;
    
    
    UIView* starredIndicator = [[UIView alloc] initWithFrame:CGRectMake(0, 15, 3, 72)];
    starredIndicator.backgroundColor = [UIColor colorWithRed:1.f green:174/255.0 blue:0.f alpha:1.f];
    starredIndicator.hidden = !self.episode.starred;
    [headerView addSubview:starredIndicator];
    self.starredIndicator = starredIndicator;
    
    // correct
    [self _updateTimeDisplay];
}

- (void) _retainSharedContent
{
    UIWebView* webview = [EpisodeViewController sharedWebView];
    if (webview.superview != self.view || [ICAppearanceManager sharedManager].appearance != self.appearance)
    {
        webview.frame = [self.view bounds];
        webview.delegate = self;
        [self.view insertSubview:webview belowSubview:self.headerView];
        
        UIScrollView* scrollView = webview.scrollView;
        scrollView.delegate = self;
        
        BOOL toolbarShown = (!self.navigationController.toolbarHidden || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);

        _dontSaveScrollOffset = YES;
        CGFloat topOffset = CGRectGetMaxY(self.headerView.frame);
        if (IS_IOS11) {
            topOffset = CGRectGetHeight(self.headerView.frame);
            toolbarShown = NO;
        }
        scrollView.contentInset = UIEdgeInsetsMake(topOffset, 0, (toolbarShown)?44:0, 0);
        scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(topOffset, 0, (toolbarShown)?44:0, 0);
        scrollView.contentOffset = CGPointMake(0, -scrollView.contentInset.top);
        _dontSaveScrollOffset = NO;
        
        [self _loadWebContent];
    }
}

- (void) _releaseSharedContent
{
    UIWebView* webview = [EpisodeViewController sharedWebView];
    if (webview.superview == self.view) {
        webview.delegate = nil;
        webview.scrollView.delegate = nil;
        [self _deleteWebContent];
        [webview removeFromSuperview];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    self.view.backgroundColor = ICBackgroundColor;
    self.headerView.backgroundColor = ICTransparentBackdropColor;

    self.titleLabel.textColor = ICTextColor;
    self.feedTitleLabel.textColor = ICMutedTextColor;
    self.timeLabel.textColor = ICMutedTextColor;
    [EpisodeViewController sharedWebView].backgroundColor = ICBackgroundColor;
    [EpisodeViewController sharedWebView].scrollView.backgroundColor = ICBackgroundColor;
    
    UINavigationBar* navBar = self.navigationController.navigationBar;
    CGRect b = self.view.bounds;
    self.headerView.frame = CGRectMake(0, CGRectGetMaxY(navBar.frame), CGRectGetWidth(b), MAX(10+72+15, CGRectGetMaxY(self.timeLabel.frame)+12));
	[self _updateTimeDisplay];
    [self _updateToolbarAnimated:NO];
    
    [self _retainSharedContent];
    
    self.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    self.longPressRecognizer.delegate = self;
    [self.view addGestureRecognizer:self.longPressRecognizer];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	
    [self _updateTitleLayout];
    [self _setObserving:YES];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

	[self _setObserving:NO];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (!_dontReleaseSharedContent) {
        [self _releaseSharedContent];
        _dontReleaseSharedContent = NO;
    }
    
    [self.view removeGestureRecognizer:self.longPressRecognizer];
    self.longPressRecognizer = nil;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [self _updateTitleLayout];
}

#pragma mark -

- (void) handleLongPress:(UILongPressGestureRecognizer*)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        UIWebView* webview = [EpisodeViewController sharedWebView];
        UIScrollView* scrollView = webview.scrollView;
        UIEdgeInsets insets = scrollView.contentInset;
        
        CGPoint location = [sender locationInView:webview];
        NSString *href = [self hrefAtLocation:CGPointMake(location.x, location.y - insets.top)];
        NSURL* url = (href) ? [NSURL URLWithString:href] : nil;

        if (url) {
            UIActivityViewController* shareController = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:@[[[OpenInSafariActivity alloc] init]]];
            if ([shareController respondsToSelector:@selector(popoverPresentationController)]) {
                shareController.popoverPresentationController.sourceView = self.view;
                shareController.popoverPresentationController.sourceRect = CGRectMake(location.x, location.y, 1, 1);
            }
            [self presentViewController:shareController animated:YES completion:NULL];
        }
        
        [App beginIgnoringInteractionEvents];
    }
    else
    {
        if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (NSString *)hrefAtLocation:(CGPoint)location {
    
    
    NSString *body = @"\n\
    var link = 0;\n\
    \n\
    var x = x__;\n\
    var y = y__;\n\
    \n\
    var d = 15;\n\
    \n\
    for (var h=0; h<=d; h++) {\n\
    for (var hi=-1; hi<=1; hi+=2) {\n\
    var hx = hi * h;\n\
    for (var v=0; v<=d; v++) {\n\
    for (var vi=-1; vi<=1; vi+=2) {\n\
    var vy = vi * v;\n\
    x = x__ + hx;\n\
    y = y__ + vy;\n\
    \n\
    var elem = document.elementFromPoint(x,y);\n\
    \n\
    do {\n\
    \n\
    if (elem == document.body) {\n\
    break;\n\
    }\n\
    \n\
    if (elem.tagName.toLowerCase() == 'a') {\n\
    link = elem;\n\
    break;\n\
    }\n\
    \n\
    elem = elem.parentNode;\n\
    \n\
    } while (elem);\n\
    \n\
    if (link) break;\n\
    \n\
    }\n\
    }\n\
    }\n\
    \n\
    if (link) break;\n\
    \n\
    }\n\
    \n\
    \n\
    if (link) {\n\
    return link.href;\n\
    }\n\
    return '';";
    
    
    
    NSString *js = [NSString stringWithFormat:@"(function(x__, y__) { %@ })(%f,%f)",body,location.x,location.y];
    
    NSString *ret = [[EpisodeViewController sharedWebView] stringByEvaluatingJavaScriptFromString:js];
    
    if ([ret hasPrefix:@"http"]) {
        return ret;
    }
    return nil;
    
    
}

#pragma mark -

- (void) _updateTitleLayout
{
    CGFloat masterWidth = CGRectGetWidth(self.view.bounds);

    CGSize titleBoundingSize = [[self.titleLabel attributedText] boundingRectWithSize:CGSizeMake(masterWidth-72-45, 72) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    IC_SIZE_INTEGRAL(titleBoundingSize);
    self.titleLabel.frame = CGRectMake(15, 10, masterWidth-72-45, titleBoundingSize.height);

    CGSize feedTitleBoundinSize = [[self.feedTitleLabel attributedText] boundingRectWithSize:CGSizeMake(masterWidth-72-45, 72) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    IC_SIZE_INTEGRAL(feedTitleBoundinSize);
    self.feedTitleLabel.frame = CGRectMake(15, CGRectGetMaxY(self.titleLabel.frame), masterWidth-72-45, feedTitleBoundinSize.height);
    
    [self _updateTimeDisplay];
    
    
    UINavigationBar* navBar = self.navigationController.navigationBar;
    self.headerView.frame = CGRectMake(0, CGRectGetMaxY(navBar.frame), masterWidth, MAX(10+72+15, CGRectGetMaxY(self.timeLabel.frame)+12));

    BOOL toolbarShown = (!self.navigationController.toolbarHidden || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    CGFloat topOffset = CGRectGetMaxY(self.headerView.frame);
    if (IS_IOS11) {
        topOffset = CGRectGetHeight(self.headerView.frame);
        toolbarShown = NO;
    }

    UIScrollView* webScrollView = [EpisodeViewController sharedWebView].scrollView;
    webScrollView.contentInset = UIEdgeInsetsMake(topOffset, 0, (toolbarShown)?44:0, 0);
    webScrollView.scrollIndicatorInsets = UIEdgeInsetsMake(topOffset, 0, (toolbarShown)?44:0, 0);
}

- (void) _updateTimeDisplay
{
    CDEpisode* episode = self.episode;
    
	self.consumeIndicator.consumed = episode.consumed;
	self.consumeIndicator.progress = (episode.duration > 0) ? (double)episode.position / (double)episode.duration : 0;
    self.consumeIndicator.tintColor = (episode.consumed) ? ICMutedTextColor : self.view.tintColor;
    
    self.starredIndicator.hidden = !episode.starred;
    
    BOOL consumed = episode.consumed;

	
	NSInteger duration = episode.duration-episode.position;
	NSString* formattedDuration = nil;
	if (duration > 1) {
        NSValueTransformer* durationTransformer = [NSValueTransformer valueTransformerForName:kICDurationValueTransformer];
        formattedDuration = [durationTransformer transformedValue:@(duration)];
	}
	
	NSDate* pubDate = episode.pubDate;
	NSDate* today = [NSDate date];
	NSDate* yesterday = [today dateByAddingTimeInterval:-86400];
	
	unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
	NSDateComponents* pubDateComponents = [[NSCalendar currentCalendar] components:unitFlags fromDate:pubDate];
	NSDateComponents* todayComponents = [[NSCalendar currentCalendar] components:unitFlags fromDate:today];
	NSDateComponents* yesterdayComponents = [[NSCalendar currentCalendar] components:unitFlags fromDate:yesterday];
	
	NSString* dateString = nil;
	NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:pubDate];
	if ([pubDateComponents year] == [todayComponents year] && [pubDateComponents month] == [todayComponents month] && [pubDateComponents day] == [todayComponents day]) {
		dateString = @"Today".ls;
	}
	else if ([pubDateComponents year] == [yesterdayComponents year] && [pubDateComponents month] == [yesterdayComponents month] && [pubDateComponents day] == [yesterdayComponents day]) {
		dateString = @"Yesterday".ls;
	}
	else if (timeInterval < 86400*7) {
		NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"EEEE"];
		dateString = [dateFormatter stringFromDate:pubDate];
	}
	else {
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[formatter setDateStyle:NSDateFormatterShortStyle];
		[formatter setTimeStyle:NSDateFormatterNoStyle];
		dateString = [formatter stringForObjectValue:pubDate];
	}
    
    
    self.timeLabel.text = (!consumed && formattedDuration) ? [NSString stringWithFormat:@"%@ %@", dateString, formattedDuration] : dateString;
    CGSize timeSize = [[self.timeLabel attributedText] boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.view.bounds)-72-45, 100) options:NSStringDrawingUsesLineFragmentOrigin context:NULL].size;
    IC_SIZE_INTEGRAL(timeSize);
    CGRect timeLabelFrame = CGRectMake(31, MAX(10+72-timeSize.height, CGRectGetMaxY(self.feedTitleLabel.frame)), timeSize.width, timeSize.height);
    self.timeLabel.frame = timeLabelFrame;
    
    self.consumeIndicator.frame = CGRectMake(15, CGRectGetMinY(timeLabelFrame)+1, 10, 10);
    self.videoIndicator.frame = CGRectMake(CGRectGetMaxX(timeLabelFrame)+5, CGRectGetMinY(timeLabelFrame)+2, 10, 9);
}

- (void) _updateToolbarAnimated:(BOOL)animated
{
    UIBarButtonItem* flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    
    EpisodePlayComboButton* playButton = [EpisodePlayComboButton buttonWithType:UIButtonTypeCustom];
    playButton.frame = CGRectMake(0, 0, 44, 44);
    playButton.contentMode = UIViewContentModeRedraw;
    [playButton addTarget:self action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
    self.playButton = playButton;
    
    [self updatePlayComboButtonState];
    
    UIBarButtonItem* playItem = [[UIBarButtonItem alloc] initWithCustomView:self.playButton];
    playItem.enabled = ([self.episode preferedMedium] != nil);
    
    UIBarButtonItem* downloadItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Toolbar Download"]
                                                                     style:UIBarButtonItemStylePlain target:self action:@selector(downloadAction:)];
    downloadItem.enabled = ([self.episode preferedMedium] != nil);
    
    UIBarButtonItem* shareItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Toolbar Share"]
                                                                     style:UIBarButtonItemStylePlain target:self action:@selector(shareAction:)];
    
    UIBarButtonItem* moreItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Toolbar More"]
                                                                     style:UIBarButtonItemStylePlain target:self action:@selector(moreAction:)];
    
    UIBarButtonItem* negativeSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    negativeSpaceItem.width = -12;
    
    [self willChangeValueForKey:@"toolbarItems"];
    [self setToolbarItems:@[ negativeSpaceItem, playItem, flexSpace, downloadItem, flexSpace, shareItem, flexSpace, moreItem ] animated:animated];
    [self didChangeValueForKey:@"toolbarItems"];

}


- (void) updatePlayComboButtonState
{
    CacheManager* cman = [CacheManager sharedCacheManager];
    CDEpisode* episode = self.episode;
    
    BOOL cached = [cman episodeIsCached:episode fastLookup:YES];
    BOOL caching = [cman isCachingEpisode:episode];
    
    if (cached) {
        self.playButton.comboState = kEpisodePlayButtonComboStateFilled;
    }
    else if (caching) {
        self.playButton.comboState = kEpisodePlayButtonComboStateFilling;
    }
    else {
        self.playButton.comboState = kEpisodePlayButtonComboStateOutline;
    }
    
    self.playButton.fillingProgress = [cman cacheProgressForEpisode:episode];
}

- (void) _setObserving:(BOOL)observing
{
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    
    if (observing && !_observing)
    {
        [nc addObserver:self selector:@selector(playbackManagerDidEndNotification:) name:PlaybackManagerDidEndNotification object:nil];
        [nc addObserver:self selector:@selector(playbackManagerDidChangeEpisodeNotification:) name:PlaybackManagerDidChangeEpisodeNotification object:nil];
        [nc addObserver:self selector:@selector(cacheManagerDidStartCachingEpisodeNotification:) name:CacheManagerDidStartCachingEpisodeNotification object:nil];
        [nc addObserver:self selector:@selector(cacheManagerDidUpdateNotification:) name:CacheManagerDidUpdateNotification object:nil];
        [nc addObserver:self selector:@selector(cacheManagerDidFinishCachingEpisodeNotification:) name:CacheManagerDidFinishCachingEpisodeNotification object:nil];
        
        [App addTaskObserver:self forKeyPath:@"networkAccessTechnology" task:^(id obj, NSDictionary *change) {
            [self _updateTimeDisplay];
        }];

    }
    else if (!observing && _observing)
    {
        [nc removeObserver:self];
        [App removeTaskObserver:self forKeyPath:@"networkAccessTechnology"];
    }
    
    _observing = observing;
}

- (void) playbackManagerDidEndNotification:(NSNotification*)notification
{
    [self _updateTimeDisplay];
}

- (void) playbackManagerDidChangeEpisodeNotification:(NSNotification*)notification
{
    [self _updateTimeDisplay];
}

- (void) cacheManagerDidStartCachingEpisodeNotification:(NSNotification*)notification
{
    [self updatePlayComboButtonState];
}

- (void) cacheManagerDidUpdateNotification:(NSNotification*)notification
{
    [self updatePlayComboButtonState];
}

- (void) cacheManagerDidFinishCachingEpisodeNotification:(NSNotification*)notification
{
    [self updatePlayComboButtonState];
    [self _updateTimeDisplay];
}

- (void) setEpisode:(CDEpisode *)episode
{
    if (_episode != episode)
    {
        [_episode removeTaskObserver:self forKeyPath:@"position"];
        [_episode removeTaskObserver:self forKeyPath:@"consumed"];
        [_episode removeTaskObserver:self forKeyPath:@"starred"];
        
        _episode = episode;
        
        if (!episode) {
            return;
        }
        
        __weak EpisodeViewController* weakSelf = self;
        [episode addTaskObserver:self forKeyPath:@"position" task:^(id obj, NSDictionary *change) {
            [weakSelf _updateTimeDisplay];
        }];
        
        [episode addTaskObserver:self forKeyPath:@"consumed" task:^(id obj, NSDictionary *change) {
            [weakSelf _updateTimeDisplay];
        }];
        
        [episode addTaskObserver:self forKeyPath:@"starred" task:^(id obj, NSDictionary *change) {
            [weakSelf _updateTimeDisplay];
        }];
    }
}


#pragma mark -
#pragma mark WebView Delegate

- (void) _startPlaybackAtTime:(double)time
{
    AudioSession* audioSession = [AudioSession sharedAudioSession];
    PlaybackManager* pman = [PlaybackManager playbackManager];
    if ([audioSession.episode isEqual:self.episode] && pman.ready)
    {
        [pman seekToTime:time];
        
        UINavigationController* navController = self.navigationController;
        if ([navController isKindOfClass:[PlaybackViewController class]]) {
            [navController popViewControllerAnimated:YES];
        }
        else {
            PlaybackViewController* playbackController = [PlaybackViewController playbackViewController];
            [playbackController presentFromParentViewController:self];
        }
    }
    else
    {
        [DMANAGER setEpisode:self.episode position:time];
        
        UINavigationController* navController = self.navigationController;
        if ([navController isKindOfClass:[PlaybackViewController class]]) {
            [navController popViewControllerAnimated:YES];
        }
        else {
            PlaybackViewController* playbackController = [PlaybackViewController playbackViewControllerWithEpisode:self.episode];
            [playbackController presentFromParentViewController:self];
        }
    }
}



- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSURL *url = request.URL;
	NSString *urlString = url.absoluteString;
	
	if ([[url scheme] isEqualToString:@"delegate"])
	{
		NSString* command = [url host];
        
        if ([command isEqualToString:@"play-chapter-timecode"])
        {
            NSString* timecodeString = [[url path] lastPathComponent];
            NSScanner* scanner = [[NSScanner alloc] initWithString:timecodeString];
            
            NSInteger hour = 0;
            [scanner scanInteger:&hour];
            
            [scanner scanString:@":" intoString:NULL];
            
            NSInteger minute = 0;
            [scanner scanInteger:&minute];
            
            [scanner scanString:@":" intoString:NULL];
            
            NSInteger second = 0;
            [scanner scanInteger:&second];
            
            double time = hour*3600.0 + minute*60.0 + second;
            [self _startPlaybackAtTime:time];
        }

		return YES;
	}
	
	// do not allow iframes
	if (navigationType == UIWebViewNavigationTypeOther && ![urlString isEqualToString:@"about:blank"]) {
		return NO;
	}
	
    _dontReleaseSharedContent = YES;
    return [self handleShowNotesURL:url];
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{
    if ([[[aWebView request].URL absoluteString] isEqualToString:@"about:blank"]) {
        [self _loadWebContent];
    }

    if (self.didFinishLoading) {
        self.didFinishLoading();
    }
}

- (void) scrollViewDidScroll:(UIScrollView*)scrollView
{
    if (!_dontSaveScrollOffset) {
        _scrollOffset = scrollView.contentOffset;
    }
}

#pragma mark -

- (void) playAction:(id)sender
{
    CacheManager* cman = [CacheManager sharedCacheManager];
    if ([cman isCachingEpisode:self.episode]) {
        [cman cancelCachingEpisode:self.episode disableAutoDownload:YES];
        return;
    }
    
    if ([self.episode preferedMedium])
    {
        PlaybackViewController* playbackController = [PlaybackViewController playbackViewControllerWithEpisode:self.episode forceReload:YES];
        [playbackController presentFromParentViewController:self];
    }
}

- (void) openURLAction:(id)sender
{
    NSURL* linkURL = self.episode.linkURL;
    NSURL* deeplinkURL = self.episode.deeplinkURL;
    NSURL* link = (deeplinkURL) ? deeplinkURL : linkURL;
    
	if (link) {
        [self handleShowNotesURL:link];
	}
}

- (void) _downloadFile
{
    CacheManager* cman = [CacheManager sharedCacheManager];
    
    BOOL enabled3G = [USER_DEFAULTS boolForKey:EnableCachingOver3G];
    ICNetworkAccessTechnlogy networkAccessTechnology = App.networkAccessTechnology;
    if (!enabled3G && networkAccessTechnology < kICNetworkAccessTechnlogyWIFI)
    {
        WEAK_SELF
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Downloading over cellular has been disabled in 'General' settings.".ls
                                                                       message:@"Do you still want to download the content of this episode right now?".ls
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Download".ls
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    STRONG_SELF
                                                    [self perform:^(id sender) {
                                                        [cman cacheEpisode:self.episode overwriteCellularLock:YES];
                                                    } afterDelay:0.3];
                                                    self.alertController = nil;
                                                }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel".ls
                                                  style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction * action) {
                                                    STRONG_SELF
                                                    self.alertController = nil;
                                                }]];
        
        self.alertController = alert;
        [self presentAlertControllerAnimated:YES completion:NULL];
    }
    else {
        [cman cacheEpisode:self.episode];
    }
}

- (void) downloadAction:(id)sender
{
    CacheManager* cman = [CacheManager sharedCacheManager];
    PlaybackManager* pman = [PlaybackManager playbackManager];
    
    WEAK_SELF
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (![cman episodeIsCached:self.episode])
    {
        NSString* addTitle = @"Download".ls;
        if ([self.episode preferedMedium].byteSize > 0LL) {
            unsigned long long bytes = [self.episode preferedMedium].byteSize - [cman numberOfDownloadedBytesForEpisode:self.episode];
            NSString* sizeString = [NSByteCountFormatter stringFromByteCount:bytes countStyle:NSByteCountFormatterCountStyleMemory];
            addTitle = [NSString stringWithFormat:@"%@ (%@)", @"Download".ls, sizeString];
        }

        [alert addAction:[UIAlertAction actionWithTitle:addTitle
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    STRONG_SELF
                                                    [self perform:^(id sender) {
                                                        
                                                        [self _downloadFile];
                                                        
                                                    } afterDelay:0.3];
                                                    self.alertController = nil;
                                                }]];
    }
    else
    {
        NSString* redownloadTitle = @"Re-Download".ls;
        unsigned long long bytes = [self.episode preferedMedium].byteSize;
        if (bytes > 0LL) {
            NSString* sizeString = [NSByteCountFormatter stringFromByteCount:bytes countStyle:NSByteCountFormatterCountStyleMemory];
            redownloadTitle = [NSString stringWithFormat:@"%@ (%@)", @"Re-Download".ls, sizeString];
        }
        
        [alert addAction:[UIAlertAction actionWithTitle:redownloadTitle
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    STRONG_SELF
                                                    [self perform:^(id sender) {
                                                        
                                                        if ([pman.playingEpisode isEqual:self.episode]) {
                                                            [[AudioSession sharedAudioSession] stop];
                                                        }
                                                        
                                                        [[CacheManager sharedCacheManager] removeCacheForEpisode:self.episode automatic:NO];
                                                        [self _updateTimeDisplay];
                                                        [self updatePlayComboButtonState];
                                                        [self _downloadFile];
                                                        
                                                    } afterDelay:0.3];
                                                    self.alertController = nil;
                                                }]];

        [alert addAction:[UIAlertAction actionWithTitle:@"Delete File".ls
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction * action) {
                                                    STRONG_SELF
                                                    [self perform:^(id sender) {
                                                        
                                                        [[CacheManager sharedCacheManager] removeCacheForEpisode:self.episode automatic:NO];
                                                        [self _updateTimeDisplay];
                                                        [self updatePlayComboButtonState];
                                                        
                                                    } afterDelay:0.3];
                                                    self.alertController = nil;
                                                }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel".ls
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                self.alertController = nil;
                                            }]];
    
    self.alertController = alert;
    [self presentAlertControllerAnimated:YES completion:NULL];
}


- (void) shareAction:(id)sender
{
    UIBarButtonItem* barButton = sender;
    
    NSURL* linkURL = self.episode.linkURL;
    NSURL* deeplinkURL = self.episode.deeplinkURL;
    NSURL* link = (deeplinkURL) ? deeplinkURL : linkURL;
    
    UIActivityViewController* shareController = [[UIActivityViewController alloc] initWithActivityItems:@[link] applicationActivities:nil];
    if ([shareController respondsToSelector:@selector(popoverPresentationController)]) {
        shareController.popoverPresentationController.barButtonItem = barButton;
    }
    [self presentViewController:shareController animated:YES completion:NULL];
}

- (void) moreAction:(id)sender
{
    WEAK_SELF
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:(self.episode.consumed)?@"Mark as Unplayed".ls:@"Mark as Played".ls
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                [self perform:^(id sender) {
                                                    
                                                    BOOL flag = !self.episode.consumed;
                                                    [DMANAGER markEpisode:self.episode asConsumed:flag];
                                                    
                                                    PlaySoundFile((flag)?@"AffirmOut":@"AffirmIn", NO);
                                                    
                                                    // stop playback of episode
                                                    if (self.episode.consumed && [self.episode isEqual:[AudioSession sharedAudioSession].episode]) {
                                                        [[AudioSession sharedAudioSession] stop];
                                                        [self.navigationItem setRightBarButtonItem:nil animated:YES];
                                                    }
                                                    
                                                    [self _updateTimeDisplay];
                                                    [self updatePlayComboButtonState];

                                                    
                                                } afterDelay:0.3];
                                                self.alertController = nil;
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:(self.episode.starred)?@"Unmark Favorite".ls:@"Mark as Favorite".ls
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                [self perform:^(id sender) {
                                                    
                                                    BOOL flag = !self.episode.starred;
                                                    [DMANAGER markEpisode:self.episode asStarred:flag];
                                                    
                                                    PlaySoundFile((flag)?@"AffirmIn":@"AffirmOut", NO);
                                                    
                                                    [self _updateTimeDisplay];
                                                    [self updatePlayComboButtonState];

                                                    
                                                } afterDelay:0.3];
                                                self.alertController = nil;
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel".ls
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                self.alertController = nil;
                                            }]];
    
    self.alertController = alert;
    [self presentAlertControllerAnimated:YES completion:NULL];
}
@end
