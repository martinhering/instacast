//
//  InstacastAppDelegate.m
//  Instacast
//
//  Created by Martin Hering on 22.12.10.
//  Copyright 2010 Vemedio. All rights reserved.
//


#import <Accounts/Accounts.h>

#import "ICManagedObjectContext.h"

#import "Test.h"
#import "InstacastAppDelegate.h"
#import "UIManager.h"
#import "CDEpisode+ShowNotes.h"

#import "DirectoryFeedViewController.h"

#import "VDModalInfo.h"
#import "ICFeedParser.h"
#import "JCommand.h"
#import "SubscriptionManager.h"
#import "UtilityFunctions.h"
#import "FeedEpisodeExtraction.h"
#import "XPFF.h"
#import "BookmarksTableViewController.h"
#import "CDModel.h"

#import "MainViewController_4.h"
#import "SubscriptionsTableViewController.h"
#import "PlaybackViewController.h"
#import "PlayerController.h"
#import "PortraitNavigationController.h"
#import "ICDurationValueTransformer.h"
#import "ICPubdateValueTransformer.h"


@interface InstacastAppDelegate ()
@property BOOL resettingContext;
@property (strong) VDModalInfo* mInfo;
@property (strong) VDModalInfo* loadingInfo;
@property (nonatomic, strong) DirectoryFeedViewController* feedView;
@end


@implementation InstacastAppDelegate {
    struct {
        unsigned int apnRegisterSuccess:1;
    } _flags;
}

+ (void) initialize
{
	NSString* defaultsPlist = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
	NSMutableDictionary* defaults = [[NSDictionary dictionaryWithContentsOfFile:defaultsPlist] mutableCopy];
	
//#warning AutoCacheNewAudioEpisodes disabled
//    [defaults setObject:@(NO) forKey:AutoCacheNewAudioEpisodes];
    
    
	NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
	[defs registerDefaults:defaults];
	
	if (![defs objectForKey:FirstLaunchDate]) {
		[defs setObject:[NSDate date] forKey:FirstLaunchDate];
        [USER_DEFAULTS setDouble:[[NSDate date] timeIntervalSince1970] forKey:LastRefreshSubscriptionDate];
	}
    
    ICAppearanceManager* aman = [ICAppearanceManager sharedManager];
    [aman updateAppearance];
    if (aman.switchesNightModeAutomatically) {
        if (![aman updateLocation]) {
            aman.switchesNightModeAutomatically = NO;
        }
    }
    
    [NSValueTransformer setValueTransformer:[[ICDurationValueTransformer alloc] init] forName:kICDurationValueTransformer];
    [NSValueTransformer setValueTransformer:[[ICPubdateValueTransformer alloc] init] forName:kICPubdateValueTransformer];
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}




#pragma mark -
#pragma mark Application lifecycle


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    [App setMinimumBackgroundFetchInterval:900];
    [App setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
	self.window.backgroundColor = ICBackgroundColor;
    //self.window.frame = CGRectMake(0, 0, 320, 568);    
    
    //DebugLog(@"%@ %@", NSStringFromCGRect(self.window.frame), NSStringFromCGRect([[UIScreen mainScreen] bounds]));
    

    [App initializeLoggers];
    
    
    if ([DatabaseManager dataStoreNeedsMigration]) {
        DebugLog(@"migration needed!");
        UIViewController* migrationViewController = [[UIViewController alloc] initWithNibName:@"DataMigrationView" bundle:nil];
        self.window.rootViewController = migrationViewController;
        
        [self performSelector:@selector(_startUpApplicationWithLaunchOptions:) withObject:launchOptions afterDelay:0.1];
    }
    else {
        [self _startUpApplicationWithLaunchOptions:launchOptions];
    }
    
    UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert
                                                                             categories:nil];
    [application registerUserNotificationSettings:settings];
    
    DebugLog(@"launchOptions %@", launchOptions);
    
    return YES;
}

- (void) _startUpApplicationWithLaunchOptions:(NSDictionary *)launchOptions
{
    MainViewController_4* mainViewController = [MainViewController_4 mainViewController];
    self.mainViewController = mainViewController;
    [UIManager sharedManager].mainViewController = mainViewController;
    
    self.window.rootViewController = self.mainViewController;
    
    [self.window makeKeyAndVisible];
    
    
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey]) {
        UILocalNotification* notification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
        [self application:App didReceiveLocalNotification:notification];
        DebugLog(@"received local notification at launch");
    }
    
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
        NSDictionary* notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        [self application:App didReceiveRemoteNotification:notification fetchCompletionHandler:^(UIBackgroundFetchResult result) {
            DebugLog(@"received remote notification at launch");
        }];
    }
    
    [self _updateAppContentAfterBecomingActive];
}



#pragma mark -


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{    
    NSSet* subscribeSchemes = [NSSet setWithObjects:@"pcast", @"itpc", @"podcast", @"podcast-subscribe", @"instacast-subscribe", @"instacast", nil];
    
	if ([subscribeSchemes containsObject:[url scheme]]) {
		[self _handlePcastURL:url];
	}
	else if ([url isFileURL] && [[[url path] pathExtension] compare:@"opml" options:NSCaseInsensitiveSearch] == NSOrderedSame)
	{
        self.mInfo = [VDModalInfo modalInfoWithProgressLabel:@"Importing…".ls];
        [self.mInfo show];
        
        NSData* opmlData = [NSData dataWithContentsOfURL:url];
		[[SubscriptionManager sharedSubscriptionManager] importOPMLData:opmlData completion:^{
            [self.mInfo close];
            self.mInfo = nil;
        }];
	}
    
    else if ([url isFileURL] && [[[url path] pathExtension] compare:@"xpff" options:NSCaseInsensitiveSearch] == NSOrderedSame)
	{
        NSString* filename = [[url path] lastPathComponent];
        
        WEAK_SELF
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Import Bookmarks".ls
                                                                       message:[NSString stringWithFormat:@"Do you want to import bookmarks from '%@'?".ls, filename]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Import".ls
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    STRONG_SELF
                                                    [self perform:^(id sender) {

                                                        NSData* xpffData = [NSData dataWithContentsOfURL:url];
                                                        
                                                        XPFFImportData(xpffData, ^(NSArray *bookmarks, NSError *error) {
                                                            
                                                            for(CDBookmark* bookmark in bookmarks) {
                                                                [DMANAGER addBookmark:bookmark];
                                                            }
                                                            
                                                            [DMANAGER save];
                                                            
                                                            BookmarksTableViewController* bookmarksController = (BookmarksTableViewController*)((MainViewController_4*)self.mainViewController).contentViewController;
                                                            if ([bookmarksController isKindOfClass:[BookmarksTableViewController class]]) {
                                                                [bookmarksController reload];
                                                            }
                                                        });
                                                        
                                                    } afterDelay:0.3];
                                                    self.mainViewController.alertController = nil;
                                                }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel".ls
                                                  style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction * action) {
                                                    STRONG_SELF
                                                    self.mainViewController.alertController = nil;
                                                }]];
        
        self.mainViewController.alertController = alert;
        [self.mainViewController presentAlertControllerAnimated:YES completion:NULL];
	}
	return YES;
}

- (void) _updateAppContentAfterBecomingActive
{
    //DebugLog(@"applicationDidBecomeActive, state: %d", App.applicationState);
	App.idleTimerDisabled = [USER_DEFAULTS boolForKey:DisableAutoLock];
    
    if (_flags.apnRegisterSuccess == 0)
    {
        // iOS 8 remote notifications always work!
        if ([App respondsToSelector:@selector(registerForRemoteNotifications)]) {
            [App registerForRemoteNotifications];
        }
        
        if (![App isRegisteredForRemoteNotifications]) {
            _flags.apnRegisterSuccess = 0;
        }    
    }
    
    [[ICAppearanceManager sharedManager] switchNightModeAutomaticallyNow];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self _updateAppContentAfterBecomingActive];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	//DebugLog(@"applicationWillResignActive, state: %d", App.applicationState);
	App.applicationIconBadgeNumber = ([USER_DEFAULTS boolForKey:ShowApplicationBadgeForUnseen]) ? DMANAGER.unplayedList.numberOfEpisodes : 0;
	
	if (!self.mainViewController.presentedViewController) {
		[[CacheManager sharedCacheManager] tidyUp];
	}
    
    [DMANAGER saveAndSync:NO];
}

- (void) setNeedsStatusBarAppearanceUpdate {
    [self.mainViewController setNeedsStatusBarAppearanceUpdate];
}
#pragma mark -
#pragma mark Push Notifications

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    DebugLog(@"didRegisterUserNotificationSettings %@", notificationSettings);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DidRegisterUserNotificationSettings" object:self];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    _flags.apnRegisterSuccess = 1;
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    ErrLog(@"register for remote notifications failed: %@", error);
    _flags.apnRegisterSuccess = 0;
}


- (CDFeed*) _subscribedFeedForNotification:(NSDictionary*)notification
{
    NSDictionary* aps = notification[@"aps"];
    NSString* feedMd5 = notification[@"feed_hash"];
    
    if (!feedMd5) {
        feedMd5 = aps[@"feed_hash"];
    }
    
    //NSString* guidMd5 = [notification objectForKey:@"episode_hash"];
    
    for(CDFeed* feed in DMANAGER.visibleFeeds) {
        if ([[[feed.sourceURL absoluteString] MD5Hash] isEqualToString:feedMd5]) {
            return feed;
        }
    }
    return nil;
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler
{
    DebugLog(@"remote notification: %@", userInfo);
    NSDictionary* notificationContent = userInfo[@"aps"];
    
//    NSDictionary* alert = notificationContent[@"alert"];
//    if (alert && [alert isKindOfClass:[NSDictionary class]])
//    {
//        NSString* body = alert[@"body"];
//        if (body) {
//            [App alertWithTitle:@"Notification".ls message:body];
//        }
//    }
//    
    
    CDFeed* feed = [self _subscribedFeedForNotification:userInfo];
    if (feed)
    {
        NSString* feedEvent = notificationContent[@"feed_event"];
        
        if ([feedEvent isEqualToString:@"reload"])
        {
            [[SubscriptionManager sharedSubscriptionManager] reloadContentOfFeed:feed recoverArchivedEpisodes:NO completion:^(BOOL success, NSArray* newEpisodes, NSError *error) {
                
                if (success) {
                    [self _handleReceivedNewEpisodesAfterRemoteNotification:newEpisodes feed:feed];
                }
                
                UIBackgroundFetchResult result = (success) ? (([newEpisodes count] > 0) ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData) : UIBackgroundFetchResultFailed;
                handler(result);
                
            }];
        }
        else
        {
            [[SubscriptionManager sharedSubscriptionManager] refreshFeeds:@[feed] etagHandling:NO completion:^(BOOL success, NSArray* newEpisodes, NSError* error) {
                
                if (success) {
                    [self _handleReceivedNewEpisodesAfterRemoteNotification:newEpisodes feed:feed];
                }
                
                UIBackgroundFetchResult result = (success) ? (([newEpisodes count] > 0) ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData) : UIBackgroundFetchResultFailed;
                handler(result);
            }];
        }
    }
    else {
        handler(UIBackgroundFetchResultNoData);
    }
}

- (void) _handleReceivedNewEpisodesAfterRemoteNotification:(NSArray*)newEpisodes feed:(CDFeed*)feed
{
    CacheManager* cman = [CacheManager sharedCacheManager];
    if ([newEpisodes count] > 0 && ![cman isCachingFeed:feed])
    {
        for(CDEpisode* episode in newEpisodes)
        {
            if ([episode.feed boolForKey:EnableNewEpisodeNotification] && App.applicationState == UIApplicationStateBackground) {
                UILocalNotification* notification = [[UILocalNotification alloc] init];
                NSString* episodeTitle = [NSString stringWithFormat:@"%@ - %@", episode.feed.title, [episode cleanTitleUsingFeedTitle:episode.feed.title]];
                notification.alertBody = [NSString stringWithFormat:@"'%@' is available to stream.".ls, episodeTitle];
                notification.soundName = @"NewEpisodes";
                notification.userInfo = @{ @"episode_hash" : [episode objectHash]};
                [App presentLocalNotificationNow:notification];
            }
        }
    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    if (!notification) {
        return;
    }
    
    NSString* episodeHash = notification.userInfo[@"episode_hash"];
    
    CDEpisode* episode = [DMANAGER episodeWithObjectHash:episodeHash];
    [self.mainViewController showShowNotesOfEpisode:episode animated:NO];
    
    [application cancelLocalNotification:notification];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)localNotification completionHandler:(void (^)())completionHandler
{    
    if ([identifier isEqualToString:@"play"]) {
        NSString* episodeHash = localNotification.userInfo[@"episode_hash"];
        CDEpisode* episode = [DMANAGER episodeWithObjectHash:episodeHash];
        [[AudioSession sharedAudioSession] playEpisode:episode];
    }
    
    completionHandler();
}

#pragma mark - Background Fetch

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler
{
    [[CacheManager sharedCacheManager] handleEventsForBackgroundURLSession:identifier completionHandler:completionHandler];
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // return immediately if there's no internet
        if (App.networkAccessTechnology < kICNetworkAccessTechnlogyEDGE) {
            DebugLog(@"no network available to fetch in background");
            completionHandler(UIBackgroundFetchResultFailed);
            return;
        }
        
        // 1 abo rauspicken, biggest last update interval
        NSArray* subscriptions = [DMANAGER visibleFeeds];
        NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUpdate" ascending:YES];
        NSArray* sortedSubscriptions = [subscriptions sortedArrayUsingDescriptors:@[ sortDescriptor ]];
        
        NSMutableArray* firstSubscriptions = [[NSMutableArray alloc] init];
        NSInteger i=0;
        
#define MAX_SUBSCRIPTIONS_TO_FETCH 1
        
        for(CDFeed* feed in sortedSubscriptions)
        {
            [firstSubscriptions addObject:feed];
            DebugLog(@"'background fetch %@'", feed.title);
            
            i++;
            if (i>=MAX_SUBSCRIPTIONS_TO_FETCH) {
                break;
            }
        }
        
        
        NSDate* startDate = [NSDate date];
        [[SubscriptionManager sharedSubscriptionManager] refreshFeeds:firstSubscriptions
                                                         etagHandling:YES
                                                           completion:^(BOOL success, NSArray *newEpisodes, NSError* error) {

                                                               ErrLog(@"background fetch interval: %lf sec", [[NSDate date] timeIntervalSinceDate:startDate]);
                                                               
                                                               if (success) {
                                                                   completionHandler(([newEpisodes count] > 0) ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData );
                                                               }
                                                               else {
                                                                   completionHandler(UIBackgroundFetchResultFailed);
                                                               }
                                                           }];
    });
}


#pragma mark -
#pragma mark URL Handling

- (void) _handlePcastURL:(NSURL*)url
{
    NSString* urlString = [[url absoluteString] substringFromIndex:[[url scheme] length]];
    if ([urlString hasPrefix:@":http://"] || [urlString hasPrefix:@":https://"]) {
        NSString* newURLString = [urlString substringFromIndex:1];
        url = [NSURL URLWithString:newURLString];
    }
    
    // convert to http url
	if (![[url scheme] isEqualToString:@"http"] && ![[url scheme] isEqualToString:@"https"]) {
		NSString* scheme = [url scheme];
		NSString* urlString = [url absoluteString];
		urlString = [urlString stringByReplacingCharactersInRange:NSMakeRange(0, [scheme length]) withString:@"http"];
		url = [NSURL URLWithString:urlString];
	}
    
    __weak InstacastAppDelegate* weakSelf = self;
    self.feedView = [DirectoryFeedViewController directoryFeedViewController];
    self.feedView.feedURL = url;
    self.feedView.canBeCanceled = YES;
    self.feedView.didLoadFeed = ^(BOOL success, NSError* error) {
        STRONG_SELF
        if (!success)
        {
            [weakSelf perform:^(id sender) {
                
                if (error) {
                    [self.feedView presentError:error];
                }
                
                [self.mainViewController dismissViewControllerAnimated:YES completion:^{
                    self.feedView = nil;
                }];
            } afterDelay:0.5];
            return;
        }
        
        else {
            weakSelf.feedView = nil;
        }
    };
    
    PortraitNavigationController* navController = [[PortraitNavigationController alloc] initWithRootViewController:weakSelf.feedView];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    if (self.mainViewController.presentedViewController) {
        [self.mainViewController.presentedViewController presentViewController:navController animated:YES completion:NULL];
    } else {
        [self.mainViewController presentViewController:navController animated:YES completion:NULL];
    }
    
    [self.feedView startLoading];
}

- (void) _playEpisode:(CDEpisode*)episode atPosition:(NSTimeInterval)position
{
    episode.position = position;
    PlaybackViewController* playbackController = [PlaybackViewController playbackViewControllerWithEpisode:episode forceReload:YES];
    [playbackController presentFromParentViewController:self.mainViewController];
}


@end
