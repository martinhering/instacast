//
//  ValuesTableViewController.m
//  Instacast
//
//  Created by Martin Hering on 29.11.12.
//
//

#import "ValuesTableViewController.h"
#import "UITableViewController+Settings.h"

@interface ValuesTableViewController ()

@end

@implementation ValuesTableViewController

+ (ValuesTableViewController*) tableViewController
{
    return [[self alloc] initWithStyle:UITableViewStyleGrouped];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setScrollView:self.tableView contentInsets:UIEdgeInsetsZero byAdjustingForStandardBars:YES];
    
    self.navigationItem.title = self.title;
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
    
    if (self.valueType == kValueTypeInteger) {
        NSNumber* value = [NSNumber numberWithInteger:[USER_DEFAULTS integerForKey:self.key]];
        
        if (([self.values indexOfObject:value] == indexPath.row)) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.textLabel.textColor = ICTintColor;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.textColor = ICTextColor;
        }
    }
    else if (self.valueType == kValueTypeString) {
        NSString* value = [USER_DEFAULTS stringForKey:self.key];
        
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id value = [self.values objectAtIndex:indexPath.row];
    if (value == [NSNull null]) {
        [USER_DEFAULTS removeObjectForKey:self.key];
    }
    else
    {
        switch (self.valueType) {
            case kValueTypeString:
                [USER_DEFAULTS setObject:value forKey:self.key];
                break;
            case kValueTypeBool:
                [USER_DEFAULTS setBool:[value boolValue] forKey:self.key];
                break;
            case kValueTypeInteger:
                [USER_DEFAULTS setInteger:[value integerValue] forKey:self.key];
                break;
            case kValueTypeDouble:
                [USER_DEFAULTS setDouble:[value doubleValue] forKey:self.key];
                break;
            default:
                break;
        }
    }
    
    NSArray* cells = [tableView visibleCells];
    for(UITableViewCell* cell in cells) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textColor = ICTextColor;
    }
    
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    cell.textLabel.textColor = ICTintColor;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
