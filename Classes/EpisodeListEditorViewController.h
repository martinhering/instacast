//
//  EpisodeListEditorViewController.h
//  Instacast
//
//  Created by Martin Hering on 18.08.14.
//
//

#import <UIKit/UIKit.h>

@class CDEpisodeList;

@interface EpisodeListEditorViewController : UITableViewController

+ (instancetype) episodeListEditorViewControllerWithList:(CDEpisodeList*)list;

@end
