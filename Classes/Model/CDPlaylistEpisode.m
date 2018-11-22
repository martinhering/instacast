//
//  CDPlaylistEpisode.m
//  Instacast
//
//  Created by Martin Hering on 09.08.12.
//
//

#import "CDPlaylistEpisode.h"
#import "CDEpisode.h"
#import "CDPlaylist.h"


@implementation CDPlaylistEpisode {
    BOOL _userAction;
    BOOL _observing;
}


@dynamic rank;
@dynamic list;
@dynamic episode;


- (void) setObserving:(BOOL)observing
{
    if (!_observing && observing)
    {
        __weak CDPlaylistEpisode* weakSelf = self;
        [self addTaskObserver:self forKeyPath:@"rank" task:^(id obj, NSDictionary *change) {
            CDPlaylist* list = weakSelf.list;
            [list _clearCacheWhenChangingExternally];
        }];
        
        _observing = YES;
    }
    else if (_observing && !observing)
    {
        [self removeTaskObserver:self forKeyPath:@"rank"];
        _observing = NO;
    }
}

- (void) awakeFromFetch
{
    [super awakeFromFetch];
    if (self.managedObjectContext == DMANAGER.objectContext) {
        [self setObserving:YES];
    }
}

- (void) awakeFromInsert
{
    [super awakeFromInsert];
    if (self.managedObjectContext == DMANAGER.objectContext) {
        [self setObserving:YES];
    }
}

- (void) willTurnIntoFault
{
    if (self.managedObjectContext == DMANAGER.objectContext) {
        [self setObserving:NO];
    }
}

@end
