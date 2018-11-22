//
//  ValuesTableViewController.h
//  Instacast
//
//  Created by Martin Hering on 29.11.12.
//
//

#import <UIKit/UIKit.h>
enum {
    kValueTypeString = 0,
    kValueTypeBool,
    kValueTypeInteger,
    kValueTypeDouble,
};
typedef NSInteger ValueType;


@interface ValuesTableViewController : UITableViewController

+ (ValuesTableViewController*) tableViewController;

@property (nonatomic, strong) NSString* key;
@property (nonatomic, assign) ValueType valueType;
@property (nonatomic, strong) NSArray* titles;
@property (nonatomic, strong) NSArray* values;
@property (nonatomic, strong) NSString* footerText;

@end
