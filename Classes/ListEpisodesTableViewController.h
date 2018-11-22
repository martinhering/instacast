//
//  ListEpisodesTableViewController.h
//  Instacast
//
//  Created by Martin Hering on 21.08.14.
//
//

#import "EpisodesTableViewController.h"

@interface ListEpisodesTableViewController : EpisodesTableViewController

+ (instancetype) viewControllerWithList:(CDEpisodeList*)list;

@property (nonatomic, strong) CDEpisodeList* list;

@end
