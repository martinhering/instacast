//
//  BookmarksTableViewController.m
//  Instacast
//
//  Created by Martin Hering on 22.03.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <MessageUI/MessageUI.h>

#import "BookmarksTableViewController.h"

#import "PlaybackViewController.h"
#import "FeedEpisodeExtraction.h"
#import "VDModalInfo.h"
#import "ToolbarLabelsViewController.h"
#import "OptionsViewController.h"
#import "XPFF.h"
#import "BookmarksTableViewCell.h"
#import "NumberAccessoryView.h"
#import "CDModel.h"
#import "PortraitNavigationController.h"
#import "IOS8FixedSeparatorTableViewCell.h"

static NSString* kBookmarkIndexHash = @"hash";
static NSString* kBookmarkIndexFeedURL = @"feedURL";
static NSString* kBookmarkIndexEpisodeGuid = @"episodeGuid";
static NSString* kBookmarkIndexFeedTitle = @"feedTitle";
static NSString* kBookmarkIndexEpisodeTitle = @"episodeTitle";
static NSString* kBookmarkIndexImageURL = @"imageURL";


@interface BookmarksTableViewController () <UIGestureRecognizerDelegate, UIDocumentInteractionControllerDelegate, MFMailComposeViewControllerDelegate>
@property (nonatomic, strong) NSArray* sections;
@property (nonatomic, strong) NSDictionary* bookmarks;
@property (nonatomic, assign) BOOL bookmarksChanged;
@property (nonatomic, strong) NSIndexPath* actionIndexPath;

@property (nonatomic, strong) ToolbarLabelsViewController* toolbarLabelsViewController;

@property (nonatomic, strong) UIBarButtonItem* labelsItems;

@property (nonatomic, strong) UIDocumentInteractionController* interactionController;
@property (nonatomic, assign) BOOL multiple;
@end

@implementation BookmarksTableViewController {
    BOOL _observing;
    BOOL _userAction;
}

+ (id) bookmarksController
{
    return [[BookmarksTableViewController alloc] initWithStyle:UITableViewStylePlain];
}

- (void) dealloc
{
    [self _setObserving:NO];
}


#pragma mark -

- (void) _setObserving:(BOOL)observing
{
    if (observing && !_observing)
    {
        [DMANAGER addTaskObserver:self forKeyPath:@"bookmarks" task:^(id obj, NSDictionary *change) {
            if (!_userAction) {
                [self _reloadBookmarks];
                [self.tableView reloadData];
                [self _updateToolbarAnimated:YES];
                [self _updateToolbarLabels];
            }
        }];
        
        _observing = YES;
    }
    else if (!observing && _observing)
    {
        [DMANAGER removeTaskObserver:self forKeyPath:@"bookmarks"];
        _observing = NO;
    }
}

- (NSArray*) _bookmarksWithEpisodeHash:(NSString*)episodeHash
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"episodeHash == %@", episodeHash];
    NSArray* bookmarks = [DMANAGER.bookmarks filteredArrayUsingPredicate:predicate];
    return bookmarks;
}

- (void) _reloadBookmarks
{
    self.multiple = NO;
    
    if (self.parentHash)
    {
        NSPredicate* parentHashPredicate = [NSPredicate predicateWithFormat:@"episodeHash == %@", self.parentHash];
        NSArray* theBookmarks = [DMANAGER.bookmarks filteredArrayUsingPredicate:parentHashPredicate];
        
        NSMutableDictionary* myBookmarks = [NSMutableDictionary dictionaryWithCapacity:100];
        [myBookmarks setObject:theBookmarks forKey:self.parentHash];
        
        
        NSMutableArray* mySections = [NSMutableArray arrayWithCapacity:[_bookmarks count]];
        
        for(CDBookmark* bookmark in theBookmarks)
        {
            NSMutableDictionary* section = [NSMutableDictionary dictionaryWithCapacity:3];
            
            [section setObject:bookmark.episodeHash forKey:kBookmarkIndexHash];
            
            if (bookmark.feedURL)
                [section setObject:bookmark.feedURL forKey:kBookmarkIndexFeedURL];
            
            if (bookmark.feedTitle)
                [section setObject:bookmark.feedTitle forKey:kBookmarkIndexFeedTitle];
            
            if (bookmark.episodeTitle)
                [section setObject:bookmark.episodeTitle forKey:kBookmarkIndexEpisodeTitle];
            
            if (bookmark.episodeGuid)
                [section setObject:bookmark.episodeGuid forKey:kBookmarkIndexEpisodeGuid];
            
            if (bookmark.imageURL)
                [section setObject:bookmark.imageURL forKey:kBookmarkIndexImageURL];
            
            [mySections addObject:section];
        }
        
        self.sections = mySections;
        self.bookmarks = myBookmarks;
    }
    else
    {
        NSMutableDictionary* bookmarkIndex = [[NSMutableDictionary alloc] init];
        
        for(CDBookmark* bookmark in DMANAGER.bookmarks)
        {
            NSMutableArray* groupedBookmarks = bookmarkIndex[bookmark.episodeHash];
            if (!groupedBookmarks) {
                groupedBookmarks = [[NSMutableArray alloc] init];
                bookmarkIndex[bookmark.episodeHash] = groupedBookmarks;
            }
            
            [groupedBookmarks addObject:bookmark];
        }
        
    
        NSMutableArray* mySections = [NSMutableArray arrayWithCapacity:[bookmarkIndex count]];
        NSMutableDictionary* myBookmarks = [NSMutableDictionary dictionaryWithCapacity:100];
        
        for(NSString* episodeHash in bookmarkIndex)
        {
            NSArray* bookmarks = bookmarkIndex[episodeHash];
            CDBookmark* bookmark = [bookmarks lastObject];
            
            NSMutableDictionary* section = [NSMutableDictionary dictionaryWithCapacity:3];
            if (bookmark.feedTitle)
                [section setObject:bookmark.feedTitle forKey:kBookmarkIndexFeedTitle];

            if (bookmark.feedURL)
                [section setObject:bookmark.feedURL forKey:kBookmarkIndexFeedURL];

            if (bookmark.episodeTitle)
                [section setObject:bookmark.episodeTitle forKey:kBookmarkIndexEpisodeTitle];
            
            if (bookmark.episodeGuid)
                [section setObject:bookmark.episodeGuid forKey:kBookmarkIndexEpisodeGuid];
            
            if (bookmark.imageURL) {
                [section setObject:bookmark.imageURL forKey:kBookmarkIndexImageURL];
            }
            
            [section setObject:episodeHash forKey:kBookmarkIndexHash];
            [mySections addObject:section];

            
            NSArray* bmarks = [self _bookmarksWithEpisodeHash:episodeHash];
            if (bmarks) {
                [myBookmarks setObject:bmarks forKey:episodeHash];
            }
            if ([bmarks count] > 1) {
                self.multiple = YES;
            }
        }
        
        NSSortDescriptor* feedSortDescriptor = [[NSSortDescriptor alloc] initWithKey:kBookmarkIndexFeedTitle ascending:YES];
        NSSortDescriptor* episodeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:kBookmarkIndexEpisodeTitle ascending:YES];
        
        self.sections = [mySections sortedArrayUsingDescriptors:@[feedSortDescriptor, episodeSortDescriptor]];
        self.bookmarks = myBookmarks;
    }
}

- (void) _updateToolbarLabels
{
    NSInteger num = (self.parentHash) ? [self.sections count] : [DMANAGER.bookmarks count];
    if (num == 0) {
        self.toolbarLabelsViewController.mainText = @"No Bookmarks".ls;
    }
    else if (num == 1) {
        self.toolbarLabelsViewController.mainText = @"1 Bookmark".ls;
    } else{
        self.toolbarLabelsViewController.mainText = [NSString stringWithFormat:@"%d Bookmarks".ls, num];
    }
    self.toolbarLabelsViewController.auxiliaryText = nil;
    
    [self.toolbarLabelsViewController layout];
}

- (void) _updateToolbarAnimated:(BOOL)animated
{
    UIBarButtonItem* flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self setToolbarItems:@[flexSpace, self.labelsItems, flexSpace] animated:animated];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setScrollView:self.tableView contentInsets:UIEdgeInsetsZero byAdjustingForStandardBars:YES];

    if (!self.title) {
        self.title = @"Bookmarks".ls;
    }
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
	self.tableView.rowHeight = 57+10;
	self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    self.toolbarLabelsViewController = [ToolbarLabelsViewController toolbarLabelsViewController];
    
    self.labelsItems = [[UIBarButtonItem alloc] initWithCustomView:self.toolbarLabelsViewController.view];
    self.labelsItems.width = CGRectGetWidth(self.toolbarLabelsViewController.view.bounds);
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tableView.separatorColor = ICTableSeparatorColor;
    self.tableView.backgroundColor = ICBackgroundColor;
    
    [self _reloadBookmarks];

    [self.tableView reloadData];
    
    [self _updateToolbarAnimated:YES];
    [self _updateToolbarLabels];
    
    [self _setObserving:YES];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self _setObserving:NO];
}


- (void) reload
{
    [self _reloadBookmarks];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return MAX(1,[self.sections count]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.sections count] == 0)
    {
        static NSString *BookmarksPlaceholder = @"BookmarksPlaceholderCellItem";
		
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:BookmarksPlaceholder];
		if (cell == nil) {
			cell = [[IOS8FixedSeparatorTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:BookmarksPlaceholder];
		}
		cell.backgroundColor = self.tableView.backgroundColor;
		
		cell.textLabel.text = @"No bookmarks yet.".ls;
		cell.textLabel.font = [UIFont systemFontOfSize:15.0f];
		cell.textLabel.textColor = ICMutedTextColor;
		cell.textLabel.textAlignment = NSTextAlignmentCenter;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
        return cell;
    }
    else
    {
        static NSString *CellIdentifier = @"Cell";
        BookmarksTableViewCell *cell = (BookmarksTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[BookmarksTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
        cell.backgroundColor = self.tableView.backgroundColor;
        
        NSDictionary* section = [self.sections objectAtIndex:indexPath.row];
        NSString* hash = [section objectForKey:kBookmarkIndexHash];
        NSArray* myBookmarks = [self.bookmarks objectForKey:hash];
        
        if (self.parentHash)
        {
            // = [self.bookmarks objectForKey:self.parentHash];
            CDBookmark* bookmark = [myBookmarks objectAtIndex:indexPath.row];
            cell.textLabel.text = bookmark.title;
            NSInteger time = MAX(0,bookmark.position);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)(time/3600)%60, (long)(time/60%60), (long)time%60];
            cell.accessoryView.hidden = YES;
            cell.numberLabel.text = nil;
            cell.timeLabel.text = nil;
        }
        
        else
        {
            cell.textLabel.text = [section objectForKey:kBookmarkIndexEpisodeTitle];
            cell.detailTextLabel.text = [section objectForKey:kBookmarkIndexFeedTitle];
            cell.accessoryView.hidden = NO;
            cell.numberLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[myBookmarks count]];
            cell.timeLabel.text = nil;
        }
        
        cell.accessoryIndented = NO;
        cell.imageView.image = [UIImage imageNamed:@"Podcast Placeholder 56"];
        
        CDFeed* feed = [DMANAGER feedWithSourceURL:[section objectForKey:kBookmarkIndexFeedURL]];
        ImageCacheManager* iman = [ImageCacheManager sharedImageCacheManager];
        
        NSURL* imageURL = (feed) ? feed.imageURL : [section objectForKey:kBookmarkIndexImageURL];
        [iman imageForURL:imageURL  size:56 grayscale:NO sender:cell completion:^(UIImage *image) {
            cell.imageView.image = image;
        }];

        return cell;
    }
    
    return nil;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ([self.sections count] > 0);
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self _deleteRows:[NSArray arrayWithObject:indexPath]];
    }
}

#pragma mark - Table view delegate

- (void) _playEpisode:(CDEpisode*)episode withBookmark:(CDBookmark*)bookmark
{
    AudioSession* audioSession = [AudioSession sharedAudioSession];
    PlaybackManager* pman = [PlaybackManager playbackManager];
    
    if ([audioSession.episode isEqual:episode] && pman.ready)
    {
        [pman seekToTime:bookmark.position];
        
        PlaybackViewController* playbackController = [PlaybackViewController playbackViewController];
        [playbackController presentFromParentViewController:self];
    }
    else
    {
        [DMANAGER setEpisode:episode position:bookmark.position];
        PlaybackViewController* playbackController = [PlaybackViewController playbackViewControllerWithEpisode:episode forceReload:YES];
        [playbackController presentFromParentViewController:self];
    }
}

- (void) playBookmark:(CDBookmark*)bookmark section:(NSDictionary*)section
{
    CDEpisode* episode = [DMANAGER episodeWithObjectHash:bookmark.episodeHash];
    
    if (!episode)
    {
        VDModalInfo* modelInfo = [VDModalInfo modalInfoWithProgressLabel:@"Loading…".ls];
        [modelInfo show];
        
        NSString* episodeGuid = [section objectForKey:kBookmarkIndexEpisodeGuid];
        NSURL* feedURL = [section objectForKey:kBookmarkIndexFeedURL];
        
        
        [FeedEpisodeExtraction extractEpisodeWithGuid:episodeGuid fromFeedWithURL:feedURL completion:^(CDEpisode *episode, NSError *error) {
            if (error) {
                [self presentError:error];
                return;
            }

            [self _playEpisode:episode withBookmark:bookmark];
            
            [modelInfo close];
        }];
    }
    
    else {
        [self _playEpisode:episode withBookmark:bookmark];
    }
}

- (void) renameBookmark:(CDBookmark*)bookmark section:(NSDictionary*)section indexPath:(NSIndexPath*)indexPath
{
    WEAK_SELF
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Rename Bookmark".ls
                                                                   message:bookmark.title
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Bookmark title".ls;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Save".ls
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                
                                                NSString* text = self.alertController.textFields.firstObject.text;
                                                
                                                [self perform:^(id sender) {
                                                    
                                                    _userAction = YES;
                                                    bookmark.title = text;
                                                    [DMANAGER save];
                                                    
                                                    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                                                    _userAction = NO;

                                                    
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

- (void) selectBookmark:(CDBookmark*)bookmark section:(NSDictionary*)section indexPath:(NSIndexPath*)indexPath
{
    WEAK_SELF
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Start Playing".ls
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                [self perform:^(id sender) {
                                                    [self playBookmark:bookmark section:section];
                                                } afterDelay:0.3];
                                                [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
                                                self.alertController = nil;
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Rename".ls
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                [self perform:^(id sender) {
                                                    [self renameBookmark:bookmark section:section indexPath:indexPath];
                                                } afterDelay:0.3];
                                                [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
                                                self.alertController = nil;
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel".ls
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
                                                self.alertController = nil;
                                            }]];
    
    self.alertController = alert;
    [self presentAlertControllerAnimated:YES completion:NULL];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.editing && [self.sections count] > 0)
    {
        NSDictionary* section = [self.sections objectAtIndex:indexPath.row];
        
        if (self.parentHash)
        {
            NSArray* myBookmarks = [self.bookmarks objectForKey:self.parentHash];
            CDBookmark* bookmark = [myBookmarks objectAtIndex:indexPath.row];
            
            [self selectBookmark:bookmark section:section indexPath:indexPath];
        }
        
        else
        {
            NSString* hash = [section objectForKey:kBookmarkIndexHash];            
 
            UIBarButtonItem* a = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
            self.navigationItem.backBarButtonItem = a;
            
            NSString* episodeTitle = [section objectForKey:kBookmarkIndexEpisodeTitle];
            
            BookmarksTableViewController* controller = [BookmarksTableViewController bookmarksController];
            controller.parentHash = hash;
            controller.title = episodeTitle;
            [self.navigationController pushViewController:controller animated:YES];

        }
    }
    else
    {
        [self _updateToolbarAnimated:NO];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editing) {
        [self _updateToolbarAnimated:NO];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark -

- (void) setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    [self _updateToolbarAnimated:animated];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark -
#pragma mark Actions

- (void) _deleteRows:(NSArray*)rows
{
    _userAction = YES;
    
    for(NSIndexPath* indexPath in rows)
    {
        if (self.parentHash)
        {
            NSString* hash = self.parentHash;
            NSArray* myBookmarks = [self.bookmarks objectForKey:hash];
            CDBookmark* bookmark = [myBookmarks objectAtIndex:indexPath.row];
            [DMANAGER.objectContext deleteObject:bookmark];
        }
        else
        {
            NSString* hash = [[self.sections objectAtIndex:indexPath.row] objectForKey:kBookmarkIndexHash];
            NSArray* myBookmarks = [self.bookmarks objectForKey:hash];
            
            for(CDBookmark* bookmark in myBookmarks) {
                [DMANAGER.objectContext deleteObject:bookmark];
            }
        }
    }
    [DMANAGER save];
    
    if (self.didDeleteRows) {
        self.didDeleteRows(rows);
    }
    
    [self _reloadBookmarks];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && self.parentHash && [self.sections count] == 1) {
        [self.navigationController popViewControllerAnimated:YES];
    }

    else if ([self.sections count] == 0) {
        [self.tableView reloadRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationFade];
    }
    
    else {
        [self.tableView deleteRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationFade];
    }
    
    _userAction = NO;
}

- (void) deleteAction:(id)sender
{
    NSArray* rows = [self.tableView indexPathsForSelectedRows];
    [self _deleteRows:rows];
}

- (void) playButtonAction:(UIButton*)button
{
    NSDictionary* section = [self.sections objectAtIndex:button.tag];
    
    if (self.parentHash) {
        NSString* hash = self.parentHash;
        NSArray* myBookmarks = [self.bookmarks objectForKey:hash];
        CDBookmark* bookmark = [myBookmarks objectAtIndex:button.tag];
        
        [self playBookmark:bookmark section:section];
    }
    else
    {
        NSString* hash = [section objectForKey:kBookmarkIndexHash];
        NSArray* myBookmarks = [self.bookmarks objectForKey:hash];
        CDBookmark* bookmark = [myBookmarks objectAtIndex:0];
        
        [self playBookmark:bookmark section:section];
    }
}

- (void) editAction:(id)sender
{
    [self setEditing:!self.editing animated:YES];
}


#pragma mark -

- (void) documentInteractionControllerDidDismissOpenInMenu: (UIDocumentInteractionController *) controller
{
    self.interactionController = nil;
}


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:^{
    }];
	
	if (error) {
		[self presentError:error];
	}
}


@end
