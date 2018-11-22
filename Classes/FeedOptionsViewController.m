//
//  FeedOptionsViewController.m
//  Instacast
//
//  Created by Martin Hering on 31.05.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import "FeedOptionsViewController.h"

#import "FeedSettingsViewController.h"
#import "CDModel.h"
#import "SubscriptionSettingTableViewCell.h"

static NSString* kFeedCell = @"FeedCell";


@interface FeedOptionsViewController ()

@end

@implementation FeedOptionsViewController

+ (FeedOptionsViewController*) viewController
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

    [self.tableView registerClass:[SubscriptionSettingTableViewCell class] forCellReuseIdentifier:kFeedCell];
    
    self.clearsSelectionOnViewWillAppear = YES;
    self.navigationItem.title = @"Subscriptions".ls;
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
    return [DMANAGER.feeds count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SubscriptionSettingTableViewCell *cell = (SubscriptionSettingTableViewCell*)[tableView dequeueReusableCellWithIdentifier:kFeedCell forIndexPath:indexPath];

    CDFeed* feed = [DMANAGER.feeds objectAtIndex:indexPath.row];
    cell.textLabel.text = feed.title;
    cell.disclosureView.tintColor = ([feed hasCustomProperties]) ? ICTintColor : [UIColor colorWithRed:199/255.f green:199/255.f blue:204/255.f alpha:1.f];
    
    cell.switchControl.on = !feed.parked;
    cell.switchControl.tag = indexPath.row;
    [cell.switchControl addTarget:self action:@selector(switchParking:) forControlEvents:UIControlEventValueChanged];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CDFeed* feed = [DMANAGER.feeds objectAtIndex:indexPath.row];
    
    FeedSettingsViewController* viewController = [FeedSettingsViewController feedSettingsViewControllerWithFeed:feed];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"Use switch to temporarily disable subscription. Colored disclosure triangles indicate that custom settings apply.".ls;
}

- (void) switchParking:(UISwitch*)switchControl
{
    NSInteger index = switchControl.tag;
    CDFeed* feed = [DMANAGER.feeds objectAtIndex:index];
    feed.parked = !switchControl.on;
    
    [DMANAGER save];
}

@end
