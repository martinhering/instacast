//
//  PlayerInfoHeaderFooterView.h
//  Instacast
//
//  Created by Martin Hering on 03.08.14.
//
//

#import <UIKit/UIKit.h>

@interface PlayerInfoHeaderFooterView : UITableViewHeaderFooterView
@property (nonatomic, strong, readonly) UIButton* editButton;
@property (nonatomic, strong, readonly) UIButton* doneButton;

@property (nonatomic) BOOL canEdit;
@property (nonatomic) BOOL editing;
- (void) setEditing:(BOOL)editing animated:(BOOL)animated;
@end
