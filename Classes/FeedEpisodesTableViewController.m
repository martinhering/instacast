//
//  EpisodesTableViewController.m
//  Instacast
//
//  Created by Martin Hering on 29.12.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "FeedEpisodesTableViewController.h"
#import "FeedViewController.h"

#import "SubscriptionManager.h"
#import "EpisodeViewController.h"
#import "VDModalInfo.h"
#import "PlaybackViewController.h"
#import "AnimatingLabel.h"
#import "PlaybackViewController.h"
#import "UIManager.h"

#import "EpisodesTableViewCell.h"
#import "ToolbarLabelsViewController.h"
#import "CDModel.h"
#import "NumberAccessoryView.h"
#import "ICFeedHeaderViewController.h"
#import "ImageFunctions.h"
#import "FeedSettingsViewController.h"
#import "STITunesStore.h"
#import "CDFeed+Helper.h"
#import "ICFTSController.h"

@interface FeedEpisodesTableViewController() <UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) NSFetchedResultsController* fetchController;
@property (nonatomic, strong) ICFeedHeaderViewController* headerViewController;
@property (nonatomic, strong) UIToolbar* headerToolbar;
@property (nonatomic, strong) UIView* headerToolbarSeparatorView;
@property (nonatomic, weak) UIBarButtonItem* shareItem;
@property (nonatomic, strong) VDModalInfo* modalInfo;
@property (nonatomic, strong) UIView* tableHeaderView;
@end

@implementation FeedEpisodesTableViewController {
    NSMutableSet* _selectionPreservingIndexPathes;
}

+ (FeedEpisodesTableViewController*) episodesControllerWithFeed:(CDFeed*)feed
{
	FeedEpisodesTableViewController* controller = [[self alloc] initWithStyle:UITableViewStylePlain];
    controller.feed = feed;
	return controller;
}


- (void) addAdditionalButtonsToLongPressActionSheet:(UIAlertController*)sheet rowIndexPath:(NSIndexPath*)indexPath completionBlock:(void (^)())completionBlock
{
    WEAK_SELF
    [sheet addAction:[UIAlertAction actionWithTitle:@"Delete".ls
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                [self perform:^(id sender) {
                                                    [self archiveEpisodesAtRowAtIndexPath:indexPath];
                                                } afterDelay:0.3];
                                                completionBlock();
                                            }]];
}

- (void) addAdditionalButtonsToMultiSelectEditActionSheet:(UIAlertController*)sheet selectedIndexPathes:(NSArray*)selectedIndexPathes completionBlock:(void (^)())completionBlock
{
    WEAK_SELF
    [sheet addAction:[UIAlertAction actionWithTitle:@"Delete".ls
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                [self perform:^(id sender) {
                                                    NSMutableArray* myEpisodes = [self.episodes mutableCopy];
                                                    for(NSIndexPath* indexPath in selectedIndexPathes)
                                                    {
                                                        if (indexPath.row < [myEpisodes count]) {
                                                            CDEpisode* episode = myEpisodes[indexPath.row];
                                                            episode.archived = YES;
                                                            [[CacheManager sharedCacheManager] removeCacheForEpisode:episode automatic:NO];
                                                        }
                                                    }
                                                    [DMANAGER save];
                                                    
                                                    [self updateEpisodes];
                                                    [self _updateToolbarItemsAnimated:NO];
                                                } afterDelay:0.3];
                                                completionBlock();
                                            }]];
}


#pragma mark -
#pragma mark View lifecycle

- (void) updateEpisodes
{
    self.episodes = [self.fetchController fetchedObjects];
}

- (BOOL) showsImage
{
    return NO;
}

- (void) _updateFetchController
{
    BOOL reverseOrder = ([[self.feed stringForKey:FeedSortOrder] isEqualToString:SortOrderOlderFirst]);
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Episode"];
    if ([self.searchTerm length] > 0)
    {
        NSSet* episodeGuids = [DMANAGER.ftsController episodeUIDsForSearchTerm:self.searchTerm];
        
        NSString* t = [NSString stringWithFormat:@"*%@*", self.searchTerm];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"feed == %@ && archived == %@ && (guid IN %@ || feed.title like[cd] %@ || feed.author like[cd] %@ || feed.summary like[cd] %@)", self.feed, @NO, episodeGuids, t, t, t];
        
    } else {
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"feed == %@ && archived == %@", self.feed, @NO];
    }
    
    fetchRequest.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"pubDate" ascending:reverseOrder] ];
    
    NSString* cacheName = [NSString stringWithFormat:@"_feed_episodes_%@", self.feed.title];
    [NSFetchedResultsController deleteCacheWithName:cacheName];
    self.fetchController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                               managedObjectContext:DMANAGER.objectContext
                                                                 sectionNameKeyPath:nil
                                                                          cacheName:cacheName];
    self.fetchController.delegate = self;
    [self.fetchController performFetch:nil];
    
    [self updateEpisodes];
}

#pragma mark - FetchedResultsController delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    if (self.userAction) {
        return;
    }
    
    [self.tableView beginUpdates];
    _selectionPreservingIndexPathes = [[NSMutableSet alloc] init];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    if (self.userAction) {
        return;
    }
    
    NSArray* indexPathes = [self.tableView indexPathsForSelectedRows];
    BOOL indexPathWasSelected = [indexPathes containsObject:indexPath];
    
    
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
            if (indexPathWasSelected) {
                [_selectionPreservingIndexPathes addObject:indexPath];
            }
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (self.userAction) {
        return;
    }
    
    [self updateEpisodes];
    [self.tableView endUpdates];
    [self _updateToolbarLabels];
    
    for (NSIndexPath* indexPath in _selectionPreservingIndexPathes) {
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    
    _selectionPreservingIndexPathes = nil;
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = ([self.searchTerm length] > 0) ? [NSString stringWithFormat:@"'%@'", self.searchTerm] : nil;
    
    WEAK_SELF
    self.editingStyle = EpisodesTableViewEditingStyleNormal;
    
    {
        CGFloat w = CGRectGetWidth(self.view.bounds);
        self.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 93+45)];
        self.tableHeaderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        
        self.headerViewController = [ICFeedHeaderViewController viewController];
        self.headerViewController.view.frame = CGRectMake(0, 0, w, 93);
        self.headerViewController.titleLabel.text = self.feed.title;
        self.headerViewController.subtitleLabel.text = self.feed.author;
        
        ImageCacheManager* iman = [ImageCacheManager sharedImageCacheManager];
        [iman imageForURL:self.feed.imageURL size:72 grayscale:NO sender:self completion:^(UIImage *image) {
            STRONG_SELF
            if (image) {
                self.headerViewController.imageView.image = image;
            }
        }];
        
        [self addChildViewController:self.headerViewController];
        [self.tableHeaderView addSubview:self.headerViewController.view];
        [self.headerViewController didMoveToParentViewController:self];

        self.headerViewController.action = ^() {
            STRONG_SELF
            
            UIBarButtonItem* a = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
            self.navigationItem.backBarButtonItem = a;
            
            FeedViewController* feedInfoController = [FeedViewController feedViewController];
            feedInfoController.feed = self.feed;
            [self.navigationController pushViewController:feedInfoController animated:YES];
        };
        
        UIView* headerToolbarSeparatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 93, w, 0.5)];
        [self.tableHeaderView addSubview:headerToolbarSeparatorView];
        self.headerToolbarSeparatorView = headerToolbarSeparatorView;
        
        self.headerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 94, w, 44)];
        self.headerToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [self.headerToolbar setShadowImage:[[UIImage alloc] init] forToolbarPosition:UIBarPositionAny];
        [self.tableHeaderView addSubview:self.headerToolbar];
        
        [self _updateHeaderToolbar];
    }
    
    [self updateEpisodes];
    [self _updateToolbarItemsAnimated:NO];
}

- (void) _updateHeaderToolbar
{
    UIBarButtonItem* reloadItem = [[UIBarButtonItem alloc] initWithTitle:@"Reload".ls
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(reload:)];
    
    UIBarButtonItem* shareItem = [[UIBarButtonItem alloc] initWithTitle:@"Share".ls
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(share:)];
    
    UIBarButtonItem* settingsItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings".ls
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(settings:)];
    
    UIBarButtonItem* fixItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixItem.width = -1;
    
    UIBarButtonItem* flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    
    [self.headerToolbar setItems:@[fixItem, reloadItem, flexItem, shareItem, flexItem, settingsItem, fixItem]];
    self.shareItem = shareItem;
}

- (void) _updateToolbarLabels
{
    NSInteger numEpisodes = [self.episodes count];
    
    if (numEpisodes == 0) {
        self.toolbarLabelsViewController.mainText = @"No Episodes".ls;
        self.toolbarLabelsViewController.auxiliaryText = @"";
    }
    else
    {
        self.toolbarLabelsViewController.mainText = (numEpisodes == 1) ? @"1 Episode".ls : [NSString stringWithFormat:@"%d Episodes".ls, numEpisodes];
        self.toolbarLabelsViewController.auxiliaryText = @"";
    }

    [self.toolbarLabelsViewController layout];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    CGFloat w = CGRectGetWidth(self.view.bounds);
    self.headerToolbar.frame = CGRectMake(0, 94, w, 44);
    
    [self.headerToolbar setBackgroundImage:ICImageFromByDrawingInContext(CGSizeMake(1, 1), ^() {
        [ICBackgroundColor set];
        UIRectFill(CGRectMake(0, 0, 1, 1));
    })
                        forToolbarPosition:UIToolbarPositionAny
                                barMetrics:UIBarMetricsDefault];
    self.headerToolbarSeparatorView.backgroundColor = ICTableSeparatorColor;
    
    
    if ([self.searchTerm length] > 0)
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Toolbar Close"]
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(toolbarCloseButtonAction:)];
                                                  
    }
    
    [self reloadData];
}

- (void) reloadData
{
    [self _updateFetchController];
    [self _updateToolbarItemsAnimated:NO];
    [self _updateToolbarLabels];
    
    [self reloadDataAndPreserveSelection];
    self.tableView.tableHeaderView = ([self.searchTerm length] == 0) ? self.tableHeaderView : nil;
    self.headerToolbar.frame = CGRectMake(0, 94, CGRectGetWidth(self.tableHeaderView.frame), 44);
}

- (void) toolbarCloseButtonAction:(id)sender
{
    self.navigationItem.rightBarButtonItem = nil;
    self.searchTerm = nil;
    self.title = nil;
    [self reloadData];
}

- (void) playerCloseButtonAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark -

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EpisodesTableViewCell* cell = (EpisodesTableViewCell*)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.topSeparator = (indexPath.row == 0);
    return cell;
}

#pragma mark - Actions

- (void) editAction:(id)sender
{
    [self setEditing:!self.editing animated:YES];
}


- (CGFloat) mainSplitViewContentViewControllerFixedWidth
{
    return 320;
}

- (void) reload:(id)sender
{
    self.modalInfo = [VDModalInfo modalInfoWithProgressLabel:@"Reloading…".ls];
    [self.modalInfo show];
    
    __weak FeedEpisodesTableViewController* weakSelf = self;
    
    SubscriptionManager* sman = [SubscriptionManager sharedSubscriptionManager];
    [sman reloadContentOfFeed:self.feed
      recoverArchivedEpisodes:NO
                   completion:^(BOOL success, NSArray* newEpisodes, NSError* error) {
                       
                       if (error) {
                           [self presentError:error];
                       }
                       
                       [sman autoDownloadEpisodesInFeed:self.feed];
                       
                       if ([newEpisodes count] > 0) {
                            PlaySoundFile(@"NewEpisodes",NO);
                       }
                       
                       [weakSelf updateEpisodes];
                       
                       [weakSelf.modalInfo close];
                       weakSelf.modalInfo = nil;
                   }];
}



- (void) settings:(id)sender
{
    FeedSettingsViewController* viewController = [FeedSettingsViewController feedSettingsViewControllerWithFeed:self.feed];
    PortraitNavigationController* navController = [[PortraitNavigationController alloc] initWithRootViewController:viewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:^{
        
    }];
}

- (void) archiveEpisodesAtRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath) {
        return;
    }
    
    NSArray* lEpisodes = self.episodes;
    
    // swiping on an empty cell not allowed
    if (indexPath.row >= [lEpisodes count]) {
        return;
    }
    
    CDEpisode* episode = (CDEpisode*)[lEpisodes objectAtIndex:indexPath.row];
    

    [[CacheManager sharedCacheManager] removeCacheForEpisode:episode automatic:NO];
    [DMANAGER setEpisode:episode archived:YES];
    [self updateEpisodes];
    
    [self _updateToolbarItemsAnimated:NO];
    [self _updateToolbarLabels];
}

#pragma mark - Sharing

- (void) share:(id)sender
{
    NSURL* feedURL = [self.feed sourceURLAsPcastURL];
    
    UIActivityViewController* shareController = [[UIActivityViewController alloc] initWithActivityItems:@[feedURL] applicationActivities:nil];
    if ([shareController respondsToSelector:@selector(popoverPresentationController)]) {
        shareController.popoverPresentationController.barButtonItem = sender;
    }
    [self presentViewController:shareController animated:YES completion:NULL];
}
@end

