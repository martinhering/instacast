//
//  MainSidebarController.m
//  Instacast
//
//  Created by Martin Hering on 29.06.13.
//
//

#import "MainSidebarController.h"
#import "MainSidebarTableCell.h"

#define ROW_HEIGHT 40

static NSString* kDataCellIdentifier = @"DataCell";
static NSString* kHeaderCellIdentifier = @"HeaderCell";

@implementation MainSidebarItem

+ (instancetype) itemWithTitle:(NSString*)title tag:(NSInteger)tag image:(UIImage*)image selectedImage:(UIImage*)selectedImage
{
    MainSidebarItem* item = [[self alloc] init];
    item.title = title;
    item.tag = tag;
    item.image = image;
    item.selectedImage = selectedImage;
    return item;
}

@end

@interface MainSidebarController ()
@end

@implementation MainSidebarController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.allowsMultipleSelection = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = ROW_HEIGHT;
    
    [self.tableView registerClass:[MainSidebarTableCell class] forCellReuseIdentifier:kDataCellIdentifier];
    [self.tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:kHeaderCellIdentifier];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = ICDarkBackgroundColor;
    [self.tableView reloadData];
    
    [self updateRowSelectionForSelectedItemTag];
    [self updateTableTopInset:UIInterfaceOrientationPortrait];
}


- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void) updateTableTopInset:(UIInterfaceOrientation)orientation
{
    CGRect b = self.view.bounds;
    CGFloat h = 0;
    
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        h = (CGRectGetHeight(b) < CGRectGetWidth(b)) ? CGRectGetHeight(b) : CGRectGetWidth(b);
    }
    else {
        h = (CGRectGetHeight(b) > CGRectGetWidth(b)) ? CGRectGetHeight(b) : CGRectGetWidth(b);
    }
    
    
    NSInteger itemCount = [self.items count]-1;
    for (NSArray* items in self.items) {
        itemCount += [items count];
    }
    
    CGFloat headerHeight = floorf((h-(itemCount*(ROW_HEIGHT+1)))/2);
    headerHeight = MAX(headerHeight, 94+15);
    self.tableView.contentInset = UIEdgeInsetsMake(headerHeight, 0, 0, 0);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [self updateTableTopInset:interfaceOrientation];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.items count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.items[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MainSidebarTableCell *cell = [tableView dequeueReusableCellWithIdentifier:kDataCellIdentifier forIndexPath:indexPath];
    
    NSArray* sectionItems = self.items[indexPath.section];
    MainSidebarItem* item = sectionItems[indexPath.row];
    cell.objectValue = item;
    
    NSInteger badgeNumber = (item.badgeNumber) ? item.badgeNumber() : 0;
    cell.badgeButton.hidden = (badgeNumber == 0);
    
    [cell.badgeButton setTitle:[@(badgeNumber) stringValue] forState:UIControlStateNormal];
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray* sectionItems = self.items[indexPath.section];
    MainSidebarItem* item = sectionItems[indexPath.row];
    
    NSInteger lastSelectedItemTag = self.selectedItemTag;
    self.selectedItemTag = item.tag;
    [self updateRowSelectionForSelectedItemTag];
    
    if (!self.didSelectItem(item)) {
        self.selectedItemTag = lastSelectedItemTag;
        [self updateRowSelectionForSelectedItemTag];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section != 0) {
        return 20.0f;
    }
    
    return 0.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UITableViewHeaderFooterView* headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kHeaderCellIdentifier];
    
    UIView *customView = [[UIView alloc] initWithFrame:CGRectZero];
    customView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    customView.backgroundColor = [UIColor clearColor];
    
    headerView.backgroundView = customView;

    return headerView;
}

- (void) updateRowSelectionForSelectedItemTag
{
    [self.items enumerateObjectsUsingBlock:^(NSArray* sectionItems, NSUInteger section, BOOL *stop1) {
        [sectionItems enumerateObjectsUsingBlock:^(MainSidebarItem* item, NSUInteger row, BOOL *stop2) {
            if (item.tag == self.selectedItemTag) {
                NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
                *stop1 = YES;
                *stop2 = YES;
            }
        }];
    }];
}


@end
