//
//  CacheManager+FileDetector.m
//  Instacast
//
//  Created by Martin Hering on 07.02.13.
//
//

#import "CacheManager+FileDetector.h"

static NSString* kCacheManagerNetBrowserProperty = @"CacheManagerNetBrowser";
static NSString* kCacheManagerNetServicesProperty = @"CacheManagerNetServices";
static NSString* kCacheManagerFileReflectorsProperty = @"CacheManagerFileReflectors";
static NSString* kDefaultsFileReflectorUID = @"FileReflectorUID";

NSString* CacheManagerDidUpdateFileReflectorsNotification = @"CacheManagerDidUpdateFileReflectorsNotification";

@interface CacheManager () <NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@end


@implementation CacheManager (FileDetector)

- (void) initFileDetector
{
    NSNetServiceBrowser* browser = [[NSNetServiceBrowser alloc] init];
    browser.delegate = self;
    [browser searchForServicesOfType:@"_http._tcp." inDomain:@""];
    
    [self setAssociatedObject:browser forKey:kCacheManagerNetBrowserProperty];
    
    NSMutableSet* netServices = [[NSMutableSet alloc] init];
    [self setAssociatedObject:netServices forKey:kCacheManagerNetServicesProperty];
    
    NSMutableSet* fileReflectors = [[NSMutableSet alloc] init];
    [self setAssociatedObject:fileReflectors forKey:kCacheManagerFileReflectorsProperty];
}

- (NSSet*) fileReflectors
{
    return [self associatedObjectForKey:kCacheManagerFileReflectorsProperty];
}

- (NSURL*) remoteURLWithLocalURL:(NSURL*)localURL forFileReflector:(NSNetService*)fileReflector
{
    NSString* filename = [localURL lastPathComponent];
    NSString* host = [fileReflector hostName];
    NSInteger port = [fileReflector port];
    
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%ld/%@", host, (long)port, filename]];
}

#pragma mark -
#pragma mark NSNetServiceBrowserDelegate

-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    NSMutableSet* netServices = [self associatedObjectForKey:kCacheManagerNetServicesProperty];
    
    [netServices addObject:aNetService];
    
    aNetService.delegate = self;
    [aNetService startMonitoring];
    [aNetService resolveWithTimeout:10];
}


- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    NSDictionary * aTXTDictionary = [NSNetService dictionaryFromTXTRecordData:sender.TXTRecordData];
    NSData* aValue = [aTXTDictionary valueForKey:@"com.vemedio.uid"];

    if (aValue)
    {
        NSString* myReflectorUID = [USER_DEFAULTS stringForKey:kDefaultsFileReflectorUID];
        NSString* uid = [[NSString alloc] initWithData:aValue encoding:NSUTF8StringEncoding];
        NSMutableSet* fileReflectors = [self associatedObjectForKey:kCacheManagerFileReflectorsProperty];
        
        if (![fileReflectors containsObject:sender] && ![uid isEqualToString:myReflectorUID]) {
            [self willChangeValueForKey:@"fileReflectors"];
            [fileReflectors addObject:sender];
            [self didChangeValueForKey:@"fileReflectors"];
            
            DebugLog(@"Discovered File Reflector: %@",sender.name);
            [[NSNotificationCenter defaultCenter] postNotificationName:CacheManagerDidUpdateFileReflectorsNotification object:self];
        }
    }
}


-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    NSMutableSet* fileReflectors = [self associatedObjectForKey:kCacheManagerFileReflectorsProperty];
    NSMutableSet* netServices = [self associatedObjectForKey:kCacheManagerNetServicesProperty];
    
    [self willChangeValueForKey:@"fileReflectors"];
    
    [fileReflectors removeObject:aNetService];
    
    BOOL wasListed = [netServices containsObject:aNetService];
    [netServices removeObject:aNetService];
    
    [self didChangeValueForKey:@"fileReflectors"];
    
    if (wasListed)
    {
        DebugLog(@"Removed File Reflector: %@",aNetService.name);
        [[NSNotificationCenter defaultCenter] postNotificationName:CacheManagerDidUpdateFileReflectorsNotification object:self];
    }
}

@end
