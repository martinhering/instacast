//
//  CacheManager+FileDetector.h
//  Instacast
//
//  Created by Martin Hering on 07.02.13.
//
//


extern NSString* CacheManagerDidUpdateFileReflectorsNotification;

@interface CacheManager (FileDetector)

- (void) initFileDetector;

- (NSSet*) fileReflectors;

- (NSURL*) remoteURLWithLocalURL:(NSURL*)localURL forFileReflector:(id)fileReflector;
@end
