//
//  ICPagedFeedParser.h
//  InstacastMac
//
//  Created by Martin Hering on 12.04.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICFeed.h"
#import "ICCategory.h"
#import "ICEpisode.h"
#import "ICMedia.h"
#import "ICChapter.h"

@interface ICPagedFeedParser : NSOperation

@property (strong) NSURL* url;
@property (strong) NSString* username;
@property (strong) NSString* password;
@property BOOL dontAskForCredentials;
@property BOOL allowsCellularAccess;

@property (strong, readonly) NSMutableDictionary* alternateFeedData;

@property (copy) void (^didParsePage)(NSInteger page);
@property (copy) void (^didParseFeedBlock)(ICFeed* feed);
@property (copy) void (^didEndWithError)(NSError* error);
@property (copy) void (^didCancel)();
@end
