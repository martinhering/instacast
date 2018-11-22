//
//  OptionsViewController.h
//  Instacast
//
//  Created by Martin Hering on 07.11.11.
//  Copyright (c) 2011 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OptionsViewController : UITableViewController {
    BOOL _observing;
}

+ (OptionsViewController*) optionsViewController;

@end
