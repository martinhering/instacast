//
//  CDEpisode.h
//  Instacast
//
//  Created by Martin Hering on 07.08.12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CDBase.h"

@class CDChapter, CDFeed, CDMedium;

@interface CDEpisode : CDBase

@property (nonatomic, strong) NSString * objectHash;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSString * subtitle;
@property (nonatomic, strong) NSString * guid;
@property (nonatomic, strong) NSDate* pubDate;
@property (nonatomic, strong) NSURL * imageURL;
@property (nonatomic, strong) NSURL * linkURL;
@property (nonatomic, strong) NSString * author;
@property (nonatomic, strong) NSString * summary;
@property (nonatomic, strong) NSString * fulltext;
@property (nonatomic, strong) NSURL * paymentURL;
@property (nonatomic, strong) NSURL * deeplinkURL;
@property (nonatomic) BOOL video;
@property (nonatomic) BOOL explicitContent;
@property (nonatomic) int32_t duration;
@property (nonatomic) BOOL consumed;
@property (nonatomic) BOOL starred;
@property (nonatomic) BOOL archived;
@property (nonatomic) int32_t position;
@property (nonatomic, strong) CDFeed *feed;
@property (nonatomic, strong) NSDate* lastPlayed;
@property (nonatomic, strong) NSDate* lastDownloaded;

@property (nonatomic, strong) NSSet *media;
@property (nonatomic, strong) NSSet *chapters;
@property (nonatomic, strong) NSSet *episodeLists;

- (CDMedium*) preferedMedium;
- (NSArray*) sortedChapters;

@property (nonatomic, readonly) int32_t timeLeft;
@property (nonatomic, readonly) BOOL downloaded;

- (void) reconstructObjectHash;
@end

@interface CDEpisode (CoreDataGeneratedAccessors)

- (void)addMediaObject:(CDMedium *)value;
- (void)removeMediaObject:(CDMedium *)value;
- (void)addMedia:(NSSet *)values;
- (void)removeMedia:(NSSet *)values;

- (void)addChaptersObject:(CDChapter *)value;
- (void)removeChaptersObject:(CDChapter *)value;
- (void)addChapters:(NSSet *)values;
- (void)removeChapters:(NSSet *)values;

@end
