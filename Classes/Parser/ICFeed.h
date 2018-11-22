//
//  ICFeed.h
//  ICFeedParser
//
//  Created by Martin Hering on 16.07.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

@interface ICFeed : NSObject

+ (id) feed;

@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* subtitle;
@property (nonatomic, strong) NSURL* sourceURL;
@property (nonatomic, strong) NSURL* changedSourceURL;
@property (nonatomic, strong) NSURL* imageURL;
@property (nonatomic, strong) NSDate* pubDate;
@property (nonatomic, strong) NSDate* lastUpdate;
@property (nonatomic, strong) NSString* generator;
@property (nonatomic) BOOL video;
@property (nonatomic) BOOL completed;
@property (nonatomic) BOOL blocked;
@property (nonatomic, strong) NSURL* linkURL;
@property (nonatomic, strong) NSString* language;
@property (nonatomic, strong) NSString* country;
@property (nonatomic, strong) NSString* summary;
@property (nonatomic, strong) NSString* textDescription;
@property (nonatomic, strong) NSString* author;
@property (nonatomic, strong) NSString* copyright;
@property (nonatomic, strong) NSString* owner;
@property (nonatomic, strong) NSString* ownerEmail;
@property (nonatomic) BOOL explicitContent;
@property (nonatomic, strong) NSURL* paymentURL;
@property (nonatomic, strong) NSString* etag;

// paged feed support
@property (nonatomic, strong) NSURL* firstPageURL;
@property (nonatomic, strong) NSURL* lastPageURL;
@property (nonatomic, strong) NSURL* prevPageURL;
@property (nonatomic, strong) NSURL* nextPageURL;

// relations
@property (nonatomic, strong) NSArray* categories;
@property (nonatomic, strong) NSArray* episodes;

@property (nonatomic, strong) NSString* username;
@property (nonatomic, strong) NSString* password;
@property (nonatomic, strong) NSString* contentHash;

@end
