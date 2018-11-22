//
//  MediaFilesViewController.m
//  Instacast
//
//  Created by Martin Hering on 24.10.12.
//
//

#import "MediaFilesViewController.h"
#import "UIManager.h"

#import "VDModalInfo.h"
#import "CDEpisode+ShowNotes.h"
#import "ValuesTableViewController.h"
#import "UITableViewController+Settings.h"

enum {
    kLimitSettingSection = 0,
    kAutoDownloadSettingsSection,
    kAutoDeleteSettingsSection,
    kDownloadedSection,
    kDeleteAllButton,
    kNumberOfSections
};

static NSString *CellIdentifier = @"Cell";
static NSString* PlaceholderCellIdentifier = @"PlaceholderCell";
static NSString* SettingCellIdentifier = @"SettingCell";

@interface MediaFilesViewController () <UIDocumentInteractionControllerDelegate>
@property (nonatomic, strong) NSArray* cachedEpisodes;
@property (nonatomic, strong) UIDocumentInteractionController* interactionController;
@end

@implementation MediaFilesViewController

+ (id) viewController
{
    return [[self alloc] initWithStyle:UITableViewStyleGrouped];
}

- (void) _reloadContent
{
    NSSortDescriptor* feedDescriptor = [[NSSortDescriptor alloc] initWithKey:@"feed.title" ascending:YES];
    NSSortDescriptor* titleDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    self.cachedEpisodes = [[[CacheManager sharedCacheManager] cachedEpisodes] sortedArrayUsingDescriptors:@[feedDescriptor, titleDescriptor]];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setScrollView:self.tableView contentInsets:UIEdgeInsetsZero byAdjustingForStandardBars:YES];
    
    self.clearsSelectionOnViewWillAppear = YES;
    self.navigationItem.title = @"Offline Storage".ls;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tableView.backgroundColor = ICBackgroundColor;
    self.tableView.separatorColor = ICGroupCellSelectedBackgroundColor;
    
    [[CacheManager sharedCacheManager] autoClearAndMakeRoomForBytes:0 automatic:YES];
    [self _reloadContent];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case kLimitSettingSection:
            return 1;
        case kAutoDownloadSettingsSection:
            return 2;
        case kAutoDeleteSettingsSection:
            return 2;
        case kDownloadedSection:
            return MAX(1,[self.cachedEpisodes count]);
        case kDeleteAllButton:
            return 1;
        default:
            break;
    }

    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kDeleteAllButton)
    {
        UITableViewCell* cell = [self resetCell];
        cell.userInteractionEnabled = YES;
        cell.textLabel.text = @"Delete Content".ls;
        return cell;
    }
    
    else if (indexPath.section == kLimitSettingSection)
    {
        UITableViewCell *cell = [self detailCell];
        
        if (indexPath.row == 0) {
            long long limit = [USER_DEFAULTS integerForKey:AutoCacheStorageLimit];
            
            cell.textLabel.text = @"Storage Limit".ls;
            
            if (limit == 0) {
                cell.detailTextLabel.text = @"No Limit".ls;
            }
            else {
                cell.detailTextLabel.text = [NSByteCountFormatter stringFromByteCount:limit*1024LL*1024LL countStyle:NSByteCountFormatterCountStyleMemory];
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        
        return cell;
    }
    
    else if (indexPath.section == kAutoDownloadSettingsSection)
    {
        UITableViewCell* cell = [self switchCell];
        UISwitch* control = (UISwitch*)cell.accessoryView;
        
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Audio Content".ls;
                control.on = [USER_DEFAULTS boolForKey:AutoCacheNewAudioEpisodes];
                break;
            case 1:
                cell.textLabel.text = @"Video Content".ls;
                control.on = [USER_DEFAULTS boolForKey:AutoCacheNewVideoEpisodes];
                break;
            default:
                break;
        }
        
        control.tag = indexPath.row;
        [control addTarget:self action:@selector(toggleDownloadSettings:) forControlEvents:UIControlEventValueChanged];
        
        return cell;
    }
    
    else if (indexPath.section == kAutoDeleteSettingsSection)
    {
        UITableViewCell* cell = [self switchCell];
        UISwitch* control = (UISwitch*)cell.accessoryView;
        
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Finished Playing".ls;
            control.on = [USER_DEFAULTS boolForKey:AutoDeleteAfterFinishedPlaying];
        }
        else if (indexPath.row == 1) {
            cell.textLabel.text = @"Marked as Played".ls;
            control.on = [USER_DEFAULTS boolForKey:AutoDeleteAfterMarkedAsPlayed];
        }
        
        control.tag = indexPath.row;
        [control addTarget:self action:@selector(toggleAutoDeleteSettings:) forControlEvents:UIControlEventValueChanged];
        
        return cell;
    }
    
    else if (indexPath.section == kDownloadedSection)
    {
        
        NSArray* episodes = self.cachedEpisodes;
        

        if ([episodes count] == 0)
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PlaceholderCellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:PlaceholderCellIdentifier];
                cell.backgroundColor = ICGroupCellBackgroundColor;
            }
            
            cell.accessoryView = nil;
            cell.textLabel.text = @"Nothing downloaded yet.".ls;
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.font = [UIFont italicSystemFontOfSize:15];
            cell.textLabel.textColor = ICMutedTextColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            return cell;
        }
        else
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
                cell.selectedBackgroundView = [[UIView alloc] init];
                cell.textLabel.font = [UIFont systemFontOfSize:13];
                cell.detailTextLabel.font = [UIFont systemFontOfSize:11];
            }
            
            cell.backgroundColor = ICGroupCellBackgroundColor;
            cell.selectedBackgroundView.backgroundColor = ICGroupCellSelectedBackgroundColor;
            cell.detailTextLabel.textColor = ICMutedTextColor;
            
            UILabel* sizeLabel = (UILabel*)cell.accessoryView;
            if (!sizeLabel) {
                sizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (44-20)/2, 65, 20)];
                sizeLabel.font = [UIFont systemFontOfSize:14];
                sizeLabel.textAlignment = NSTextAlignmentRight;
                sizeLabel.textColor = [UIColor colorWithWhite:0.5f alpha:1.0f];
                cell.accessoryView = sizeLabel;
            }
            

            CDEpisode* episode = episodes[indexPath.row];
            CDFeed* feed = episode.feed;
            
            cell.textLabel.text = [episode cleanTitleUsingFeedTitle:feed.title];
            
            unsigned long long bytes = [[CacheManager sharedCacheManager] numberOfDownloadedBytesForEpisode:episode];
            cell.detailTextLabel.text = feed.title;
            
            cell.textLabel.textColor = (episode.consumed) ? ICMutedTextColor : ICTextColor;
            sizeLabel.text = [NSByteCountFormatter stringFromByteCount:bytes countStyle:NSByteCountFormatterCountStyleMemory];
            
            return cell;
        }
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kDeleteAllButton) {
        return 43.0f;
    }
    
    return 44.0f;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSArray* episodes = self.cachedEpisodes;
        NSInteger ec = [episodes count];
        
        CDEpisode* episode = episodes[indexPath.row];
        [[CacheManager sharedCacheManager] removeCacheForEpisode:episode automatic:NO];
        
        [self _reloadContent];
        
        episodes = self.cachedEpisodes;
        
        
        if ([episodes count] > 0 && [episodes count] == ec-1) {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [tableView reloadData];
        }
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kDownloadedSection) {
        NSArray* episodes = self.cachedEpisodes;
        return ([episodes count] != 0);
    }
    
    return NO;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == kDownloadedSection) {
        return @"Downloaded Content".ls;
    }
    
    else if (section == kAutoDownloadSettingsSection) {
        return @"Auto-Download Content".ls;
    }
    
    else if (section == kAutoDeleteSettingsSection) {
        return @"Auto-Delete Content".ls;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kLimitSettingSection)
    {
        ValuesTableViewController* controller = [ValuesTableViewController tableViewController];
        controller.key = AutoCacheStorageLimit;
        controller.valueType = kValueTypeInteger;
        controller.title = @"Storage Limit".ls;
        controller.values = [NSArray arrayWithObjects:@(512),@(1024),@(2048),@(5120),@(10240),@(20480),@(0), nil];
        controller.titles = [NSArray arrayWithObjects:
                             [NSByteCountFormatter stringFromByteCount:512*1024LL*1024LL countStyle:NSByteCountFormatterCountStyleMemory],
                             [NSByteCountFormatter stringFromByteCount:1024*1024LL*1024LL countStyle:NSByteCountFormatterCountStyleMemory],
                             [NSByteCountFormatter stringFromByteCount:2048*1024LL*1024LL countStyle:NSByteCountFormatterCountStyleMemory].ls,
                             [NSByteCountFormatter stringFromByteCount:5120*1024LL*1024LL countStyle:NSByteCountFormatterCountStyleMemory].ls,
                             [NSByteCountFormatter stringFromByteCount:10240*1024LL*1024LL countStyle:NSByteCountFormatterCountStyleMemory].ls,
                             [NSByteCountFormatter stringFromByteCount:20480*1024LL*1024LL countStyle:NSByteCountFormatterCountStyleMemory].ls,
                             @"No Limit".ls, nil];
        controller.footerText = @"Played episodes and old content will be automatically deleted when the storage limit is exceeded.".ls;
        [self.navigationController pushViewController:controller animated:YES];
    }
    
    else if (indexPath.section == kDeleteAllButton)
    {
        [self clearCacheAction:indexPath];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    else if (indexPath.section == kDownloadedSection)
    {
        NSArray* episodes = self.cachedEpisodes;
        if ([episodes count] == 0) {
            return;
        }
        
        
        CDEpisode* episode = episodes[indexPath.row];
        
        NSURL* cacheURL = [[CacheManager sharedCacheManager] URLForCachedEpisode:episode];
        self.interactionController = [UIDocumentInteractionController interactionControllerWithURL:cacheURL];
        self.interactionController.delegate = self;
        self.interactionController.name = episode.title;
        self.interactionController.UTI = @"public.data";
        
        CGRect cellRect = [self.tableView rectForRowAtIndexPath:indexPath];
        
        if (![self.interactionController presentOpenInMenuFromRect:cellRect inView:self.tableView animated:YES]) {
            self.interactionController = nil;
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
}

- (void) documentInteractionControllerDidDismissOpenInMenu: (UIDocumentInteractionController *) controller
{
    self.interactionController = nil;
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}


- (void) clearCacheAction:(NSIndexPath*)cellIndexPath
{
    CacheManager* cman = [CacheManager sharedCacheManager];
    
    if ([cman isCaching])
    {
        [self presentAlertControllerWithTitle:@"Currently Downloading".ls
                                      message:@"Clearing the cache is not possible while Instacast is downloading episodes. Please try again later.".ls
                                       button:@"OK".ls
                                     animated:YES
                                   completion:NULL];
        return;
    }
    
    WEAK_SELF
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Only Delete Played".ls
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                VDModalInfo* modelInfo = [VDModalInfo modalInfoWithProgressLabel:@"Clearing…".ls];
                                                [modelInfo show];
                                                
                                                [self perform:^(id sender) {
                                                    
                                                    for(CDEpisode* episode in self.cachedEpisodes) {
                                                        if (episode.consumed) {
                                                            [[CacheManager sharedCacheManager] removeCacheForEpisode:episode automatic:NO];
                                                        }
                                                    }
                                                    
                                                    [self _reloadContent];
                                                    [self.tableView reloadData];
                                                    [modelInfo close];
                                                } afterDelay:0.3f];

                                                self.alertController = nil;
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete All Content".ls
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                VDModalInfo* modelInfo = [VDModalInfo modalInfoWithProgressLabel:@"Clearing…".ls];
                                                [modelInfo show];
                                                
                                                [self perform:^(id sender) {
                                                    [cman clearTheFuckingCache];
                                                    [[ImageCacheManager sharedImageCacheManager] clearTheFuckingCache];
                                                    [self _reloadContent];
                                                    [self.tableView reloadData];
                                                    [modelInfo close];
                                                } afterDelay:0.3f];

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

- (void) toggleDownloadSettings:(UISwitch*)sender
{
    switch (sender.tag) {
        case 0:
            [USER_DEFAULTS setBool:sender.on forKey:AutoCacheNewAudioEpisodes];
            break;
        case 1:
            [USER_DEFAULTS setBool:sender.on forKey:AutoCacheNewVideoEpisodes];
            break;
        default:
            break;
    }

    [USER_DEFAULTS synchronize];
}

- (void) toggleAutoDeleteSettings:(UISwitch*)sender
{
    if (sender.tag == 0) {
        [USER_DEFAULTS setBool:sender.on forKey:AutoDeleteAfterFinishedPlaying];
    }
    else if (sender.tag == 1) {
        [USER_DEFAULTS setBool:sender.on forKey:AutoDeleteAfterMarkedAsPlayed];
    }
    
    [USER_DEFAULTS synchronize];
}
@end
