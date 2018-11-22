//
//  SubscriptionsTableViewController.m
//  Instacast
//
//  Created by Martin Hering on 28.12.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "SubscriptionsTableViewController.h"

#import "SubscriptionManager.h"
#import "SubscriptionTableViewCell.h"
#import "FeedEpisodesTableViewController.h"

#import "STITunesStore.h"
#import "ICFeedURLScraper.h"
#import "AnimatingLabel.h"


#import "OptionsViewController.h"
#import "InstacastAppDelegate.h"
#import "ToolbarLabelsViewController.h"
#import "FeedSettingsViewController.h"
#import "CDModel.h"
#import "PortraitNavigationController.h"
#import "ICRefreshControl.h"
#import "ICSearchBar.h"
#import "ICFTSController.h"
#import "DirectorySearchViewController.h"

@interface SubscriptionsTableViewController () <UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate, UISearchBarDelegate>
@property (nonatomic, strong) ToolbarLabelsViewController* toolbarLabelsViewController;
@property (nonatomic, strong) UIBarButtonItem* labelsItems;
@property (nonatomic, strong) ICSearchBar* searchBar;
@property (nonatomic, strong) NSFetchedResultsController* fetchController;
@end

@implementation SubscriptionsTableViewController {
    struct {
        unsigned int observing:1;
        unsigned int defaultPushed:1;
        unsigned int userAction:1;
    } _flags;
}

#pragma mark -
#pragma mark Initialization

+ (SubscriptionsTableViewController*) subscriptionsController
{
	return [[self alloc] initWithStyle:UITableViewStylePlain];
}

- (void) dealloc
{
    [self _setObserving:NO];
}


- (void) _setObserving:(BOOL)observing
{
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    SubscriptionManager* sman = [SubscriptionManager sharedSubscriptionManager];
    
    if (observing && _flags.observing == 0)
    {
        [nc addObserver:self selector:@selector(subscriptionManagerDidStartRefreshingFeedsNotification:) name:SubscriptionManagerDidStartRefreshingFeedsNotification object:nil];
        
        [nc addObserver:self selector:@selector(subscriptionManagerDidFinishRefreshingFeedsNotification:) name:SubscriptionManagerDidFinishRefreshingFeedsNotification object:nil];
        
        [sman addTaskObserver:self forKeyPath:@"formattedLastRefreshDate" task:^(id obj, NSDictionary *change) {
            ((ICRefreshControl*)self.refreshControl).idleText = [[SubscriptionManager sharedSubscriptionManager] formattedLastRefreshDate];
        }];
        
        [DMANAGER addTaskObserver:self forKeyPath:@"ftsIndexing" task:^(id obj, NSDictionary *change) {
            self.searchBar.showsActivity = DMANAGER.ftsIndexing;
        }];
        
        
        _flags.observing = 1;
    }
    else if (!observing && _flags.observing == 1)
    {
        [nc removeObserver:self];

        [sman removeTaskObserver:self forKeyPath:@"formattedLastRefreshDate"];
        [DMANAGER removeTaskObserver:self forKeyPath:@"ftsIndexing"];

        _flags.observing = 0;
    }
}

- (void) subscriptionManagerDidStartRefreshingFeedsNotification:(NSNotification*)notification
{
    [self.refreshControl beginRefreshing];
}

- (void) subscriptionManagerDidFinishRefreshingFeedsNotification:(NSNotification*)notification
{
    [self.refreshControl endRefreshing];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Podcasts".ls;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
	self.tableView.rowHeight = 57+10;
	self.tableView.separatorInset = UIEdgeInsetsZero;

    
    ICRefreshControl* refreshControl = [[ICRefreshControl alloc] init];
    refreshControl.pulldownText = @"Pull to refresh…".ls;
    refreshControl.refreshText = @"Looking for new episodes…".ls;
    refreshControl.idleText = [[SubscriptionManager sharedSubscriptionManager] formattedLastRefreshDate];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;

    
    ICSearchBar* searchBar = [[ICSearchBar alloc] initWithFrame:CGRectZero];
    searchBar.backgroundImage = [[UIImage alloc] init];
    searchBar.scopeBarBackgroundImage = [[UIImage alloc] init];
    
    searchBar.delegate = self;
    searchBar.placeholder = @"Search".ls;
    searchBar.translucent = YES;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [searchBar sizeToFit];
     
    self.tableView.tableHeaderView = searchBar;
    self.searchBar = searchBar;
    self.searchBar.showsActivity = DMANAGER.ftsIndexing;

    [self setScrollView:self.tableView contentInsets:UIEdgeInsetsMake(0, 0, 0, 0) byAdjustingForStandardBars:YES];
    
    self.toolbarLabelsViewController = [ToolbarLabelsViewController toolbarLabelsViewController];
    
    UILongPressGestureRecognizer* pressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    pressRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:pressRecognizer];
    
    
    self.labelsItems = [[UIBarButtonItem alloc] initWithCustomView:self.toolbarLabelsViewController.view];
    self.labelsItems.width = CGRectGetWidth(self.toolbarLabelsViewController.view.bounds);
    
    
    //[NSFetchedResultsController deleteCacheWithName:@"_subscriptiontableview_feeds_"];
    NSFetchRequest* feedsRequest = [[NSFetchRequest alloc] init];
    feedsRequest.entity = [NSEntityDescription entityForName:@"Feed" inManagedObjectContext:DMANAGER.objectContext];
    feedsRequest.predicate = [NSPredicate predicateWithFormat:@"subscribed == YES && parked == NO"];
    feedsRequest.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"rank" ascending:YES] ];
    
    
    self.fetchController = [[NSFetchedResultsController alloc] initWithFetchRequest:feedsRequest
                                                               managedObjectContext:DMANAGER.objectContext
                                                                 sectionNameKeyPath:nil
                                                                          cacheName:nil];
    self.fetchController.delegate = self;
    [self.fetchController performFetch:nil];
}


- (void) _updateToolbarLabels
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchController sections] firstObject];

    
    if ([self.searchBar.text length] == 0)
    {
        if ([sectionInfo numberOfObjects] == 0) {
            self.toolbarLabelsViewController.mainText = @"No subscription".ls;
        }
        else if ([sectionInfo numberOfObjects] == 1) {
            self.toolbarLabelsViewController.mainText = @"1 subscription".ls;
        }
        else {
            self.toolbarLabelsViewController.mainText = [NSString stringWithFormat:@"%lu %@", (unsigned long)[sectionInfo numberOfObjects], @"Subscriptions".ls];
        }
        
        unsigned long long megaBytes = [[CacheManager sharedCacheManager] numberOfDownloadedBytes];
        if (megaBytes == 0LLU) {
            self.toolbarLabelsViewController.auxiliaryText = nil;
        }
        else {
            self.toolbarLabelsViewController.auxiliaryText = [NSByteCountFormatter stringFromByteCount:megaBytes countStyle:NSByteCountFormatterCountStyleMemory];
        }
    }
    else
    {
        if ([sectionInfo numberOfObjects] == 0) {
            self.toolbarLabelsViewController.mainText = @"No subscription found".ls;
        }
        else if ([sectionInfo numberOfObjects] == 1) {
            self.toolbarLabelsViewController.mainText = @"1 subscription found".ls;
        }
        else {
            self.toolbarLabelsViewController.mainText = [NSString stringWithFormat:@"%d Subscriptions found", (int)[sectionInfo numberOfObjects]];
        }
        
        self.toolbarLabelsViewController.auxiliaryText = nil;
    }
    
    [self.toolbarLabelsViewController layout];
}


- (void) _updateToolbarItemsAnimated:(BOOL)animated
{
    UIBarButtonItem* addItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Toolbar Add"] style:UIBarButtonItemStylePlain target:self action:@selector(addAction:)];
    UIBarButtonItem* sortItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Toolbar Sort"] style:UIBarButtonItemStylePlain target:self action:@selector(sortAction:)];
     
	UIBarButtonItem* flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    [self setToolbarItems:@[addItem, flexSpace, self.labelsItems, flexSpace, sortItem] animated:animated];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tableView.separatorColor = ICTableSeparatorColor;
    self.tableView.backgroundColor = ICBackgroundColor;
    [self.searchBar appearanceDidChange];
    
    NSString* searchTerm = [USER_DEFAULTS objectForKey:kUIPersistenceSubscriptionsSearchTerm];
    if (searchTerm) {
        self.searchBar.text = searchTerm;
        [self _searchTermDidChange];
    }
    

    [self reloadDataAndTable:YES];
    
    if ([SubscriptionManager sharedSubscriptionManager].refreshing && !self.refreshControl.refreshing) {
        [self.refreshControl beginRefreshing];
    }
    else if (![SubscriptionManager sharedSubscriptionManager].refreshing && self.refreshControl.refreshing) {
        [self.refreshControl endRefreshing];
    }
    
    [self _updateToolbarItemsAnimated:YES];
    [self _updateToolbarLabels];
    
    
    NSString* savedFeedUID = [USER_DEFAULTS objectForKey:kUIPersistenceSubscriptionsSelectedFeedUID];
    if (_flags.defaultPushed == 0 && savedFeedUID) {
        __block NSUInteger index = NSNotFound;
        [[self.fetchController fetchedObjects] enumerateObjectsUsingBlock:^(CDFeed* feed, NSUInteger idx, BOOL *stop) {
            if ([feed.uid isEqualToString:savedFeedUID]) {
                index = idx;
                *stop = YES;
            }
        }];
        
        if (index != NSNotFound) {
            [self _pushControllerForFeedAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] animated:NO];
        }
    }
    else {
        [USER_DEFAULTS removeObjectForKey:kUIPersistenceSubscriptionsSelectedFeedUID];
        [USER_DEFAULTS synchronize];
    }
    
    [self _setObserving:YES];
    
    _flags.defaultPushed = 1;
}



- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
	
    [self _setObserving:NO];
}

- (void) reloadDataAndTable:(BOOL)reloadTable
{
    //self.feeds = [DMANAGER.feeds filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"parked == NO"]];
    if (reloadTable) {
        [self.tableView reloadData];

    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    }
    
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [[self.fetchController sections] count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.fetchController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchController sections] objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    }
    
    return 0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *SubscriptionFeedCell = @"SubscriptionFeedCell";

    SubscriptionTableViewCell *cell = (SubscriptionTableViewCell*)[tableView dequeueReusableCellWithIdentifier:SubscriptionFeedCell];
    if (cell == nil) {
        cell = [[SubscriptionTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:SubscriptionFeedCell];
    }
    
    cell.backgroundColor = tableView.backgroundColor;
    cell.accessibilityHint = @"Shows list of podcast episodes.".ls;
    
    
    CDFeed* feed = [self.fetchController objectAtIndexPath:indexPath];
    cell.objectValue = feed;
    
    cell.numberLabel.hidden = ([self.searchBar.text length] > 0);
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
	{
        CDFeed* feed = [self.fetchController objectAtIndexPath:indexPath];

        _flags.userAction = 1;
		[[SubscriptionManager sharedSubscriptionManager] unsubscribeFeed:feed];
        [self reloadDataAndTable:NO];
		
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        _flags.userAction = 0;
        
		UIBarButtonItem* sortItem = self.navigationItem.rightBarButtonItem;
        sortItem.enabled = ([[self.fetchController fetchedObjects] count] > 1);
        [self _updateToolbarLabels];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    _flags.userAction = 1;
    
    NSArray* feeds = DMANAGER.visibleFeeds;
    
    CDFeed* srcFeed = [self.fetchController objectAtIndexPath:fromIndexPath];
    NSUInteger srcIndex = [feeds indexOfObject:srcFeed];
    
    CDFeed* dstFeed = [self.fetchController objectAtIndexPath:toIndexPath];
    NSUInteger dstIndex = [feeds indexOfObject:dstFeed];
    
    [DMANAGER reorderFeedFromIndex:srcIndex toIndex:dstIndex];
    
    _flags.userAction = 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Unsubscribe".ls;
}

- (void) showEpisodeListForFeed:(CDFeed*)feed animated:(BOOL)animated
{
    NSArray* feeds = [self.fetchController fetchedObjects];
    if (feeds) {
        FeedEpisodesTableViewController* controller = [FeedEpisodesTableViewController episodesControllerWithFeed:feed];        
        [self.navigationController pushViewController:controller animated:animated];
    }
    else {
        [USER_DEFAULTS setObject:feed.uid forKey:kUIPersistenceSubscriptionsSelectedFeedUID];
    }
}

#pragma mark -
#pragma mark Table view delegate

- (void) _pushControllerForFeedAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    CDFeed* feed = [self.fetchController objectAtIndexPath:indexPath];
    FeedEpisodesTableViewController* controller = [FeedEpisodesTableViewController episodesControllerWithFeed:feed];
    controller.searchTerm = self.searchBar.text;
    
    [self.navigationController pushViewController:controller animated:animated];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self _pushControllerForFeedAtIndexPath:indexPath animated:YES];
    
    CDFeed* feed = [self.fetchController objectAtIndexPath:indexPath];
    [USER_DEFAULTS setObject:feed.uid forKey:kUIPersistenceSubscriptionsSelectedFeedUID];
}

#pragma mark - FetchedResultsController delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    if (_flags.userAction == 0) {
        [self.tableView beginUpdates];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    if (_flags.userAction == 1) {
        return;
    }
    
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if (_flags.userAction == 0) {
        [self.tableView endUpdates];
        [self _updateToolbarLabels];
    }
}


#pragma mark - SearchBar Delete


- (void) _searchTermDidChange
{
    NSString* searchText = self.searchBar.text;
    
    if ([searchText length] > 2)
    {
        NSSet* feedUIDs = [DMANAGER.ftsController feedUIDsForSearchTerm:searchText];
        
        self.fetchController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"subscribed == YES && parked == NO && sourceURL_ IN %@", feedUIDs];
        [self.fetchController performFetch:nil];
        [USER_DEFAULTS setObject:searchText forKey:kUIPersistenceSubscriptionsSearchTerm];
    }
    else {
        self.fetchController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"subscribed == YES && parked == NO"];
        [self.fetchController performFetch:nil];
        [USER_DEFAULTS removeObjectForKey:kUIPersistenceSubscriptionsSearchTerm];
    }
    [self.tableView reloadData];
    [self _updateToolbarLabels];
    self.editButtonItem.enabled = ([searchText length] == 0);
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self coalescedPerformSelector:@selector(_searchTermDidChange) afterDelay:0.3];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.searchBar resignFirstResponder];
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.searchBar resignFirstResponder];
}

#pragma mark -

- (void) refresh:(id)sender
{
    [[SubscriptionManager sharedSubscriptionManager] refreshAllFeedsForce:YES etagHandling:YES completion:^(BOOL success, NSArray* newEpisodes, NSError* error) {
        if (error) {
            [self presentError:error];
        }
    }];
}

#pragma mark -
#pragma mark Actions

- (void) addAction:(id)sender
{
    DirectorySearchViewController* controller = [DirectorySearchViewController directorySearchViewController];
    PortraitNavigationController* navigationController = [[PortraitNavigationController alloc] initWithRootViewController:controller];
    
    [self presentViewController:navigationController animated:YES completion:NULL];
}


- (void) sortAction:(UIBarButtonItem*)item
{
    WEAK_SELF
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Sort by".ls
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    UIAlertAction* titleAction = [UIAlertAction actionWithTitle:@"Title".ls style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              STRONG_SELF
                                                              [self perform:^(id sender) {
                                                                  [DMANAGER sortFeedsByKey:@"title" ascending:YES selector:@selector(naturalCaseInsensitiveCompare:)];
                                                              } afterDelay:0.3];
                                                              self.alertController = nil;
                                                          }];
    [alert addAction:titleAction];
    
    
    UIAlertAction* unplayedAction = [UIAlertAction actionWithTitle:@"Unplayed".ls style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action) {
                                                            STRONG_SELF
                                                            [self perform:^(id sender) {
                                                                [DMANAGER sortFeedsByKey:@"unplayedCount" ascending:NO selector:nil];
                                                            } afterDelay:0.3];
                                                            self.alertController = nil;
                                                        }];
    [alert addAction:unplayedAction];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Cancel".ls style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {
                                                              STRONG_SELF
                                                              self.alertController = nil;
                                                          }];
    [alert addAction:defaultAction];
    
    
    self.alertController = alert;
    [self presentAlertControllerAnimated:YES completion:NULL];
}


#pragma mark -
#pragma mark Gestures

- (void) handleLongPress:(UILongPressGestureRecognizer*)recognizer
{
	if (recognizer.state == UIGestureRecognizerStateBegan && !self.tableView.editing)
	{
        CGPoint location = [recognizer locationInView:self.tableView];
		NSIndexPath *rowIndexPath = [self.tableView indexPathForRowAtPoint:location];
        
//        NSArray* subscriptions = self.feeds;
//        
//        // long pressing on an empty cell not allowed
//        if (!rowIndexPath || rowIndexPath.row >= [subscriptions count]) {
//            return;
//        }
        
        CDFeed* feed = [self.fetchController objectAtIndexPath:rowIndexPath];
        
        FeedSettingsViewController* viewController = [FeedSettingsViewController feedSettingsViewControllerWithFeed:feed];
        PortraitNavigationController* navController = [[PortraitNavigationController alloc] initWithRootViewController:viewController];
        [self presentViewController:navController animated:YES completion:^{
            
        }];
	}
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] && !self.editing) {
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;
{
    return YES;
}


@end

