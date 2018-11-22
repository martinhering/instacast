//
//  ICStatusBarFixedViewController.m
//  Instacast
//
//  Created by Martin Hering on 16.05.14.
//
//

#import "ICStatusBarFixedViewController.h"


@interface ICFixedLayoutGuide : NSObject <UILayoutSupport>
- (id)initWithLength:(CGFloat)length;
@property (nonatomic) CGFloat length;
@end

@implementation ICFixedLayoutGuide

@synthesize topAnchor;
@synthesize bottomAnchor;
@synthesize heightAnchor;

- (id)initWithLength:(CGFloat)length {
    self = [super init];
    if (self) {
        _length = length;
    }
    return self;
}

@end


@interface ICStatusBarFixedViewController ()

@end

@implementation ICStatusBarFixedViewController


@end
