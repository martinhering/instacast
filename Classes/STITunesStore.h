//
//  STITunesStoreManager.h
//  Snowtape
//
//  Created by Martin Hering on 01.05.09.
//  Copyright 2009 vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* kiTunesStoreKind;
extern NSString* kiTunesStoreTitleLink;
extern NSString* kiTunesStoreTitleAffiliateLink;
extern NSString* kiTunesStoreTitle;
extern NSString* kiTunesStoreAlbumLink;
extern NSString* kiTunesStoreAlbumAffiliateLink;
extern NSString* kiTunesStoreAlbum;
extern NSString* kiTunesStoreArtistLink;
extern NSString* kiTunesStoreArtistAffiliateLink;
extern NSString* kiTunesStoreArtist;
extern NSString* kiTunesStoreTrackPrice;
extern NSString* kiTunesStoreTrackPriceCurrency;
extern NSString* kiTunesStorePreviewLink;
extern NSString* kiTunesStoreFeedURL;

extern NSString* kiTunesStoreArtwork60;
extern NSString* kiTunesStoreArtwork100;
extern NSString* kiTunesStoreArtwork170;

extern NSString* kiTunesStoreSongKind;
extern NSString* kiTunesStoreMusicVideoKind;

extern NSString* kiTunesStoreTrackId;
extern NSString* kiTunesStoreCollectionId;

@interface STITunesStore : NSObject

@property (nonatomic, strong) NSLocale* storeLocale;
@property (nonatomic, strong) NSString* media;
@property (nonatomic, strong) NSString* entity;
@property (nonatomic, strong) NSString* attribute;
@property (nonatomic, strong) NSString* searchTerm;

- (NSArray*) storeSearchResultForSearchString:(NSString*)searchString;
- (void) startStoreSearchForSearchString:(NSString*)searchString delegate:(id)delegate;
- (void) cancelStoreSearch;

- (NSString*) affiliateLinkForStoreLink:(NSString*)link;


- (NSArray*) storeItemsForTitle:(NSString*)title artist:(NSString*)artist;
- (NSArray*) storeItemsForArtist:(NSString*)artist;
- (NSArray*) storeItemsForAlbum:(NSString*)album;

#if TARGET_OS_IPHONE
- (UIImage*) imageForStoreLink:(NSString*)link;
#else
- (NSImage*) imageForStoreLink:(NSString*)link;
#endif
@end


@interface NSObject (STITunesStoreDelegate)
- (void) itunesStore:(STITunesStore*)store didFindSearchResults:(NSArray*)searchResults;
- (void) itunesStore:(STITunesStore*)store didEndWithError:(NSError*)error;
@end