//
//  EpisodesTableViewController.h
//  Instacast
//
//  Created by Martin Hering on 25.05.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString* kDefaultEpisodesSelectedEpisodeUID;

typedef enum {
    EpisodesTableViewEditingStyleNormal,
    EpisodesTableViewEditingStyleDownload,
} EpisodesTableViewEditingStyle;

@class CDEpisode;
@class ICListTitleView, ToolbarLabelsViewController;
@class EpisodePlayComboButton;

@interface EpisodesTableViewController : UITableViewController <UIGestureRecognizerDelegate>

- (void) _setObserving:(BOOL)observing;

@property (nonatomic) BOOL userAction;
@property (nonatomic, strong) NSArray* episodes;

@property (nonatomic, assign) EpisodesTableViewEditingStyle editingStyle;
@property (nonatomic, strong, readonly) ICListTitleView* titleView;
@property (nonatomic, strong, readonly) ToolbarLabelsViewController* toolbarLabelsViewController;
@property (nonatomic, strong, readonly) UIBarButtonItem* labelsItems;

- (void) updateEpisodes;
- (void) _updateToolbarLabels;
- (void) _updateToolbarItemsAnimated:(BOOL)animated;

- (void) reloadDataAndPreserveSelection;
- (BOOL) showsImage;
- (BOOL) canArchiveEpisodes;
- (BOOL) canPlayMultiple;

- (void) addAdditionalButtonsToMultiActionSheet:(UIAlertController*)sheet completionBlock:(void (^)())completionBlock;
- (void) addAdditionalButtonsToLongPressActionSheet:(UIAlertController*)sheet rowIndexPath:(NSIndexPath*)indexPath completionBlock:(void (^)())completionBlock;
- (void) addAdditionalButtonsToMultiSelectEditActionSheet:(UIAlertController*)sheet selectedIndexPathes:(NSArray*)selectedIndexPathes completionBlock:(void (^)())completionBlock;

- (void) consumeAllAction:(id)sender;
- (void) editForCachingAction:(id)sender;
- (void) showPlayingOptionsForSelection:(id)sender;
- (void) showEditingOptionsForSelection:(id)sender;

- (void) downloadSelection:(id)sender;
- (void) cancelCachingAction:(id)sender;
- (void) cancelCachingEpisode:(UIButton*)button;
- (void) playComboButtonAction:(EpisodePlayComboButton*)button;

- (void) archiveEpisodesAtRowAtIndexPath:(NSIndexPath *)indexPath;

- (void) _updateCacheButtonStateWithSelectedIndexPathes:(NSArray*)indexPathes;

- (void) restoreShowNotes;
- (void) _pushShowNotesOfEpisode:(CDEpisode*)episode animated:(BOOL)animated inAppearanceTransition:(BOOL)appearanceTransition;

- (void)enumerateEpisodesUsingBlock:(void (^)(CDEpisode* episode, NSUInteger idx, BOOL *stop))block;
@end



@interface EpisodesContainerViewController : UIViewController
+ (instancetype) containerViewControllerWithTableViewController:(EpisodesTableViewController*)tableViewController;
@property (nonatomic, strong) EpisodesTableViewController* tableViewController;
@end
