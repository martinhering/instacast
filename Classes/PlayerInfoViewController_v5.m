//
//  PlayInfoViewController2.m
//  Instacast
//
//  Created by Martin Hering on 02.08.14.
//
//

#import <objc/runtime.h>

#import "PlayerInfoViewController_v5.h"
#import "ChaptersTableViewCell.h"
#import "PlayerInfoHeaderFooterView.h"
#import "PlayerBookmarksTableViewCell.h"
#import "UIViewController+ShowNotes.h"
#import "EpisodesTableViewCell.h"
#import "PlayerVideoViewController.h"
#import "PlayerView.h"
#import "PlaybackViewController.h"

static NSString* kChapterCell = @"ChapterCell";
static NSString* kBookmarkCell = @"BookmarkCell";
static NSString* kUpNextCell = @"UpNextCell";
static NSString* kHeaderView = @"HeaderView";

enum {
    kChaptersSection = 0,
    kBookmarksSection,
    kUpNextSection,
    kNumberOfSections
};



@interface PlayerInfoViewController_v5 ()
@property (nonatomic, strong, readwrite) UIImageView* imageView;

@property (nonatomic) NSTimeInterval duration;
@property (nonatomic, strong) NSArray* chapters;
@property (nonatomic) NSInteger	currentChapterIndex;
@property (nonatomic, strong) NSArray* bookmarks;
@end


@implementation PlayerInfoViewController_v5 {
    BOOL _observing;
    CGPoint _oldContentOffset;
    CGPoint _oldScrollVelocity;
    BOOL _dismissEnded;
    CGFloat _startY;
    BOOL _didWillAppear;
}

+ (instancetype) viewController {
	return [[self alloc] initWithStyle:UITableViewStylePlain];
}

- (void) dealloc
{
    [self _setObserving:NO];
}

- (void) _setObserving:(BOOL)observing
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    
    if (observing && !_observing)
    {
        __weak PlayerInfoViewController_v5* weakSelf = self;
        
        [pman addTaskObserver:self forKeyPath:@"playingEpisode.duration" task:^(id obj, NSDictionary *change) {
            PlaybackManager* pman = [PlaybackManager playbackManager];
            weakSelf.duration = pman.playingEpisode.duration;
        }];
        
        [pman addTaskObserver:self forKeyPath:@"playingEpisode.chapters" task:^(id obj, NSDictionary *change) {
            PlaybackManager* pman = [PlaybackManager playbackManager];
            weakSelf.chapters = [pman.playingEpisode sortedChapters];
            weakSelf.duration = pman.duration;
        }];
        
        [pman addTaskObserver:self forKeyPath:@"time" task:^(id obj, NSDictionary *change) {
            [weakSelf _updateVisibleCells];
        }];
        
        [pman addTaskObserver:self forKeyPath:@"currentChapter" task:^(id obj, NSDictionary *change) {
            PlaybackManager* pman = [PlaybackManager playbackManager];
            weakSelf.currentChapterIndex = pman.currentChapter;
        }];
        
        [nc addObserver:self selector:@selector(databaseManagerDidAddBookmarkNotification:) name:DatabaseManagerDidAddBookmarkNotification object:nil];
         
        _observing = YES;
    }
    else if (!observing && _observing)
    {
        [pman removeTaskObserver:self forKeyPath:@"playingEpisode.duration"];
        [pman removeTaskObserver:self forKeyPath:@"playingEpisode.chapters"];
        [pman removeTaskObserver:self forKeyPath:@"time"];
        [pman removeTaskObserver:self forKeyPath:@"currentChapter"];
        
        [nc removeObserver:self];
        
        _observing = NO;
    }
}

- (void) databaseManagerDidAddBookmarkNotification:(NSNotification*)notification
{
    [self reloadBookmarks];
    [self.tableView reloadData];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.bottomScrollInset = self.navigationController.toolbarHidden?0:44;
    
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.allowsSelectionDuringEditing = YES;
    if (@available(iOS 11.0, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.tableView registerClass:[ChaptersTableViewCell class] forCellReuseIdentifier:kChapterCell];
    [self.tableView registerClass:[PlayerBookmarksTableViewCell class] forCellReuseIdentifier:kBookmarkCell];
    [self.tableView registerClass:[EpisodesTableViewCell class] forCellReuseIdentifier:kUpNextCell];
    [self.tableView registerClass:[PlayerInfoHeaderFooterView class] forHeaderFooterViewReuseIdentifier:kHeaderView];
    
    UIImage* placeholder = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? [UIImage imageNamed:@"Podcast Placeholder 580"] : [UIImage imageNamed:@"Podcast Placeholder 320"];
    self.imageView = [[UIImageView alloc] initWithImage:(self.image) ? self.image : placeholder];
    
    [self reloadData];
    
    [self _setObserving:YES];
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    _didWillAppear = YES;
    
    self.tableView.backgroundColor = ICBackgroundColor;
    self.tableView.separatorColor = ICTableSeparatorColor;
    
    [self layoutHeaderView];
    
    [self.tableView reloadData];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _didWillAppear = NO;
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (_didWillAppear) {
        if (!IS_IOS11) {
            
            // xxx: hard coded content Insets, because of rotation issues
            UIEdgeInsets edgeInsets = UIEdgeInsetsMake(20+44, 0, self.bottomScrollInset, 0);
            
            self.tableView.contentInset = edgeInsets;
            self.tableView.scrollIndicatorInsets = edgeInsets;
            if (CGPointEqualToPoint(self.tableView.contentOffset, CGPointZero)) {
                self.tableView.contentOffset = CGPointMake(0,-edgeInsets.top);
            }
        }
        else
        {
            UIEdgeInsets safeAreaInsets = UIEdgeInsetsMake(20+44, 0, 0, 0);
            if (@available(iOS 11.0, *)) {
                safeAreaInsets = self.view.safeAreaInsets;
            }
            
            UIEdgeInsets edgeInsets = UIEdgeInsetsMake(safeAreaInsets.top, 0, self.bottomScrollInset, 0);
            
            self.tableView.contentInset = edgeInsets;
            self.tableView.scrollIndicatorInsets = edgeInsets;
            self.tableView.contentOffset = CGPointMake(0, -safeAreaInsets.top);
        }
    }
}

- (void) layoutHeaderView
{
    CGRect b = self.view.bounds;
    
    if (self.videoViewController)
    {
        UIView* playerView = self.videoViewController.view;
        CGSize videoSize = self.videoViewController.videoSize;
        
        CGFloat aspectRatio = videoSize.width / videoSize.height;
        CGFloat viewAspectRatio = CGRectGetWidth(b) / CGRectGetHeight(b);
        
        // xxx: landscape hack for iOS 8
        if (viewAspectRatio > 1) {
            playerView.frame = CGRectMake(0, 0, CGRectGetHeight(b), floorf(CGRectGetHeight(b)/aspectRatio));
        } else {
            playerView.frame = CGRectMake(0, 0, CGRectGetWidth(b), floorf(CGRectGetWidth(b)/aspectRatio));
        }
        
        self.tableView.tableHeaderView = playerView;
    } else {
        self.imageView.frame = CGRectMake(0, 0, CGRectGetWidth(b), CGRectGetWidth(b));
        self.tableView.tableHeaderView = self.imageView;
    }
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    _oldContentOffset = self.tableView.contentOffset;
}

- (void) reloadData
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    self.chapters = [pman.playingEpisode sortedChapters];
    self.currentChapterIndex = pman.currentChapter;
    self.duration = pman.playingEpisode.duration;
    
    [self reloadBookmarks];
}

- (void) reload
{
    [self reloadData];
    [self.tableView reloadData];
    
    PlaybackManager* pman = [PlaybackManager playbackManager];
    BOOL movingVideo = pman.movingVideo;
    
    PlayerView* playerView = pman.playerView;
    
    if (playerView && movingVideo)
    {
        playerView.transform = CGAffineTransformIdentity;
        
        PlayerVideoViewController* videoViewController = self.videoViewController;
        
        if (!videoViewController) {
            videoViewController = [PlayerVideoViewController viewController];
        }
        
        videoViewController.playerView = playerView;
        videoViewController.videoSize = pman.viewImageSize;
        
        if (!self.videoViewController) {
            self.videoViewController = videoViewController;
        }
    }
    else if (self.videoViewController)
    {
        self.videoViewController = nil;
    }
    
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 10, 10) animated:YES];
}

- (void) tintColorDidChange
{
    [self.tableView reloadData];
}

- (void) reloadBookmarks
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Bookmark" inManagedObjectContext:DMANAGER.objectContext];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"episodeHash == %@", pman.playingEpisode.objectHash];
    fetchRequest.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"position" ascending:YES] ];
    
    self.bookmarks = [DMANAGER.objectContext executeFetchRequest:fetchRequest error:nil];
}


- (void) setChapters:(NSArray *)chapters
{
    if (_chapters != chapters) {
        _chapters = chapters;
        [self.tableView reloadData];
    }
}

- (void) setVideoViewController:(PlayerVideoViewController *)videoViewController
{
    if (_videoViewController != videoViewController)
    {
        PlayerVideoViewController* oldController = _videoViewController;
    
        _videoViewController = videoViewController;
        
        if (videoViewController) {
            [self addChildViewController:videoViewController];
            [self layoutHeaderView];
            [videoViewController didMoveToParentViewController:self];
        }
        else
        {            
            [oldController willMoveToParentViewController:nil];
            [self layoutHeaderView];
            [oldController removeFromParentViewController];
        }
    }
}


#pragma mark -

- (void) setImage:(UIImage *)image {
    if (_image != image) {
        _image = image;
        self.imageView.image = image;
    }
}

#pragma mark -

- (void) _updateVisibleCells
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    
    for(NSIndexPath* indexPath in self.tableView.indexPathsForVisibleRows)
    {
        ChaptersTableViewCell* cell = (ChaptersTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        if ([cell isKindOfClass:[ChaptersTableViewCell class]])
        {
            if (indexPath.row == pman.currentChapter) {
                cell.textLabel.textColor = self.view.tintColor;
                cell.numLabel.textColor = self.view.tintColor;
                cell.timeLabel.textColor = self.view.tintColor;
            }
            else
            {
                cell.textLabel.textColor = (indexPath.row <= pman.currentChapter) ? ICMutedTextColor : ICTextColor;
                cell.numLabel.textColor = ICMutedTextColor;
                cell.timeLabel.textColor = ICMutedTextColor;
            }
            
            BOOL hidden = (pman.currentChapter != indexPath.row);
            BOOL changed = (cell.progressView.hidden != hidden);
            cell.progressView.hidden = hidden;
            [cell.progressView setProgress:((pman.time - cell.objectValue.timecode) / cell.objectValue.duration) animated:(!hidden && !changed)];
        }
    }
}

- (BOOL) _hasChapters {
    return ([self.chapters count] > 0);
}

- (BOOL) _hasBookmarks {
    return ([self.bookmarks count] > 0);
}

- (BOOL) _hasUpNext {
    return ([[AudioSession sharedAudioSession].playlist count] > 0);
}

- (NSInteger) _chaptersSection {
    return 0;
}

- (NSInteger) _bookmarksSection {
    return 1;
}

- (NSInteger) _upNextSection {
    return 2;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

#pragma mark -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self _hasChapters] && section == [self _chaptersSection]) {
        return [self.chapters count];
    }
    else if ([self _hasBookmarks] && section == [self _bookmarksSection]) {
        return [self.bookmarks count];
    }
    else if ([self _hasUpNext] && section == [self _upNextSection]) {
        return [[AudioSession sharedAudioSession].playlist count];
    }
    return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    
    if ([self _hasChapters] && indexPath.section == [self _chaptersSection])
    {
        ChaptersTableViewCell* cell = (ChaptersTableViewCell*)[tableView dequeueReusableCellWithIdentifier:kChapterCell forIndexPath:indexPath];
        cell.backgroundColor = self.tableView.backgroundColor;
        
        CDChapter* chapter = [self.chapters objectAtIndex:indexPath.row];
        cell.objectValue = chapter;

        
        if (indexPath.row == pman.currentChapter) {
            cell.textLabel.textColor = self.view.tintColor;
            cell.numLabel.textColor = self.view.tintColor;
            cell.timeLabel.textColor = self.view.tintColor;
        }
        else {
            cell.textLabel.textColor = (indexPath.row <= pman.currentChapter) ? ICMutedTextColor : ICTextColor;
            cell.numLabel.textColor = ICMutedTextColor;
            cell.timeLabel.textColor = ICMutedTextColor;
        }
        
        cell.progressView.hidden = (pman.currentChapter != indexPath.row);
        cell.progressView.progress = 0;
        cell.progressView.tintColor = self.view.tintColor;
        cell.progressView.progress = (pman.time - chapter.timecode) / chapter.duration;
        
        NSArray* actions = [cell.linkButton actionsForTarget:self forControlEvent:UIControlEventValueChanged];
        for(NSString* action in actions) {
            [cell.linkButton removeTarget:self action:NSSelectorFromString(action) forControlEvents:UIControlEventTouchUpInside];
        }
        
        [cell.linkButton setAssociatedObject:chapter forKey:@"__chapter"];
        [cell.linkButton addTarget:self action:@selector(handleChapterLinkButton:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
    else if ([self _hasBookmarks] && indexPath.section == [self _bookmarksSection])
    {
        PlayerBookmarksTableViewCell* cell = (PlayerBookmarksTableViewCell*)[tableView dequeueReusableCellWithIdentifier:kBookmarkCell forIndexPath:indexPath];
        cell.backgroundColor = self.tableView.backgroundColor;
        
        CDBookmark* bookmark = [self.bookmarks objectAtIndex:indexPath.row];
        
        cell.textLabel.text = bookmark.title;
        
        NSInteger time = bookmark.position;
        cell.timeLabel.text = [NSString stringWithFormat:@"%ld:%02ld:%02ld", (long)(time/3600)%60, (long)(time/60%60), (long)time%60];
        
        return cell;
    }
    
    if ([self _hasUpNext] && indexPath.section == [self _upNextSection])
    {
        EpisodesTableViewCell* cell = (EpisodesTableViewCell*)[tableView dequeueReusableCellWithIdentifier:kUpNextCell forIndexPath:indexPath];
        cell.backgroundColor = self.tableView.backgroundColor;
        
        CDEpisode* episode = [AudioSession sharedAudioSession].playlist[indexPath.row];
        cell.embedded = YES;
        cell.panRecognizer.enabled = NO;
        cell.objectValue = episode;

        return cell;
    }
    
    return nil;
}

- (void) handleChapterLinkButton:(UIButton*)sender
{
    CDChapter* chapter = [sender associatedObjectForKey:@"__chapter"];
    [self handleShowNotesURL:chapter.linkURL];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self _hasBookmarks] && indexPath.section == [self _bookmarksSection]) {
        return YES;
    }
    
    if ([self _hasUpNext] && indexPath.section == [self _upNextSection]) {
        return YES;
    }
    
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        if ([self _hasBookmarks] && indexPath.section == [self _bookmarksSection])
        {
            CDBookmark* bookmark = [self.bookmarks objectAtIndex:indexPath.row];
            
            NSMutableArray* newBookmarks = [self.bookmarks mutableCopy];
            [newBookmarks removeObject:bookmark];
            self.bookmarks = newBookmarks;
            
            [DMANAGER removeBookmark:bookmark];
            
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
        }
        
        else if ([self _hasUpNext] && indexPath.section == [self _upNextSection])
        {
            CDEpisode* episode = [AudioSession sharedAudioSession].playlist[indexPath.row];
            
            [[AudioSession sharedAudioSession] eraseEpisodesFromUpNext:@[episode]];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self _hasUpNext] && indexPath.section == [self _upNextSection])
    {
        return YES;
    }
    
    return NO;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [[AudioSession sharedAudioSession] reorderUpNextEpisodeFromIndex:fromIndexPath.row toIndex:toIndexPath.row];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self _hasChapters] && indexPath.section == [self _chaptersSection])
    {
        CDChapter* chapter = [self.chapters objectAtIndex:indexPath.row];
        return [ChaptersTableViewCell proposedHeightWithTitle:chapter.title tableBounds:self.tableView.bounds];
    }
    else if ([self _hasBookmarks] && indexPath.section == [self _bookmarksSection])
    {
        CDBookmark* bookmark = [self.bookmarks objectAtIndex:indexPath.row];
        return [PlayerBookmarksTableViewCell proposedHeightWithTitle:bookmark.title tableBounds:self.tableView.bounds];
    }
    else if ([self _hasUpNext] && indexPath.section == [self _upNextSection])
    {
        CDEpisode* episode = [AudioSession sharedAudioSession].playlist[indexPath.row];
        return [EpisodesTableViewCell proposedHeightWithObjectValue:episode tableSize:self.tableView.bounds.size imageSize:CGSizeZero embedded:YES editing:self.editing];
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    PlayerInfoHeaderFooterView* headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kHeaderView];
    
    headerView.editButton.tintColor = self.view.tintColor;
    headerView.doneButton.tintColor = self.view.tintColor;

    NSArray* actions = [headerView.editButton actionsForTarget:self forControlEvent:UIControlEventValueChanged];
    for(NSString* action in actions) {
        [headerView.editButton removeTarget:self action:NSSelectorFromString(action) forControlEvents:UIControlEventTouchUpInside];
    }
    
    actions = [headerView.doneButton actionsForTarget:self forControlEvent:UIControlEventValueChanged];
    for(NSString* action in actions) {
        [headerView.doneButton removeTarget:self action:NSSelectorFromString(action) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if ([self _hasChapters] && section == [self _chaptersSection])
    {
        headerView.textLabel.text = @"Chapters".ls;
        headerView.canEdit = NO;
    }
    else if ([self _hasBookmarks] && section == [self _bookmarksSection])
    {
        headerView.textLabel.text = @"Bookmarks".ls;
        headerView.canEdit = YES;
    }
    else if ([self _hasUpNext] && section == [self _upNextSection])
    {
        headerView.textLabel.text = @"Up Next".ls;
        headerView.canEdit = YES;
    }
    
    if (headerView.canEdit)
    {
        [headerView.editButton setAssociatedObject:headerView forKey:@"__headerView"];
        [headerView.editButton addTarget:self action:@selector(handleHeaderViewEditButton:) forControlEvents:UIControlEventTouchUpInside];
        
        [headerView.doneButton setAssociatedObject:headerView forKey:@"__headerView"];
        [headerView.doneButton addTarget:self action:@selector(handleHeaderViewDoneButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return headerView;
}

- (void) handleHeaderViewEditButton:(UIButton*)button
{
    PlayerInfoHeaderFooterView* headerView = [button associatedObjectForKey:@"__headerView"];
    [headerView setEditing:YES animated:YES];
    [self setEditing:YES animated:YES];
}

- (void) handleHeaderViewDoneButton:(UIButton*)button
{
    PlayerInfoHeaderFooterView* headerView = [button associatedObjectForKey:@"__headerView"];
    [headerView setEditing:NO animated:YES];
    [self setEditing:NO animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self _hasChapters] && section == [self _chaptersSection]) {
        return 44;
    }
    else if ([self _hasBookmarks] && section == [self _bookmarksSection]) {
        return 44;
    }
    else if ([self _hasUpNext] && section == [self _upNextSection]) {
        return 44;
    }
    
    return 0;
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    
    if ([self _hasChapters] && indexPath.section == [self _chaptersSection])
    {
        CDChapter* chapter = [self.chapters objectAtIndex:indexPath.row];
        
        NSArray* playbackChapters = pman.chapters;
        ICMetadataChapter* playbackChapter = playbackChapters[chapter.index];
        [pman seekToChapter:playbackChapter];
        [pman play];
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else if ([self _hasBookmarks] && indexPath.section == [self _bookmarksSection])
    {
        CDBookmark* bookmark = [self.bookmarks objectAtIndex:indexPath.row];
        
        if (self.editing)
        {
            WEAK_SELF
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Edit Bookmark".ls
                                                                           message:bookmark.title
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = @"Bookmark title".ls;
                textField.text = bookmark.title;
            }];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Save".ls
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action) {
                                                        STRONG_SELF
                                                        
                                                        NSString* text = self.alertController.textFields.firstObject.text;
                                                        
                                                        [self perform:^(id sender) {

                                                            bookmark.title = text;
                                                            [DMANAGER save];
                                                            
                                                            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];

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
        else
        {
            NSTimeInterval time = bookmark.position;
            [pman seekToTime:time];
            [pman play];
            
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
    
    else if ([self _hasUpNext] && indexPath.section == [self _upNextSection])
    {
        CDEpisode* episode = [AudioSession sharedAudioSession].playlist[indexPath.row];
        
        AudioSession* audioSession = [AudioSession sharedAudioSession];
        [audioSession playEpisode:episode];
    }
}

#pragma mark -

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (IS_IOS11) {
        return;
    }

    CGFloat topOffset = scrollView.contentInset.top;
    CGFloat yOffset = scrollView.contentOffset.y + topOffset;
    UIPanGestureRecognizer* recognizer = scrollView.panGestureRecognizer;
    CGPoint translation = [recognizer translationInView:scrollView];
    CGPoint velocity = [recognizer velocityInView:scrollView];
    
    PlaybackViewController* navigationController = (PlaybackViewController*)self.navigationController;
    
    if (yOffset <= 0 && [recognizer state] == UIGestureRecognizerStateChanged)
    {
        if (!navigationController.interactive) {
            [navigationController beginInteractiveDismissing];
            scrollView.showsVerticalScrollIndicator = NO;
            _dismissEnded = NO;
            _startY = translation.y;
        }
        
        translation.y -= _startY;
        [navigationController.dismissalAnimator _driveTransitionWithTranslation:translation velocity:velocity recognizerState:recognizer.state];
        
        scrollView.transform = CGAffineTransformMakeTranslation(0, yOffset);
        _oldScrollVelocity = velocity;
    }
    else
    {
        if (navigationController.interactive) {
            [navigationController.dismissalAnimator _driveTransitionWithTranslation:translation velocity:_oldScrollVelocity recognizerState:UIGestureRecognizerStateEnded];
        
            scrollView.showsVerticalScrollIndicator = YES;
            _dismissEnded = YES;
            _startY = 0;
        }
        
        if (_dismissEnded)
        {
            if (yOffset < 0) {
                scrollView.transform = CGAffineTransformMakeTranslation(0, yOffset);
                scrollView.bounces = NO;
            }
            else {
                scrollView.transform = CGAffineTransformIdentity;
                scrollView.bounces = YES;
                _dismissEnded = NO;
            }
        }
    }
}
@end
