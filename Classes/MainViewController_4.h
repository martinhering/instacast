//
//  MainViewController_4.h
//  Instacast
//
//  Created by Martin Hering on 25.06.13.
//
//

#import "VMSlidingViewController.h"

@class CDEpisode;

@interface MainViewController_4 : VMSlidingViewController

+ (instancetype) mainViewController;

- (void) showShowNotesOfEpisode:(CDEpisode*)episode animated:(BOOL)animated;
@end
