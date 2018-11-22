//
//  STITunesStoreManager.m
//  Snowtape
//
//  Created by Martin Hering on 01.05.09.
//  Copyright 2009 vemedio. All rights reserved.
//

//#import "NSString_CleanTrackTitle.h"
#import "STITunesStore.h"

NSString* kiTunesStoreKind = @"kiTunesStoreKind";
NSString* kiTunesStoreTitleLink = @"kiTunesStoreTitleLink";
NSString* kiTunesStoreTitleAffiliateLink = @"kiTunesStoreTitleAffiliateLink";
NSString* kiTunesStoreTitle = @"kiTunesStoreTitle";
NSString* kiTunesStoreAlbumLink = @"kiTunesStoreAlbumLink";
NSString* kiTunesStoreAlbumAffiliateLink = @"kiTunesStoreAlbumAffiliateLink";
NSString* kiTunesStoreAlbum = @"kiTunesStoreAlbum";
NSString* kiTunesStoreArtistLink = @"kiTunesStoreArtistLink";
NSString* kiTunesStoreArtistAffiliateLink = @"kiTunesStoreArtistAffiliateLink";
NSString* kiTunesStoreArtist = @"kiTunesStoreArtist";
NSString* kiTunesStoreTrackPrice = @"kiTunesStoreTrackPrice";
NSString* kiTunesStoreTrackPriceCurrency = @"kiTunesStoreTrackPriceCurrency";
NSString* kiTunesStorePreviewLink = @"kiTunesStorePreviewLink";
NSString* kiTunesStoreFeedURL = @"kiTunesStoreFeedURL";

NSString* kiTunesStoreArtwork60 = @"kiTunesStoreArtwork60";
NSString* kiTunesStoreArtwork100 = @"kiTunesStoreArtwork100";
NSString* kiTunesStoreArtwork170 = @"kiTunesStoreArtwork170";

NSString* kiTunesStoreSongKind = @"song";
NSString* kiTunesStoreMusicVideoKind = @"music-video";

NSString* kiTunesStoreTrackId = @"kiTunesStoreTrackId";
NSString* kiTunesStoreCollectionId = @"kiTunesStoreCollectionId";

typedef enum {
	NoAffiliatePartnerType = 0,
	TradeDoublerAffiliatePartnerType,
	LinkshareAffiliatePartnerType,
} ITunesAffiliatePartnerType;

@interface STITunesStore ()
@property (nonatomic, strong) NSMutableData* connectionData;
@property (nonatomic, strong) NSURLConnection* connection;
@property (nonatomic, strong) id connectionDelegate;
@end


@implementation STITunesStore

- (id) init
{
	if ((self = [super init]))
	{
		_storeLocale = [NSLocale currentLocale];
		_media = @"music";
		_entity = @"musicTrack";
	}
	
	return self;
}

- (ITunesAffiliatePartnerType) _affiliatePartnerType
{
	NSArray* tradedoublerCountryCodes = [NSArray arrayWithObjects:@"AU",@"BE",@"DK",@"FI",@"FR",@"DE",@"GR",@"IE",@"IT",@"LU",@"NL",@"NO",@"PT",@"ES",@"SE",@"CH",@"GB",nil];
	NSArray* linkshareCountryCodes = [NSArray arrayWithObjects:@"US",nil];
	NSString* countryCode = [self.storeLocale objectForKey:NSLocaleCountryCode];

	if ([tradedoublerCountryCodes containsObject:countryCode]) {
		return TradeDoublerAffiliatePartnerType;
	}
	if ([linkshareCountryCodes containsObject:countryCode]) {
		return LinkshareAffiliatePartnerType;
	}
	
	return NoAffiliatePartnerType;
}

- (NSString*) affiliateLinkForStoreLink:(NSString*)link
{
	if (!link) {
		return nil;
	}

	if ([self _affiliatePartnerType] == TradeDoublerAffiliatePartnerType)
	{
        link = [link stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
		return [NSString stringWithFormat:@"http://clk.tradedoubler.com/click?p=23761&a=1644991&url=%@%%26partnerId%%3D2003",link];
	}
	
	else if ([self _affiliatePartnerType] == LinkshareAffiliatePartnerType)
	{
		NSArray* escapeChars = [NSArray arrayWithObjects:@"!",@"$",@"&",@"'",@"(",@")",@"*",@"+",@",",@"-",@"/",@":",@";",@"=",@"?",@"@",@"_",@"~",nil];
		for(NSString* ch in escapeChars)
		{
			unichar unich = [ch characterAtIndex:0];
			link = [link stringByReplacingOccurrencesOfString:ch withString:[NSString stringWithFormat:@"%%25%02X",unich]];
		}

		return [NSString stringWithFormat:@"http://click.linksynergy.com/fs-bin/stat?id=P7HkeV4/n2E&offerid=146261&type=3&subid=0&tmpid=1826&RD_PARM1=%@%%2526partnerId%%253D30",link];
	}
	
	
	return link;
}

- (NSURLRequest*) _urlRequestForSearchString:(NSString*)searchString
{
    NSString* encodedSearchString = [searchString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

	
	if ([encodedSearchString length] == 0) {
		return nil;
	}
	
	NSString* countryCode = [self.storeLocale objectForKey:NSLocaleCountryCode];
	
	NSMutableString* searchURLString = [NSMutableString stringWithFormat:@"http://itunes.apple.com/search?media=%@", self.media];
	if (self.entity) {
		[searchURLString appendFormat:@"&entity=%@", self.entity];
	}
	if (self.attribute) {
		[searchURLString appendFormat:@"&attribute=%@", self.attribute];
	}
	if (countryCode) {
		[searchURLString appendFormat:@"&country=%@", countryCode];
	}
	if (encodedSearchString) {
		[searchURLString appendFormat:@"&term=%@", encodedSearchString];
	}
	
	DebugLog(@"%@",searchURLString);
	
	return [NSURLRequest requestWithURL:[NSURL URLWithString:searchURLString] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0f];
}

- (NSArray*) _searchResultsForData:(NSData*)data
{
    NSError* error = nil;
    NSDictionary* dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!dictionary) {
        ErrLog(@"%@", [error description]);
        return nil;
    }

	
	NSMutableArray* items = [NSMutableArray array];
	
	NSArray* results = [dictionary objectForKey:@"results"];
	for(NSDictionary* result in results)
	{
		NSMutableDictionary* item = [NSMutableDictionary dictionary];
		
		if ([result objectForKey:@"trackId"]) {
			[item setObject:[result objectForKey:@"trackId"] forKey:kiTunesStoreTrackId];
		}
		
		if ([result objectForKey:@"collectionId"]) {
			[item setObject:[result objectForKey:@"collectionId"] forKey:kiTunesStoreCollectionId];
		}
		
        if ([result objectForKey:@"trackName"]) {
            [item setObject:[result objectForKey:@"trackName"] forKey:kiTunesStoreTitle];
        }
        
		NSString* link = [result objectForKey:@"trackViewUrl"];
		if (link && ![link isKindOfClass:[NSNull class]]) {
			[item setObject:link forKey:kiTunesStoreTitleLink];
			[item setObject:[self affiliateLinkForStoreLink:link] forKey:kiTunesStoreTitleAffiliateLink];
		}
		
        if ([result objectForKey:@"collectionName"]) {
            [item setObject:[result objectForKey:@"collectionName"] forKey:kiTunesStoreAlbum];
        }
        
		link = [result objectForKey:@"collectionViewUrl"];
		if (link && ![link isKindOfClass:[NSNull class]]) {
			[item setObject:link forKey:kiTunesStoreAlbumLink];
			[item setObject:[self affiliateLinkForStoreLink:link] forKey:kiTunesStoreAlbumAffiliateLink];
		}
		
        if ([result objectForKey:@"artistName"]) {
            [item setObject:[result objectForKey:@"artistName"] forKey:kiTunesStoreArtist];
        }
        
		link = [result objectForKey:@"artistViewUrl"];
		if (link && ![link isKindOfClass:[NSNull class]]) {
			[item setObject:link forKey:kiTunesStoreArtistLink];
			[item setObject:[self affiliateLinkForStoreLink:link] forKey:kiTunesStoreArtistAffiliateLink];
		}
		
        if ([result objectForKey:@"artworkUrl60"]) {
            [item setObject:[result objectForKey:@"artworkUrl60"] forKey:kiTunesStoreArtwork60];
        }
        
        if ([result objectForKey:@"artworkUrl100"]) {
            [item setObject:[result objectForKey:@"artworkUrl100"] forKey:kiTunesStoreArtwork100];
        }
		
		NSString* link100 = [result objectForKey:@"artworkUrl100"];
        if (link100) {
            NSString* link170 = [[[link100 stringByDeletingPathExtension] stringByDeletingPathExtension] stringByAppendingPathExtension:@"170x170-75.jpg"];
            [item setObject:link170 forKey:kiTunesStoreArtwork170];
        }
		
		if ([result objectForKey:@"kind"]) {
            [item setObject:[result objectForKey:@"kind"] forKey:kiTunesStoreKind];
        }
        if ([result objectForKey:@"trackPrice"]) {
            [item setObject:[result objectForKey:@"trackPrice"] forKey:kiTunesStoreTrackPrice];
        }
        if ([result objectForKey:@"currency"]) {
            [item setObject:[result objectForKey:@"currency"] forKey:kiTunesStoreTrackPriceCurrency];
        }
        if ([result objectForKey:@"previewUrl"]) {
            [item setObject:[result objectForKey:@"previewUrl"] forKey:kiTunesStorePreviewLink];
        }
        
        if ([result objectForKey:@"feedUrl"]) {
            NSString* feedURLString = [result objectForKey:@"feedUrl"];
            NSURL* feedURL = [NSURL URLWithString:feedURLString];
            if (feedURL) {
                [item setObject:feedURL forKey:kiTunesStoreFeedURL];
            }
        }
		
		//DebugLog(@"%@ %@",[result description], link170);
		
		[items addObject:item];
	}

	return items;
}

- (NSArray*) storeSearchResultForSearchString:(NSString*)searchString
{
	NSURLRequest* request = [self _urlRequestForSearchString:searchString];
	if (!request) {
		return nil;
	}
	
	NSHTTPURLResponse* response = nil;
	NSError* error = nil;
	NSData* resultData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	if (error || [response statusCode] != 200) {
		return nil;
	}
	
	
	return [self _searchResultsForData: resultData];
}


- (void) startStoreSearchForSearchString:(NSString*)searchString delegate:(id)delegate
{
    self.searchTerm = searchString;
    
	NSURLRequest* request = [self _urlRequestForSearchString:searchString];
	if (request) {
		self.connectionDelegate = delegate;
		self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
	}
	else {
		if (delegate && [delegate respondsToSelector:@selector(itunesStore:didEndWithError:)]) {
            NSError* error = [NSError errorWithDomain:@"ITunesStoreErrorDomain" 
                                                 code:0
                                             userInfo:[NSDictionary dictionaryWithObject:@"Search term is too short." forKey:NSLocalizedDescriptionKey]];
			[delegate itunesStore:self didEndWithError:error];
		}
	}
}

- (void) cancelStoreSearch
{
	[self.connection cancel];
	self.connection = nil;
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if (self.connectionDelegate && [self.connectionDelegate respondsToSelector:@selector(itunesStore:didEndWithError:)]) {
		[self.connectionDelegate itunesStore:self didEndWithError:error];
	}
	self.connection = nil;
	self.connectionDelegate = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	_connectionData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self.connectionData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSArray* searchResults = [self _searchResultsForData:self.connectionData];
	self.connectionData = nil;
	
	if (self.connectionDelegate && [self.connectionDelegate respondsToSelector:@selector(itunesStore:didFindSearchResults:)]) {
		[self.connectionDelegate itunesStore:self didFindSearchResults:searchResults];
	}
	self.connection = nil;
	self.connectionDelegate = nil;
}


#pragma mark -

- (NSArray*) storeItemsForTitle:(NSString*)title artist:(NSString*)artist
{
	NSArray* storeItems = [self storeSearchResultForSearchString:((artist) ? [NSString stringWithFormat:@"%@ %@",artist, title] : title)];
	//DebugLog(@"%@",[storeItems description]);
	return storeItems;
}

- (NSArray*) storeItemsForArtist:(NSString*)artist
{
	NSArray* storeItems = [self storeSearchResultForSearchString:artist];
	//DebugLog(@"%@",[storeItems description]);
	return storeItems;
}

- (NSArray*) storeItemsForAlbum:(NSString*)album
{
	NSArray* storeItems = [self storeSearchResultForSearchString:album];
	//DebugLog(@"%@",[storeItems description]);
	return storeItems;
}

#if TARGET_OS_IPHONE
- (UIImage*) imageForStoreLink:(NSString*)link
{
	NSURLRequest* imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:link]];
	NSHTTPURLResponse* imageResponse = nil;
	NSError* imageError = nil;
	NSData* imageData = [NSURLConnection sendSynchronousRequest:imageRequest returningResponse:&imageResponse error:&imageError];
	
	if (!imageData) {
		return nil;
	}
	
	return [[UIImage alloc] initWithData:imageData];
}
#else
- (NSImage*) imageForStoreLink:(NSString*)link
{
	NSURLRequest* imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:link]];
	NSHTTPURLResponse* imageResponse = nil;
	NSError* imageError = nil;
	NSData* imageData = [NSURLConnection sendSynchronousRequest:imageRequest returningResponse:&imageResponse error:&imageError];
	
	if (!imageData) {
		return nil;
	}
	
	return [[NSImage alloc] initWithData:imageData];
}
#endif

@end
