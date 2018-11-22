//
//  GeneralSettingsViewController.m
//  Instacast
//
//  Created by Martin Hering on 21.06.13.
//
//

#import "GeneralSettingsViewController.h"
#import "UITableViewController+Settings.h"
#import "SettingsValuesTableViewController.h"
#import "PlaybackDefines.h"
#import "InstacastAppDelegate.h"

typedef NS_ENUM(NSInteger, GeneralSettingsSections) {
    k3GSection = 0,
    kPlaybackSection,
    kAppearanceThemeSection,
    kAppSection,
    kDebuggingSection,
    kNumberOfSections,
};

typedef NS_ENUM(NSInteger, CellularDataUsage) {
    kDontUseCellularData = 0,
    kDontDownloadOverCellular,
    kUseCellularData,
};

@interface GeneralSettingsViewController ()
@end

@implementation GeneralSettingsViewController

+ (GeneralSettingsViewController*) viewController
{
    return [[self alloc] initWithStyle:UITableViewStyleGrouped];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setScrollView:self.tableView contentInsets:UIEdgeInsetsZero byAdjustingForStandardBars:YES];
    
    self.clearsSelectionOnViewWillAppear = YES;
    self.navigationItem.title = @"General".ls;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tableView.backgroundColor = ICBackgroundColor;
    self.tableView.separatorColor = ICGroupCellSelectedBackgroundColor;
    
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
        case k3GSection:
            return 3;
        case kPlaybackSection:
            return 6;
        case kAppearanceThemeSection:
            return 2;
        case kAppSection:
            return 2;
        case kDebuggingSection:
            return 1;
        default:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == k3GSection)
    {
        UITableViewCell* cell = [self standardCell];
        
        CellularDataUsage usage = kDontUseCellularData;
        if ([USER_DEFAULTS boolForKey:EnableStreamingOver3G] && ![USER_DEFAULTS boolForKey:EnableCachingOver3G]) {
            usage = kDontDownloadOverCellular;
        }
        else if ([USER_DEFAULTS boolForKey:EnableStreamingOver3G] && [USER_DEFAULTS boolForKey:EnableCachingOver3G]) {
            usage = kUseCellularData;
        }
        
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Don't use Cellular Data".ls;
                cell.textLabel.textColor = (usage == kDontUseCellularData) ? ICTintColor : ICTextColor;
                cell.accessoryType = (usage == kDontUseCellularData) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                break;
            case 1:
                cell.textLabel.text = @"Don't download media".ls;
                cell.textLabel.textColor = (usage == kDontDownloadOverCellular) ? ICTintColor : ICTextColor;
                cell.accessoryType = (usage == kDontDownloadOverCellular) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                break;
            case 2:
                cell.textLabel.text = @"Always use Cellular Data".ls;
                cell.textLabel.textColor = (usage == kUseCellularData) ? ICTintColor : ICTextColor;
                cell.accessoryType = (usage == kUseCellularData) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                break;
            default:
                break;
        }
        
        cell.detailTextLabel.text = nil;
        return cell;
    }
    
    else if (indexPath.section == kPlaybackSection)
    {
        NSDictionary* skippingValues = @{ @5 : @"5 Seconds".ls, @10 : @"10 Seconds".ls, @20 : @"20 Seconds".ls, @30 : @"30 Seconds".ls, @60 : @"1 Minute".ls, @120 : @"2 Minutes".ls, @300 : @"5 Minutes".ls, @600 : @"10 Minutes".ls };
        
        switch (indexPath.row) {
            case 0:
            {
                UITableViewCell* cell = [self switchCell];
                UISwitch* control = (UISwitch*)cell.accessoryView;
                
                cell.textLabel.text = @"Replay after Pause".ls;
                control.on = [USER_DEFAULTS boolForKey:PlayerReplayAfterPause];
                
                cell.detailTextLabel.text = nil;
                
                control.tag = indexPath.row;
                [control addTarget:self action:@selector(togglePlayerSettings:) forControlEvents:UIControlEventValueChanged];
                return cell;
            }
            case 1:
            {
                UITableViewCell* cell = [self detailCell];
                
                cell.textLabel.text = @"Skipping Back".ls;
                
                NSInteger period = [USER_DEFAULTS integerForKey:PlayerSkipBackPeriod];
                cell.detailTextLabel.text = skippingValues[@(period)];
                
                return cell;
            }
            case 2:
            {
                UITableViewCell* cell = [self detailCell];
                
                cell.textLabel.text = @"Skipping Forward".ls;
                
                NSInteger period = [USER_DEFAULTS integerForKey:PlayerSkipForwardPeriod];
                cell.detailTextLabel.text = skippingValues[@(period)];
                
                return cell;
            }
            case 3:
            {
                UITableViewCell* cell = [self detailCell];
                
                cell.textLabel.text = @"Speed".ls;
                
                NSInteger speed = [USER_DEFAULTS integerForKey:DefaultPlaybackSpeed];
                
                NSDictionary* speedValues = @{ @(PlaybackSpeedControlNormalSpeed) : @"Normal (1x)".ls,
                                               @(PlaybackSpeedControlDoubleSpeed) : @"Fast (2x)".ls,
                                               @(PlaybackSpeedControlPlusHalfSpeed) : @"Faster (1.5x)".ls,
                                               @(PlaybackSpeedControlMinusHalfSpeed) : @"Slower (0.5x)".ls,
                                               @(PlaybackSpeedControlTripleSpeed) : @"Crazy (3x)".ls };
                
                cell.detailTextLabel.text = speedValues[@(speed)];
                
                return cell;
            }
            case 4:
            {
                UITableViewCell* cell = [self detailCell];
                
                cell.textLabel.text = @"System Controls".ls;
                
                DefaultPlayerControls controls = [USER_DEFAULTS integerForKey:kDefaultPlayerControls];
                
                NSDictionary* values = @{ @(kPlayerSeekingControls) : @"Seeking".ls,
                                          @(kPlayerSeekingAndSkippingChaptersControls) : @"Seeking and Skipping Chapters".ls,
                                          @(kPlayerSkippingControls) : @"Skipping".ls };
                
                cell.detailTextLabel.text = [values[@(controls)] ls];
                
                return cell;
            }
            case 5:
            {
                UITableViewCell* cell = [self switchCell];
                UISwitch* control = (UISwitch*)cell.accessoryView;
                control.tag = indexPath.row;
                
                cell.textLabel.text = @"Disable Auto-Lock".ls;
                control.on = [USER_DEFAULTS boolForKey:DisableAutoLock];
                
                cell.detailTextLabel.text = nil;

                [control addTarget:self action:@selector(togglePlayerSettings:) forControlEvents:UIControlEventValueChanged];
                return cell;
            }
                
            default:
                break;
        }
    }
    
    else if (indexPath.section == kAppearanceThemeSection)
    {
        BOOL switchAutomatically = [ICAppearanceManager sharedManager].switchesNightModeAutomatically;
        
        switch (indexPath.row) {
            case 0:
            {
                UITableViewCell* cell = [self switchCell];
                UISwitch* control = (UISwitch*)cell.accessoryView;
                control.tag = indexPath.row;
                
                cell.textLabel.text = @"Enable".ls;
                
                control.on = [ICAppearanceManager sharedManager].nightMode;
                [control addTarget:self action:@selector(toggleNightModeSettings:) forControlEvents:UIControlEventValueChanged];
                
                
                return cell;
            }
            case 1:
            {
                UITableViewCell* cell = [self switchCell];
                UISwitch* control = (UISwitch*)cell.accessoryView;
                control.tag = indexPath.row;
                
                cell.textLabel.text = @"Switch Automatically".ls;
                control.on = switchAutomatically;
                [control addTarget:self action:@selector(toggleNightModeSettings:) forControlEvents:UIControlEventValueChanged];
                return cell;
            }
            
            default:
                break;
        }
        
    }
    
    else if (indexPath.section == kAppSection)
    {
        switch (indexPath.row) {
            case 0:
            {
                UITableViewCell* cell = [self switchCell];
                UISwitch* control = (UISwitch*)cell.accessoryView;
                control.tag = indexPath.row;
                
                cell.textLabel.text = @"Application Badge".ls;
                control.on = [USER_DEFAULTS boolForKey:ShowApplicationBadgeForUnseen];
                [control addTarget:self action:@selector(toggleAppSettings:) forControlEvents:UIControlEventValueChanged];
                return cell;
            }
            case 1:
            {
                UITableViewCell* cell = [self switchCell];
                UISwitch* control = (UISwitch*)cell.accessoryView;
                control.tag = indexPath.row;
                
                cell.textLabel.text = @"Interface Sounds".ls;
                control.on = [USER_DEFAULTS boolForKey:UISoundEnabled];
                [control addTarget:self action:@selector(toggleAppSettings:) forControlEvents:UIControlEventValueChanged];
                return cell;
            }
            default:
                break;
        }
    }
    
    else if (indexPath.section == kDebuggingSection)
    {
        UITableViewCell* cell = [self detailCell];
        
        cell.textLabel.text = @"Send Reports".ls;
        
        NSInteger value = [USER_DEFAULTS integerForKey:AllowSendingDiagnostics];
        NSDictionary* values = @{ @2 : @"Automatically".ls, @1 : @"Ask Before Sending".ls, @0 : @"Don't Send".ls };
        cell.detailTextLabel.text = values[@(value)];
        
        return cell;
        
    }
    
    return nil;
}


- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case k3GSection:
            return @"Cellular Data (EDGE, 3G, LTE)".ls;
        case kPlaybackSection:
            return @"Playback".ls;
        case kAppearanceThemeSection:
            return @"Night Mode".ls;
        case kAppSection:
            return @"Miscellaneous".ls;
        case kDebuggingSection:
            return @"Crash & Failure Diagnostics".ls;
        default:
            break;
    }
    
    return nil;
}

- (NSString*) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (section)
    {
        case k3GSection:
        {
            return @"You can either disable the usage of cellular data completely (which might decrease the user experience when not on WiFi), enable cellular usage for everything except downloading episodes, or enable cellular usage for everything including downloading episodes. Disabling cellular data completely will also prevent iOS's cellular data alert from popping up.".ls;
        }
        case kDebuggingSection:
        {
            NSString* footerText = @"Help Vemedio improve its products and services by automatically sending reports upon application crash or failure. Reports do not include any personal or private data.".ls;
            footerText = [footerText stringByAppendingFormat:@"\n\nCloud ID: %@", [NSBundle deviceId]];
            return footerText;
        }
        case kAppearanceThemeSection:
        {
            return @"Night mode can be enabled automatically at sunset, and disabled automatically at sunrise. To calculate the times of sunset and sunrise, Instacast asks for your permission to gather location data. Location data is only ever gathered when you open the app – never in the background.".ls;
        }
        default:
            break;
    }
    
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == k3GSection)
    {
        switch (indexPath.row) {
            case 0:
            {
                [USER_DEFAULTS setBool:NO forKey:EnableStreamingOver3G];
                [USER_DEFAULTS setBool:NO forKey:EnableCachingImagesOver3G];
                [USER_DEFAULTS setBool:NO forKey:EnableRefreshingOver3G];
                [USER_DEFAULTS setBool:NO forKey:EnableSyncingOver3G];
                [USER_DEFAULTS setBool:NO forKey:EnableCachingOver3G];
                break;
            }
            case 1:
                [USER_DEFAULTS setBool:YES forKey:EnableStreamingOver3G];
                [USER_DEFAULTS setBool:YES forKey:EnableCachingImagesOver3G];
                [USER_DEFAULTS setBool:YES forKey:EnableRefreshingOver3G];
                [USER_DEFAULTS setBool:YES forKey:EnableSyncingOver3G];
                [USER_DEFAULTS setBool:NO forKey:EnableCachingOver3G];
                break;
            case 2:
                [USER_DEFAULTS setBool:YES forKey:EnableStreamingOver3G];
                [USER_DEFAULTS setBool:YES forKey:EnableCachingImagesOver3G];
                [USER_DEFAULTS setBool:YES forKey:EnableRefreshingOver3G];
                [USER_DEFAULTS setBool:YES forKey:EnableSyncingOver3G];
                [USER_DEFAULTS setBool:YES forKey:EnableCachingOver3G];
                break;
            default:
                break;
        }

        // update table
        for(NSIndexPath* ip in [tableView indexPathsForVisibleRows]) {
            if (ip.section == indexPath.section) {
                [tableView cellForRowAtIndexPath:ip].accessoryType = UITableViewCellAccessoryNone;
                [tableView cellForRowAtIndexPath:ip].textLabel.textColor = ICTextColor;
            }
        }
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        [tableView cellForRowAtIndexPath:indexPath].textLabel.textColor = ICTintColor;
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }

    else if (indexPath.section == kPlaybackSection)
    {
        switch (indexPath.row) {
            case 1:
            case 2:
            {
                SettingsValuesTableViewController* controller = [SettingsValuesTableViewController tableViewController];
                controller.valueType = kSettingTypeInteger;
                controller.key = (indexPath.row == 1) ? PlayerSkipBackPeriod : PlayerSkipForwardPeriod;
                controller.title = (indexPath.row == 1) ? @"Skipping Back".ls : @"Skipping Forward".ls;
                controller.values = @[ @5, @10, @20, @30, @60, @120, @300, @600 ];
                controller.titles = @[ @"5 Seconds".ls, @"10 Seconds".ls, @"20 Seconds".ls, @"30 Seconds".ls, @"1 Minute".ls, @"2 Minutes".ls, @"5 Minutes".ls, @"10 Minutes".ls];
                [self.navigationController pushViewController:controller animated:YES];
                break;
            }
            case 3:
            {
                SettingsValuesTableViewController* controller = [SettingsValuesTableViewController tableViewController];
                controller.valueType = kSettingTypeInteger;
                controller.key = DefaultPlaybackSpeed;
                controller.title = @"Speed".ls;
                controller.values = @[ @(PlaybackSpeedControlMinusHalfSpeed), @(PlaybackSpeedControlNormalSpeed), @(PlaybackSpeedControlPlusHalfSpeed), @(PlaybackSpeedControlDoubleSpeed), @(PlaybackSpeedControlTripleSpeed) ];
                controller.titles = @[ @"Slower (0.5x)".ls, @"Normal (1x)".ls, @"Faster (1.5x)".ls, @"Fast (2x)".ls, @"Crazy (3x)".ls ];
                [self.navigationController pushViewController:controller animated:YES];
                break;
            }
            case 4:
            {
                SettingsValuesTableViewController* controller = [SettingsValuesTableViewController tableViewController];
                controller.valueType = kSettingTypeInteger;
                controller.key = kDefaultPlayerControls;
                controller.title = @"System Controls".ls;
                controller.values = @[ @(kPlayerSeekingControls), @(kPlayerSeekingAndSkippingChaptersControls), @(kPlayerSkippingControls)];
                controller.titles = @[ @"Seeking".ls, @"Seeking and Skipping Chapters".ls, @"Skipping".ls];
                [self.navigationController pushViewController:controller animated:YES];
                break;
            }
            default:
                break;
        }
    }
    
    else if (indexPath.section == kDebuggingSection)
    {
        SettingsValuesTableViewController* controller = [SettingsValuesTableViewController tableViewController];
        controller.valueType = kSettingTypeInteger;
        controller.key = AllowSendingDiagnostics;
        controller.title = @"Send Reports".ls;
        controller.values = @[ @2, @1, @0 ];
        controller.titles = @[ @"Automatically".ls, @"Ask Before Sending".ls, @"Don't Send".ls ];
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void) toggle3GSettings:(UISwitch*)sender
{
    switch (sender.tag) {
        case 0:
        {
            [USER_DEFAULTS setBool:sender.on forKey:EnableStreamingOver3G];
            [USER_DEFAULTS setBool:sender.on forKey:EnableCachingImagesOver3G];
            [USER_DEFAULTS setBool:sender.on forKey:EnableRefreshingOver3G];
            [USER_DEFAULTS setBool:sender.on forKey:EnableSyncingOver3G];
            break;
        }
        case 1:
        {
            [USER_DEFAULTS setBool:sender.on forKey:EnableCachingOver3G];
            break;
        }
        default:
            break;
    }
}

- (void) togglePlayerSettings:(UISwitch*)sender
{
    if (sender.tag == 0) {
        [USER_DEFAULTS setBool:sender.on forKey:PlayerReplayAfterPause];
    }
    else if (sender.tag == 5) {
        [USER_DEFAULTS setBool:sender.on forKey:DisableAutoLock];
    }
}

- (void) toggleAppSettings:(UISwitch*)sender
{
    if (sender.tag == 0) {
        [USER_DEFAULTS setBool:sender.on forKey:ShowApplicationBadgeForUnseen];
    }
    else if (sender.tag == 1) {
        [USER_DEFAULTS setBool:sender.on forKey:UISoundEnabled];
    }
}


- (void) toggleNightModeSettings:(UISwitch*)sender
{
    UISwitch* theSwitch = sender;
    
    switch (sender.tag) {
        case 0:
        {
            [self perform:^(id sender) {
                [ICAppearanceManager sharedManager].nightMode = theSwitch.on;
            } afterDelay:0.3];
        }
            break;
        case 1:
        {
            [ICAppearanceManager sharedManager].switchesNightModeAutomatically = sender.on;
            
            [self perform:^(id sender) {
                if (![[ICAppearanceManager sharedManager] switchNightModeAutomaticallyNow])
                {
                    [self presentAlertControllerWithTitle:@"Location Services denied".ls
                                                  message:@"To switch to night mode automatically, please go to iOS's Settings app and allow Instacast to use Location Services.".ls
                                                   button:@"OK".ls
                                                 animated:YES
                                               completion:NULL];
                }
                
                if ([ICAppearanceManager sharedManager].switchesNightModeAutomatically != theSwitch.on) {
                    theSwitch.on = [ICAppearanceManager sharedManager].switchesNightModeAutomatically;
                }
                
            } afterDelay:0.3];
        }
            break;
            
        default:
            break;
    }
    
}
@end
