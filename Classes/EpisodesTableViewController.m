//
//  EpisodesTableViewController.m
//  Instacast
//
//  Created by Martin Hering on 25.05.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "EpisodesTableViewController.h"
#import "EpisodesTableViewCell.h"


#import "UIManager.h"

#import "VDModalInfo.h"
#import "CDModel.h"
#import "CDEpisode+ShowNotes.h"

#import "EpisodeViewController.h"
#import "PlaybackViewController.h"
#import "EpisodePlayComboButton.h"

#import "AlertStylePopoverController.h"
#import "NumberAccessoryView.h"

#import "ToolbarLabelsViewController.h"
#import "ICSidebarPanGestureRecognizer.h"
#import "UpNextTableViewController.h"

NSString* kDefaultEpisodesSelectedEpisodeUID = @"DefaultEpisodesSelectedEpisodeUID";

@interface EpisodesTableViewController ()
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
@property (nonatomic, strong) NSDateFormatter* weekdayDateFormatter;
@property (nonatomic, strong, readwrite) ToolbarLabelsViewController* toolbarLabelsViewController;
@property (nonatomic, strong, readwrite) UIBarButtonItem* labelsItems;
@property (nonatomic, weak) UITapGestureRecognizer* cancelDeleteButtonTapRecognizer;

@end

@implementation EpisodesTableViewController {
@private
    BOOL _defaultsPushed;
    BOOL _observing;
}

- (void)dealloc
{
    [[ImageCacheManager sharedImageCacheManager] cancelImageCacheOperationsWithSender:self];
    [self _setObserving:NO];
}

- (void) _setObserving:(BOOL)observing
{
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    
    if (observing && !_observing)
    {
        [[CacheManager sharedCacheManager] addTaskObserver:self forKeyPath:@"cachingEpisodes" task:^(id obj, NSDictionary *change) {
            [[self.tableView visibleCells] makeObjectsPerformSelector:@selector(updatePlayComboButtonState)];
        }];
        
        [nc addObserver:self selector:@selector(cacheManagerDidUpdateNotification:) name:CacheManagerDidUpdateNotification object:nil];
        [nc addObserver:self selector:@selector(cacheManagerDidClearCacheNotification:) name:CacheManagerDidClearCacheNotification object:nil];
        
        _observing = YES;
    }
    else if (!observing && _observing)
    {
        [nc removeObserver:self];
        
        [[CacheManager sharedCacheManager] removeTaskObserver:self forKeyPath:@"cachingEpisodes"];
        
        _observing = NO;
    }
}

- (void) cacheManagerDidUpdateNotification:(NSNotification*)notification
{
    [[self.tableView visibleCells] makeObjectsPerformSelector:@selector(updatePlayComboButtonState)];
}

- (void) cacheManagerDidClearCacheNotification:(NSNotification*)notification
{
    [[self.tableView visibleCells] makeObjectsPerformSelector:@selector(updatePlayComboButtonState)];
}


- (BOOL) showsImage
{
    return YES;
}

- (BOOL) canArchiveEpisodes
{
    return YES;
}

- (BOOL) canPlayMultiple
{
    return YES;
}

- (void) addAdditionalButtonsToMultiActionSheet:(UIAlertController*)sheet completionBlock:(void (^)())completionBlock
{
    
}

- (void) addAdditionalButtonsToLongPressActionSheet:(UIAlertController*)sheet rowIndexPath:(NSIndexPath*)indexPath completionBlock:(void (^)())completionBlock
{
    
}

- (void) addAdditionalButtonsToMultiSelectEditActionSheet:(UIAlertController*)sheet selectedIndexPathes:(NSArray*)selectedIndexPathes completionBlock:(void (^)())completionBlock
{

}

- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization.
	}
    return self;
}


- (void) viewDidLoad
{
    [super viewDidLoad];
    [self setScrollView:self.tableView contentInsets:UIEdgeInsetsZero byAdjustingForStandardBars:YES];
    
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);

    self.toolbarLabelsViewController = [ToolbarLabelsViewController toolbarLabelsViewController];
    
    self.labelsItems = [[UIBarButtonItem alloc] initWithCustomView:self.toolbarLabelsViewController.view];
    self.labelsItems.width = CGRectGetWidth(self.toolbarLabelsViewController.view.bounds);
    
    
    UITapGestureRecognizer* cancelDeleteButtonTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelDelete:)];
    cancelDeleteButtonTapRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:cancelDeleteButtonTapRecognizer];
    self.cancelDeleteButtonTapRecognizer = cancelDeleteButtonTapRecognizer;
}

- (void) restoreShowNotes
{
    NSString* savedEpisodeUID = [USER_DEFAULTS objectForKey:kDefaultEpisodesSelectedEpisodeUID];
    
    if (!_defaultsPushed && savedEpisodeUID) {
        __block CDEpisode* selectedEpisode = nil;;
        [self.episodes enumerateObjectsUsingBlock:^(CDEpisode* episode, NSUInteger idx, BOOL *stop) {
            if ([episode.uid isEqualToString:savedEpisodeUID]) {
                selectedEpisode = episode;
                *stop = YES;
            }
        }];
        
        if (selectedEpisode) {
            [self _pushShowNotesOfEpisode:selectedEpisode animated:NO inAppearanceTransition:YES];
        }
    }
    else {
        [USER_DEFAULTS removeObjectForKey:kDefaultEpisodesSelectedEpisodeUID];
        [USER_DEFAULTS synchronize];
    }
    _defaultsPushed = YES;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.tableView.backgroundColor = ICBackgroundColor;
    self.tableView.separatorColor = ICTableSeparatorColor;
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];

    [self restoreShowNotes];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self _setObserving:YES];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[ImageCacheManager sharedImageCacheManager] cancelImageCacheOperationsWithSender:self];
    [self _setObserving:NO];
}



- (void) updateEpisodes
{
    self.episodes = nil;
}

- (void) _updateToolbarLabels
{
    
}


- (void) _updateToolbarItemsAnimated:(BOOL)animated
{
	UIBarButtonItem* flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    [self willChangeValueForKey:@"toolbarItems"];
	
	if (self.tableView.editing && self.editingStyle == EpisodesTableViewEditingStyleDownload)
	{
        NSInteger selectedCellsCount = [[self.tableView indexPathsForSelectedRows] count];
        NSInteger rowCount = [self.tableView numberOfRowsInSection:0];
        
        UIBarButtonItem* fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        fixedSpace.width = 20.f;
        
        NumberAccessoryView* numView = [[NumberAccessoryView alloc] initWithStyle:NumberAccessoryViewStyleEdgyOutline];
        numView.backgroundColor = [UIColor clearColor];
        numView.outlineColor = [UIColor colorWithWhite:0.8f alpha:1.f];
        numView.font = [UIFont boldSystemFontOfSize:11.0f];
        numView.num = [[self.tableView indexPathsForSelectedRows] count];
        [numView sizeToFit];
        
//        UIBarButtonItem* countItem = [[UIBarButtonItem alloc] initWithCustomView:numView];
//        
        UIBarButtonItem* selectAllItem = [[UIBarButtonItem alloc] initWithTitle:(selectedCellsCount < rowCount) ? @"All".ls : @"Deselect".ls
                                                                       style:UIBarButtonItemStylePlain
																	  target:self
                                                                      action:@selector(selectAllAction:)];
        
		UIBarButtonItem* editItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Multitoolbar Edit"]
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(showEditingOptionsForSelection:)];
        editItem.enabled = (selectedCellsCount > 0);
        
        UIBarButtonItem* playItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Multitoolbar Play"]
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(showPlayingOptionsForSelection:)];
        playItem.enabled = (selectedCellsCount > 0);
        
        UIBarButtonItem* downloadItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Multitoolbar Download"]
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(downloadSelection:)];
        downloadItem.enabled = (selectedCellsCount > 0);
		
		UIBarButtonItem* cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                    target:self
                                                                                    action:@selector(editForCachingAction:)];
        
        [self setToolbarItems:[NSArray arrayWithObjects: editItem, fixedSpace, playItem, fixedSpace, downloadItem, flexSpace, selectAllItem, fixedSpace, cancelItem,nil] animated:animated];
	}
    else
	{
        UIBarButtonItem* cacheItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Toolbar Select"]
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(editForCachingAction:)];
        
        cacheItem.enabled = ([self.episodes count] > 0);
        
        UIBarButtonItem* consumeAllItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Toolbar Complete"]
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(consumeAllAction:)];
        consumeAllItem.enabled = ([self.episodes count] > 0);
        

        [self setToolbarItems:@[consumeAllItem, flexSpace, self.labelsItems, flexSpace, cacheItem] animated:animated];
	}
    
    [self didChangeValueForKey:@"toolbarItems"];
    
}


- (void) reloadDataAndPreserveSelection
{
    NSArray* myEpisodes = self.episodes;
    
    NSMutableArray* selectedEpisodes = [NSMutableArray array];
    
    NSArray* indexPathes = [self.tableView indexPathsForSelectedRows];
    for(NSIndexPath* indexPath in indexPathes)
    {
        if (indexPath.row < [myEpisodes count]) {
            [selectedEpisodes addObject:myEpisodes[indexPath.row]];
        }
    }
    
    [self.tableView reloadData];
    
    for(CDEpisode* episode in selectedEpisodes) {
        NSUInteger index = [myEpisodes indexOfObject:episode];
        if (index != NSNotFound) {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
}

#pragma mark -

- (NSInteger) playbackTime
{
    __block NSInteger playbackTime = 0;
    [self enumerateEpisodesUsingBlock:^(CDEpisode* episode, NSUInteger idx, BOOL *stop) {
        playbackTime += episode.duration;
    }];
    
    return playbackTime;
}

- (NSInteger) _numberOfNotPlayedDisplayEpisodes
{
	// count non-consumed
	__block NSInteger nonConsumed = 0;
	[self enumerateEpisodesUsingBlock:^(CDEpisode* episode, NSUInteger idx, BOOL *stop) {
		nonConsumed += (episode.consumed) ? 0 : 1;
	}];
	return nonConsumed;
}

- (NSInteger) _numberOfPlayedDisplayEpisodes
{
	// count non-consumed
	__block NSInteger nonConsumed = 0;
	[self enumerateEpisodesUsingBlock:^(CDEpisode* episode, NSUInteger idx, BOOL *stop) {
		nonConsumed += (episode.consumed) ? 1 : 0;
	}];
	return nonConsumed;
}

- (NSInteger) _numberOfPlayedDownloadedEpisodes
{
    CacheManager* cman = [CacheManager sharedCacheManager];
    // count non-consumed
    __block NSInteger downloaded = 0;
    [self enumerateEpisodesUsingBlock:^(CDEpisode* episode, NSUInteger idx, BOOL *stop) {
        downloaded += (episode.consumed && [cman episodeIsCached:episode])?1:0;
    }];
    return downloaded;
}

- (void)enumerateEpisodesUsingBlock:(void (^)(CDEpisode* episode, NSUInteger idx, BOOL *stop))block
{
    [[self.episodes copy] enumerateObjectsUsingBlock:block];
}


- (void) _setAllAsConsumed:(BOOL)consumed
{
	VDModalInfo* allConsumedModalInfo = [VDModalInfo modalInfo];
	allConsumedModalInfo.closableByTap = NO;
	
	allConsumedModalInfo.textLabel.text = (consumed) ? @"All Played".ls : @"All Unplayed".ls;
	allConsumedModalInfo.animation = VDModalInfoAnimationScaleUp;
	allConsumedModalInfo.showingProgress = YES;
	allConsumedModalInfo.size = CGSizeMake(125, 125);
	
	[allConsumedModalInfo show];
	
	[self perform:^(id sender) {

        [DMANAGER.objectContext.undoManager disableUndoRegistration];
        
        [DMANAGER beginInterruptSaving];
        [self enumerateEpisodesUsingBlock:^(CDEpisode* episode, NSUInteger idx, BOOL *stop) {
            [DMANAGER markEpisode:episode asConsumed:consumed];
        }];
        [DMANAGER endInterruptSaving];
        
        [DMANAGER.objectContext.undoManager enableUndoRegistration];
        [DMANAGER save];
        
        [self updateEpisodes];
        [self.tableView reloadData];
        [self _updateToolbarLabels];
        [self _updateToolbarItemsAnimated:NO];
        
        [allConsumedModalInfo close];
        
    } afterDelay:0.3];
}

- (void) _archiveAllPlayed
{
    VDModalInfo* modelInfo = [VDModalInfo modalInfoWithProgressLabel:@"Deleting…".ls];
	[modelInfo show];
	
	[self perform:^(id sender) {
        
        [DMANAGER.objectContext.undoManager disableUndoRegistration];
        [self enumerateEpisodesUsingBlock:^(CDEpisode* episode, NSUInteger idx, BOOL *stop) {
            if (episode.consumed && !episode.starred)
            {
                [[CacheManager sharedCacheManager] removeCacheForEpisode:episode automatic:NO];
                episode.archived = YES;
            }
        }];
        [DMANAGER.objectContext.undoManager enableUndoRegistration];
        [DMANAGER save];
        
        [self updateEpisodes];
        [self.tableView reloadData];
        [self _updateToolbarLabels];
        [self _updateToolbarItemsAnimated:NO];
        
        [modelInfo close];
        
    } afterDelay:0.3];
}

- (void) _clearCacheOfAllPlayed
{
    VDModalInfo* modelInfo = [VDModalInfo modalInfoWithProgressLabel:@"Clearing…".ls];
	[modelInfo show];
	
	[self perform:^(id sender) {
        
        CacheManager* cman = [CacheManager sharedCacheManager];
        
        [self enumerateEpisodesUsingBlock:^(CDEpisode* episode, NSUInteger idx, BOOL *stop) {
            if (episode.consumed && [cman episodeIsCached:episode]) {
                [[CacheManager sharedCacheManager] removeCacheForEpisode:episode automatic:NO];
            }
        }];
        
        [self updateEpisodes];
        [self.tableView reloadData];
        [self _updateToolbarLabels];
        [self _updateToolbarItemsAnimated:NO];
        
        [modelInfo close];
        
    } afterDelay:0.3];
}


- (void) consumeAllAction:(id)sender
{
    WEAK_SELF
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    if ([self _numberOfNotPlayedDisplayEpisodes] > 0) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Mark all as Played".ls
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    STRONG_SELF
                                                    [self perform:^(id sender) {
                                                        [self _setAllAsConsumed:YES];
                                                    } afterDelay:0.3];
                                                    self.alertController = nil;
                                                }]];
    }
    
    if ([self.episodes count]-[self _numberOfNotPlayedDisplayEpisodes] > 0) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Mark all as Unplayed".ls
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    STRONG_SELF
                                                    [self perform:^(id sender) {
                                                        [self _setAllAsConsumed:NO];
                                                    } afterDelay:0.3];
                                                    self.alertController = nil;
                                                }]];
    }
    
    if ([self _numberOfPlayedDownloadedEpisodes] > 0) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Delete played content".ls
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction * action) {
                                                    STRONG_SELF
                                                    [self perform:^(id sender) {
                                                        [self _clearCacheOfAllPlayed];
                                                    } afterDelay:0.3];
                                                    self.alertController = nil;
                                                }]];
    }
    
    if ([self canArchiveEpisodes] && [self _numberOfPlayedDisplayEpisodes] > 0) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Delete all Played".ls
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction * action) {
                                                    STRONG_SELF
                                                    [self perform:^(id sender) {
                                                        [self _archiveAllPlayed];
                                                    } afterDelay:0.3];
                                                    self.alertController = nil;
                                                }]];
    }
    
    [self addAdditionalButtonsToMultiActionSheet:alert completionBlock:^{
        STRONG_SELF
        self.alertController = nil;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel".ls
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                self.alertController = nil;
                                            }]];
    
    self.alertController = alert;
    [self presentAlertControllerAnimated:YES completion:NULL];
}


- (void) _updateCacheButtonStateWithSelectedIndexPathes:(NSArray*)indexPathes
{
    if (self.editing)
    {
        [self _updateToolbarItemsAnimated:NO];
    }
}


#pragma mark -
#pragma mark Pan Gesture

- (void) didSwipeRightInCellAtIndexPath:(NSIndexPath*)indexPath
{
	NSArray* lEpisodes = self.episodes;
    
    // swiping on an empty cell not allowed
    if (indexPath.section != 0 || indexPath.row >= [lEpisodes count]) {
        return;
    }
    
	CDEpisode* episode = (CDEpisode*)[lEpisodes objectAtIndex:indexPath.row];
	EpisodesTableViewCell* cell = (EpisodesTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    
	if ([cell isKindOfClass:[EpisodesTableViewCell class]])
	{
		BOOL flag = !episode.consumed;
		
        self.userAction = YES;
        [DMANAGER markEpisode:episode asConsumed:flag];
        
        // stop playback of episode
		if (flag && [episode isEqual:[AudioSession sharedAudioSession].episode]) {
			[[AudioSession sharedAudioSession] stop];
		}
		
        [cell updatePlayedAndStarredState];
		[self _updateToolbarItemsAnimated:NO];
        [self _updateToolbarLabels];
		
        self.userAction = NO;
		PlaySoundFile((flag)?@"AffirmOut":@"AffirmIn", NO);
	}
}

- (void) toggleFavoriteAtIndexPath:(NSIndexPath*)indexPath
{
	NSArray* lEpisodes = self.episodes;
    
    // swiping on an empty cell not allowed
    if (indexPath.section != 0 || indexPath.row >= [lEpisodes count]) {
        return;
    }
    
	CDEpisode* episode = (CDEpisode*)[lEpisodes objectAtIndex:indexPath.row];
	EpisodesTableViewCell* cell = (EpisodesTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    
	if ([cell isKindOfClass:[EpisodesTableViewCell class]])
	{
		BOOL flag = !episode.starred;
		
        self.userAction = YES;
        [DMANAGER markEpisode:episode asStarred:flag];
        
        [cell updatePlayedAndStarredState];
		[self _updateToolbarItemsAnimated:NO];
        [self _updateToolbarLabels];
		self.userAction = NO;
		PlaySoundFile((flag)?@"AffirmIn":@"AffirmOut", NO);
	}
}

- (UIView*) _separatorViewOfCell:(UITableViewCell*)cell
{
    for(UIView* subview in cell.subviews) {
        if (CGRectGetHeight(subview.bounds) == 1) {
            return subview;
        }
    }
    
    return nil;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.cancelDeleteButtonTapRecognizer)
    {
        for(NSIndexPath* indexPath in [self.tableView indexPathsForVisibleRows])
        {
            EpisodesTableViewCell* cell = (EpisodesTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
            if (cell.showsDeleteControl) {
                return YES;
            }
        }
    }
    
    return NO;
}

- (void) cancelDelete:(id)sender
{
    for(NSIndexPath* indexPath in [self.tableView indexPathsForVisibleRows])
    {
        EpisodesTableViewCell* cell = (EpisodesTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        if (cell.showsDeleteControl) {
            [cell cancelDelete:nil];
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self cancelDelete:nil];
}


#pragma mark -
#pragma mark Actions

- (void) showActionSheetForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSArray* lEpisodes = self.episodes;
    
    // swiping on an empty cell not allowed
    if (indexPath.row >= [lEpisodes count]) {
        return;
    }
    
    CDEpisode* episode = (CDEpisode*)[lEpisodes objectAtIndex:indexPath.row];
    
    WEAK_SELF
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:episode.title
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:(episode.starred) ? @"Unmark Favorite".ls : @"Mark as Favorite".ls
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                [self perform:^(id sender) {
                                                    [self toggleFavoriteAtIndexPath:indexPath];
                                                    [self cancelDelete:nil];
                                                } afterDelay:0.3];
                                                self.alertController = nil;
                                            }]];
    
    AudioSession* session = [AudioSession sharedAudioSession];
    
    if (![episode isEqual:session.episode]) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Add to Up Next".ls
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    STRONG_SELF
                                                    [self perform:^(id sender) {
                                                        UpNextTableViewController* upNext = [UpNextTableViewController viewController];
                                                        upNext.episodesToInsert = @[episode];
                                                        
                                                        PortraitNavigationController* navController = [[PortraitNavigationController alloc] initWithRootViewController:upNext];
                                                        navController.modalPresentationStyle = UIModalPresentationFormSheet;
                                                        [self presentViewController:navController animated:YES completion:NULL];
                                                    } afterDelay:0.3];
                                                    self.alertController = nil;
                                                }]];
    }
    
    
    if (![[CacheManager sharedCacheManager] episodeIsCached:episode] && ![[CacheManager sharedCacheManager] isCachingEpisode:episode])
    {
        [alert addAction:[UIAlertAction actionWithTitle:@"Download".ls
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    STRONG_SELF
                                                    [self perform:^(id sender) {
                                                        [self _askUserForCellularDownloadIfNecessary:^(BOOL canDownload) {
                                                            if (canDownload) {
                                                                [[CacheManager sharedCacheManager] cacheEpisode:episode overwriteCellularLock:YES];
                                                                EpisodesTableViewCell* cell = (EpisodesTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
                                                                [cell updatePlayComboButtonState];
                                                                
                                                                [self cancelDelete:nil];
                                                            }
                                                        }];
                                                    } afterDelay:0.3];
                                                    self.alertController = nil;
                                                }]];
    }
    
    if ([[CacheManager sharedCacheManager] episodeIsCached:episode])
    {
        [alert addAction:[UIAlertAction actionWithTitle:@"Delete File".ls
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    STRONG_SELF
                                                    [self perform:^(id sender) {
                                                        [[CacheManager sharedCacheManager] removeCacheForEpisode:episode automatic:NO];
                                                        EpisodesTableViewCell* cell = (EpisodesTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
                                                        [cell updatePlayComboButtonState];
                                                        [self cancelDelete:nil];
                                                    } afterDelay:0.3];
                                                    self.alertController = nil;
                                                }]];
    }
    
#ifdef DEBUG
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Notify after 10 seconds"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                [self perform:^(id sender) {
                                                    UILocalNotification* notification = [[UILocalNotification alloc] init];
                                                    NSString* episodeTitle = [NSString stringWithFormat:@"%@ - %@", episode.feed.title, [episode cleanTitleUsingFeedTitle:episode.feed.title]];
                                                    if ([notification respondsToSelector:@selector(alertTitle)]) {
                                                        notification.alertTitle = @"New Episode".ls;
                                                    }
                                                    if ([notification respondsToSelector:@selector(category)]) {
                                                        notification.category = @"episode_available";
                                                    }
                                                    notification.alertBody = [NSString stringWithFormat:@"'%@' is available to play.".ls, episodeTitle];
                                                    notification.soundName = @"NewEpisodes";
                                                    notification.userInfo = @{ @"episode_hash" : [episode objectHash], @"podcast" : episode.feed.title, @"episode" : [episode cleanTitleUsingFeedTitle:episode.feed.title]};
                                                    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:10];
                                                    [App scheduleLocalNotification:notification];
                                                    
                                                    [self cancelDelete:nil];
                                                } afterDelay:0.3];
                                                self.alertController = nil;
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Perma-Delete"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                [self perform:^(id sender) {
                                                    [DMANAGER.objectContext deleteObject:episode];
                                                    [DMANAGER saveAndSync:NO];
                                                } afterDelay:0.3];
                                                self.alertController = nil;
                                            }]];
#endif
    
    [self addAdditionalButtonsToLongPressActionSheet:alert rowIndexPath:indexPath completionBlock:^{
        STRONG_SELF
        self.alertController = nil;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel".ls
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                self.alertController = nil;
                                            }]];
    
    self.alertController = alert;
    [self presentAlertControllerAnimated:YES completion:NULL];
}


- (void) editForCachingAction:(id)sender
{
	if (!self.tableView.editing) {
        self.editingStyle = EpisodesTableViewEditingStyleDownload;
		[self setEditing:YES animated:YES];
	}
	else {
        self.editingStyle = EpisodesTableViewEditingStyleNormal;
		[self setEditing:NO animated:YES];
	}
}



- (void) showPlayingOptionsForSelection:(id)sender
{
    NSArray* selectedIndexPathes = [self.tableView indexPathsForSelectedRows];
    NSMutableArray* selectedEpisodes = [NSMutableArray array];
    for(NSIndexPath* indexPath in selectedIndexPathes) {
        [selectedEpisodes addObject:self.episodes[indexPath.row]];
    }
    AudioSession* session = [AudioSession sharedAudioSession];
    
    CDEpisode* firstEpisode = [selectedEpisodes firstObject];
    
    // current episode is replaced with first item
    // current episode is prepended to up next
    PlaybackViewController* playbackController = [PlaybackViewController playbackViewControllerWithEpisode:firstEpisode forceReload:YES];
    [playbackController presentFromParentViewController:self.navigationController];
    
    // prepend all other episode from the selection to up next,
    // current episode will play after selection
    [selectedEpisodes removeObjectAtIndex:0];
    if ([selectedEpisodes count] > 0) {
        [session prependToUpNext:selectedEpisodes];
    }
    [self setEditing:NO animated:YES];
}

- (void) showEditingOptionsForSelection:(id)sender
{
    NSArray* selectedIndexPathes = [self.tableView indexPathsForSelectedRows];
    
    typedef void(^ForEachEpisodeBlock)(CDEpisode* episode);
    void (^foreachSelectedEpisode)() = ^(ForEachEpisodeBlock block) {
        
        NSArray* selectedIndexPathes = [self.tableView indexPathsForSelectedRows];
        for(NSIndexPath* indexPath in selectedIndexPathes) {
            CDEpisode* episode = self.episodes[indexPath.row];
            block(episode);
        }
        [self.tableView reloadRowsAtIndexPaths:selectedIndexPathes withRowAnimation:UITableViewRowAnimationFade];
        [DMANAGER save];
    };
    

    WEAK_SELF
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Mark as Played".ls
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                [self perform:^(id sender) {
                                                    foreachSelectedEpisode(^(CDEpisode* episode){
                                                        episode.consumed = YES;
                                                    });
                                                    PlaySoundFile(@"AffirmIn", NO);
                                                } afterDelay:0.3];
                                                self.alertController = nil;
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Mark as Unplayed".ls
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                [self perform:^(id sender) {
                                                    foreachSelectedEpisode(^(CDEpisode* episode){
                                                        episode.consumed = NO;
                                                    });
                                                    PlaySoundFile(@"AffirmIn", NO);
                                                } afterDelay:0.3];
                                                self.alertController = nil;
                                            }]];
    
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Mark as Favorite".ls
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                [self perform:^(id sender) {
                                                    foreachSelectedEpisode(^(CDEpisode* episode){
                                                        episode.starred = YES;
                                                    });
                                                    PlaySoundFile(@"AffirmOut", NO);
                                                } afterDelay:0.3];
                                                self.alertController = nil;
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Unmark Favorites".ls
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                [self perform:^(id sender) {
                                                    foreachSelectedEpisode(^(CDEpisode* episode){
                                                        episode.starred = NO;
                                                    });
                                                    PlaySoundFile(@"AffirmOut", NO);
                                                } afterDelay:0.3];
                                                self.alertController = nil;
                                            }]];
    
    [self addAdditionalButtonsToMultiSelectEditActionSheet:alert
                                       selectedIndexPathes:selectedIndexPathes
                                           completionBlock:^{
                                               STRONG_SELF
                                               self.alertController = nil;
                                           }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel".ls
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                self.alertController = nil;
                                            }]];
    
    self.alertController = alert;
    [self presentAlertControllerAnimated:YES completion:NULL];
}

- (void) _askUserForCellularDownloadIfNecessary:(void (^)(BOOL canDownload))completionHandler
{
    BOOL enabled3G = [USER_DEFAULTS boolForKey:EnableCachingOver3G];
    if (enabled3G || App.networkAccessTechnology == kICNetworkAccessTechnlogyWIFI) {
        completionHandler(YES);
        return;
    }
    
    
    WEAK_SELF
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Downloading over cellular has been disabled in 'General' settings.".ls
                                                                   message:@"Do you still want to download the content of this episode right now?".ls
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"Download".ls
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                [self perform:^(id sender) {
                                                    completionHandler(YES);
                                                } afterDelay:0.3];
                                                self.alertController = nil;
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel".ls
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                [self perform:^(id sender) {
                                                    completionHandler(NO);
                                                } afterDelay:0.3];
                                                self.alertController = nil;
                                            }]];
    
    self.alertController = alert;
    [self presentAlertControllerAnimated:YES completion:NULL];
}

- (void) downloadSelection:(id)sender
{
    NSArray* selectedIndexPathes = [self.tableView indexPathsForSelectedRows];
    CacheManager* cman = [CacheManager sharedCacheManager];
    
    [self _askUserForCellularDownloadIfNecessary:^(BOOL canDownload) {
        if (canDownload) {
            for(NSIndexPath* selectedIndexPath in selectedIndexPathes) {
                CDEpisode* episode = [self.episodes objectAtIndex:selectedIndexPath.row];
                [cman cacheEpisode:episode overwriteCellularLock:YES];
            }
            [self setEditing:NO animated:YES];
            [self.tableView reloadRowsAtIndexPaths:selectedIndexPathes withRowAnimation:UITableViewRowAnimationFade];
        }
    }];
}

- (void) cancelCachingAction:(id)sender
{
	[[CacheManager sharedCacheManager] cancelCaching];
}

- (void) cancelCachingEpisode:(UIButton*)button
{
	NSInteger index = button.tag - 2000;
	CDEpisode* episode = [self.episodes objectAtIndex:index];
	
	[[CacheManager sharedCacheManager] cancelCachingEpisode:episode disableAutoDownload:YES];
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
    
    self.userAction = YES;
    [[CacheManager sharedCacheManager] removeCacheForEpisode:episode automatic:NO];
    [DMANAGER setEpisode:episode archived:YES];
    [self updateEpisodes];
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
    [self.tableView endUpdates];
    
    [self _updateToolbarItemsAnimated:NO];
    [self _updateToolbarLabels];
    self.userAction = NO;
}

- (void) selectAllAction:(id)sender
{
    NSInteger rowCount = [self.tableView numberOfRowsInSection:0];
    NSArray* selectedRows = [self.tableView indexPathsForSelectedRows];
    
    if ([selectedRows count] < rowCount)
    {
        NSInteger row = 0;
        for (row=0; row<rowCount; row++) {
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:0];
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
    else
    {
        for(NSIndexPath* indexPath in selectedRows)
        {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
    
    [self _updateCacheButtonStateWithSelectedIndexPathes:selectedRows];
}

#pragma mark -
#pragma mark Content Selection


- (void) setEditingStyle:(EpisodesTableViewEditingStyle)editingStyle
{
    if (_editingStyle != editingStyle) {
        _editingStyle = editingStyle;
        
        switch (_editingStyle) {
            case EpisodesTableViewEditingStyleNormal:
                self.tableView.allowsMultipleSelectionDuringEditing = NO;
                break;
            case EpisodesTableViewEditingStyleDownload:
                self.tableView.allowsMultipleSelectionDuringEditing = YES;
                break;
            default:
                break;
        }
    }
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    if (!editing) {
        self.editingStyle = EpisodesTableViewEditingStyleNormal;
    }
    
    [self _updateToolbarItemsAnimated:animated];
}


#pragma mark - TableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
	if (section == 0) {
		return [self.episodes count];
	}
    
	return 0;
}

- (void) _setCell:(EpisodesTableViewCell*)cell imageForFeed:(CDFeed*)feed episode:(CDEpisode*)episode
{
    if ([self showsImage])
    {
        cell.iconView.image = [UIImage imageNamed:@"Podcast Placeholder 56"];
        
        NSURL* imageURL = (episode.imageURL) ? episode.imageURL : feed.imageURL;
        if (!imageURL) {
            return;
        }
        
        
        ImageCacheManager* iman = [ImageCacheManager sharedImageCacheManager];
        UIImage* cachedImage = [iman localImageForImageURL:imageURL size:56 grayscale:(episode.consumed)];
        if (cachedImage) {
            cell.iconView.image = cachedImage;
        }
    }
    else {
        cell.iconView.image = nil;
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* EpisodesCellIdentifier = @"EpisodesContentCell";
    
    EpisodesTableViewCell* cell = (EpisodesTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:EpisodesCellIdentifier];
    if (!cell) {
        cell = [[EpisodesTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:EpisodesCellIdentifier];
        [cell.playAccessoryButton addTarget:self action:@selector(playComboButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    cell.backgroundColor = self.tableView.backgroundColor;
    cell.tintColor = self.view.tintColor;
    
    CDEpisode* episode = [self.episodes objectAtIndex:indexPath.row];
    
    //NSLog(@"feed uid: %@ %@ %d %d", episode.feed.uid, episode.feed.sourceURL, episode.feed.subscribed, episode.feed.parked);
    
    cell.objectValue = episode;
    cell.playAccessoryButton.userInfo = episode;
    
    if (self.showsImage) {
        cell.iconView.image = [UIImage imageNamed:@"Podcast Placeholder 56"];
        NSURL* imageURL = (episode.imageURL) ? episode.imageURL : episode.feed.imageURL;
        
        ImageCacheManager* iman = [ImageCacheManager sharedImageCacheManager];
        [iman imageForURL:imageURL size:56 grayscale:NO sender:cell completion:^(UIImage *image) {
            if (image) {
                cell.iconView.image = image;
            }
        }];
    }
    
    __weak EpisodesTableViewController* weakSelf = self;
    cell.shouldShowMore = ^(NSIndexPath* indexPath) {
        __strong EpisodesTableViewController* strongSelf = weakSelf;
        
        NSArray* lEpisodes = strongSelf.episodes;
        
        // long pressing on an empty cell not allowed
        if (indexPath.row >= [lEpisodes count]) {
            return;
        }
        
        [strongSelf showActionSheetForRowAtIndexPath:indexPath];
    };
    
    cell.didPanRight = ^(NSIndexPath* indexPath) {
        [weakSelf didSwipeRightInCellAtIndexPath:indexPath];
    };
    
    cell.panDidBegin = ^(NSIndexPath* indexPath) {

        EpisodesTableViewCell* actionCell = (EpisodesTableViewCell*)[weakSelf.tableView cellForRowAtIndexPath:indexPath];
        
        for(NSIndexPath* indexPath2 in [self.tableView indexPathsForVisibleRows]) {
            EpisodesTableViewCell* myCell = (EpisodesTableViewCell*)[weakSelf.tableView cellForRowAtIndexPath:indexPath2];
            if (myCell != actionCell && myCell.showsDeleteControl) {
                [myCell cancelDelete:nil];
            }
        }
    };
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CDEpisode* episode = [self.episodes objectAtIndex:indexPath.row];
    
    CGSize imageSize = (self.showsImage) ? CGSizeMake(56, 56) : CGSizeZero;
    
    CGFloat h = [EpisodesTableViewCell proposedHeightWithObjectValue:episode tableSize:self.tableView.bounds.size imageSize:imageSize embedded:NO editing:self.editing];
    
    return h;
}

#pragma mark - Table view delegate


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}


- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self _updateCacheButtonStateWithSelectedIndexPathes:[self.tableView indexPathsForSelectedRows]];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.episodes count] == 0) {
        return;
    }
    
    if (self.editingStyle == EpisodesTableViewEditingStyleDownload) {
        [self _updateCacheButtonStateWithSelectedIndexPathes:[self.tableView indexPathsForSelectedRows]];
        return;
    }
    
    
    CDEpisode* episode = (CDEpisode*)[self.episodes objectAtIndex:indexPath.row];
    [self _pushShowNotesOfEpisode:episode animated:YES inAppearanceTransition:NO];
    
    [USER_DEFAULTS setObject:episode.uid forKey:kDefaultEpisodesSelectedEpisodeUID];
    [USER_DEFAULTS synchronize];
}


#pragma mark -

- (void) playComboButtonAction:(EpisodePlayComboButton*)button
{
    CDEpisode* episode = (CDEpisode*)button.userInfo;
    
    if (button.comboState == kEpisodePlayButtonComboStateFilling || button.comboState == kEpisodePlayButtonComboStateHolding)
    {
        CacheManager* cman = [CacheManager sharedCacheManager];
        [cman cancelCachingEpisode:episode disableAutoDownload:YES];
    }
    else
    {
        PlaybackViewController* playbackController = [PlaybackViewController playbackViewControllerWithEpisode:episode forceReload:YES];
        [playbackController presentFromParentViewController:self.navigationController autostart:YES completion:NULL];
    }
}

- (void) _pushShowNotesOfEpisode:(CDEpisode*)episode animated:(BOOL)animated inAppearanceTransition:(BOOL)appearanceTransition
{
    UIBarButtonItem* a = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = a;
    
    EpisodeViewController* controller = [EpisodeViewController episodeViewController];
    controller.episode = episode;
    controller.view.tintColor = ICTintColor;
    controller.view.frame = controller.view.frame;
    [self.navigationController pushViewController:controller animated:animated];
}
@end


#pragma  mark -

@interface EpisodesContainerViewController ()
@property (nonatomic, strong) UIView* navigationExtensionView;
@end


@implementation EpisodesContainerViewController {
    BOOL _observing;
}


+ (instancetype) containerViewControllerWithTableViewController:(EpisodesTableViewController*)tableViewController
{
    EpisodesContainerViewController* controller = [[EpisodesContainerViewController alloc] initWithNibName:nil bundle:nil];
    controller.tableViewController = tableViewController;
    return controller;
}

- (void)dealloc
{
	[self _setObserving:NO];
}

- (void) _setObserving:(BOOL)observing
{
    if (observing && !_observing)
    {
        __weak EpisodesContainerViewController* weakSelf = self;
        [self.tableViewController addTaskObserver:self forKeyPath:@"toolbarItems" task:^(id obj, NSDictionary *change) {
            [weakSelf setToolbarItems:[weakSelf.tableViewController toolbarItems]];
        }];
    
        _observing = YES;
    }
    else if (!observing && _observing)
    {
        [self.tableViewController removeTaskObserver:self forKeyPath:@"toolbarItems"];
        
        _observing = NO;
    }
    
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem* a = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = a;
    
    CGRect b = self.view.bounds;
    self.tableViewController.view.frame = b;
    
    self.tableViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self addChildViewController:self.tableViewController];
    [self.view addSubview:self.tableViewController.view];
    [self.tableViewController didMoveToParentViewController:self];
    
    self.navigationExtensionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(b), 20+44+22)];
    self.navigationExtensionView.backgroundColor = ICTransparentBackdropColor;
    [self.view addSubview:self.navigationExtensionView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self _setObserving:YES];
    [self setToolbarItems:[self.tableViewController toolbarItems] animated:YES];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self _setObserving:NO];
}


@end
