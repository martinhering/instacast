//
//  MainSidebarController.h
//  Instacast
//
//  Created by Martin Hering on 29.06.13.
//
//

#import <UIKit/UIKit.h>

@interface MainSidebarItem : NSObject
+ (instancetype) itemWithTitle:(NSString*)title tag:(NSInteger)tag image:(UIImage*)image selectedImage:(UIImage*)selectedImage;
@property (nonatomic, strong) NSString* title;
@property (nonatomic) NSInteger tag;
@property (nonatomic) UIImage* image;
@property (nonatomic) UIImage* selectedImage;
@property (nonatomic, copy) NSUInteger (^badgeNumber)();
@end



@interface MainSidebarController : UITableViewController

@property (nonatomic, strong) NSArray* items;
@property (nonatomic, copy) BOOL(^didSelectItem)(MainSidebarItem* item);
@property (nonatomic) NSInteger selectedItemTag;

- (void) updateRowSelectionForSelectedItemTag;
@end
