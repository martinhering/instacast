//
//  MainViewController_4.m
//  Instacast
//
//  Created by Martin Hering on 25.06.13.
//
//


#import "MainViewController_4.h"
#import "MainSidebarController.h"
#import "SubscriptionsTableViewController.h"
#import "OptionsViewController.h"
#import "ICNowPlayingActivityControl.h"
#import "PlaybackViewController.h"
#import "PlaylistsTableViewController.h"

#import "EpisodesTableViewController.h"
#import "DownloadsViewController.h"
#import "BookmarksTableViewController.h"
#import "ICManagedObjectContext.h"
#import "ListEpisodesTableViewController.h"
#import "MainActivityViewController.h"
#import "StatusBarFixingViewController.h"

#import "VDModalInfo.h"

typedef NS_ENUM(NSInteger, MainSidebarItemTags) {
    kMainSidebarItemSubscriptions   = 2,
    kMainSidebarItemLists           = 3,
    kMainSidebarItemBookmarks       = 4,
    kMainSidebarItemSearch          = 5,
    kMainSidebarItemDownloads       = 6,
    kMainSidebarItemUpNext          = 7,
    kMainSidebarItemSettings        = 8,
    kMainSidebarItemUnplayed        = 9,
    kMainSidebarItemImported        = 10,
};

@interface MainViewController_4 () <UINavigationControllerDelegate>
@property (nonatomic, strong, readwrite) UINavigationController* rootNavigationController;
@property (nonatomic, strong, readwrite) MainSidebarController* sidebarController;
@property (nonatomic, strong, readwrite) MainActivityViewController* activityViewController;

@property (nonatomic, readonly) CDEpisodeList* unplayedPlaylist;
@end

@implementation MainViewController_4 {
    BOOL _observing;
    BOOL _laterDidAppear;
    BOOL _didWillAppear;
}



+ (instancetype) mainViewController
{
    return [[self alloc] initWithNibName:nil bundle:nil];
}

- (void) dealloc
{
    [self _setObserving:NO];
}

- (void) _setObserving:(BOOL)observing
{
    if (observing && !_observing)
    {
        WEAK_SELF
        
        [self.activityViewController addTaskObserver:self forKeyPath:@"visible" task:^(id obj, NSDictionary *change) {
            [weakSelf setNeedsContentControllerLayoutUpdateAnimated:YES];
        }];
        
        [self.unplayedPlaylist addTaskObserver:self forKeyPath:@"name" task:^(id obj, NSDictionary *change) {
            MainSidebarItem* sidebarItem = [weakSelf.sidebarController.items.firstObject firstObject];
            sidebarItem.title = self.unplayedPlaylist.name;
        }];
        
        _observing = YES;
    }
    else if (!observing && _observing)
    {
        [self.activityViewController removeTaskObserver:self forKeyPath:@"visible"];
        [self.unplayedPlaylist removeTaskObserver:self forKeyPath:@"name"];
                
        _observing = NO;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    //self.view.tintColor = ICTintColor;
    self.view.backgroundColor = ICDarkBackgroundColor;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    CGRect b = self.view.bounds;
    MainActivityViewController* activityViewController = [MainActivityViewController viewController];
    activityViewController.view.frame = CGRectMake(0, CGRectGetHeight(b), CGRectGetWidth(b), 44);
    activityViewController.view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    self.activityViewController = activityViewController;

    [self.activityViewController.nowPlayingControl addTarget:self action:@selector(playNow:) forControlEvents:UIControlEventTouchUpInside];
    

    self.sidebarController = [[MainSidebarController alloc] initWithStyle:UITableViewStylePlain];
    self.sidebarController.items = @[
                                     @[
                                         [MainSidebarItem itemWithTitle:self.unplayedPlaylist.name
                                                                    tag:kMainSidebarItemUnplayed
                                                                  image:[UIImage imageNamed:@"Menu Unplayed"]
                                                          selectedImage:[UIImage imageNamed:@"Menu Unplayed Filled"]],
                                         
                                      ],
                                      @[
                                         
                                         [MainSidebarItem itemWithTitle:@"Podcasts".ls
                                                                    tag:kMainSidebarItemSubscriptions
                                                                  image:[UIImage imageNamed:@"Menu Subscriptions"]
                                                          selectedImage:[UIImage imageNamed:@"Menu Subscriptions Filled"]],

                                         
                                         [MainSidebarItem itemWithTitle:@"Episodes".ls
                                                                    tag:kMainSidebarItemLists
                                                                  image:[UIImage imageNamed:@"Menu Lists"]
                                                          selectedImage:[UIImage imageNamed:@"Menu Lists"]],
                                         
                                         [MainSidebarItem itemWithTitle:@"Bookmarks".ls
                                                                    tag:kMainSidebarItemBookmarks
                                                                  image:[UIImage imageNamed:@"Menu Bookmarks"]
                                                          selectedImage:[UIImage imageNamed:@"Menu Bookmarks Filled"]],

                                         ],
                                     @[

                                         [MainSidebarItem itemWithTitle:@"Downloads".ls
                                                                    tag:kMainSidebarItemDownloads
                                                                  image:[UIImage imageNamed:@"Menu Downloads"]
                                                          selectedImage:[UIImage imageNamed:@"Menu Downloads Filled"]],

                                         [MainSidebarItem itemWithTitle:@"Settings".ls
                                                                    tag:kMainSidebarItemSettings
                                                                  image:[UIImage imageNamed:@"Menu Settings"]
                                                          selectedImage:[UIImage imageNamed:@"Menu Settings"]],
                                         ]
                                     ];
    
    NSInteger savedMainSidebarItemTag = [USER_DEFAULTS integerForKey:kUIPersistenceMainSidebarItem];
    if (savedMainSidebarItemTag > 0) {
        [self _selectMainSidebarItemWithTag:savedMainSidebarItemTag];
        self.sidebarController.selectedItemTag = savedMainSidebarItemTag;
    }
    else {
        [self _selectMainSidebarItemWithTag:kMainSidebarItemSubscriptions];
        self.sidebarController.selectedItemTag = kMainSidebarItemSubscriptions;
    }
    
    
    __weak MainViewController_4* weakSelf = self;
    self.sidebarController.didSelectItem = ^(MainSidebarItem* item) {
        
        if ([weakSelf _selectMainSidebarItemWithTag:item.tag])
        {
            [USER_DEFAULTS setInteger:item.tag forKey:kUIPersistenceMainSidebarItem];
            [USER_DEFAULTS synchronize];
            [weakSelf setSidebarShown:NO animated:YES];
            
            return YES;
        }
        
        return NO;
    };

    self.sidebarViewController = self.sidebarController;

    [self _setObserving:YES];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _didWillAppear = YES;
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (_didWillAppear) {
        [self setNeedsContentControllerLayoutUpdateAnimated:NO];
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _laterDidAppear = YES;
    _didWillAppear = NO;
    
    [self presentNextViewController];
}


- (void) playNow:(id)sender
{
    PlaybackViewController* playbackController = [PlaybackViewController playbackViewController];
    [playbackController presentFromParentViewController:self autostart:NO completion:^{
        [self setSidebarShown:NO animated:NO];
    }];
}

- (void) showDownloads:(id)sender
{
    DownloadsViewController* downloadsController = [DownloadsViewController downloadsViewController];
    
    downloadsController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Player Close"]
                                                                                            style:UIBarButtonItemStylePlain
                                                                                           target:self
                                                                                           action:@selector(playerCloseButtonAction:)];
    
    PortraitNavigationController* navController = [[PortraitNavigationController alloc] initWithRootViewController:downloadsController];
    navController.toolbarHidden = NO;
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self presentViewController:navController animated:YES completion:^{
    }];
}

- (void) playerCloseButtonAction:(id)sender
{
    DownloadsViewController* downloadsController = [DownloadsViewController downloadsViewController];
    [downloadsController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark -

- (void) setNeedsContentControllerLayoutUpdateAnimated:(BOOL)animated
{
    [super setNeedsContentControllerLayoutUpdateAnimated:animated];
    
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsMake(20, 0, 0, 0);
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = self.view.safeAreaInsets;
    }
    
    CGRect b = self.view.bounds;
    CGRect invisbleRect = CGRectMake(0, CGRectGetHeight(b), CGRectGetWidth(b), 44+safeAreaInsets.bottom);
    CGRect visibleRect = CGRectMake(0, CGRectGetHeight(b)-44-safeAreaInsets.bottom, CGRectGetWidth(b), 44+safeAreaInsets.bottom);
    
    if (self.activityViewController.visible && !self.activityViewController.parentViewController) {
        [self addChildViewController:self.activityViewController];
        [self.view insertSubview:self.activityViewController.view aboveSubview:self.sidebarViewController.view];
        [self.activityViewController didMoveToParentViewController:self];
    }
    else if (!self.activityViewController.visible && self.activityViewController.parentViewController) {
        [self.activityViewController willMoveToParentViewController:nil];
        [self.activityViewController.view removeFromSuperview];
        [self.activityViewController removeFromParentViewController];
    }
    
    if (animated) {
        [UIView animateWithDuration:0.3f animations:^{
            self.activityViewController.view.frame = (!self.activityViewController.visible) ? invisbleRect : visibleRect;
        }];
    }
    else
    {
        self.activityViewController.view.frame = (!self.activityViewController.visible) ? invisbleRect : visibleRect;
    }
}

- (CGRect) rectForContentControllerWhenShown:(BOOL)shown
{
    CGRect rect = [super rectForContentControllerWhenShown:shown];
    
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsMake(20, 0, 0, 0);
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = self.view.safeAreaInsets;
    }
    
    if (self.activityViewController.visible) {
        rect.size.height -= (safeAreaInsets.bottom);
        rect.size.height -= 44;
    }
    
    return rect;
}

- (CDEpisodeList*) unplayedPlaylist
{
    CDEpisodeList* unplayedList = nil;
    
    for(CDEpisodeList* list in DMANAGER.lists)
    {
        if ([list isKindOfClass:[CDEpisodeList class]]) {
            if ([list.icon isEqualToString:@"List Unplayed"]) {
                unplayedList = list;
            }
        }
    }
    
    if (!unplayedList)
    {
        unplayedList = [NSEntityDescription insertNewObjectForEntityForName:@"EpisodeList" inManagedObjectContext:DMANAGER.objectContext];
        unplayedList.name = @"Unplayed".ls;
        unplayedList.icon = @"List Unplayed";
        unplayedList.rank = (int32_t)[DMANAGER.lists count]+1;
        unplayedList.played = NO;
        unplayedList.orderBy = @"pubDate";
        unplayedList.descending = YES;
        unplayedList.groupByPodcast = NO;
        unplayedList.uid = @"default.unplayed";
        [DMANAGER save];
    }
    return unplayedList;
}


- (UIViewController*) _statusBarAdjustingContainerViewControllerForViewController:(UIViewController*)viewController
{
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    BOOL xScreen = (CGRectGetWidth(screenBounds) == 375 && CGRectGetHeight(screenBounds) == 812);
    CGFloat statusbarHeight = (xScreen) ? 44 : 20;
    
    StatusBarFixingViewController* vc = [[StatusBarFixingViewController alloc] initWithNibName:nil bundle:nil];
    vc.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    vc.view.frame = CGRectMake(0, 0, 100, 100);
    viewController.view.frame = CGRectMake(0, statusbarHeight, 100, 100-statusbarHeight);
    [vc addChildViewController:viewController];
    [vc.view addSubview:viewController.view];
    [viewController didMoveToParentViewController:vc];
    return vc;
}

- (BOOL) _selectMainSidebarItemWithTag:(NSInteger)tag
{
    switch (tag) {
        case kMainSidebarItemLists:
        {
            PlaylistsTableViewController* controller = [PlaylistsTableViewController viewController];
            controller.navigationItem.leftBarButtonItem = self.sidebarMenuItem;
            
            PortraitNavigationController* navController = [[PortraitNavigationController alloc] initWithRootViewController:controller];
            navController.view.tintColor = ICTintColor;
            navController.toolbarHidden = NO;
            self.contentViewController = [self _statusBarAdjustingContainerViewControllerForViewController:navController];
            return YES;
        }

        case kMainSidebarItemSettings:
        {
            OptionsViewController* controller = [OptionsViewController optionsViewController];
            controller.navigationItem.leftBarButtonItem = self.sidebarMenuItem;
            
            PortraitNavigationController* navController = [[PortraitNavigationController alloc] initWithRootViewController:controller];
            self.contentViewController = [self _statusBarAdjustingContainerViewControllerForViewController:navController];
            return YES;
        }

        case kMainSidebarItemBookmarks:
        {
            BookmarksTableViewController* controller = [BookmarksTableViewController bookmarksController];
            controller.navigationItem.leftBarButtonItem = self.sidebarMenuItem;
            
            PortraitNavigationController* navController = [[PortraitNavigationController alloc] initWithRootViewController:controller];
            navController.view.tintColor = ICTintColor;
            navController.toolbarHidden = NO;
            self.contentViewController = [self _statusBarAdjustingContainerViewControllerForViewController:navController];
            return YES;
        }
        case kMainSidebarItemUnplayed:
        {
            UIViewController* controller = [ListEpisodesTableViewController viewControllerWithList:[self unplayedPlaylist]];
            controller.navigationItem.leftBarButtonItem = self.sidebarMenuItem;
            
            PortraitNavigationController* navController = [[PortraitNavigationController alloc] initWithRootViewController:controller];
            navController.view.tintColor = ICTintColor;
            navController.toolbarHidden = NO;
            self.contentViewController = [self _statusBarAdjustingContainerViewControllerForViewController:navController];

            return YES;
        }
        case kMainSidebarItemDownloads:
        {
            UIViewController* controller = [DownloadsViewController downloadsViewController];
            controller.navigationItem.leftBarButtonItem = self.sidebarMenuItem;
            
            PortraitNavigationController* navController = [[PortraitNavigationController alloc] initWithRootViewController:controller];
            navController.view.tintColor = ICTintColor;
            navController.toolbarHidden = NO;
            self.contentViewController = [self _statusBarAdjustingContainerViewControllerForViewController:navController];
            
            return YES;
        }

        default:
        case kMainSidebarItemSubscriptions:
        {
            SubscriptionsTableViewController* controller = [SubscriptionsTableViewController subscriptionsController];
            controller.navigationItem.leftBarButtonItem = self.sidebarMenuItem;
            
            PortraitNavigationController* navController = [[PortraitNavigationController alloc] initWithRootViewController:controller];
            navController.view.tintColor = ICTintColor;
            navController.toolbarHidden = NO;
            self.contentViewController = [self _statusBarAdjustingContainerViewControllerForViewController:navController];
            return YES;
        }
    }

    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    }
    
    return UIInterfaceOrientationMaskPortrait;
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [self animateAdditionalSidebarViewsDuringShow:self.sidebarShown];
}


- (void) showShowNotesOfEpisode:(CDEpisode*)episode animated:(BOOL)animated
{
    if (self.presentedViewController)
    {
        [self clearViewControllerPresentationQueue];
        [self dismissViewControllerAnimated:NO completion:NULL];
    }
    
    
    if (self.sidebarController.selectedItemTag != kMainSidebarItemSubscriptions) {
        if ([self _selectMainSidebarItemWithTag:kMainSidebarItemSubscriptions]) {
            self.sidebarController.selectedItemTag = kMainSidebarItemSubscriptions;
        }
    }
    
    [USER_DEFAULTS setObject:episode.uid forKey:kDefaultEpisodesSelectedEpisodeUID];
    

    UIViewController* contentViewController = self.contentViewController;
    UINavigationController* navigationController = [contentViewController.childViewControllers firstObject];
    [navigationController popToRootViewControllerAnimated:NO];
    
    SubscriptionsTableViewController* subscriptionTableViewController = [navigationController.viewControllers firstObject];
    [subscriptionTableViewController showEpisodeListForFeed:episode.feed animated:NO];
}

- (void) playerCloseButtonAction2:(id)sender
{
    [self.presentedViewController dismissViewControllerAnimated:YES completion:^() {
        [self presentNextViewController];
    }];
}


@end
