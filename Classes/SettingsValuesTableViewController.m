//
//  FeedSettingsValuesTableViewController.m
//  Instacast
//
//  Created by Martin Hering on 20.02.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import "SettingsValuesTableViewController.h"

#import "FeedSettingsViewController.h"
#import "UITableViewController+Settings.h"

@interface NSUserDefaults (Settings)
- (void) setString:(NSString*)string forKey:(NSString *)aKey;
@end

@implementation NSUserDefaults (Settings)
- (void) setString:(NSString*)string forKey:(NSString *)aKey
{
    [self setObject:string forKey:aKey];
}
@end


@implementation SettingsValuesTableViewController

+ (SettingsValuesTableViewController*) tableViewController
{
    return [[self alloc] initWithStyle:UITableViewStyleGrouped];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setScrollView:self.tableView contentInsets:UIEdgeInsetsZero byAdjustingForStandardBars:YES];
    
    self.navigationItem.title = self.title;
    if ([[self.navigationController.viewControllers objectAtIndex:0] isKindOfClass:[FeedSettingsViewController class]]) {
        self.navigationItem.prompt = self.feed.title;
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tableView.backgroundColor = ICBackgroundColor;
    self.tableView.separatorColor = ICGroupCellSelectedBackgroundColor;
    
    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return [self.values count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [self standardCell];
    
    cell.textLabel.text = [self.titles objectAtIndex:indexPath.row];

    if (self.valueType == kSettingTypeInteger) {
        NSNumber* value = [NSNumber numberWithInteger:[[self source] integerForKey:self.key]];
        
        if (([self.values indexOfObject:value] == indexPath.row)) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.textLabel.textColor = ICTintColor;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.textColor = ICTextColor;
        }
    }
    else if (self.valueType == kSettingTypeString) {
        NSString* value = [[self source] stringForKey:self.key];
        
        if (([self.values indexOfObject:value] == indexPath.row) || (!value && self.values[indexPath.row] == [NSNull null])) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.textLabel.textColor = ICTintColor;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.textColor = ICTextColor;
        }
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return self.footerText;
}


#pragma mark - Table view delegate

- (id) source
{
    return (self.feed) ? self.feed : USER_DEFAULTS;
}

- (void) _setString:(NSString*)value forKey:(NSString*)key
{
    if (self.feed && [value isEqualToString:[USER_DEFAULTS stringForKey:key]]) {
        [self.feed resetValueForKey:key];
        return;
    }
    
    [[self source] setString:value forKey:key];
}

- (void) _setBool:(BOOL)value forKey:(NSString*)key
{
    if (self.feed && value == [USER_DEFAULTS boolForKey:key]) {
        [self.feed resetValueForKey:key];
        return;
    }
    
    [[self source] setBool:value forKey:key];
}

- (void) _setInteger:(NSInteger)value forKey:(NSString*)key
{
    if (self.feed && value == [USER_DEFAULTS integerForKey:key]) {
        [self.feed resetValueForKey:key];
        return;
    }
    
    [[self source] setInteger:value forKey:key];
}

- (void) _setDouble:(BOOL)value forKey:(NSString*)key
{
    if (self.feed && value == [USER_DEFAULTS doubleForKey:key]) {
        [self.feed resetValueForKey:key];
        return;
    }
    
    [[self source] setDouble:value forKey:key];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id value = [self.values objectAtIndex:indexPath.row];
    if (value == [NSNull null]) {
        if (self.feed) {
            [self.feed resetValueForKey:self.key];
        }
        else {
            [USER_DEFAULTS removeObjectForKey:self.key];
        }
    }
    else
    {
        switch (self.valueType) {
            case kSettingTypeString:
                [self _setString:value forKey:self.key];
                break;
            case kSettingTypeBool:
                [self _setBool:[value boolValue] forKey:self.key];
                break;
            case kSettingTypeInteger:
                [self _setInteger:[value integerValue] forKey:self.key];
                break;
            case kSettingTypeDouble:
                [self _setDouble:[value doubleValue] forKey:self.key];
                break;
            default:
                break;
        }
    }
    
    NSArray* cells = [tableView visibleCells];
    for(UITableViewCell* cell in cells) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textColor =  ICTextColor;
    }
    
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    cell.textLabel.textColor = ICTintColor;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
