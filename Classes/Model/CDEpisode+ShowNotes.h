//
//  CDEpisode+ShowNotes.h
//  Instacast
//
//  Created by Martin Hering on 06.11.12.
//
//

#import "CDEpisode.h"

@interface CDEpisode (ShowNotes)

- (NSString*) cleanTitleUsingFeedTitle:(NSString*)feedTitle;
- (NSString*) cleanedShowNotes;
- (NSArray*) showLinks;

@end

extern NSString* kEpisodeShowLinksTitle;
extern NSString* kEpisodeShowLinksLink;