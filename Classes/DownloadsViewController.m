//
//  DownloadsViewController.m
//  Instacast
//
//  Created by Martin Hering on 22.10.11.
//  Copyright (c) 2011 Vemedio. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "DownloadsViewController.h"

#import "DownloadsTableViewCell.h"
#import "CDModel.h"
#import "CDEpisode+ShowNotes.h"
#import "EpisodePlayComboButton.h"

@interface DownloadsViewController ()
@property (nonatomic, strong) UIView* functionOverlayView;
@property (nonatomic, strong) UILabel* captionLabel;
@property (nonatomic, strong) UIButton* pauseButton;
@end

@implementation DownloadsViewController {
    BOOL _observing;
    BOOL _userAction;
}

+ (DownloadsViewController*) downloadsViewController
{
    return [[self alloc] initWithStyle:UITableViewStylePlain];
}

- (void) dealloc
{
    [self _setObserving:NO];
}


#pragma mark - View lifecycle

- (void) _setObserving:(BOOL)observing
{
    if (observing && !_observing)
    {
        __weak DownloadsViewController* weakSelf = self;
        
        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self name:CacheManagerDidUpdateNotification object:nil handler:^(NSNotification *notification) {
            NSArray* indexPaths = [weakSelf.tableView indexPathsForVisibleRows];
            NSArray* cachingEpisodes = [[CacheManager sharedCacheManager] cachingEpisodes];
            
            for(NSIndexPath* indexPath in indexPaths)
            {
                if (indexPath.row >= [cachingEpisodes count]) {
                    continue;
                }
                
                DownloadsTableViewCell* cell = (DownloadsTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
                if ([cell isKindOfClass:[DownloadsTableViewCell class]])
                {
                    CDEpisode* episode = [cachingEpisodes objectAtIndex:indexPath.row];
                    [weakSelf _updateCellProgress:cell withEpisode:episode];
                }
            }
            
            [weakSelf _updateCaption];
            [weakSelf _updateToolbar];
        }];
        
        [[CacheManager sharedCacheManager] addTaskObserver:self forKeyPath:@"cachingEpisodes" task:^(id obj, NSDictionary *change) {
            if (!_userAction) {
                [weakSelf.tableView reloadData];
            }
        }];
        
        [nc addObserver:self name:CacheManagerDidEndCachingNotification object:nil handler:^(NSNotification *notification) {
            [weakSelf _updateCaption];
            [weakSelf dismissViewControllerAnimated:YES completion:NULL];
        }];
        
    }
    else if (!observing && _observing)
    {
        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        [nc removeHandlerForObserver:self name:CacheManagerDidUpdateNotification object:nil];
        [nc removeHandlerForObserver:self name:CacheManagerDidEndCachingNotification object:nil];

        [[CacheManager sharedCacheManager] removeTaskObserver:self forKeyPath:@"cachingEpisodes"];
    }
    
    _observing = observing;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.rowHeight = 70;
    
    self.navigationItem.title = @"Downloads".ls;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;

    UIBarButtonItem* flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem* pauseItem = [[UIBarButtonItem alloc] initWithTitle:@"Pause".ls
                                                                  style:UIBarButtonItemStylePlain target:self action:@selector(toggleLoading:)];
    
    UIBarButtonItem* cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel All".ls
                                                                  style:UIBarButtonItemStylePlain target:self action:@selector(cancelAllDownloads:)];
    
    
    UILabel* captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 4, 150, 40)];
    captionLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    captionLabel.font = [UIFont systemFontOfSize:11];
    captionLabel.textColor = [UIColor colorWithWhite:0.5f alpha:1.f];
    captionLabel.textAlignment = NSTextAlignmentCenter;
    self.captionLabel = captionLabel;
    
    UIView* captionContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 150, 44)];
    [captionContainer addSubview:captionLabel];

    UIBarButtonItem* captionButtonItem = [[UIBarButtonItem alloc] initWithCustomView:captionContainer];
    
    [self setToolbarItems:@[pauseItem, flexSpace, captionButtonItem, flexSpace, cancelItem]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setScrollView:self.tableView contentInsets:UIEdgeInsetsZero byAdjustingForStandardBars:YES];
    
    self.tableView.backgroundColor = ICBackgroundColor;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.separatorColor = ICTableSeparatorColor;
    [self.tableView reloadData];
    
    [self _setObserving:YES];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self _loadImagesForOnscreenRows];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[ImageCacheManager sharedImageCacheManager] cancelImageCacheOperationsWithSender:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self _setObserving:NO];
}


#pragma mark -


- (void) _updateCellProgress:(DownloadsTableViewCell*)cell withEpisode:(CDEpisode*)episode
{
	CacheManager* cman = [CacheManager sharedCacheManager];
	
	double progress = [cman cacheProgressForEpisode:episode];
	cell.progressView.progress = progress;
	
	NSTimeInterval timeLeft = [cman cacheTimeLeftForEpisode:episode];
	
	long long expectedContentLength = [cman expectedContentLengthForEpisode:episode];
	long long loadedContentLength = expectedContentLength*progress;
	
	if ([cman isLoadingEpisodeSuspended:episode]) {
		cell.sizeLabel.text = @"Paused…".ls;
        cell.playAccessoryButton.comboState = kEpisodePlayButtonComboStateHolding;
	}
    else if (![cman isLoadingEpisode:episode]) {
		cell.sizeLabel.text = @"Waiting to download…".ls;
        cell.playAccessoryButton.comboState = kEpisodePlayButtonComboStateHolding;
	}
	else if (loadedContentLength == 0) {
		cell.sizeLabel.text = @"Loading…".ls;
        cell.playAccessoryButton.comboState = kEpisodePlayButtonComboStateFilling;
	}
    else {
		cell.sizeLabel.text = [NSString stringWithFormat:@"%@ of %@".ls, [NSByteCountFormatter stringFromByteCount:loadedContentLength countStyle:NSByteCountFormatterCountStyleFile], [NSByteCountFormatter stringFromByteCount:expectedContentLength countStyle:NSByteCountFormatterCountStyleFile]];
        cell.playAccessoryButton.comboState = kEpisodePlayButtonComboStateFilling;
	}
	
	NSString* timeString = nil;
	if (timeLeft > 0 && expectedContentLength > 0) {
        NSString* time = [NSString stringWithFormat:@"%ld:%02ld", (long)timeLeft/60, (long)timeLeft%60];
		timeString = [NSString stringWithFormat:@"%@ left".ls, time];
	}
	NSString* prevTimeString = cell.timeLabel.text;
	cell.timeLabel.text = (loadedContentLength == 0) ? nil : timeString;
	
	// change layout if time label content changed
	if ((prevTimeString && !timeString) || (!prevTimeString && timeString)) {
		[cell setNeedsLayout];
	}
}

- (void) _updateToolbar
{
    UIBarButtonItem* pauseItem = self.toolbarItems[0];
    
    if ([[CacheManager sharedCacheManager] isCachingSuspended]) {
        pauseItem.title = @"Resume".ls;
    } else {
        pauseItem.title = @"Pause".ls;
    }
}

- (void) _updateCaption
{
    if (!self.captionLabel) {
        return;
    }
    
    CacheManager* cman = [CacheManager sharedCacheManager];
    
    if ([cman isCachingSuspended])
    {
        if (![self.captionLabel.layer animationForKey:@"pulseAnimation"]) {
            CABasicAnimation* pulseAnimation = [CABasicAnimation animation];
            pulseAnimation.keyPath = @"opacity";
            pulseAnimation.fromValue = [NSNumber numberWithFloat: 1.0];
            pulseAnimation.toValue = [NSNumber numberWithFloat: 0.0];
            pulseAnimation.duration = 0.75;
            pulseAnimation.repeatCount = MAXFLOAT;
            pulseAnimation.autoreverses = YES;
            pulseAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            [self.captionLabel.layer addAnimation:pulseAnimation forKey:@"pulseAnimation"];
        }
        
        self.captionLabel.text = @"Downloads paused".ls;
    }
    else
    {
        if ([self.captionLabel.layer animationForKey:@"pulseAnimation"]) {
            [self.captionLabel.layer removeAllAnimations];
            self.captionLabel.layer.opacity = 1.0f;
        }
        
        if ([cman isCaching])
        {
            double rate = cman.rate;

            if (rate > 1024) {
                NSString* rateString = [NSByteCountFormatter stringFromByteCount:(long long)rate countStyle:NSByteCountFormatterCountStyleMemory];
                self.captionLabel.text = [NSString stringWithFormat:@"%@/s", rateString];
            }
            else if (rate == 0) {
                self.captionLabel.text = nil;
            }
        }
        else {
            self.captionLabel.text = nil;
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    CacheManager* cman = [CacheManager sharedCacheManager];
    
    if (section == 0) {
        return [[cman cachingEpisodes] count];
    }
    
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CacheManager* cman = [CacheManager sharedCacheManager];
    
    if (indexPath.section == 0)
    {
        static NSString *CellIdentifier = @"DownloadsEpisodesCachingCell";
        
        DownloadsTableViewCell *cell = (DownloadsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[DownloadsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            [cell.playAccessoryButton addTarget:self action:@selector(cancelCachingEpisode:) forControlEvents:UIControlEventTouchUpInside];
        }
        cell.backgroundColor = tableView.backgroundColor;
        
        NSArray* episodes = [cman cachingEpisodes];
        CDEpisode* episode = [episodes objectAtIndex:indexPath.row];
        CDFeed* feed = episode.feed;
        
        cell.tag = indexPath.row;
        
        // make sure the feed title is not repeated in episode title
        NSString* title = [episode cleanTitleUsingFeedTitle:feed.title];
        
        cell.textLabel.text = title;
        cell.accessoryView = cell.playAccessoryButton;
        
        UIButton* accessoryButton = (UIButton*)cell.accessoryView;
        accessoryButton.tag = indexPath.row;
        
        cell.imageView.tag = 0;
        cell.imageView.image = [UIImage imageNamed:@"Podcast Placeholder 56"];
        NSURL* imageURL = (episode.imageURL) ? episode.imageURL : episode.feed.imageURL;
        
        ImageCacheManager* iman = [ImageCacheManager sharedImageCacheManager];
        [iman imageForURL:imageURL size:56 grayscale:NO sender:self completion:^(UIImage *image) {
            if (image) {
                cell.imageView.image = image;
                cell.imageView.tag = 1;
            }
        }];

        
        [self _updateCellProgress:cell withEpisode:episode];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
        
        return cell;
    }
    
    
    return nil;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return (indexPath.section == 0);
}


// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == 0);
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    _userAction = YES;
    [[CacheManager sharedCacheManager] reorderCachingEpisodeFromIndex:fromIndexPath.row toIndex:toIndexPath.row];
    _userAction = NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - Table view delegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark Actions

- (void) cancelCachingEpisode:(UIButton*)button
{
    CacheManager* cman = [CacheManager sharedCacheManager];
    
	NSInteger index = button.tag;
    NSArray* episodes = [cman cachingEpisodes];
    
    if ([episodes count] > index) {
        CDEpisode* episode = [episodes objectAtIndex:index];
        [cman cancelCachingEpisode:episode disableAutoDownload:YES];
    }
}

- (void) cancelAllDownloads:(id)sender
{
    CacheManager* cman = [CacheManager sharedCacheManager];
    NSArray* cachingEpisode = [cman cachingEpisodes];
    for(CDEpisode* episode in [cachingEpisode copy]) {
        [cman cancelCachingEpisode:episode disableAutoDownload:YES];
    }
}

- (void) toggleEditing:(id)sender
{
    [self setEditing:!self.editing animated:YES];
    [self _updateToolbar];
}

- (void) toggleLoading:(id)sender
{
    CacheManager* cman = [CacheManager sharedCacheManager];
    
    if ([cman isCachingSuspended]) {
        [cman resumeCaching];
    }
    else {
        [cman pauseCaching];
    }
    [self _updateToolbar];
    [self _updateCaption];
}

#pragma mark -
#pragma mark ScrollView Delegate

- (void) _loadImagesForOnscreenRows
{
    [[ImageCacheManager sharedImageCacheManager] cancelImageCacheOperationsWithSender:self];
    
	NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
	for (NSIndexPath *indexPath in visiblePaths)
	{
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
        
        if (cell.imageView.tag == 0)
        {
            CacheManager* cman = [CacheManager sharedCacheManager];
            
            NSArray* episodes = [cman cachingEpisodes];
            CDEpisode* episode = [episodes objectAtIndex:indexPath.row];
            
            NSURL* imageURL = (episode.imageURL) ? episode.imageURL : episode.feed.imageURL;
            
            ImageCacheManager* iman = [ImageCacheManager sharedImageCacheManager];
            [iman imageForURL:imageURL size:56 grayscale:NO sender:self completion:^(UIImage *image) {
                if (image) {
                    cell.imageView.image = image;
                    cell.imageView.tag = 1;
                }
            }];
        }
	}
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [[ImageCacheManager sharedImageCacheManager] cancelImageCacheOperationsWithSender:self];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if (!decelerate) {
        [self _loadImagesForOnscreenRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self _loadImagesForOnscreenRows];
}
@end
