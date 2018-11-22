//
//  CDEpisodeList.h
//  Instacast
//
//  Created by Martin Hering on 18.08.14.
//
//

#import "CDList.h"

extern NSString* kEpisodeIconUnplayed;


@interface CDEpisodeList : CDList

@property (nonatomic, strong) NSString* icon;
@property (nonatomic, strong) NSString* query;

@property (nonatomic) BOOL audio;
@property (nonatomic) BOOL video;

@property (nonatomic) BOOL downloaded;
@property (nonatomic) BOOL downloading;
@property (nonatomic) BOOL notDownloaded;

@property (nonatomic) BOOL starred;
@property (nonatomic) BOOL notStarred;

@property (nonatomic) BOOL unplayed;
@property (nonatomic) BOOL unfinished;
@property (nonatomic) BOOL played;

@property (nonatomic, strong) NSString* orderBy;
@property (nonatomic) BOOL groupByPodcast;
@property (nonatomic) BOOL descending;

@property (nonatomic) BOOL continuousPlayback;

@property (nonatomic, strong) NSSet* includedFeeds;
@property (nonatomic, strong) NSOrderedSet* episodes;

- (void) invalidateCaches;
- (void) invalidateSortedEpisodes;

//- (void) addNumberOfEpisodes:(NSInteger)number;
@end
