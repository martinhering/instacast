//
//  EpisodeListPodcastSelectionTableViewController.h
//  Instacast
//
//  Created by Martin Hering on 21.08.14.
//
//

#import <UIKit/UIKit.h>

@interface EpisodeListPodcastSelectionTableViewController : UITableViewController

+ (instancetype) viewController;

@property (nonatomic, strong) NSOrderedSet* selectedPodcasts;
@end
