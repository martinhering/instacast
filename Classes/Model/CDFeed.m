//
//  CDFeed.m
//  Instacast
//
//  Created by Martin Hering on 07.08.12.
//
//

#import "SFHFKeychainUtils.h"

#import "CDFeed.h"
#import "CDCategory.h"
#import "CDEpisode.h"
#import "CDFeedProperty.h"

@interface CDFeed ()
@property (nonatomic, strong) NSString * sourceURL_;
@property (nonatomic, strong) NSString * imageURL_;
@property (nonatomic, strong) NSString * linkURL_;
@property (nonatomic, strong) NSString * paymentURL_;

@property (nonatomic, readwrite) NSInteger unplayedCount;
@property (nonatomic, readwrite) NSInteger episodesCount;
@property (nonatomic, readwrite) NSInteger starredCount;
@end


@implementation CDFeed {
    BOOL        _observing;
}

- (NSString*) designatedUID
{
    return [self.sourceURL_ MD5Hash];
}

- (NSSet*) keyPathesForValuesNotToBeLogged
{
    return [NSSet setWithObjects:@"lastUpdate",nil];
}

@synthesize unplayedCount;
@synthesize episodesCount;
@synthesize starredCount;
@dynamic displayTitle;

@dynamic title;
@dynamic subtitle;
@dynamic summary;
@dynamic fulltext;
@dynamic sourceURL_;
@dynamic imageURL_;
@dynamic pubDate;
@dynamic lastUpdate;
@dynamic etag;
@dynamic contentHash;
@dynamic linkURL_;
@dynamic language;
@dynamic country;
@dynamic author;
@dynamic copyright;
@dynamic owner;
@dynamic ownerEmail;
@dynamic paymentURL_;
@dynamic username;
@dynamic rank;
@dynamic subscribed;
@dynamic parked;
@dynamic video;
@dynamic completed;
@dynamic explicitContent;
@dynamic categories;
@dynamic episodes;
@dynamic properties;

- (NSURL*) sourceURL
{
    if (self.sourceURL_) {
        return [NSURL URLWithString:self.sourceURL_];
    }
    return nil;
}

- (void) setSourceURL:(NSURL *)sourceURL
{
    // make sure we update the password, because it's sourceURL dependent
    NSString* oldPassword = self.password;
    
    self.sourceURL_ = [sourceURL absoluteString];
    
    if (oldPassword) {
        self.password = oldPassword;
    }
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

- (NSString*) password
{
	if (!self.username) {
		return nil;
	}
	
	NSError* error = nil;
	NSString* password = [SFHFKeychainUtils getPasswordForUsername:self.username andServiceName:[self.sourceURL absoluteString] error:&error];
	
	if (error) {
		ErrLog(@"error getting password from keychain for feed: %@ (error: %@)", [self.sourceURL absoluteString], [error description]);
	}
	
	return password;
}

- (void) setPassword:(NSString *)password
{
	NSError* error = nil;
	if (password)
	{
		if (![SFHFKeychainUtils storeUsername:self.username
								  andPassword:password
							   forServiceName:[self.sourceURL absoluteString]
							   updateExisting:YES
										error:&error]) {
			ErrLog(@"error storing password in keychain for feed: %@ (error: %@)", [self.sourceURL absoluteString], [error description]);
		}
	}
	else if (self.username) {
		if (![SFHFKeychainUtils deleteItemForUsername:self.username andServiceName:[self.sourceURL absoluteString] error:&error]) {
			ErrLog(@"error deleting password from keychain for feed: %@ (error: %@)", [self.sourceURL absoluteString], [error description]);
		}
	}
}

+ (NSSet*) keyPathsForValuesAffectingEpisodesCount
{
    return [[NSSet alloc] initWithObjects:@"episodes", nil];
}

- (NSInteger) episodesCount
{
    NSManagedObjectContext* context = [self managedObjectContext];
    
    if (episodesCount == -1 && context) {
        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
        fetchRequest.entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:context];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"feed == %@ AND archived == %@", self, @NO];
        episodesCount = [context countForFetchRequest:fetchRequest error:nil];
    }
    
    return episodesCount;
}

+ (NSSet*) keyPathsForValuesAffectingUnplayedCount
{
    return [[NSSet alloc] initWithObjects:@"episodes", nil];
}

- (NSInteger) unplayedCount
{
    NSManagedObjectContext* context = [self managedObjectContext];
    
    if (unplayedCount == -1 && context) {
        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
        fetchRequest.entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:context];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"feed == %@ AND consumed == %@ AND archived == %@", self, @NO, @NO];
        unplayedCount = [context countForFetchRequest:fetchRequest error:nil];
    }
    
    return unplayedCount;
}

- (NSInteger) downloadedCount
{
    NSArray* cachedEpisodes = [CacheManager sharedCacheManager].cachedEpisodes;
    NSInteger i = 0;
    for(CDEpisode* episode in cachedEpisodes) {
        if ([episode.feed isEqual:self]) {
            i++;
        }
    }
    return i;
}


- (void) invalidateCounts
{
    self.unplayedCount = -1;
    self.episodesCount = -1;
    
    [self willChangeValueForKey:@"unplayedCount"];
    [self didChangeValueForKey:@"unplayedCount"];
    
    [self willChangeValueForKey:@"episodesCount"];
    [self didChangeValueForKey:@"episodesCount"];
    
    [self willChangeValueForKey:@"downloadedCount"];
    [self didChangeValueForKey:@"downloadedCount"];
}

- (void) awakeFromFetch
{
    [super awakeFromFetch];
    [self invalidateCounts];
}

- (NSDate*) lastPlayed
{
    NSArray* sortedEpisodes = [self.episodes sortedArrayUsingDescriptors:@[ [[NSSortDescriptor alloc] initWithKey:@"lastPlayed" ascending:NO] ]];
    NSDate* lastPlayed = ((CDEpisode*)[sortedEpisodes firstObject]).lastPlayed;
    return lastPlayed;
}

- (NSDate*) lastPubDate
{
    NSArray* sortedEpisodes = [self.episodes sortedArrayUsingDescriptors:@[ [[NSSortDescriptor alloc] initWithKey:@"pubDate" ascending:NO] ]];
    NSDate* pubDate = ((CDEpisode*)[sortedEpisodes firstObject]).pubDate;
    return pubDate;
}

- (NSString*) displayTitle
{
    if ([self stringForKey:kUserDefinedFeedName]) {
        return [self stringForKey:kUserDefinedFeedName];
    }
    
    return self.title;
}

- (void) setDisplayTitle:(NSString *)displayTitle
{
    if (![[self stringForKey:kUserDefinedFeedName] isEqualToString:displayTitle]) {
        [self setString:displayTitle forKey:kUserDefinedFeedName];
    }
}



@end


NSString* kUserDefinedFeedName = @"UserDefinedFeedName";

@implementation CDFeed (FeedProperties)

- (CDFeedProperty*) propertyForKey:(NSString*)key insertOnDemand:(BOOL)insertOnDemand
{
    CDFeedProperty* property = nil;
    
    for(CDFeedProperty* p in self.properties) {
        if ([p.key isEqualToString:key]) {
            property = p;
            break;
        }
    }
    
    if (!property && insertOnDemand) {
        property = [NSEntityDescription insertNewObjectForEntityForName:@"FeedProperty" inManagedObjectContext:self.managedObjectContext];
        property.key = key;
        
        [[self mutableSetValueForKey:@"properties"] addObject:property];
    }
    return property;
}


- (BOOL) boolForKey:(NSString*)defaultName
{
    CDFeedProperty* property = [self propertyForKey:defaultName insertOnDemand:NO];
    if (property) {
        return property.boolValue;
    }
    
    return [USER_DEFAULTS boolForKey:defaultName];
}

- (void) setBool:(BOOL)boolValue forKey:(NSString *)defaultName
{
    CDFeedProperty* property = [self propertyForKey:defaultName insertOnDemand:YES];
    property.boolValue = boolValue;
}

- (NSInteger) integerForKey:(NSString*)defaultName
{
    CDFeedProperty* property = [self propertyForKey:defaultName insertOnDemand:NO];
    if (property) {
        return property.int32Value;
    }
    
    return [USER_DEFAULTS integerForKey:defaultName];
}

- (void) setInteger:(NSInteger)integerValue forKey:(NSString *)defaultName
{
    CDFeedProperty* property = [self propertyForKey:defaultName insertOnDemand:YES];
    property.int32Value = (int32_t)integerValue;
}

- (NSString*) stringForKey:(NSString*)defaultName
{
    CDFeedProperty* property = [self propertyForKey:defaultName insertOnDemand:NO];
    if (property) {
        return property.stringValue;
    }
    
    return [USER_DEFAULTS stringForKey:defaultName];
}

- (void) setString:(NSString*)stringValue forKey:(NSString *)defaultName
{
    CDFeedProperty* property = [self propertyForKey:defaultName insertOnDemand:YES];
    property.stringValue = stringValue;
}

- (double) doubleForKey:(NSString*)defaultName
{
    CDFeedProperty* property = [self propertyForKey:defaultName insertOnDemand:NO];
    if (property) {
        return property.doubleValue;
    }
    
    return [USER_DEFAULTS doubleForKey:defaultName];
}

- (void) setDouble:(double)doubleValue forKey:(NSString *)defaultName
{
    CDFeedProperty* property = [self propertyForKey:defaultName insertOnDemand:YES];
    property.doubleValue = doubleValue;
}

- (void) resetValueForKey:(NSString*)defaultName
{
    CDFeedProperty* property = [self propertyForKey:defaultName insertOnDemand:NO];
    if (property) {
        [self.managedObjectContext deleteObject:property];
    }
}

- (void) resetAllProperties
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"FeedProperty" inManagedObjectContext:self.managedObjectContext];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"feed == %@ OR feed == nil", self];
    NSArray* properties = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    
    for(NSManagedObject* object in properties) {
        [self.managedObjectContext deleteObject:object];
    }
    self.properties = nil;
}

- (BOOL) hasCustomProperties
{
    return ([self.properties count] > 0);
}

- (NSArray*) propertyKeys
{
    NSMutableArray* keys = [NSMutableArray array];
    
    for(CDFeedProperty* property in self.properties) {
        [keys addObject:property.key];
    }
    
    return keys;
}
@end


