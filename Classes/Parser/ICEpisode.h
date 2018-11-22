//
//  ICEpisode.h
//  ICFeedParser
//
//  Created by Martin Hering on 16.07.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

@class ICMedia, ICFeed;

@interface ICEpisode : NSObject

+ (id) episode;

@property (nonatomic, strong) NSString* guid;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString*	subtitle;
@property (nonatomic, strong) NSDate* pubDate;
@property (nonatomic) NSInteger duration;
@property (nonatomic) BOOL video;
@property (nonatomic, strong) NSURL* imageURL;
@property (nonatomic, strong) NSURL* link;
@property (nonatomic, strong) NSString* author;
@property (nonatomic, strong) NSString* summary;
@property (nonatomic, strong) NSString* textDescription;
@property (nonatomic) BOOL explicitContent;
@property (nonatomic) BOOL blocked;
@property (nonatomic, strong) NSURL* paymentURL;
@property (nonatomic, strong) NSURL* deeplink;
@property (nonatomic, strong) NSURL* pscLink;
@property (nonatomic, strong) NSString* objectHash;

// relations
@property (nonatomic, strong) NSArray* media;
@property (nonatomic, strong) NSArray* chapters;
@property (nonatomic, weak) ICFeed* feed;

- (BOOL) isEqualToEpisode:(ICEpisode*)episode;

- (NSString*) cleanTitleUsingFeedTitle:(NSString*)feedTitle;
- (NSString*) cleanedShowNotes;
- (ICMedia*) preferedMedium;
@end
