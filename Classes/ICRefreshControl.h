//
//  ICRefreshControl.h
//  Instacast
//
//  Created by Martin Hering on 04.08.13.
//
//

#import <UIKit/UIKit.h>

@interface ICRefreshControl : UIRefreshControl

@property (nonatomic, strong) NSString* pulldownText;
@property (nonatomic, strong) NSString* refreshText;
@property (nonatomic, strong) NSString* idleText;

@end
