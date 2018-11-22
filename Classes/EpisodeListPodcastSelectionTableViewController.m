//
//  EpisodeListPodcastSelectionTableViewController.m
//  Instacast
//
//  Created by Martin Hering on 21.08.14.
//
//

#import "EpisodeListPodcastSelectionTableViewController.h"
#import "UITableViewController+Settings.h"


@interface EpisodeListPodcastSelectionTableViewController ()
@end

@implementation EpisodeListPodcastSelectionTableViewController

+ (instancetype) viewController {
    return [[self alloc] initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Add Selected Podcasts".ls;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.selectedPodcasts) {
        self.selectedPodcasts = [[NSOrderedSet alloc] init];
    }
    
    [self setScrollView:self.tableView contentInsets:UIEdgeInsetsZero byAdjustingForStandardBars:YES];
    
    self.tableView.backgroundColor = ICBackgroundColor;
    self.tableView.separatorColor = ICGroupCellSelectedBackgroundColor;
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [DMANAGER.visibleFeeds count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self standardCell];
    
    CDFeed* feed = [DMANAGER.visibleFeeds objectAtIndex:indexPath.row];
    cell.textLabel.text = feed.title;
    
    UIImage* localImage = [[ImageCacheManager sharedImageCacheManager] localImageForImageURL:feed.imageURL size:56 grayscale:NO];
    cell.imageView.image = localImage;
    
    cell.accessoryType = ([self.selectedPodcasts containsObject:feed]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - Actions

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CDFeed* feed = [DMANAGER.visibleFeeds objectAtIndex:indexPath.row];
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if ([self.selectedPodcasts containsObject:feed]) {
        [[self mutableOrderedSetValueForKey:@"selectedPodcasts"] removeObject:feed];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else
    {
        NSMutableOrderedSet* newSet = [self.selectedPodcasts mutableCopy];
        [newSet addObject:feed];
        
        NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"rank" ascending:YES];
        [newSet sortUsingDescriptors:@[ sortDescriptor ]];
        
        self.selectedPodcasts = newSet;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
