//
//  UpNextTableViewController.h
//  Instacast
//
//  Created by Martin Hering on 31.10.14.
//
//

#import <UIKit/UIKit.h>

@interface UpNextTableViewController : UITableViewController

+ (instancetype) viewController;

@property (nonatomic, strong) NSArray* episodesToInsert;

@end
