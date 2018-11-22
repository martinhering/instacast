//
//  UITableViewController+Settings.h
//  Instacast
//
//  Created by Martin Hering on 22.06.13.
//
//

#import <UIKit/UIKit.h>

@interface UITableViewController (Settings)
- (UITableViewCell*) standardCellWithClass:(Class)cellClass;
- (UITableViewCell*) standardCell;
- (UITableViewCell*) switchCell;
- (UITableViewCell*) textInputCell;
- (UITableViewCell*) detailCell;
- (UITableViewCell*) resetCell;
- (UITableViewCell*) buttonCell;

- (UITableViewCell*) textCell;
- (CGFloat)heightForTextCellUsingText:(NSString*)text;
@end
