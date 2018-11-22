//
//  CDFeedProperty.m
//  Instacast
//
//  Created by Martin Hering on 08.08.12.
//
//

#import "CDFeedProperty.h"
#import "CDFeed.h"

@interface CDFeedProperty ()
@property (nonatomic) int32_t integerValue;
@end

@implementation CDFeedProperty

//- (NSString*) designatedUID
//{
//    return [[@"CDFeedProperty" stringByAppendingString:[self.feed.sourceURL absoluteString]] MD5Hash];
//}

@dynamic boolValue;
@dynamic dateValue;
@dynamic doubleValue;
@dynamic integerValue;
@dynamic key;
@dynamic stringValue;
@dynamic feed;

@dynamic int32Value;

- (int32_t) int32Value {
    return self.integerValue;
}

- (void) setInt32Value:(int32_t)int32Value
{
    self.integerValue = int32Value;
}
@end
