//
//  TwitterHelper.h
//  Instacast
//
//  Created by Martin Hering on 05.04.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TwitterHelper : NSObject {

}

+ (BOOL) handleTwitterURL:(NSURL*)url;
+ (void) openTweetInTwitterApp:(NSString*)tweetId user:(NSString*)user;
+ (void) openUserInTwitterApp:(NSString*)username;
+ (void) tweetMessage:(NSString*)message url:(NSURL*)url hostViewController:(UIViewController*)hostViewController;
@end
