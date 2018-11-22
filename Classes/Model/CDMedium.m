//
//  CDMedium.m
//  Instacast
//
//  Created by Martin Hering on 07.08.12.
//
//

#import "CDMedium.h"
#import "CDEpisode.h"


@interface CDMedium ()
@property (nonatomic, strong) NSString * fileURL_;
@end

@implementation CDMedium

- (NSString*) designatedUID
{
    if (!self.fileURL) {
        return [[[NSUUID alloc] init] UUIDString];
    }
    return [[self.fileURL absoluteString] MD5Hash];
}

@dynamic fileURL_;
@dynamic mimeType;
@dynamic byteSize;
@dynamic episode;


- (NSURL*) fileURL
{
    if (self.fileURL_) {
        return [NSURL URLWithString:self.fileURL_];
    }
    return nil;
}

- (void) setFileURL:(NSURL *)fileURL
{
    self.fileURL_ = [fileURL absoluteString];
}

@end
