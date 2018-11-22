//
//  CDEpisode.m
//  Instacast
//
//  Created by Martin Hering on 07.08.12.
//
//

#import "CDEpisode.h"
#import "CDChapter.h"
#import "CDFeed.h"
#import "CDMedium.h"

@interface CDEpisode ()
@property (nonatomic, strong) NSString * imageURL_;
@property (nonatomic, strong) NSString * linkURL_;
@property (nonatomic, strong) NSString * paymentURL_;
@property (nonatomic, strong) NSString * deeplinkURL_;
@property (nonatomic, strong) NSArray* showLinks_;
@end

@implementation CDEpisode

//@synthesize temporarySavedProperities;

- (void) reconstructObjectHash
{
    self.objectHash = [[NSString stringWithFormat:@"%@%@", [self.feed.sourceURL absoluteString], self.guid] MD5Hash];
}

- (NSString*) designatedUID
{
    if (!self.objectHash) {
        [self reconstructObjectHash];
    }
    
    return self.objectHash;
}

- (NSSet*) keyPathesForValuesNotToBeLogged
{
    return [NSSet setWithObjects:@"fulltext", @"lastDownloaded",nil];
}

@dynamic objectHash;
@dynamic title;
@dynamic subtitle;
@dynamic guid;
@dynamic pubDate;
@dynamic imageURL_;
@dynamic linkURL_;
@dynamic author;
@dynamic summary;
@dynamic fulltext;
@dynamic paymentURL_;
@dynamic deeplinkURL_;
@dynamic video;
@dynamic explicitContent;
@dynamic duration;
@dynamic lastPlayed;
@dynamic consumed;
@dynamic starred;
@dynamic archived;
@dynamic position;
@dynamic lastDownloaded;

@dynamic timeLeft;
@dynamic downloaded;

@dynamic feed;
@dynamic media;
@dynamic chapters;
@dynamic episodeLists;

@synthesize showLinks_;


- (NSURL*) deeplinkURL
{
    if (self.deeplinkURL_) {
        return [NSURL URLWithString:self.deeplinkURL_];
    }
    return nil;
}

- (void) setDeeplinkURL:(NSURL *)deeplinkURL
{
    self.deeplinkURL_ = [deeplinkURL absoluteString];
}

- (NSURL*) linkURL
{
    if (self.linkURL_) {
        return [NSURL URLWithString:self.linkURL_];
    }
    return nil;
}

- (void) setLinkURL:(NSURL *)linkURL
{
    self.linkURL_ = [linkURL absoluteString];
}

- (NSURL*) paymentURL
{
    if (self.paymentURL_) {
        return [NSURL URLWithString:self.paymentURL_];
    }
    return nil;
}

- (void) setPaymentURL:(NSURL *)paymentURL
{
    self.paymentURL_ = [paymentURL absoluteString];
}

- (NSURL*) imageURL
{
    if (self.imageURL_) {
        return [NSURL URLWithString:self.imageURL_];
    }
    return nil;
}

- (void) setImageURL:(NSURL *)imageURL
{
    self.imageURL_ = [imageURL absoluteString];
}

- (void) setArchived:(BOOL)archived
{
    [self willChangeValueForKey:@"archived"];
    [self setPrimitiveValue:@(archived) forKey:@"archived"];
    [self didChangeValueForKey:@"archived"];
        
    [self.feed invalidateCounts];
}

- (void) setConsumed:(BOOL)consumed
{
    [self willChangeValueForKey:@"consumed"];
    [self setPrimitiveValue:@(consumed) forKey:@"consumed"];
    [self didChangeValueForKey:@"consumed"];
        
    [self.feed invalidateCounts];
}

- (void) setStarred:(BOOL)starred
{
    [self willChangeValueForKey:@"starred"];
    [self setPrimitiveValue:@(starred) forKey:@"starred"];
    [self didChangeValueForKey:@"starred"];
    
    [self.feed invalidateCounts];
}

- (void) setFeed:(CDFeed *)feed
{
    [self willChangeValueForKey:@"feed"];
    [self setPrimitiveValue:feed forKey:@"feed"];
    [self didChangeValueForKey:@"feed"];
        
    [feed invalidateCounts];
}

#pragma mark -

- (CDMedium*) preferedMedium
{
    NSSet* mediaItems = self.media;
	if ([mediaItems count] == 0) {
		return nil;
	}
    
    NSArray* preferredMediaTypes = [NSArray arrayWithObjects:@"audio/x-m4a", @"video/mp4", @"video/x-m4v", @"audio/mpeg", nil];
    
    NSMutableArray* filteredItems = [[NSMutableArray alloc] init];
	for(CDMedium* media in mediaItems) {
        if ([preferredMediaTypes containsObject:media.mimeType]) {
            [filteredItems addObject:media];
		}
	}
	
    CDMedium* mediaWithBiggestFileSize = nil;
    for(CDMedium* media in filteredItems) {
        if (media.byteSize > mediaWithBiggestFileSize.byteSize) {
            mediaWithBiggestFileSize = media;
        }
    }
    
    if (mediaWithBiggestFileSize) {
        return mediaWithBiggestFileSize;
    }
    
	for(CDMedium* media in mediaItems) {
		if ([media.mimeType rangeOfString:@"audio" options:NSCaseInsensitiveSearch].location != NSNotFound ||
			[media.mimeType rangeOfString:@"video" options:NSCaseInsensitiveSearch].location != NSNotFound) {
			return media;
		}
	}
    
    CDMedium* media = [mediaItems anyObject];
    
    if ([media.mimeType hasPrefix:@"image"]) {
        return nil;
    }
	
	return media;
}

- (NSArray*) sortedChapters
{
    return [self.chapters sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES]]];
}

- (NSString*) objectHash
{
    [self willAccessValueForKey:@"objectHash"];
    NSString* objectHash = [self primitiveValueForKey:@"objectHash"];
    [self didAccessValueForKey:@"objectHash"];
    
    if (!objectHash) {
        objectHash = [[NSString stringWithFormat:@"%@%@", [self.feed.sourceURL absoluteString], self.guid] MD5Hash];
    }
    
    return objectHash;
}

+ (NSSet*) keyPathsForValuesAffectingTimeLeft
{
    return [NSSet setWithObjects:@"duration", @"position",nil];
}


- (int32_t) timeLeft {
    [self willAccessValueForKey:@"timeLeft"];
    int32_t timeLeft = MAX(0, self.duration - self.position);
    [self didAccessValueForKey:@"timeLeft"];
    return timeLeft;
}

- (BOOL) downloaded {
    [self willAccessValueForKey:@"downloaded"];
    BOOL downloaded = [[CacheManager sharedCacheManager] episodeIsCached:self fastLookup:YES];
    [self didAccessValueForKey:@"downloaded"];
    return downloaded;
}
/*
- (void) setNotAvailable
{
    self.feed = nil;
    self.title = nil;
    self.author = nil;
    self.deeplinkURL = nil;
    self.fulltext = nil;
    self.imageURL = nil;
    self.lastDownloaded = nil;
    self.lastPlayed = nil;
    self.linkURL = nil;
    self.paymentURL = nil;
    self.pubDate = nil;
    self.subtitle = nil;
    self.summary = nil;
    
    for(NSManagedObject* object in [self.media copy]) {
        [self.managedObjectContext deleteObject:object];
    }
    
    for(NSManagedObject* object in [self.chapters copy]) {
        [self.managedObjectContext deleteObject:object];
    }
}
*/

@end
