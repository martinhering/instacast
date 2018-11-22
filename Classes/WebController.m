    //
//  WebController.m
//  Instacast
//
//  Created by Martin Hering on 13.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import "WebController.h"
#import "UtilityFunctions.h"
#import "UIViewController+ShowNotes.h"
#import "ICListTitleView.h"
#import "OpenInSafariActivity.h"

@interface WebController ()
@property (nonatomic, readwrite, strong) UIWebView* webView;
@property (nonatomic, strong) UIBarButtonItem* actionItem;
@property (nonatomic, strong) UIBarButtonItem* reloadItem;
@property (nonatomic, strong) UIBarButtonItem* backItem;
@property (nonatomic, strong) UIBarButtonItem* forwardItem;
@property (nonatomic, strong) UIBarButtonItem* activityItem;
@property (nonatomic, assign) BOOL canceled;
@property (nonatomic, assign) BOOL failed;
@property (nonatomic, assign) BOOL closed;
@property (nonatomic, strong) ICListTitleView* titleView;
@end

@implementation WebController {
    NSInteger _loading;
    BOOL _toolbarWasHidden;
}

+ (WebController*) webController
{
	WebController* controller = [[self alloc] initWithNibName:nil bundle:nil];
    controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    return controller;
}

- (void)dealloc {
	_webView.delegate = nil;
}


- (BOOL) _canDisplayTwoTitles:(UIInterfaceOrientation)orientation
{
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad || UIInterfaceOrientationIsPortrait(orientation));
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.view.backgroundColor = ICBackgroundColor;
    
	self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	self.webView.delegate = self;
	self.webView.scalesPageToFit = YES;
    self.webView.backgroundColor = ICBackgroundColor;
    self.webView.scrollView.backgroundColor = ICBackgroundColor;

    for(UIView* subview in self.webView.scrollView.subviews) {
        subview.backgroundColor = ICBackgroundColor;
    }
    
	[self.view addSubview:self.webView];
	
	NSURLRequest* request = [NSURLRequest requestWithURL:self.url];
	[self.webView loadRequest:request];
	
	UIBarButtonItem* flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    CGRect b = self.view.bounds;
    
    self.titleView = [[ICListTitleView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(b)-88, 44)];

    
    // action item
    self.actionItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Toolbar Share"]
                                                       style:UIBarButtonItemStylePlain target:self action:@selector(actionAction:)];
    
    self.backItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Toolbar Previous"]
                                                     style:UIBarButtonItemStylePlain target:self action:@selector(backAction:)];

    self.forwardItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Toolbar Next"]
                                                        style:UIBarButtonItemStylePlain target:self action:@selector(forwardAction:)];
    
    self.reloadItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Toolbar Reload"]
                                                       style:UIBarButtonItemStylePlain target:self action:@selector(reloadAction:)];
    self.reloadItem.width = 44;
    
    self.navigationItem.titleView = self.titleView;
    
    
    UIActivityIndicatorView* activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0,0,44,44)];
    activityIndicator.activityIndicatorViewStyle = [ICAppearanceManager sharedManager].appearance.activityIndicatorStyle;
    [activityIndicator startAnimating];
    self.activityItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    self.activityItem.width = 44;
    
    [self setToolbarItems:[NSArray arrayWithObjects:self.backItem, flexSpace, self.forwardItem, flexSpace, self.activityItem, flexSpace, self.actionItem, nil]];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setScrollView:self.webView.scrollView contentInsets:UIEdgeInsetsZero byAdjustingForStandardBars:YES];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _toolbarWasHidden = self.navigationController.toolbarHidden;
    [self.navigationController setToolbarHidden:NO animated:YES];
}


- (void) viewWillDisappear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:_toolbarWasHidden animated:YES];
    
	self.canceled = YES;
	[super viewWillDisappear:animated];
	[self.webView stopLoading];
    
    if (_loading != 0) {
        [App releaseNetworkActivity];
        _loading--;
    }
}

 
#pragma mark - WebView Delegate

- (void) _updateToolbar
{
    BOOL loading = (_loading != 0);
    
	self.backItem.enabled = [self.webView canGoBack];
	self.forwardItem.enabled = [self.webView canGoForward];
	self.reloadItem.enabled = !loading;
	self.actionItem.enabled = (!self.failed);
	
    UIBarButtonItem* flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    if (loading) {
        [(UIActivityIndicatorView*)(self.activityItem.customView) startAnimating];
        [self setToolbarItems:[NSArray arrayWithObjects:self.backItem, flexSpace, self.forwardItem, flexSpace, self.activityItem, flexSpace, self.actionItem, nil]];
    } else {
        [(UIActivityIndicatorView*)(self.activityItem.customView) stopAnimating];
        [self setToolbarItems:[NSArray arrayWithObjects:self.backItem, flexSpace, self.forwardItem, flexSpace, self.reloadItem, flexSpace, self.actionItem, nil]];
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	self.failed = NO;
    
	[App retainNetworkActivity];
    _loading++;
	[self _updateToolbar];
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{
	NSString* title = [aWebView stringByEvaluatingJavaScriptFromString:@"document.title"];
	self.navigationItem.title = title;
    self.titleView.textLabel.text = title;
    
    NSString* href = [aWebView stringByEvaluatingJavaScriptFromString:@"document.location.href"];
    self.titleView.detailTextLabel.text = href;
	
	[App releaseNetworkActivity];
    _loading--;
    [self _updateToolbar];
}

#define WebKitErrorCannotShowURL 101
#define WebKitErrorFrameLoadInterruptedByPolicyChange 102

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [App releaseNetworkActivity];
    _loading--;
    
	if ([error code] == kCFURLErrorCancelled) {
		return;
	}
    
    if ([error code] == WebKitErrorCannotShowURL && [App canOpenURL:self.url]) {
        [App openURL:self.url];
        self.canceled = YES;
        [self performSelector:@selector(popAfterDelay) withObject:nil afterDelay:0.5];
        self.closed = YES;
        return;
    }
    
    ErrLog(@"error loading page %@", error);
	
    if (!self.canceled && [error code] != 204 && [error code] != WebKitErrorCannotShowURL && [error code] != WebKitErrorFrameLoadInterruptedByPolicyChange)
    {
        [self presentAlertControllerWithTitle:@"Loading website failed.".ls
                                      message:@"Either the server is not available or you may not have an internet connection.".ls
                                       button:@"OK".ls
                                     animated:YES
                                   completion:NULL];
    }
    
    self.failed = YES;
    [self _updateToolbar];
    [self performSelector:@selector(popAfterDelay) withObject:nil afterDelay:0.5];
    self.closed = YES;
}

- (void) popAfterDelay
{
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Actions


- (void) actionAction:(id)sender
{
    UIActivityViewController* shareController = [[UIActivityViewController alloc] initWithActivityItems:@[self.url] applicationActivities:@[[[OpenInSafariActivity alloc] init]]];
    if ([shareController respondsToSelector:@selector(popoverPresentationController)]) {
        shareController.popoverPresentationController.barButtonItem = sender;
    }
    [self presentViewController:shareController animated:YES completion:NULL];
}


- (void) reloadAction:(id)sender
{
	[self.webView reload];
}

- (void) backAction:(id)sender
{
	[self.webView goBack];
}

- (void) forwardAction:(id)sender
{
	[self.webView goForward];
}

@end
