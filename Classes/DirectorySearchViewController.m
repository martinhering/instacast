    //
//  DirectorySearchViewController.m
//  Instacast
//
//  Created by Martin Hering on 17.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import "DirectorySearchViewController.h"
#import "DirectoryFeedTableViewCell.h"
#import "DirectoryFeedViewController.h"

#import "STITunesStore.h"
#import "ICFeedURLScraper.h"
#import "ICFeedParser.h"
#import "ICSearchBar.h"


@interface DirectorySearchViewController ()
@property (nonatomic, strong) ICSearchBar* searchBar;
@property (nonatomic, strong) NSString* searchTerm;
@property (nonatomic, strong) STITunesStore* store;
@property (nonatomic, strong) NSArray* searchResults;
@property (nonatomic, strong) NSMutableDictionary* imageCache;
@property (nonatomic, weak) NSTimer* searchTimer;
@property (nonatomic, strong) ICFeedURLScraper* scraper;
@property (nonatomic, strong) ICFeedParser* feedParser;
@property (nonatomic) BOOL searchBarActive;
@end

NSString* kUIPersistenceDirectorySearchSearchString = @"SearchControllerSearchString";
NSString* kUIPersistenceDirectorySearchSelectedScopeIndex = @"DirectorySearchSelectedScopeIndex";


@implementation DirectorySearchViewController

+ (DirectorySearchViewController*) directorySearchViewController
{
	return [[self alloc] initWithStyle:UITableViewStylePlain];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Search".ls;

    self.tableView.rowHeight = 57+10;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    
	ICSearchBar* searchBar = [[ICSearchBar alloc] initWithFrame:CGRectZero];
    self.searchBar = searchBar;
    
    searchBar.backgroundImage = [[UIImage alloc] init];
    searchBar.scopeBarBackgroundImage = [[UIImage alloc] init];
    
	searchBar.delegate = self;
	searchBar.scopeButtonTitles = [NSArray arrayWithObjects:@"Title".ls, @"Author".ls, @"Description".ls, nil];
	searchBar.showsScopeBar = YES;
	searchBar.selectedScopeButtonIndex = [USER_DEFAULTS integerForKey:kUIPersistenceDirectorySearchSelectedScopeIndex];
	searchBar.placeholder = @"Search or Enter URL".ls;
	searchBar.text = [USER_DEFAULTS objectForKey:kUIPersistenceDirectorySearchSearchString];
    searchBar.translucent = YES;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	[searchBar sizeToFit];
    
	self.tableView.tableHeaderView = searchBar;
	
	self.imageCache = [NSMutableDictionary dictionary];
	
	if ([searchBar.text length] > 2) {
		self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(searchTimer:) userInfo:self.searchBar.text repeats:NO];
	}
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    [self setScrollView:self.tableView contentInsets:UIEdgeInsetsZero byAdjustingForStandardBars:YES];
	
    self.tableView.backgroundColor = ICBackgroundColor;
    self.tableView.separatorColor = ICTableSeparatorColor;
    
    [self.searchBar appearanceDidChange];
    
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Player Close"] style:UIBarButtonItemStylePlain target:self action:@selector(close:)];
    
	[self.tableView reloadData];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// remove search timer
	[self.searchTimer invalidate];
	self.searchTimer = nil;
	
	[NSRunLoop cancelPreviousPerformRequestsWithTarget:self];
}


- (void)dealloc {
	
	[_store cancelStoreSearch];
	[_scraper cancel];
	[_feedParser cancel];
}

- (void) close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}
#pragma mark TableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.searchResults count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"DirectoryFeedCell";
	
	DirectoryFeedTableViewCell *cell = (DirectoryFeedTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[DirectoryFeedTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
	}
    cell.backgroundColor = tableView.backgroundColor;
    
    if (indexPath.row >= [self.searchResults count]) {
        return cell;
    }
	
	NSDictionary* searchResult = [self.searchResults objectAtIndex:indexPath.row];
	cell.textLabel.text = [searchResult objectForKey:kiTunesStoreAlbum];
	cell.detailTextLabel.text = [searchResult objectForKey:kiTunesStoreArtist];
	
	
	cell.video = NO;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

	NSString* imageURLString = [searchResult objectForKey:kiTunesStoreArtwork100];
	UIImage* image = [self.imageCache objectForKey:imageURLString];
	if (image) {
        cell.imageView.image = image;
	}
	else
	{
		cell.imageView.image = [UIImage imageNamed:@"Podcast Placeholder 56"];
		
		NSURL* imageURL = [NSURL URLWithString:imageURLString];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
			NSData* imageData = [[NSData alloc] initWithContentsOfURL:imageURL];
			UIImage* image = [[UIImage alloc] initWithData:imageData];
			
			if (image)
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					cell.imageView.image = image;
					[self.imageCache setObject:image forKey:imageURLString];
				});
			}
		});
	}

	return cell;
}

#pragma mark TableView Delegate

- (void) _abortSelectingCell
{
	NSIndexPath* selectedIndexPath = [self.tableView indexPathForSelectedRow];
	if (selectedIndexPath) {
		UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:selectedIndexPath];
		cell.accessoryView = nil;
		[self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
	}
	self.view.userInteractionEnabled = YES;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self.searchBar resignFirstResponder];
	
	NSDictionary* searchResult = [self.searchResults objectAtIndex:indexPath.row];
    NSURL* feedURL = searchResult[kiTunesStoreFeedURL];
	
    if (feedURL) {
        __weak DirectorySearchViewController* weakSelf = self;
        DirectoryFeedViewController* feedViewController = [DirectoryFeedViewController directoryFeedViewController];
        feedViewController.feedURL = feedURL;
        feedViewController.processAlternateFeeds = YES;
        feedViewController.shouldPopBackToList = YES;
        feedViewController.didLoadFeed = ^(BOOL success, NSError* error) {
            if (error) {
                [self presentError:error];
                [weakSelf.navigationController popViewControllerAnimated:YES];
            }
        };
        [feedViewController startLoading];
        [self.navigationController pushViewController:feedViewController animated:YES];
    }
    else
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark -
#pragma mark ScrollView Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{	
	[self.searchBar resignFirstResponder];
}

#pragma mark UISearchBar Delegate

- (void) searchTimer:(NSTimer*)timer
{
	self.searchTimer = nil;
	NSString* searchText = [timer userInfo];
    
    if ([searchText rangeOfString:@"://"].location != NSNotFound) {
        return;
    }
    
    [App retainNetworkActivity];
    
	self.store = [[STITunesStore alloc] init];
	self.store.media = @"podcast";
	self.store.entity = @"podcast";
	
	NSArray* attributeTerms = [NSArray arrayWithObjects:@"titleTerm", @"artistTerm", @"descriptionTerm", nil];
	self.store.attribute = [attributeTerms objectAtIndex:self.searchBar.selectedScopeButtonIndex];
	
	[self.store startStoreSearchForSearchString:searchText delegate:self];
	
	[USER_DEFAULTS setObject:searchText forKey:kUIPersistenceDirectorySearchSearchString];
	[USER_DEFAULTS setInteger:self.searchBar.selectedScopeButtonIndex forKey:kUIPersistenceDirectorySearchSelectedScopeIndex];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	[self.searchTimer invalidate];
	self.searchTimer = nil;
	
	if (self.store) {
		[self.store cancelStoreSearch];
		[App releaseNetworkActivity];
	}
	
	if ([searchText length] >= 3)
	{
		self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(searchTimer:) userInfo:searchText repeats:NO];
	}
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	[self.searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	self.searchTerm = self.searchBar.text;
	[self.searchBar resignFirstResponder];
    
    if ([self.searchTerm rangeOfString:@"://"].location != NSNotFound)
    {
        NSURL* feedURL = [NSURL URLWithString:self.searchTerm];
        
        NSString* urlString = [[feedURL absoluteString] substringFromIndex:[[feedURL scheme] length]];
        if ([urlString hasPrefix:@":http://"] || [urlString hasPrefix:@":https://"]) {
            NSString* newURLString = [urlString substringFromIndex:1];
            feedURL = [NSURL URLWithString:newURLString];
        }
        
        if (![[feedURL scheme] caseInsensitiveEquals:@"http"] && ![[feedURL scheme] caseInsensitiveEquals:@"https"]) {
            NSString* scheme = [feedURL scheme];
            NSString* urlString = [feedURL absoluteString];
            urlString = [urlString stringByReplacingCharactersInRange:NSMakeRange(0, [scheme length]) withString:@"http"];
            feedURL = [NSURL URLWithString:urlString];
        }
        
        if (feedURL)
        {
            __weak DirectorySearchViewController* weakSelf = self;
            
            DirectoryFeedViewController* feedViewController = [DirectoryFeedViewController directoryFeedViewController];
            
            if ([[[feedURL host] lowercaseString] isEqualToString:@"itunes.apple.com"]) {
                feedViewController.itunesURL = feedURL;
            } else {
                feedViewController.feedURL = feedURL;
            }
            feedViewController.didLoadFeed = ^(BOOL success, NSError* error) {
                if (error) {
                    [self presentError:error];
                    [weakSelf.navigationController popViewControllerAnimated:YES];
                }
            };
            [feedViewController startLoading];
            [self.navigationController pushViewController:feedViewController animated:YES];
        }
        
        return;
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    self.searchBarActive = YES;
	//[self.searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    self.searchBarActive = NO;
	//[self.searchBar setShowsCancelButton:NO animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
	[self.searchTimer invalidate];
	self.searchTimer = nil;

	self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(searchTimer:) userInfo:self.searchBar.text repeats:NO];
}

//- (BOOL) prefersStatusBarHidden
//{
//    return self.searchBarActive;
//}

- (void) setSearchBarActive:(BOOL)searchBarActive
{
    if (searchBarActive != _searchBarActive) {
        _searchBarActive = searchBarActive;
        
        /*
        CGFloat barHeight = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? 20 : 0;
        
        if (searchBarActive)
        {
            [self setNeedsStatusBarAppearanceUpdate];
            
            [self.tableView setContentOffset:CGPointMake(0, 0) animated:YES];
            [self perform:^(id sender) {
                [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 50, 0)];
            } afterDelay:0.3];

            [self.searchBar setShowsCancelButton:YES animated:YES];
            
            UIButton* button = [self.searchBar valueForKey:@"cancelButton"];
            button.tintColor = ICTintColor;
            
            [self.navigationController setNavigationBarHidden:YES animated:YES];
        }
        else
        {

            [self.tableView setContentOffset:CGPointMake(0, -barHeight-44) animated:YES];
            [self perform:^(id sender) {
                [self.tableView setContentInset:UIEdgeInsetsMake(barHeight+44, 0, 50, 0)];
                [self setNeedsStatusBarAppearanceUpdate];
            } afterDelay:0.3];
            
            [self.navigationController setNavigationBarHidden:NO animated:YES];
            
            [self.searchBar setShowsCancelButton:NO animated:YES];
            [self.searchBar resignFirstResponder];
        }
         */
    }
}


#pragma mark iTunes Store Delegate

- (void) itunesStore:(STITunesStore*)store didFindSearchResults:(NSArray*)theSearchResults
{
	DebugLog(@"itunesStore end %lu", (unsigned long)[theSearchResults count]);
	self.searchResults = theSearchResults;
	self.store = nil;
	
	//self.tableView.scrollEnabled = ([self.searchResults count] > 0);
	[self.tableView reloadData];
	//[self.tableView setContentOffset:CGPointMake(0, -20-44) animated:NO];
	
	[App releaseNetworkActivity];
}

- (void) itunesStore:(STITunesStore*)store didEndWithError:(NSError*)error
{
	ErrLog(@"iTunes Store fail: %@", [error description]);
	self.store = nil;
	self.searchResults = nil;
	
	//self.tableView.scrollEnabled = NO;
	[self.tableView reloadData];
	//[self.tableView setContentOffset:CGPointMake(0, -20-44) animated:NO];
	
	[App releaseNetworkActivity];
}



- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {

    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{

}
@end
