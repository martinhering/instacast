//
//  FeedSettingsViewController.m
//  Instacast
//
//  Created by Martin Hering on 17.02.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import "FeedSettingsViewController.h"

#import "SettingsValuesTableViewController.h"
#import "PlaybackDefines.h"
#import "CDModel.h"
#import "SubscriptionManager.h"
#import "UITableViewController+Settings.h"

enum {
    kEpisodesSection,
    kNewsModeSection,
    kAggregateUnavailableEpisodesSection,
    kAutoDownloadSettingsSection,
    kAutoDeleteSettingsSection,
    kPlaybackSection,
    kResetSection,
    kNumberOfSections
};

@interface FeedSettingsViewController ()
@property (nonatomic, strong) CDFeed* feed;
@property (nonatomic, strong) NSArray* deletedEpisodes;
@end

@implementation FeedSettingsViewController

+ (FeedSettingsViewController*) feedSettingsViewControllerWithFeed:(CDFeed*)feed;
{
    FeedSettingsViewController* controller = [[self alloc] initWithStyle:UITableViewStyleGrouped];
    controller.feed = feed;
    return controller;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
   
    
    self.clearsSelectionOnViewWillAppear = YES;

    
    if ([self.navigationController.viewControllers objectAtIndex:0] == self) {
        self.navigationItem.title = @"Subscription Settings".ls;
        self.navigationItem.prompt = self.feed.title;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                                target:self
                                                                                                action:@selector(doneAction:)];
    } else {
        self.navigationItem.title = self.feed.title;
    }
    
    
    NSManagedObjectContext* context = DMANAGER.objectContext;
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:context];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"feed = %@ && archived == %@", self.feed, @YES];
    self.deletedEpisodes = [context executeFetchRequest:fetchRequest error:nil];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[self setScrollView:self.tableView contentInsets:UIEdgeInsetsZero byAdjustingForStandardBars:YES];
    
    self.tableView.backgroundColor = ICBackgroundColor;
    self.tableView.separatorColor = ICGroupCellSelectedBackgroundColor;
    
    [self.tableView reloadData];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void) doneAction:(id)sender
{
    [DMANAGER save];
    [self dismissViewControllerAnimated:YES completion:^{
        SubscriptionManager* sman = [SubscriptionManager sharedSubscriptionManager];
        [sman autoDownloadEpisodesInFeed:self.feed];
    }];
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case kEpisodesSection:
            return 1;
        case kNewsModeSection:
            return 1;
        case kAggregateUnavailableEpisodesSection:
            return 1;
        case kAutoDownloadSettingsSection:
            return 2;
        case kAutoDeleteSettingsSection:
            return 2;
        case kPlaybackSection:
            return 3;
        case kResetSection:
            return 1;
        default:
            break;
    }
    return 0;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = nil;

    if (indexPath.section == kEpisodesSection)
    {
        switch (indexPath.row) {
            case 0:
            {
                cell = [self detailCell];
                cell.textLabel.text = @"Sort Order".ls;
                
                NSString* feedSortOrder = [self.feed stringForKey:FeedSortOrder];
                cell.detailTextLabel.text = ([feedSortOrder isEqualToString:@"NewerFirst"]) ? @"Newest First".ls : @"Oldest First".ls;
                break;
            }
            default:
            {
                break;
            }
        }
    }
    
    else if (indexPath.section == kNewsModeSection)
    {
        UITableViewCell* cell = [self switchCell];
        UISwitch* control = (UISwitch*)cell.accessoryView;
        
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"News Mode".ls;
                control.on = [self.feed boolForKey:AutoDeleteNewsMode];
                break;
            default:
                break;
        }
        
        control.tag = indexPath.row;
        [control addTarget:self action:@selector(toggleNewsModeSettings:) forControlEvents:UIControlEventValueChanged];
        
        return cell;
    }
    
    else if (indexPath.section == kAggregateUnavailableEpisodesSection)
    {
        UITableViewCell* cell = [self switchCell];
        UISwitch* control = (UISwitch*)cell.accessoryView;
        
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Show Unavailable Episodes".ls;
                control.on = [self.feed boolForKey:kDefaultShowUnavailableEpisodes];
                break;
            default:
                break;
        }
        
        control.tag = indexPath.row;
        [control addTarget:self action:@selector(toggleShowUnavailableEpisodes:) forControlEvents:UIControlEventValueChanged];
        return cell;
    }
    
    else if (indexPath.section == kAutoDownloadSettingsSection)
    {
        UITableViewCell* cell = [self switchCell];
        UISwitch* control = (UISwitch*)cell.accessoryView;
        
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Audio Content".ls;
                control.on = [self.feed boolForKey:AutoCacheNewAudioEpisodes];
                break;
            case 1:
                cell.textLabel.text = @"Video Content".ls;
                control.on = [self.feed boolForKey:AutoCacheNewVideoEpisodes];
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
        
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Finished Playing".ls;
                control.on = [self.feed boolForKey:AutoDeleteAfterFinishedPlaying];
                break;
            case 1:
                cell.textLabel.text = @"Marked as Played".ls;
                control.on = [self.feed boolForKey:AutoDeleteAfterMarkedAsPlayed];
                break;
            default:
                break;
        }
        
        control.tag = indexPath.row;
        [control addTarget:self action:@selector(toggleAutoDeleteSettings:) forControlEvents:UIControlEventValueChanged];
        
        return cell;
    }

    else if (indexPath.section == kPlaybackSection)
    {
        NSDictionary* v = @{ @5 : @"5 Seconds", @10 : @"10 Seconds", @20 : @"20 Seconds", @30 : @"30 Seconds", @60 : @"1 Minute", @120 : @"2 Minutes", @300 : @"5 Minutes", @600 : @"10 Minutes" };
        
        switch (indexPath.row) {
            case 0:
            {
                cell = [self detailCell];
                cell.textLabel.text = @"Skipping Back".ls;
                
                NSInteger period = [self.feed integerForKey:PlayerSkipBackPeriod];
                NSString* localizedKey = v[@(period)];
                cell.detailTextLabel.text = localizedKey.ls;
                
                break;
            }
            case 1:
            {
                cell = [self detailCell];
                cell.textLabel.text = @"Skipping Forward".ls;
                
                NSInteger period = [self.feed integerForKey:PlayerSkipForwardPeriod];
                NSString* localizedKey = v[@(period)];
                cell.detailTextLabel.text = localizedKey.ls;
                
                break;
            }
            case 2:
                cell = [self detailCell];
                cell.textLabel.text = @"Speed".ls;
                
                NSInteger speed = [self.feed integerForKey:DefaultPlaybackSpeed];
                switch (speed) {
                    case PlaybackSpeedControlNormalSpeed:
                        cell.detailTextLabel.text = @"Normal (1x)".ls;
                        break;
                    case PlaybackSpeedControlDoubleSpeed:
                        cell.detailTextLabel.text = @"Fast (2x)".ls;
                        break;
                    case PlaybackSpeedControlPlusHalfSpeed:
                        cell.detailTextLabel.text = @"Faster (1.5x)".ls;
                        break;
                    case PlaybackSpeedControlMinusHalfSpeed:
                        cell.detailTextLabel.text = @"Slower (0.5x)".ls;
                        break;
                    case PlaybackSpeedControlTripleSpeed:
                        cell.detailTextLabel.text = @"Crazy (3x)".ls;
                        break;
                    default:
                        break;
                }
                
                
                break;
            default:
                break;
        }
    }
    
    else if (indexPath.section == kResetSection)
    {
        cell = [self resetCell];
        cell.textLabel.text = @"Reset to Defaults".ls;
        
        if (![self.feed hasCustomProperties])
        {
            cell.userInteractionEnabled = NO;
            cell.textLabel.textColor = ICMutedTextColor;
        }
        else
        {
            cell.userInteractionEnabled = YES;
            cell.textLabel.textColor = [UIColor redColor];
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case kEpisodesSection:
            return @"Episodes".ls;
            break;
        case kAutoDownloadSettingsSection:
            return @"Auto-Download Content".ls;
            break;
        case kAutoDeleteSettingsSection:
            return @"Auto-Delete Content".ls;
            break;
        case kPlaybackSection:
            return @"Playback".ls;
            break;
        default:
            break;
    }
    return nil;
}

- (void) toggleShowUnavailableEpisodes:(UISwitch*)sender
{
    [self setBool:sender.on forKey:kDefaultShowUnavailableEpisodes];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kResetSection] withRowAnimation:UITableViewRowAnimationNone];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kEpisodesSection)
    {
        if (indexPath.row == 0)
        {
            SettingsValuesTableViewController* controller = [SettingsValuesTableViewController tableViewController];
            controller.feed = self.feed;
            
            controller.key = FeedSortOrder;
            controller.valueType = kSettingTypeString;
            controller.title = @"Sort Order".ls;
            controller.values = [NSArray arrayWithObjects:@"NewerFirst", @"OlderFirst", nil];
            controller.titles = [NSArray arrayWithObjects:@"Newest First".ls, @"Oldest First".ls, nil];
            
            [self.navigationController pushViewController:controller animated:YES];
        }
    }

    else if (indexPath.section == kPlaybackSection)
    {
        if (indexPath.row == 0 || indexPath.row == 1)
        {
            SettingsValuesTableViewController* controller = [SettingsValuesTableViewController tableViewController];
            controller.feed = self.feed;
            controller.valueType = kSettingTypeInteger;
            controller.key = (indexPath.row == 0 ) ? PlayerSkipBackPeriod : PlayerSkipForwardPeriod;
            controller.title = (indexPath.row == 0 ) ? @"Skipping Back".ls : @"Skipping Forward".ls;
            controller.values = @[ @(5), @(10), @(20), @(30), @(60), @(120), @(300), @(600) ];
            controller.titles = @[@"5 Seconds".ls, @"10 Seconds".ls, @"20 Seconds".ls, @"30 Seconds".ls, @"1 Minute".ls, @"2 Minutes".ls, @"5 Minutes".ls, @"10 Minutes".ls];
            [self.navigationController pushViewController:controller animated:YES];
        }
        
        else if (indexPath.row == 2)
        {
            SettingsValuesTableViewController* controller = [SettingsValuesTableViewController tableViewController];
            controller.feed = self.feed;
            controller.valueType = kSettingTypeInteger;
            controller.key = DefaultPlaybackSpeed;
            controller.title = @"Speed".ls;
            controller.values = [NSArray arrayWithObjects:
                                 [NSNumber numberWithInteger:PlaybackSpeedControlMinusHalfSpeed],
                                 [NSNumber numberWithInteger:PlaybackSpeedControlNormalSpeed],
                                 [NSNumber numberWithInteger:PlaybackSpeedControlPlusHalfSpeed],
                                 [NSNumber numberWithInteger:PlaybackSpeedControlDoubleSpeed],
                                 [NSNumber numberWithInteger:PlaybackSpeedControlTripleSpeed],nil];
            controller.titles = [NSArray arrayWithObjects:
                                 @"Slower (0.5x)".ls,
                                 @"Normal (1x)".ls,
                                 @"Faster (1.5x)".ls,
                                 @"Fast (2x)".ls,
                                 @"Crazy (3x)".ls, nil];
            [self.navigationController pushViewController:controller animated:YES];
        }
    }
    
    else if (indexPath.section == kResetSection)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];

        WEAK_SELF
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Reset to Defaults".ls
                                                                       message:@"Are you sure you want to reset all custom subscription settings to default?".ls
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Reset".ls
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction * action) {
                                                    STRONG_SELF
                                                    [self perform:^(id sender) {
                                                        [self.feed resetAllProperties];
                                                        [self.tableView reloadData];
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

}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == kResetSection) {
        return @"Resets subscription specific settings back to default settings.".ls;
    }
    else if (section == kNewsModeSection) {
        return @"Enable News Mode to only keep the most recent episode(s) of a podcast.".ls;
    }
    else if (section == kAggregateUnavailableEpisodesSection) {
        return @"Enable to show all episodes regardless of whether or not they are still available on the publisher's server.".ls;
    }
    
    
    
    return nil;
}

- (void) setBool:(BOOL)value forKey:(NSString*)key
{
    if (value == [USER_DEFAULTS boolForKey:key]) {
        [self.feed resetValueForKey:key];
    }
    else {
        [self.feed setBool:value forKey:key];
    }
}

- (void) toggleDownloadSettings:(UISwitch*)sender
{
    switch (sender.tag) {
        case 0:
            [self setBool:sender.on forKey:AutoCacheNewAudioEpisodes];
            break;
        case 1:
            [self setBool:sender.on forKey:AutoCacheNewVideoEpisodes];
            break;
            
        default:
            break;
    }
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kResetSection] withRowAnimation:UITableViewRowAnimationNone];
}

- (void) toggleNewsModeSettings:(UISwitch*)sender
{
    if (sender.tag == 0) {
        [self setBool:sender.on forKey:AutoDeleteNewsMode];
    }
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kResetSection] withRowAnimation:UITableViewRowAnimationNone];
}


- (void) toggleAutoDeleteSettings:(UISwitch*)sender
{
    if (sender.tag == 0) {
        [self setBool:sender.on forKey:AutoDeleteAfterFinishedPlaying];
    }
    else if (sender.tag == 1) {
        [self setBool:sender.on forKey:AutoDeleteAfterMarkedAsPlayed];
    }
    else if (sender.tag == 2) {
        [self setBool:sender.on forKey:AutoDeleteNewsMode];
        
    }
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kResetSection] withRowAnimation:UITableViewRowAnimationNone];
}

@end
