//
//  CDFeed+Helper.m
//  Instacast
//
//  Created by Martin Hering on 18.12.12.
//
//

#import "CDFeed+Helper.h"

@implementation CDFeed (Helper)

- (NSArray*) sortedEpisodes
{
    BOOL reverseOrder = ([[self stringForKey:FeedSortOrder] isEqualToString:SortOrderOlderFirst]);
    
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:self.managedObjectContext];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"feed == %@ AND archived == %@", self, @NO];
    fetchRequest.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"pubDate" ascending:reverseOrder] ];
    [fetchRequest setIncludesSubentities:NO];
    return [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
}

- (NSArray*) chronologicallySortedEpisodes
{
    NSManagedObjectContext* context = [self managedObjectContext];
    
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:context];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"feed == %@ AND archived == %@", self, @NO, @NO];
    fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"pubDate" ascending:NO]];
    
    NSError* error;
    NSArray* episodes = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        ErrLog(@"error getting sorted episodes: %@", error);
    }
    return episodes;
}

- (NSArray*) unplayedEpisodes
{
    BOOL reverseOrder = ([[self stringForKey:FeedSortOrder] isEqualToString:SortOrderOlderFirst]);
    NSSet* filteredEpisodes = [self.episodes filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"archived == %@ AND consumed == %@", @NO, @NO]];
    return [filteredEpisodes sortedArrayUsingDescriptors:@[ [[NSSortDescriptor alloc] initWithKey:@"pubDate" ascending:reverseOrder] ]];
}

- (NSURL*) sourceURLAsPcastURL
{
	NSString* urlString = [self.sourceURL absoluteString];
	if (!urlString) {
		return nil;
	}
	
	urlString = [urlString stringByReplacingCharactersInRange:NSMakeRange(0, [[self.sourceURL scheme] length]) withString:@"podcast"];
	return [NSURL URLWithString:urlString];
}

@end
