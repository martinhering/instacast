//
//  ListEpisodesTableViewController.m
//  Instacast
//
//  Created by Martin Hering on 21.08.14.
//
//

#import "ListEpisodesTableViewController.h"
#import "ToolbarLabelsViewController.h"
#import "EpisodeListEditorViewController.h"
#import "EpisodePlayComboButton.h"
#import "ICRefreshControl.h"

#define EPISODE_PAGE_SIZE 25

@interface ListEpisodesTableViewController ()
@property (nonatomic) NSInteger loadPages;
@property (nonatomic) NSArray* allEpisodes;
@end

@implementation ListEpisodesTableViewController {
    BOOL _list_episodes_observing;
}

+ (instancetype) viewControllerWithList:(CDEpisodeList*)list
{
    ListEpisodesTableViewController* controller = [[self alloc] initWithStyle:UITableViewStylePlain];
    controller.list = list;
    return controller;
}

- (void) _setObserving:(BOOL)observing
{
    [super _setObserving:observing];
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    SubscriptionManager* sman = [SubscriptionManager sharedSubscriptionManager];
    
    if (observing && !_list_episodes_observing)
    {
        __weak ListEpisodesTableViewController* weakSelf = self;
        
        [self addTaskObserver:self forKeyPath:@"list.numberOfEpisodes" task:^(id obj, NSDictionary *change) {
            [weakSelf _updateToolbarLabels];
            
            if (!weakSelf.userAction) {
                [weakSelf updateEpisodes];
                [weakSelf reloadDataAndPreserveSelection];

                [weakSelf _updateToolbarItemsAnimated:NO];
                [weakSelf _updateToolbarLabels];
            }
        }];
        
        [nc addObserver:self name:SubscriptionManagerDidStartRefreshingFeedsNotification object:nil handler:^(NSNotification *notification) {
            [self.refreshControl beginRefreshing];
        }];
        
        [nc addObserver:self name:SubscriptionManagerDidFinishRefreshingFeedsNotification object:nil handler:^(NSNotification *notification) {
            [self.refreshControl endRefreshing];
        }];
        
        [sman addTaskObserver:self forKeyPath:@"formattedLastRefreshDate" task:^(id obj, NSDictionary *change) {
            ((ICRefreshControl*)self.refreshControl).idleText = [[SubscriptionManager sharedSubscriptionManager] formattedLastRefreshDate];
        }];
        
        _list_episodes_observing = YES;
    }
    else if (!observing && _list_episodes_observing)
    {
        [self removeTaskObserver:self forKeyPath:@"list.numberOfEpisodes"];
        
        [nc removeHandlerForObserver:self name:SubscriptionManagerDidStartRefreshingFeedsNotification object:nil];
        [nc removeHandlerForObserver:self name:SubscriptionManagerDidFinishRefreshingFeedsNotification object:nil];
        
        [sman removeTaskObserver:self forKeyPath:@"formattedLastRefreshDate"];
        _list_episodes_observing = NO;
    }
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.list.name;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit".ls style:UIBarButtonItemStylePlain target:self action:@selector(editButtonAction:)];

    ICRefreshControl* refreshControl = [[ICRefreshControl alloc] init];
    refreshControl.pulldownText = @"Pull to refresh…".ls;
    refreshControl.refreshText = @"Looking for new episodes…".ls;
    refreshControl.idleText = [[SubscriptionManager sharedSubscriptionManager] formattedLastRefreshDate];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (void) editButtonAction:(id)sender
{
    EpisodeListEditorViewController* controller = [EpisodeListEditorViewController episodeListEditorViewControllerWithList:self.list];
    PortraitNavigationController* navController = [[PortraitNavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:navController animated:YES completion:NULL];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // only enable editing on dynamic lists
    self.navigationItem.rightBarButtonItem.enabled = ([self.list.episodes count] == 0);
    
    [self updateEpisodes];
    [self reloadDataAndPreserveSelection];
    
    [self _updateToolbarItemsAnimated:NO];
    [self _updateToolbarLabels];
    
    if ([SubscriptionManager sharedSubscriptionManager].refreshing && !self.refreshControl.refreshing) {
        [self.refreshControl beginRefreshing];
    }
    else if (![SubscriptionManager sharedSubscriptionManager].refreshing && self.refreshControl.refreshing) {
        [self.refreshControl endRefreshing];
    }
    
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

- (NSArray*) _loadNextPage
{
    NSInteger numEpisodes = [self.allEpisodes count];
    
    NSInteger start = MIN(numEpisodes, self.loadPages * EPISODE_PAGE_SIZE);
    NSInteger end = MIN(numEpisodes, start+EPISODE_PAGE_SIZE);
    
    if (end-start <= 0) {
        return nil;
    }
    
    NSArray* newEpisodes = [self.allEpisodes subarrayWithRange:NSMakeRange(start, end-start)];
    if (self.episodes) {
        self.episodes = [self.episodes arrayByAddingObjectsFromArray:newEpisodes];
    } else {
        self.episodes = newEpisodes;
    }
    self.loadPages++;

    return newEpisodes;
}

- (void) updateEpisodes
{
    self.allEpisodes = [self.list sortedEpisodes];
    self.loadPages = 0;
    self.episodes = nil;
    [self _loadNextPage];
}

- (void)enumerateEpisodesUsingBlock:(void (^)(CDEpisode* episode, NSUInteger idx, BOOL *stop))block
{
    [self.allEpisodes enumerateObjectsUsingBlock:block];
}

#pragma mark -

- (NSInteger) _playbackTime
{
    NSInteger playbackTime = 0;
    for(CDEpisode* episode in self.allEpisodes) {
        playbackTime += episode.duration;
    }
    
    return playbackTime;
}

- (void) _updateToolbarLabels
{
    NSInteger numEpisodes = [self.list numberOfEpisodes];
    
    if (numEpisodes == 0) {
        self.toolbarLabelsViewController.mainText = @"No Episodes".ls;
        self.toolbarLabelsViewController.auxiliaryText = @"";
    }
    else
    {
        self.toolbarLabelsViewController.mainText = (numEpisodes == 1) ? @"1 Episode".ls : [NSString stringWithFormat:@"%d Episodes".ls, numEpisodes];
        
        NSInteger duration = [self _playbackTime];
        NSValueTransformer* durationTransformer = [NSValueTransformer valueTransformerForName:kICDurationValueTransformer];
        NSString* durString = [durationTransformer transformedValue:@(duration)];
        self.toolbarLabelsViewController.auxiliaryText = durString;
    }
    
    
    [self.toolbarLabelsViewController layout];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGSize size = scrollView.contentSize;
    if (size.height == 0) {
        return;
    }
    
    UIEdgeInsets insets = scrollView.contentInset;
    CGPoint offset = scrollView.contentOffset;
    CGPoint bottomScroll = CGPointMake(0, size.height - CGRectGetHeight(scrollView.frame) + insets.top);
    
    if (offset.y > bottomScroll.y) {
        NSArray* newEpisodes = [self _loadNextPage];
        if ([newEpisodes count] > 0) {
            [self reloadDataAndPreserveSelection];
        }
    }
}

- (void) playComboButtonAction:(EpisodePlayComboButton*)button
{
    [super playComboButtonAction:button];
    
    if ((button.comboState != kEpisodePlayButtonComboStateFilling || button.comboState != kEpisodePlayButtonComboStateHolding) && self.list.continuousPlayback)
    {
        AudioSession* session = [AudioSession sharedAudioSession];
        [session eraseAllEpisodesFromUpNext];
        
        CDEpisode* episode = (CDEpisode*)button.userInfo;
        NSInteger location = [self.allEpisodes indexOfObject:episode];
        
        if (location != NSNotFound)
        {
            if (location+1 < [self.episodes count])
            {
                AudioSession* session = [AudioSession sharedAudioSession];
                
                // add only 10 episodes to up next
                NSInteger length = MIN([self.allEpisodes count]-location-1, 10);
                NSArray* remainingEpisodes = [self.allEpisodes subarrayWithRange:NSMakeRange(location+1, length)];
                [session appendToUpNext:remainingEpisodes];
            }
        }
    }
}

#pragma mark - Editing
/*
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    CDEpisode* episode = [self.episodes objectAtIndex:indexPath.row];
    
    [[self mutableArrayValueForKey:@"episodes"] removeObjectAtIndex:indexPath.row];

    [[CacheManager sharedCacheManager] removeCacheForEpisode:episode automatic:NO];
    [DMANAGER setEpisode:episode archived:YES];
    
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}
*/

#pragma mark - Archiving

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
    
    self.userAction = YES;
    
    CDEpisode* episode = [self.episodes objectAtIndex:indexPath.row];
    
    [[self mutableArrayValueForKey:@"episodes"] removeObjectAtIndex:indexPath.row];
    [[self mutableArrayValueForKey:@"allEpisodes"] removeObjectAtIndex:indexPath.row];
    
    [[CacheManager sharedCacheManager] removeCacheForEpisode:episode automatic:NO];
    [DMANAGER setEpisode:episode archived:YES];
    
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    [self _updateToolbarItemsAnimated:NO];
    [self _updateToolbarLabels];
    
    self.userAction = NO;
}
@end
