//
//  EpisodeListEditorViewController.m
//  Instacast
//
//  Created by Martin Hering on 18.08.14.
//
//

#import "EpisodeListEditorViewController.h"
#import "UITableViewController+Settings.h"
#import "ICButtonsTableViewCell.h"
#import "EpisodeListPodcastSelectionTableViewController.h"
#import "ICListEditorPodcastCell.h"
#import "InstacastAppDelegate.h"

enum {
    kSectionAppearance,
    kSectionIncludeAttributes,
    kSectionIncludeSearch,
    kSectionIncludePodcasts,
    kSectionOrderBy,
    kSectionOrderOptions,
    kSectionContinuousPlayback,
    kNumberOfSections
};


static NSString* kCellIdentifier = @"Cell";
static NSString* kButtonCellIdentifier = @"ButtonCell";

@interface EpisodeListEditorViewController () <UITextFieldDelegate>
@property (nonatomic, strong) CDEpisodeList* episodeList;

@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* selectedIcon;
@property (nonatomic, strong) NSString* query;
@property (nonatomic) BOOL includeAudio;
@property (nonatomic) BOOL includeVideo;
@property (nonatomic) BOOL includeUnplayed;
@property (nonatomic) BOOL includeUnfinished;
@property (nonatomic) BOOL includePlayed;
@property (nonatomic) BOOL includeStarred;
@property (nonatomic) BOOL includeNotStarred;
@property (nonatomic) BOOL includeDownloaded;
@property (nonatomic) BOOL includeNotDownloaded;

@property (nonatomic) BOOL includeAllPodcasts;
@property (nonatomic, strong) NSOrderedSet* selectedPodcasts;

@property (nonatomic, strong) NSString* orderBy;
@property (nonatomic) BOOL descending;
@property (nonatomic) BOOL groupByPodcast;
@property (nonatomic) BOOL continuousPlayback;

@property (nonatomic, strong) EpisodeListPodcastSelectionTableViewController* podcastSelectionController;
@end

@implementation EpisodeListEditorViewController

+ (instancetype) episodeListEditorViewControllerWithList:(CDEpisodeList*)list {
    EpisodeListEditorViewController* controller = [[self alloc] initWithStyle:UITableViewStyleGrouped];
    controller.episodeList = list;
    return controller;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.editing = YES;
    self.tableView.allowsSelectionDuringEditing = YES;
 
    if (self.episodeList) {
        self.title = @"Edit List".ls;
    }
    else {
        self.title = @"New List".ls;
    }
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancelButtonAction:)];

    
    if (self.episodeList)
    {
        CDEpisodeList* list = self.episodeList;
        
        self.name = list.name;
        self.selectedIcon = list.icon;
        self.query = list.query;
        self.includeAudio = list.audio;
        self.includeVideo = list.video;
        self.includeUnplayed = list.unplayed;
        self.includeUnfinished = list.unfinished;
        self.includePlayed = list.played;
        self.includeStarred = list.starred;
        self.includeNotStarred = list.notStarred;
        self.includeDownloaded = list.downloaded;
        self.includeNotDownloaded = list.notDownloaded;
        self.includeAllPodcasts = ([list.includedFeeds count] == 0);
        
        NSMutableOrderedSet* selectedPodcasts = [[NSMutableOrderedSet alloc] init];
        for(CDFeed* feed in DMANAGER.visibleFeeds) {
            if ([list.includedFeeds containsObject:feed]) {
                [selectedPodcasts addObject:feed];
            }
        }
        self.selectedPodcasts = selectedPodcasts;
        self.groupByPodcast = list.groupByPodcast;
        self.descending = list.descending;
        self.orderBy = list.orderBy;
        self.continuousPlayback = list.continuousPlayback;
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save".ls
                                                                                  style:UIBarButtonItemStyleDone
                                                                                 target:self
                                                                                 action:@selector(doneButtonAction:)];
    }
    else
    {
        self.name = @"New List".ls;
        self.selectedIcon = @"List Custom";
        self.query = nil;
        self.includeAudio = YES;
        self.includeVideo = YES;
        self.includeUnplayed = YES;
        self.includeUnfinished = YES;
        self.includePlayed = YES;
        self.includeStarred = YES;
        self.includeNotStarred = YES;
        self.includeDownloaded = YES;
        self.includeNotDownloaded = YES;
        self.includeAllPodcasts = YES;
        self.groupByPodcast = NO;
        self.descending = YES;
        self.orderBy = @"pubDate";
        self.continuousPlayback = YES;
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add".ls
                                                                                  style:UIBarButtonItemStyleDone
                                                                                 target:self
                                                                                 action:@selector(doneButtonAction:)];
    }
    
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setScrollView:self.tableView contentInsets:UIEdgeInsetsZero byAdjustingForStandardBars:YES];
    
    self.tableView.backgroundColor = ICBackgroundColor;
    self.tableView.separatorColor = ICGroupCellSelectedBackgroundColor;
    
    
    if (self.podcastSelectionController)
    {
        self.selectedPodcasts = self.podcastSelectionController.selectedPodcasts;
        self.podcastSelectionController = nil;
    }
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) save
{
    CDEpisodeList* list = self.episodeList;
    if (!list) {
        list = [NSEntityDescription insertNewObjectForEntityForName:@"EpisodeList" inManagedObjectContext:DMANAGER.objectContext];
    }
    
    
    UITextField* nameTextField = (UITextField*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kSectionAppearance]].accessoryView;
    [nameTextField resignFirstResponder];
    
    UITextField* keywordTextField = (UITextField*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kSectionIncludeSearch]].accessoryView;
    [keywordTextField resignFirstResponder];
    
    list.name = self.name;
    list.icon = self.selectedIcon;
    list.query = self.query;
    
    list.audio = self.includeAudio;
    list.video = self.includeVideo;
    list.unplayed = self.includeUnplayed;
    list.unfinished = self.includeUnfinished;
    list.played = self.includePlayed;
    list.starred = self.includeStarred;
    list.notStarred = self.includeNotStarred;
    list.downloaded = self.includeDownloaded;
    list.notDownloaded = self.includeNotDownloaded;
    list.includedFeeds = [NSSet setWithArray:[self.selectedPodcasts array]];
    list.groupByPodcast = self.groupByPodcast;
    list.descending = self.descending;
    list.orderBy = self.orderBy;
    list.continuousPlayback = self.continuousPlayback;
    list.rank = -1;
    
    [list invalidateCaches];

    [DMANAGER saveAndSync:NO];
    [DMANAGER addList:list];
}

- (void) cancelButtonAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void) doneButtonAction:(id)sender
{
    [self save];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark -

- (NSArray*) _possibleIconNames
{
    return @[@"List Custom", @"List Unplayed", @"List Favorites", @"List Downloaded", @"List Partially Played", @"List Most Recent", @"List Recently Played", @"List Audio", @"List Video", @"List Search" ];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case kSectionAppearance:
            return 2;
        case kSectionIncludeAttributes:
            return 4;
        case kSectionIncludeSearch:
            return 1;
        case kSectionIncludePodcasts:
            return (!self.includeAllPodcasts) ? [self.selectedPodcasts count]+2 : 1;
        case kSectionOrderBy:
            return 5;
        case kSectionOrderOptions:
            return 3;
        case kSectionContinuousPlayback:
            return 1;
        default:
            break;
    }
    return 0;
}

- (ICButtonsTableViewCell*) _buttonCell
{
    ICButtonsTableViewCell *cell = (ICButtonsTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:kButtonCellIdentifier];
    if (cell == nil) {
        cell = [[ICButtonsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kButtonCellIdentifier];
    }
    cell.backgroundColor = ICGroupCellBackgroundColor;
    cell.selectedBackgroundView.backgroundColor = ICTableSelectedBackgroundColor;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kSectionAppearance:
        {
            switch (indexPath.row) {
                case 0:
                {
                    UITableViewCell* cell = [self textInputCell];
                    cell.backgroundColor = ICGroupCellBackgroundColor;
                    cell.separatorInset = UIEdgeInsetsZero;
                    
                    cell.textLabel.text = @"Name".ls;
                    UITextField* textField = (UITextField*)cell.accessoryView;
                    textField.placeholder = @"New Episode List".ls;
                    textField.text = self.name;
                    textField.textColor = ICTintColor;
                    textField.delegate = self;
                    textField.tag = 111;
                    
                    return cell;
                }
                case 1:
                {
                    ICButtonsTableViewCell* cell = [self _buttonCell];
                    cell.backgroundColor = ICGroupCellBackgroundColor;
                    cell.separatorInset = UIEdgeInsetsZero;
                    
                    NSMutableArray* buttons = [[NSMutableArray alloc] init];
                    for(NSString* iconName in [self _possibleIconNames])
                    {
                        UIButton* button = [ICButtonsTableViewCell configuredButtonWithTitle:nil imageNamed:iconName];
                        
                        if ([iconName isEqualToString:self.selectedIcon]) {
                            button.selected = YES;
                        }
                        
                        [buttons addObject:button];
                    }
                    
                    cell.buttons = buttons;

                    cell.buttonTappedAtIndex = ^(UIButton* sender, NSInteger index) {
                        self.selectedIcon = [[self _possibleIconNames] objectAtIndex:index];
                    };
                    
                    return cell;
                }
                default:
                    break;
            }
            break;
        }
        case kSectionIncludeAttributes:
        {
            ICButtonsTableViewCell* cell = [self _buttonCell];
            cell.backgroundColor = ICGroupCellBackgroundColor;
            cell.separatorInset = UIEdgeInsetsZero;
            cell.allowsMultiSelection = YES;
            
            switch (indexPath.row) {
                case 0:
                {
                    UIButton* audioButton = [ICButtonsTableViewCell configuredButtonWithTitle:@"Audio".ls imageNamed:@"List Settings Audio"];
                    audioButton.selected = self.includeAudio;
                    
                    UIButton* videoButton = [ICButtonsTableViewCell configuredButtonWithTitle:@"Video".ls imageNamed:@"List Settings Video"];
                    videoButton.selected = self.includeVideo;
                    
                    cell.buttons = @[ audioButton, videoButton ];
                    
                    cell.buttonTappedAtIndex = ^(UIButton* sender, NSInteger index) {
                        switch (index) {
                            case 0:
                                self.includeAudio = sender.selected;
                                break;
                            case 1:
                                self.includeVideo = sender.selected;
                                break;
                            default:
                                break;
                        }
                    };
                    return cell;
                }
                case 1:
                {
                    UIButton* unplayedButton = [ICButtonsTableViewCell configuredButtonWithTitle:@"Unplayed".ls imageNamed:@"List Settings Unplayed"];
                    unplayedButton.selected = self.includeUnplayed;
                    
                    UIButton* partiallyPlayedButton = [ICButtonsTableViewCell configuredButtonWithTitle:@"Unfinished".ls imageNamed:@"List Settings Unfinished"];
                    partiallyPlayedButton.selected = self.includeUnfinished;

                    UIButton* playedButton = [ICButtonsTableViewCell configuredButtonWithTitle:@"Played".ls imageNamed:@"List Settings Played"];
                    playedButton.selected = self.includePlayed;

                    cell.buttons = @[ unplayedButton, partiallyPlayedButton, playedButton ];
                    
                    cell.buttonTappedAtIndex = ^(UIButton* sender, NSInteger index) {
                        switch (index) {
                            case 0:
                                self.includeUnplayed = sender.selected;
                                break;
                            case 1:
                                self.includeUnfinished = sender.selected;
                                break;
                            case 2:
                                self.includePlayed = sender.selected;
                                break;
                            default:
                                break;
                        }
                    };
                    
                    return cell;
                }
                case 2:
                {
                    UIButton* starredButton = [ICButtonsTableViewCell configuredButtonWithTitle:@"Starred".ls imageNamed:@"List Settings Starred"];
                    starredButton.selected = self.includeStarred;
                    
                    UIButton* notStarredButton = [ICButtonsTableViewCell configuredButtonWithTitle:@"Not Starred".ls imageNamed:@"List Settings Not Starred"];
                    notStarredButton.selected = self.includeNotStarred;

                    cell.buttons = @[ starredButton, notStarredButton ];
                    
                    cell.buttonTappedAtIndex = ^(UIButton* sender, NSInteger index) {
                        switch (index) {
                            case 0:
                                self.includeStarred = sender.selected;
                                break;
                            case 1:
                                self.includeNotStarred = sender.selected;
                                break;
                            default:
                                break;
                        }
                    };
                    
                    return cell;
                }
                case 3:
                {
                    UIButton* downloadedButton = [ICButtonsTableViewCell configuredButtonWithTitle:@"Downloaded".ls imageNamed:@"List Settings Downloaded"];
                    downloadedButton.selected = self.includeDownloaded;
                    
                    UIButton* notDownloadedButton = [ICButtonsTableViewCell configuredButtonWithTitle:@"Not Downloaded".ls imageNamed:@"List Settings Not Downloaded"];
                    notDownloadedButton.selected = self.includeNotDownloaded;
                    
                    cell.buttons = @[ downloadedButton, notDownloadedButton ];
                    
                    cell.buttonTappedAtIndex = ^(UIButton* sender, NSInteger index) {
                        switch (index) {
                            case 0:
                                self.includeDownloaded = sender.selected;
                                break;
                            case 1:
                                self.includeNotDownloaded = sender.selected;
                                break;
                            default:
                                break;
                        }
                    };
                    
                    return cell;
                }
                default:
                    break;
            }
            break;
        }
        case kSectionIncludeSearch:
        {
            UITableViewCell* cell = [self textInputCell];
            cell.backgroundColor = ICGroupCellBackgroundColor;
            cell.separatorInset = UIEdgeInsetsZero;
            
            cell.textLabel.text = @"Search".ls;
            UITextField* textField = (UITextField*)cell.accessoryView;
            textField.placeholder = @"Keyword".ls;
            textField.text = self.query;
            textField.textColor = ICTintColor;
            textField.delegate = self;
            textField.tag = 112;
            
            return cell;
            
            break;
        }
        case kSectionIncludePodcasts:
        {
            if (self.includeAllPodcasts) {
                UITableViewCell* cell = [self switchCell];
                cell.textLabel.text = @"All Podcasts".ls;
                UISwitch* control = (UISwitch*)cell.accessoryView;
                control.on = YES;
                [control addTarget:self action:@selector(toggleIncludeSelectedPodcasts:) forControlEvents:UIControlEventValueChanged];
                return cell;
            }
            
            if (indexPath.row == 0)
            {
                UITableViewCell* cell = [self switchCell];
                cell.textLabel.text = @"All Podcasts".ls;
                UISwitch* control = (UISwitch*)cell.accessoryView;
                control.on = NO;
                [control addTarget:self action:@selector(toggleIncludeSelectedPodcasts:) forControlEvents:UIControlEventValueChanged];
                return cell;
            }
            else if (indexPath.row > 0 && indexPath.row < [self.selectedPodcasts count] + 1)
            {
                CDFeed* feed = self.selectedPodcasts[indexPath.row-1];
                
                UITableViewCell* cell = [self standardCellWithClass:[ICListEditorPodcastCell class]];
                cell.textLabel.text = feed.title;
                
                UIImage* localImage = [[ImageCacheManager sharedImageCacheManager] localImageForImageURL:feed.imageURL size:44 grayscale:NO];
                cell.imageView.image = localImage;
                if (!localImage)
                {
                    cell.imageView.image = [UIImage imageNamed:@"Podcast Placeholder 56"];
                    [[ImageCacheManager sharedImageCacheManager] imageForURL:feed.imageURL size:44 grayscale:NO sender:self completion:^(UIImage *image) {
                        cell.imageView.image = image;
                    }];
                }
                
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                return cell;
            }
            else
            {
                UITableViewCell* cell = [self standardCell];
                cell.textLabel.text = @"Add Selected Podcasts".ls;
                cell.textLabel.textColor = ICMutedTextColor;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                return cell;
            }
            break;
        }
        case kSectionOrderBy:
        {
            UITableViewCell* cell = [self standardCell];
            
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Publish Date".ls;
                    cell.accessoryType = ([self.orderBy isEqualToString:@"pubDate"]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                case 1:
                    cell.textLabel.text = @"Last Played".ls;
                    cell.accessoryType = ([self.orderBy isEqualToString:@"lastPlayed"]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                case 2:
                    cell.textLabel.text = @"Last Downloaded".ls;
                    cell.accessoryType = ([self.orderBy isEqualToString:@"lastDownloaded"]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                case 3:
                    cell.textLabel.text = @"Duration".ls;
                    cell.accessoryType = ([self.orderBy isEqualToString:@"duration"]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                case 4:
                    cell.textLabel.text = @"Time Left".ls;
                    cell.accessoryType = ([self.orderBy isEqualToString:@"timeLeft"]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                default:
                    break;
            }
            
            return cell;
        }
        case kSectionOrderOptions:
        {
            UITableViewCell* cell = [self standardCell];
            
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Ascending".ls;
                    cell.accessoryType = (!self.descending) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                case 1:
                    cell.textLabel.text = @"Descending".ls;
                    cell.accessoryType = (self.descending) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                case 2:
                {
                    UITableViewCell* cell = [self switchCell];
                    cell.textLabel.text = @"Group by Podcast".ls;
                    UISwitch* control = (UISwitch*)cell.accessoryView;
                    control.on = self.groupByPodcast;
                    [control addTarget:self action:@selector(toggleGroupByPodcast:) forControlEvents:UIControlEventValueChanged];
                    return cell;
                }
                default:
                    break;
            }
            return cell;
        }
        case kSectionContinuousPlayback:
        {
            UITableViewCell* cell = [self standardCell];
            
            switch (indexPath.row) {
                case 0:
                {
                    UITableViewCell* cell = [self switchCell];
                    cell.textLabel.text = @"Continuous Playback".ls;
                    UISwitch* control = (UISwitch*)cell.accessoryView;
                    control.on = self.continuousPlayback;
                    [control addTarget:self action:@selector(toggleContinuousPlayback:) forControlEvents:UIControlEventValueChanged];
                    return cell;
                }
                default:
                    break;
            }
            return cell;
        }
        default:
            break;
    }
    
    
    
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case kSectionAppearance:
            return @"Appearance".ls;
        case kSectionIncludeAttributes:
            return @"Include Attributes".ls;
        case kSectionIncludeSearch:
            return @"Contains Keyword".ls;
        case kSectionIncludePodcasts:
            return @"Include Podcasts".ls;
        case kSectionOrderBy:
            return @"Order By".ls;
        case kSectionOrderOptions:
            return @"Order Options".ls;
        default:
            break;
    }
    return nil;
}

- (NSString*) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (section) {
        case kSectionIncludeAttributes:
            return @"Deactivate attributes of episodes that should not be included in this episode list.".ls;
        case kSectionIncludeSearch:
            return @"Enter a keyword that episodes must contain.".ls;
        case kSectionOrderBy:
            return nil;
        case kSectionOrderOptions:
            return @"Enable 'Group by Podcast' to order episodes according to podcast priority. Change the podcast priority by reordering podcasts in the podcast list manually.".ls;
        case kSectionContinuousPlayback:
            return @"Enable 'Continuous Playback' to copy remaining episodes to Up Next when playback starts.".ls;
        default:
            break;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kSectionIncludeAttributes:
            return 107;
            
        default:
            break;
    }

    return 44;
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField.tag == 111) {
        self.name = textField.text;
    }
    else if (textField.tag == 112) {
        self.query = textField.text;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kSectionAppearance]];
    if ([cell.accessoryView isKindOfClass:[UITextField class]]) {
        [cell.accessoryView resignFirstResponder];
    }
    
    cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kSectionIncludeSearch]];
    if ([cell.accessoryView isKindOfClass:[UITextField class]]) {
        [cell.accessoryView resignFirstResponder];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Editing

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kSectionIncludePodcasts && !self.includeAllPodcasts && indexPath.row > 0 && indexPath.row < [self.selectedPodcasts count]+2) {
        return YES;
    }
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kSectionIncludePodcasts && !self.includeAllPodcasts && indexPath.row > 0 && indexPath.row < [self.selectedPodcasts count]+1) {
        return UITableViewCellEditingStyleDelete;
    }
    
    else if (indexPath.section == kSectionIncludePodcasts && !self.includeAllPodcasts && indexPath.row == [self.selectedPodcasts count]+1) {
        return UITableViewCellEditingStyleInsert;
    }
    return UITableViewCellEditingStyleNone;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Remove".ls;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kSectionIncludePodcasts && !self.includeAllPodcasts && indexPath.row > 0 && indexPath.row < [self.selectedPodcasts count]+1)
    {
        CDFeed* feed = self.selectedPodcasts[indexPath.row-1];
        [[self mutableOrderedSetValueForKey:@"selectedPodcasts"] removeObject:feed];
        [tableView deleteRowsAtIndexPaths:@[ indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    
    else if (indexPath.section == kSectionIncludePodcasts && !self.includeAllPodcasts && indexPath.row == [self.selectedPodcasts count]+1) {
        [self _pushPodcastSelectionTableViewController];
    }
}

#pragma mark - Actions

- (void) _pushPodcastSelectionTableViewController
{
    UIBarButtonItem* a = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = a;
    
    self.podcastSelectionController = [EpisodeListPodcastSelectionTableViewController viewController];
    self.podcastSelectionController.selectedPodcasts = self.selectedPodcasts;
    [self.navigationController pushViewController:self.podcastSelectionController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kSectionOrderBy || indexPath.section == kSectionOrderOptions)
    {
        UITableViewCell* selectedCell = [tableView cellForRowAtIndexPath:indexPath];
        if (selectedCell.selectionStyle == UITableViewCellSelectionStyleNone) {
            return;
        }
        
        for(NSIndexPath* visibleIndexPath in [tableView indexPathsForVisibleRows])
        {
            UITableViewCell* cell = [tableView cellForRowAtIndexPath:visibleIndexPath];
            if (visibleIndexPath.section == indexPath.section) {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        
        selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        
        if (indexPath.section == kSectionOrderBy)
        {
            NSArray* orderActions = @[ @"pubDate", @"lastPlayed", @"lastDownloaded", @"duration", @"timeLeft" ];
            self.orderBy = orderActions[indexPath.row];
        }
        
        else if (indexPath.section == kSectionOrderOptions)
        {
            switch (indexPath.row) {
                case 0:
                    self.descending = NO;
                    break;
                case 1:
                    self.descending = YES;
                    break;
                default:
                    break;
            }
        }
    }
    
    else if (indexPath.section == kSectionIncludePodcasts && !self.includeAllPodcasts && indexPath.row == [self.selectedPodcasts count]+1)
    {
        [self _pushPodcastSelectionTableViewController];
    }
}

- (void) toggleIncludeSelectedPodcasts:(UISwitch*)sender
{
    BOOL oldIncludeAllPodcasts = self.includeAllPodcasts;
    self.includeAllPodcasts = sender.on;
    
    if (!sender.on && oldIncludeAllPodcasts)
    {
        [self.tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:1 inSection:kSectionIncludePodcasts] ] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (sender.on && !oldIncludeAllPodcasts)
    {
        NSInteger rows = [self.tableView numberOfRowsInSection:kSectionIncludePodcasts];
        NSMutableArray* indexPathes = [[NSMutableArray alloc] init];
        NSInteger i;
        for(i=1; i<rows; i++) {
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:kSectionIncludePodcasts];
            [indexPathes addObject:indexPath];
        }
        
        [self.tableView deleteRowsAtIndexPaths:indexPathes withRowAnimation:UITableViewRowAnimationFade];
        self.selectedPodcasts = nil;
    }
}

- (void) toggleGroupByPodcast:(UISwitch*)sender
{
    self.groupByPodcast = sender.on;
}

- (void) toggleContinuousPlayback:(UISwitch*)sender
{
    self.continuousPlayback = sender.on;
}


@end
