//
//  CDList.m
//  Instacast
//
//  Created by Martin Hering on 07.08.12.
//
//

#import "CDList.h"


@implementation CDList

@dynamic name;
@dynamic rank;

+ (NSSet*) keyPathsForValuesAffectingNumberOfEpisodes
{
    return [NSSet setWithObject:@"sortedEpisodes"];
}

- (NSUInteger) numberOfEpisodes
{
    return 0;
}

- (void) calculateNumberOfEpisodesCompletion:(void (^)(NSUInteger numberOfEpisodes))completion {
    if (completion) {
        completion([self numberOfEpisodes]);
    }
}

- (NSArray*) sortedEpisodes
{
    return nil;
}

- (NSInteger) playbackTime
{
    NSInteger playbackTime = 0;
    for(CDEpisode* episode in self.sortedEpisodes) {
        playbackTime += episode.duration;
    }
    
    return playbackTime;
}

- (IC_IMAGE*) image
{
#if TARGET_OS_IPHONE
    return [[UIImage imageNamed:@"List Custom"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
#else
    return nil;
#endif
}

+ (void) updateRanksOfLists:(NSArray*)lists
{
    NSInteger num = 0;
    for(CDList* list in lists) {
        list.rank = (int32_t)num;
        num++;
    }
}
@end
