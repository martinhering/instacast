//
//  PlayerView.m
//  Instacast
//
//  Created by Martin Hering on 06.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import "PlayerView.h"
#import <AVFoundation/AVFoundation.h>

@implementation PlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

@end

