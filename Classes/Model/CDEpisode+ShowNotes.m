//
//  CDEpisode+ShowNotes.m
//  Instacast
//
//  Created by Martin Hering on 06.11.12.
//
//

#import "CDEpisode+ShowNotes.h"

NSString* kEpisodeShowLinksTitle = @"title";
NSString* kEpisodeShowLinksLink = @"link";

@interface CDEpisode (Private)
@property (nonatomic, strong) NSArray* showLinks_;
@end


@implementation CDEpisode (ShowNotes)

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
    NSMutableString* showNotes = [((self.fulltext) ? self.fulltext : self.summary) mutableCopy];
    [showNotes replaceOccurrencesOfRegex:@"<p><br\\s*/>\\s*</p>" withString:@"" options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators];
    [showNotes replaceOccurrencesOfRegex:@"<td class=\"flattr_cell\">.*?</td>" withString:@"" options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators];
    [showNotes replaceOccurrencesOfRegex:@"<object.*?>.*?<\\/object>" withString:@"" options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators];
    [showNotes replaceOccurrencesOfRegex:@"<iframe.*?>.*?<\\/iframe>" withString:@"" options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators];
    [showNotes replaceOccurrencesOfRegex:@"<audio.*?>.*?<\\/audio>" withString:@"" options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators];
    [showNotes replaceOccurrencesOfRegex:@"<video.*?>.*?<\\/video>" withString:@"" options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators];
    [showNotes replaceOccurrencesOfRegex:@"<script.*?>.*?<\\/script>" withString:@"" options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators];
    [showNotes replaceOccurrencesOfRegex:@"style=\".*?\"" withString:@"" options:NSRegularExpressionCaseInsensitive];
    [showNotes replaceOccurrencesOfRegex:@"class=\"(?!podlove).*?\"" withString:@"" options:NSRegularExpressionCaseInsensitive];
    [showNotes replaceOccurrencesOfRegex:@"<a.*?<img.*?src=\".*?\\/flattr-badge-large.png\".*?<\\/a>" withString:@"" options:NSRegularExpressionCaseInsensitive];
    [showNotes replaceOccurrencesOfRegex:@"<a.*?<img.*?src=\".*?\\/flattr_logo_16.png\".*?<\\/a>" withString:@"" options:NSRegularExpressionCaseInsensitive];
    [showNotes replaceOccurrencesOfRegex:@"<a.*?<img.*?src=\"\".*?<\\/a>" withString:@"" options:NSRegularExpressionCaseInsensitive];
    [showNotes replaceOccurrencesOfRegex:@"<img.*?width=\"1\".*?>" withString:@"" options:NSRegularExpressionCaseInsensitive];
    
    [showNotes replaceOccurrencesOfString:@"<p></p>" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [showNotes length])];
    return showNotes;
}

- (NSArray*) showLinks
{
    if (self.showLinks_) {
        return self.showLinks_;
    }
    
    NSMutableArray* myLinks = [[NSMutableArray alloc] init];
    NSMutableDictionary* index = [[NSMutableDictionary alloc] init];
    
    NSString* description = [self cleanedShowNotes];
    
    if (!description) {
        return nil;
    }
    
    static NSString* linkRegEx = @"<a.*?href=\"(.*?)\".*?>(.*?)<\\/";
    
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:linkRegEx options:0 error:&error];
    
    [regex enumerateMatchesInString:description
                            options:0
                              range:NSMakeRange(0, [description length])
                         usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                             
                             if ([result numberOfRanges] >= 3)
                             {
                                 NSString* link = [description substringWithRange:[result rangeAtIndex:1]];
                                 NSString* title = [[description substringWithRange:[result rangeAtIndex:2]] stringByDecodingHTMLEntities];
                                 
                                 if ([title length] > 0 && link && ![index objectForKey:title])
                                 {
                                     NSMutableDictionary* linkDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:link, kEpisodeShowLinksLink, title, kEpisodeShowLinksTitle, nil];
                                     [myLinks addObject:linkDict];
                                     
                                     [index setObject:link forKey:title];
                                 }
                             }
                         }];
    
    self.showLinks_ = myLinks;
    return self.showLinks_;
}



@end
