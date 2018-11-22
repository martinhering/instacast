//
//  CDFeed.h
//  Instacast
//
//  Created by Martin Hering on 07.08.12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CDBase.h"

@class CDCategory, CDEpisode;

@interface CDFeed : CDBase

@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSString * subtitle;
@property (nonatomic, strong) NSString * summary;
@property (nonatomic, strong) NSString * fulltext;
@property (nonatomic, strong) NSURL * sourceURL;
@property (nonatomic, strong) NSURL * imageURL;
@property (nonatomic, strong) NSDate* pubDate;
@property (nonatomic, strong) NSDate* lastUpdate;
@property (nonatomic, strong) NSString * etag;
@property (nonatomic, strong) NSURL * linkURL;
@property (nonatomic, strong) NSString * language;
@property (nonatomic, strong) NSString * country;
@property (nonatomic, strong) NSString * author;
@property (nonatomic, strong) NSString * copyright;
@property (nonatomic, strong) NSString * owner;
@property (nonatomic, strong) NSString * ownerEmail;
@property (nonatomic, strong) NSURL * paymentURL;
@property (nonatomic, strong) NSString * username;
@property (nonatomic, copy) NSString * password;
@property (nonatomic) int32_t rank;
@property (nonatomic) BOOL subscribed;
@property (nonatomic) BOOL parked;
@property (nonatomic) BOOL video;
@property (nonatomic) BOOL completed;
@property (nonatomic) BOOL explicitContent;
@property (nonatomic, strong) NSString* contentHash;
@property (nonatomic, strong) NSSet *categories;
@property (nonatomic, strong) NSSet *episodes;
@property (nonatomic, strong) NSSet *properties;


@property (nonatomic, readonly) NSInteger episodesCount;
@property (nonatomic, readonly) NSInteger unplayedCount;
@property (nonatomic, readonly) NSInteger downloadedCount;
@property (nonatomic, readonly) NSDate* lastPlayed;
@property (nonatomic, readonly) NSDate* lastPubDate;


@property (nonatomic, strong) NSString * displayTitle;

- (void) invalidateCounts;

@end

@interface CDFeed (CoreDataGeneratedAccessors)
- (void)addCategoriesObject:(CDCategory *)value;
- (void)removeCategoriesObject:(CDCategory *)value;
- (void)addCategories:(NSSet *)values;
- (void)removeCategories:(NSSet *)values;

- (void)addEpisodesObject:(CDEpisode *)value;
- (void)removeEpisodesObject:(CDEpisode *)value;
- (void)addEpisodes:(NSSet *)values;
- (void)removeEpisodes:(NSSet *)values;
@end



extern NSString* kUserDefinedFeedName;

@interface CDFeed (FeedProperties)
- (BOOL) boolForKey:(NSString*)defaultName;
- (void) setBool:(BOOL)boolValue forKey:(NSString *)defaultName;

- (NSInteger) integerForKey:(NSString*)defaultName;
- (void) setInteger:(NSInteger)integerValue forKey:(NSString *)defaultName;

- (NSString*) stringForKey:(NSString*)defaultName;
- (void) setString:(NSString*)stringValue forKey:(NSString *)defaultName;

- (double) doubleForKey:(NSString*)defaultName;
- (void) setDouble:(double)doubleValue forKey:(NSString *)defaultName;

- (void) resetValueForKey:(NSString*)defaultName;
- (void) resetAllProperties;
- (BOOL) hasCustomProperties;
- (NSArray*) propertyKeys;
@end