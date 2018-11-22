//
//  CDSmartPlaylist.h
//  Instacast
//
//  Created by Martin Hering on 09.08.12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CDList.h"

extern NSString* kSmartListTypeUnplayed;
extern NSString* kSmartListTypeStarred;
extern NSString* kSmartListTypeDownload;
extern NSString* kSmartListTypeMostRecent;
extern NSString* kSmartListTypePartiallyPlayed;
extern NSString* kSmartListTypeRecentlyPlayed;

extern NSString* kSmartListSortNewestFirst;
extern NSString* kSmartListSortOldestFirst;


extern NSString* kSmartListPredicateTitleKey;
extern NSString* kSmartListPredicateTypeKey;
extern NSString* kSmartListPredicateSortOrderKey;
extern NSString* kSmartListPredicateGroupedKey;
extern NSString* kSmartListPredicateSortKeyKey;

@interface CDSmartPlaylist : CDList

@property (nonatomic, strong) NSDictionary* smartPredicate;

- (NSFetchRequest*) episodesFetchRequest;

@property (nonatomic, strong) NSSortDescriptor* sortDescriptor;
- (void) _notifySortedEpisodesChanged;
@end
