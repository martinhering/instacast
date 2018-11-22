//
//  OpenInSafariActivity.m
//  Instacast
//
//  Created by Martin Hering on 05.11.14.
//
//

#import "OpenInSafariActivity.h"

@interface OpenInSafariActivity ()
@property (nonatomic, strong) NSURL* URL;
@end

@implementation OpenInSafariActivity

- (NSString *)activityType
{
    return NSStringFromClass([self class]);
}

- (NSString *)activityTitle
{
    return @"Open in Safari".ls;
}

- (UIImage *)activityImage
{
    return [UIImage imageNamed:@"OpenInSafari Activity"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:activityItem]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]]) {
            self.URL = activityItem;
        }
    }
}

- (void)performActivity
{
    BOOL completed = [[UIApplication sharedApplication] openURL:self.URL];
    
    [self activityDidFinish:completed];
}

@end
