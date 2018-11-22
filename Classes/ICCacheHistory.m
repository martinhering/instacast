//
//  ICCacheHistory.m
//  Instacast
//
//  Created by Martin Hering on 20.03.13.
//
//

#import "ICCacheHistory.h"

static NSString* kDidAutoDownloadKey = @"DidAutoDownload";

@interface ICCacheHistory ()
@property (nonatomic, strong) NSString* filePath;
@property (nonatomic, strong) NSMutableDictionary* history;
@property (nonatomic) BOOL shouldSave;
@end

@implementation ICCacheHistory

- (id) initWithContentsOfFile:(NSString*)filePath
{
    if ((self = [self init]))
    {
        _filePath = filePath;
        [self _readHistoryFile];
    }
        
    return self;
}

- (void) _readHistoryFile
{
    NSData* data = [NSData dataWithContentsOfFile:self.filePath];
    if (data) {
        self.history = [NSPropertyListSerialization propertyListWithData:data
                                                                 options:NSPropertyListMutableContainersAndLeaves
                                                                  format:NULL
                                                                   error:nil];
    }

    if (!self.history || ![self.history isKindOfClass:[NSMutableDictionary class]]) {
        self.history = [NSMutableDictionary dictionary];
    }
}

- (void) _saveHistoryFile
{
    [self.history writeToFile:self.filePath atomically:YES];
}

- (void) save {
    [self _saveHistoryFile];
    self.shouldSave = NO;
}

- (void) clear {
    [self.history removeAllObjects];
    [self save];
}

- (id) valueForKey:(NSString *)key episode:(CDEpisode*)episode
{
    if (!episode.objectHash) {
        return nil;
    }
    NSMutableDictionary* values = [self.history objectForKey:episode.objectHash];
    return [values objectForKey:key];
}

- (void) setValue:(id)value forKey:(NSString *)key episode:(CDEpisode*)episode
{
    if (!episode.objectHash) {
        return;
    }
    
    NSMutableDictionary* values = [self.history objectForKey:episode.objectHash];
    if (!values) {
        values = [NSMutableDictionary dictionary];
        [self.history setObject:values forKey:episode.objectHash];
    }
    
    [values setValue:value forKey:key];
    self.shouldSave = YES;
    
    [self coalescedPerformSelector:@selector(save)];
}

- (void) removeValueForKey:(NSString *)key episode:(CDEpisode*)episode
{
    if (!episode.objectHash) {
        return;
    }
    
    NSMutableDictionary* values = [self.history objectForKey:episode.objectHash];
    return [values removeObjectForKey:key];
}

#pragma mark -

- (BOOL) episodeDidAutoDownload:(CDEpisode*)episode
{
    return [[self valueForKey:kDidAutoDownloadKey episode:episode] boolValue];
}

- (void) setEpisode:(CDEpisode*)episode didAutoDownload:(BOOL)autoDownload
{
    [self setValue:@(autoDownload) forKey:kDidAutoDownloadKey episode:episode];
}

- (void) resetValuesForEpisode:(CDEpisode*)episode
{
    if (!episode.objectHash) {
        return;
    }
    
    [self.history removeObjectForKey:episode.objectHash];
}
        
        
@end
