//
//  ICEpisode.m
//  ICFeedParser
//
//  Created by Martin Hering on 16.07.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import "ICEpisode.h"
#import "ICMedia.h"

@implementation ICEpisode

+ (id) episode
{
    return [[self alloc] init];
}

- (BOOL) isEqual:(ICEpisode*)episode
{
	return ([self.guid isEqualToString:episode.guid]);
}

- (BOOL) isEqualToEpisode:(ICEpisode*)episode
{
	return ([self.objectHash isEqualToString:episode.objectHash]);
}

- (NSComparisonResult)compare:(ICEpisode *)episode
{
	NSComparisonResult result = [self.pubDate compare:episode.pubDate];
	if (result == NSOrderedAscending) {
		return NSOrderedDescending;
	}
	else if (result == NSOrderedDescending) {
		return NSOrderedAscending;
	}
	return NSOrderedSame;
}

#pragma mark -

- (NSString*) cleanTitleUsingFeedTitle:(NSString*)feedTitle
{
	NSString* title = self.title;
	
	if (!feedTitle) {
		return title;
	}
	
    NSMutableCharacterSet* set = [NSMutableCharacterSet characterSetWithCharactersInString:@"-:,;—#–"];
    [set formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSArray* trimStrings = [NSArray arrayWithObjects:feedTitle, @"episode", @"ep.", nil];
    
	if ([title length] > [feedTitle length]+3)
    {
        for(NSString* trimString in trimStrings)
        {
            NSRange trimRange = [title rangeOfString:trimString options:NSAnchoredSearch | NSCaseInsensitiveSearch];
            if (trimRange.location != NSNotFound) {
                title = [title stringByReplacingCharactersInRange:trimRange withString:@""];
                title = [title stringByTrimmingCharactersInSet:set];
            }
        }
	}
    
    title = [title stringByTrimmingCharactersInSet:set];
	return title;
}

- (NSString*) cleanedShowNotes
{
    NSMutableString* showNotes = [((self.textDescription) ? self.textDescription : self.summary) mutableCopy];
    [showNotes replaceOccurrencesOfRegex:@"<object.*?>.*?<\\/object>" withString:@""];
    [showNotes replaceOccurrencesOfRegex:@"<audio.*?>.*?<\\/audio>" withString:@""];
    [showNotes replaceOccurrencesOfRegex:@"<video.*?>.*?<\\/video>" withString:@""];
    [showNotes replaceOccurrencesOfRegex:@"style=\".*?\"" withString:@""];
    [showNotes replaceOccurrencesOfRegex:@"class=\".*?\"" withString:@""];
    [showNotes replaceOccurrencesOfRegex:@"<a.*?<img.*?src=\".*?\\/flattr-badge-large.png\".*?<\\/a>" withString:@""];
    [showNotes replaceOccurrencesOfRegex:@"<a.*?<img.*?src=\".*?\\/flattr_logo_16.png\".*?<\\/a>" withString:@""];
    [showNotes replaceOccurrencesOfString:@"<p></p>" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [showNotes length])];
    
    return showNotes;
}

- (ICMedia*) preferedMedium
{
    NSArray* mediaItems = self.media;
	if ([mediaItems count] == 0) {
		return nil;
	}
    
    NSArray* preferredMediaTypes = [NSArray arrayWithObjects:@"audio/x-m4a", @"video/mp4", @"video/x-m4v", @"audio/mpeg", nil];
    
	for(ICMedia* media in mediaItems) {
        if ([preferredMediaTypes containsObject:media.mimeType]) {
			return media;
		}
	}
	
	for(ICMedia* media in mediaItems) {
		if ([media.mimeType rangeOfString:@"audio" options:NSCaseInsensitiveSearch].location != NSNotFound ||
			[media.mimeType rangeOfString:@"video" options:NSCaseInsensitiveSearch].location != NSNotFound) {
			return media;
		}
	}
    
    ICMedia* media = [mediaItems objectAtIndex:0];
    
    if ([media.mimeType hasPrefix:@"image"]) {
        return nil;
    }
	
	return media;
}

@end
