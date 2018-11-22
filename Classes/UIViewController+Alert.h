//
//  UIViewController+Alert.h
//  Instacast
//
//  Created by Martin Hering on 11.02.16.
//  Copyright © 2016 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Alert)

@property (nonatomic, strong) UIAlertController* alertController;

- (BOOL) presentAlertControllerAnimated:(BOOL)animated completion:(void (^)(void))completion;
- (BOOL) presentAlertControllerWithTitle:(NSString*)title message:(NSString*)message button:(NSString*)buttonTitle animated:(BOOL)animated completion:(void (^)(void))completion;
- (BOOL) presentError:(NSError*)error;
@end
