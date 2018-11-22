//
//  CDChapter.m
//  Instacast
//
//  Created by Martin Hering on 07.08.12.
//
//

#import "CDChapter.h"
#import "CDEpisode.h"


@interface CDChapter ()
@property (nonatomic, strong) NSString* linkURL_;
@end

@implementation CDChapter

@dynamic index;
@dynamic title;
@dynamic duration;
@dynamic timecode;
@dynamic linkURL_;
@dynamic episode;

- (NSURL*) linkURL
{
    if (self.linkURL_) {
        return [NSURL URLWithString:self.linkURL_];
    }
    return nil;
}

- (void) setLinkURL:(NSURL *)linkURL
{
    self.linkURL_ = [linkURL absoluteString];
}

@end
