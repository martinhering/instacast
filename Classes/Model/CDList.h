//
//  CDList.h
//  Instacast
//
//  Created by Martin Hering on 07.08.12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CDBase.h"

@interface CDList : CDBase

@property (nonatomic, strong) NSString * name;
@property (nonatomic) int32_t rank;

@property (nonatomic, readonly) NSUInteger numberOfEpisodes;
@property (nonatomic, readonly) NSArray* sortedEpisodes;

- (NSInteger) playbackTime;

@property (nonatomic, readonly) id image;

- (void) calculateNumberOfEpisodesCompletion:(void (^)(NSUInteger numberOfEpisodes))completion;

+ (void) updateRanksOfLists:(NSArray*)lists;
@end
