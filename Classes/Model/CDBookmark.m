//
//  CDBookmark.m
//  Instacast
//
//  Created by Martin Hering on 07.08.12.
//
//

#import "CDBookmark.h"

@interface CDBookmark ()
@property (nonatomic, strong) NSString * feedURL_;
@property (nonatomic, strong) NSString * imageURL_;
@end

@implementation CDBookmark

@dynamic episodeHash;
@dynamic title;
@dynamic feedURL_;
@dynamic imageURL_;
@dynamic episodeGuid;
@dynamic feedTitle;
@dynamic episodeTitle;
@dynamic position;

- (NSURL*) feedURL
{
    if (self.feedURL_) {
        return [NSURL URLWithString:self.feedURL_];
    }
    return nil;
}

- (void) setFeedURL:(NSURL *)feedURL
{
    self.feedURL_ = [feedURL absoluteString];
}

- (NSURL*) imageURL
{
    if (self.imageURL_) {
        return [NSURL URLWithString:self.imageURL_];
    }
    return nil;
}

- (void) setImageURL:(NSURL *)imageURL
{
    self.imageURL_ = [imageURL absoluteString];
}


@end
