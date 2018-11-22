//
//  PlaylistsTableViewControllerViewController.m
//  Instacast
//
//  Created by Martin Hering on 03.04.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <MessageUI/MessageUI.h>


#import "PlaylistsTableViewController.h"

#import "SubscriptionManager.h"
#import "ICPlaylistsTableViewCell.h"
#import "VDModalInfo.h"

#import "STITunesStore.h"
#import "ICFeedURLScraper.h"
#import "AnimatingLabel.h"


#import "OptionsViewController.h"
#import "InstacastAppDelegate.h"

#import "ToolbarLabelsViewController.h"
#import "BookmarksTableViewController.h"
#import "CDModel.h"
#import "PortraitNavigationController.h"
#import "ICRefreshControl.h"
#import "EpisodeListEditorViewController.h"
#import "ListEpisodesTableViewController.h"


@interface PlaylistsTableViewController () <MFMailComposeViewControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, assign) NSInteger action;
@property (nonatomic, strong) ToolbarLabelsViewController* toolbarLabelsViewController;
@property (nonatomic, strong) UIBarButtonItem* labelsItems;
@end

@implementation PlaylistsTableViewController {
    BOOL _observing;
    BOOL _defaultPushed;
    BOOL _userAction;
}

#pragma mark -
#pragma mark Initialization

+ (PlaylistsTableViewController*) viewController
{
	return [[self alloc] initWithStyle:UITableViewStylePlain];
}

- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization.
    }
    return self;
}

- (void)dealloc
{
    [self _setObserving:NO];
}

#pragma mark -
#pragma mark View lifecycle

- (void) _setObserving:(BOOL)observing
{
    SubscriptionManager* sman = [SubscriptionManager sharedSubscriptionManager];
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    
    if (observing && !_observing)
    {
        [DMANAGER addTaskObserver:self forKeyPath:@"lists" task:^(id obj, NSDictionary *change) {
            if (!_userAction) {
                [self.tableView reloadData];
                [self _updateToolbarItemsAnimated:NO];
                [self _updateToolbarLabels];
            }
        }];
        
        [nc addObserver:self selector:@selector(subscriptionManagerDidAddEpisodesNotification:) name:SubscriptionManagerDidAddEpisodesNotification object:nil];
        [nc addObserver:self selector:@selector(subscriptionManagerDidStartRefreshingFeedsNotification:) name:SubscriptionManagerDidStartRefreshingFeedsNotification object:nil];
        [nc addObserver:self selector:@selector(subscriptionManagerDidFinishRefreshingFeedsNotification:) name:SubscriptionManagerDidFinishRefreshingFeedsNotification object:nil];
        
        [sman addTaskObserver:self forKeyPath:@"formattedLastRefreshDate" task:^(id obj, NSDictionary *change) {
            ((ICRefreshControl*)self.refreshControl).idleText = [[SubscriptionManager sharedSubscriptionManager] formattedLastRefreshDate];
        }];
        

        _observing = YES;
    }
    else if (!observing && _observing)
    {
        [DMANAGER removeTaskObserver:self forKeyPath:@"lists"];
        [nc removeObserver:self];
        
        [sman removeTaskObserver:self forKeyPath:@"formattedLastRefreshDate"];
        _observing = NO;
    }
}

- (void) subscriptionManagerDidAddEpisodesNotification:(NSNotification*)notification
{
    if (!_userAction) {
        [self.tableView reloadData];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setScrollView:self.tableView contentInsets:UIEdgeInsetsZero byAdjustingForStandardBars:YES];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.title = @"Episodes".ls;
    
    self.tableView.rowHeight = 44;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    
    ICRefreshControl* refreshControl = [[ICRefreshControl alloc] init];
    refreshControl.pulldownText = @"Pull to refresh…".ls;
    refreshControl.refreshText = @"Looking for new episodes…".ls;
    refreshControl.idleText = [[SubscriptionManager sharedSubscriptionManager] formattedLastRefreshDate];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    
    self.toolbarLabelsViewController = [ToolbarLabelsViewController toolbarLabelsViewController];
    
    self.labelsItems = [[UIBarButtonItem alloc] initWithCustomView:self.toolbarLabelsViewController.view];
    self.labelsItems.width = CGRectGetWidth(self.toolbarLabelsViewController.view.bounds);

    
    UILongPressGestureRecognizer* pressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
	pressRecognizer.delegate = self;
	[self.tableView addGestureRecognizer:pressRecognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tableView.separatorColor = ICTableSeparatorColor;
    self.tableView.backgroundColor = ICBackgroundColor;
	
    
	[self.tableView reloadData];
    
    [self _updateToolbarItemsAnimated:YES];
    [self _updateToolbarLabels];
    
    if ([SubscriptionManager sharedSubscriptionManager].refreshing && !self.refreshControl.refreshing) {
        [self.refreshControl beginRefreshing];
    }
    else if (![SubscriptionManager sharedSubscriptionManager].refreshing && self.refreshControl.refreshing) {
        [self.refreshControl endRefreshing];
    }
    
    
    NSString* savedUID = [USER_DEFAULTS objectForKey:kUIPersistencePlaylistsSelectedPlaylistUID];
    if (_defaultPushed == 0 && savedUID) {
        __block NSUInteger index = NSNotFound;
        [DMANAGER.lists enumerateObjectsUsingBlock:^(CDList* list, NSUInteger idx, BOOL *stop) {
            if ([list.uid isEqualToString:savedUID]) {
                index = idx;
                *stop = YES;
            }
        }];
        
        if (index != NSNotFound) {
            [self _pushControllerForListAtIndex:index animated:NO];
        }
    }
    else {
        [USER_DEFAULTS removeObjectForKey:kUIPersistencePlaylistsSelectedPlaylistUID];
        [USER_DEFAULTS synchronize];
    }
    _defaultPushed = 1;
    
    [self _setObserving:YES];
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
	
    [self _setObserving:NO];
}

- (void) _updateToolbarLabels
{
    if ([DMANAGER.lists count] == 0) {
        self.toolbarLabelsViewController.mainText = @"No Lists".ls;
    }
    else if ([DMANAGER.lists count] == 1) {
        self.toolbarLabelsViewController.mainText = @"1 List".ls;
    }
    else {
        self.toolbarLabelsViewController.mainText = [NSString stringWithFormat:@"%d Lists".ls, [DMANAGER.lists count]];
    }
    
    unsigned long long megaBytes = [[CacheManager sharedCacheManager] numberOfDownloadedBytes];
    if (megaBytes == 0LLU) {
        self.toolbarLabelsViewController.auxiliaryText = nil;
    }
    else {
        self.toolbarLabelsViewController.auxiliaryText = [NSByteCountFormatter stringFromByteCount:megaBytes countStyle:NSByteCountFormatterCountStyleMemory];
    }
    [self.toolbarLabelsViewController layout];
}

- (void) _updateToolbarItemsAnimated:(BOOL)animated
{
    UIBarButtonItem* addButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Toolbar Add"] style:UIBarButtonItemStylePlain target:self action:@selector(addAction:)];
    
    
	UIBarButtonItem* flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                               target:nil
                                                                               action:nil];
    

    [self setToolbarItems:@[addButtonItem, flexSpace, self.labelsItems, flexSpace] animated:animated];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [DMANAGER.lists count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    ICPlaylistsTableViewCell *cell = (ICPlaylistsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[ICPlaylistsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.backgroundColor = self.tableView.backgroundColor;
    
    CDList* list = [DMANAGER.lists objectAtIndex:indexPath.row];
    cell.objectValue = list;
        
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    _userAction = YES;
    CDList* list = [DMANAGER.lists objectAtIndex:indexPath.row];
    [DMANAGER removeList:list];
    
    // Delete the row from the data source.
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    _userAction = NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    _userAction = YES;
    [DMANAGER reorderListFromIndex:fromIndexPath.row toIndex:toIndexPath.row];
    _userAction = NO;
}


#pragma mark -
#pragma mark Table view delegate

- (void) _pushControllerForListAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    CDList* list = [DMANAGER.lists objectAtIndex:index];
    
    if (![list isKindOfClass:[CDEpisodeList class]]) {
        return;
    }
    
    UIBarButtonItem* a = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = a;
    
    ListEpisodesTableViewController* episodesController = [ListEpisodesTableViewController viewControllerWithList:(CDEpisodeList*)list];
    [self.navigationController pushViewController:episodesController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.editing) {
        [self _pushControllerForListAtIndex:indexPath.row animated:YES];
        
        CDList* list = [DMANAGER.lists objectAtIndex:indexPath.row];
        [USER_DEFAULTS setObject:list.uid forKey:kUIPersistencePlaylistsSelectedPlaylistUID];
        [USER_DEFAULTS synchronize];
    }
    else {
        [self _updateToolbarItemsAnimated:NO];
    }
}


#pragma mark -
#pragma mark ScrollView Delegate


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
}


#pragma mark -
#pragma mark Actions

- (void) setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    [self _updateToolbarItemsAnimated:YES];
}


- (void) addAction:(id)sender
{
    EpisodeListEditorViewController* controller = [EpisodeListEditorViewController episodeListEditorViewControllerWithList:nil];
    PortraitNavigationController* navController = [[PortraitNavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:navController animated:YES completion:^{
        
    }];
}


- (void) actionAction:(id)sender
{
    OptionsViewController* optionsViewController = [OptionsViewController optionsViewController];
    PortraitNavigationController* navController = [[PortraitNavigationController alloc] initWithRootViewController:optionsViewController];
    
    [self presentViewController:navController animated:YES completion:^{
    }];
}

- (void) refresh:(id)sender
{
    [[SubscriptionManager sharedSubscriptionManager] refreshAllFeedsForce:YES etagHandling:YES completion:^(BOOL success, NSArray* newEpisodes, NSError* error) {
        if (error) {
            [self presentError:error];
        }
    }];
}


#pragma mark -
#pragma mark Gestures

- (void) handleLongPress:(UILongPressGestureRecognizer*)recognizer
{
	if (recognizer.state == UIGestureRecognizerStateBegan && !self.tableView.editing)
	{
        CGPoint location = [recognizer locationInView:self.tableView];
		NSIndexPath *rowIndexPath = [self.tableView indexPathForRowAtPoint:location];
        
        // long pressing on an empty cell not allowed
        if (!rowIndexPath || rowIndexPath.row >= [DMANAGER.lists count]) {
            return;
        }
        
        CDEpisodeList* list = [DMANAGER.lists objectAtIndex:rowIndexPath.row];

        if ([list isKindOfClass:[CDEpisodeList class]])
        {
            EpisodeListEditorViewController* controller = [EpisodeListEditorViewController episodeListEditorViewControllerWithList:list];
            PortraitNavigationController* navController = [[PortraitNavigationController alloc] initWithRootViewController:controller];
            [self presentViewController:navController animated:YES completion:^{
                
            }];
        }
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
