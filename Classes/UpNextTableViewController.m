//
//  UpNextTableViewController.m
//  Instacast
//
//  Created by Martin Hering on 31.10.14.
//
//

#import "UpNextTableViewController.h"
#import "EpisodesTableViewCell.h"

static NSString* kUpNextCell = @"UpNextCell";

@interface UpNextTableViewController ()

@end

@implementation UpNextTableViewController

+ (instancetype) viewController {
    return [[self alloc] initWithStyle:UITableViewStylePlain];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self setScrollView:self.tableView contentInsets:UIEdgeInsetsMake(20, 0, 0, 0) byAdjustingForStandardBars:YES];
    
    self.title = @"Up Next".ls;
    
    self.tableView.separatorInset = UIEdgeInsetsZero;
    [self.tableView registerClass:[EpisodesTableViewCell class] forCellReuseIdentifier:kUpNextCell];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Player Close"] style:UIBarButtonItemStylePlain target:self action:@selector(playerCloseButtonAction:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Remove All".ls style:UIBarButtonItemStylePlain target:self action:@selector(removeAllButtonAction:)];
    
    [self setEditing:YES animated:NO];
}

- (void) playerCloseButtonAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void) removeAllButtonAction:(id)sender
{
    [[AudioSession sharedAudioSession] eraseAllEpisodesFromUpNext];
    [self.tableView reloadData];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tableView.backgroundColor = ICBackgroundColor;
    self.tableView.separatorColor = ICTableSeparatorColor;
    
    // remove existing episodes from Up Next
    if ([self.episodesToInsert count] > 0) {
        [[AudioSession sharedAudioSession] eraseEpisodesFromUpNext:self.episodesToInsert];
    }
    
    [self.tableView reloadData];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // insert rows
    if ([self.episodesToInsert count] > 0)
    {
        AudioSession* audioSession = [AudioSession sharedAudioSession];
        // remove currently playing
        NSMutableArray* mutableEpisodes = [self.episodesToInsert mutableCopy];
        [mutableEpisodes removeObject:audioSession.episode];
        
        [[AudioSession sharedAudioSession] prependToUpNext:mutableEpisodes];
        
        NSMutableArray* rows = [[NSMutableArray alloc] init];
        NSInteger i;
        for(i=0; i<[mutableEpisodes count]; i++) {
            [rows addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        
        self.episodesToInsert = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[AudioSession sharedAudioSession].playlist count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EpisodesTableViewCell* cell = (EpisodesTableViewCell*)[tableView dequeueReusableCellWithIdentifier:kUpNextCell forIndexPath:indexPath];
    cell.backgroundColor = self.tableView.backgroundColor;
    
    CDEpisode* episode = [AudioSession sharedAudioSession].playlist[indexPath.row];
    cell.embedded = YES;
    cell.panRecognizer.enabled = NO;
    cell.objectValue = episode;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CDEpisode* episode = [AudioSession sharedAudioSession].playlist[indexPath.row];
    return [EpisodesTableViewCell proposedHeightWithObjectValue:episode tableSize:self.tableView.bounds.size imageSize:CGSizeZero embedded:YES editing:self.editing];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        CDEpisode* episode = [AudioSession sharedAudioSession].playlist[indexPath.row];
            
        [[AudioSession sharedAudioSession] eraseEpisodesFromUpNext:@[episode]];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [[AudioSession sharedAudioSession] reorderUpNextEpisodeFromIndex:fromIndexPath.row toIndex:toIndexPath.row];
}
@end
