//
//  APNOptionsViewController.m
//  Instacast
//
//  Created by Martin Hering on 01.06.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import "NotificationSettingsViewController.h"
#import "UITableViewController+Settings.h"

typedef NS_ENUM(NSInteger, kNotificationSettingsSections) {
    kNotifications,
    kSubscriptions,
    kNumberOfSections,
};


@interface NotificationSettingsViewController ()

@end

@implementation NotificationSettingsViewController

+ (NotificationSettingsViewController*) viewController
{
    return [[self alloc] initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setScrollView:self.tableView contentInsets:UIEdgeInsetsZero byAdjustingForStandardBars:YES];

    self.clearsSelectionOnViewWillAppear = YES;
    self.navigationItem.title = @"Notifications".ls;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tableView.backgroundColor = ICBackgroundColor;
    self.tableView.separatorColor = ICGroupCellSelectedBackgroundColor;
    
    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return ([USER_DEFAULTS boolForKey:EnableNewEpisodeNotification]) ? kNumberOfSections : kNumberOfSections-1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case kNotifications:
            return 3;
        case kSubscriptions:
            return [DMANAGER.feeds count];
        default:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kNotifications)
    {
        UITableViewCell* cell = [self switchCell];
        UISwitch* control = (UISwitch*)cell.accessoryView;
        control.tag = indexPath.row;
        
        switch (indexPath.row) {
            case 0:
            {
                cell.textLabel.text = @"Refreshing finished.".ls;
                control.on = [USER_DEFAULTS boolForKey:EnableManualRefreshFinishedNotification];
                [control addTarget:self action:@selector(toggleLocalNotifications:) forControlEvents:UIControlEventValueChanged];
                break;
            }
            case 1:
            {
                cell.textLabel.text = @"Downloading finished.".ls;
                control.on = [USER_DEFAULTS boolForKey:EnableManualDownloadFinishedNotification];
                [control addTarget:self action:@selector(toggleLocalNotifications:) forControlEvents:UIControlEventValueChanged];
                break;
            }
            case 2:
            {
                cell.textLabel.text = @"New episode available.".ls;
                control.on = [USER_DEFAULTS boolForKey:EnableNewEpisodeNotification];
                [control addTarget:self action:@selector(toggleLocalNotifications:) forControlEvents:UIControlEventValueChanged];
                break;
            }
            default:
                break;
        }
        

        return cell;
    }
    else if (indexPath.section == kSubscriptions)
    {
        UITableViewCell* cell = [self switchCell];
        UISwitch* control = (UISwitch*)cell.accessoryView;
        control.tag = indexPath.row;
        
        CDFeed* feed = [DMANAGER.feeds objectAtIndex:indexPath.row];
        cell.textLabel.text = feed.title;
        
        control.on = [feed boolForKey:EnableNewEpisodeNotification];
        [control addTarget:self action:@selector(toggleFeed:) forControlEvents:UIControlEventValueChanged];
        
        return cell;
    }
    
    return nil;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == kSubscriptions) {
        return @"New episode available".ls;
    }
    else if (section == kNotifications) {
        return @"Types".ls;
    }
    return nil;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -

- (void) toggleLocalNotifications:(UISwitch*)sender
{
    if (sender.tag == 0) {
        [USER_DEFAULTS setBool:sender.on forKey:EnableManualRefreshFinishedNotification];
    }
    else if (sender.tag == 1) {
        [USER_DEFAULTS setBool:sender.on forKey:EnableManualDownloadFinishedNotification];
    }
    else if (sender.tag == 2) {
        [USER_DEFAULTS setBool:sender.on forKey:EnableNewEpisodeNotification];
        
        if (sender.on && [self.tableView numberOfSections] == kNumberOfSections-1) {
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:kSubscriptions] withRowAnimation:UITableViewRowAnimationFade];
        }
        else if (!sender.on && [self.tableView numberOfSections] == kNumberOfSections) {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:kSubscriptions] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    
    [USER_DEFAULTS synchronize];
}


- (void) toggleFeed:(UISwitch*)sender
{
    NSInteger index = sender.tag;
    CDFeed* feed = [DMANAGER.feeds objectAtIndex:index];
    [feed setBool:sender.on forKey:EnableNewEpisodeNotification];
}


@end
