//
//  PlayerSpeedButton.m
//  Instacast
//
//  Created by Martin Hering on 10.01.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import "PlayerSpeedButton.h"
#import "VDModalInfo.h"

@implementation PlayerSpeedButton {
    BOOL        _observing;
    NSDate*     _trackingDate;
    NSTimer*    _longTrackingTimer;
}

- (void) _updateImage
{
    PlaybackManager* pman = [PlaybackManager playbackManager];
    
    if (pman.speedControl == PlaybackSpeedControlNormalSpeed) {
        [self setImage:[[UIImage imageNamed:@"Player Speed Outline"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
              forState:UIControlStateNormal];
        [self setTitleColor:self.tintColor forState:UIControlStateNormal];
        [self setTitleColor:self.tintColor forState:UIControlStateHighlighted];
    }
    else {
        [self setImage:[[UIImage imageNamed:@"Player Speed Fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
              forState:UIControlStateNormal];
        [self setTitleColor:ICBackgroundColor forState:UIControlStateNormal];
        [self setTitleColor:ICBackgroundColor forState:UIControlStateHighlighted];
    }
    
    switch (pman.speedControl) {
        case PlaybackSpeedControlNormalSpeed:
            [self setTitle:@"1x" forState:UIControlStateNormal];
            break;
        case PlaybackSpeedControlDoubleSpeed:
            [self setTitle:@"2x" forState:UIControlStateNormal];
            break;
        case PlaybackSpeedControlPlusHalfSpeed:
            [self setTitle:@"1.5x" forState:UIControlStateNormal];
            break;
        case PlaybackSpeedControlMinusHalfSpeed:
            [self setTitle:@"0.5x" forState:UIControlStateNormal];
            break;
        case PlaybackSpeedControlTripleSpeed:
            [self setTitle:@"3x" forState:UIControlStateNormal];
            break;
        default:
            break;
    }
    
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    if (newWindow)
    {
        [self _updateImage];
        
        _observing = YES;
        [[PlaybackManager playbackManager] addTaskObserver:self forKeyPath:@"speedControl" task:^(id obj, NSDictionary *change) {
            [self _updateImage];
        }];
    }
    else
    {
        if (_observing) {
            [[PlaybackManager playbackManager] removeTaskObserver:self forKeyPath:@"speedControl"];
            _observing = NO;
        }
    }
}

- (void) tintColorDidChange
{
    if ([PlaybackManager playbackManager].speedControl == PlaybackSpeedControlNormalSpeed) {
        [self setTitleColor:self.tintColor forState:UIControlStateNormal];
        [self setTitleColor:self.tintColor forState:UIControlStateHighlighted];
    }
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    _trackingDate = [NSDate date];
    
    _longTrackingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_longTrackingTimerAction:) userInfo:nil repeats:NO];

    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (void) _longTrackingTimerAction:(NSTimer*)timer
{
    [PlaybackManager playbackManager].speedControl = PlaybackSpeedControlNormalSpeed;
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Playback set to original speed.".ls);
    
    VDModalInfo* modalInfo = [VDModalInfo modalInfo];
    modalInfo.closableByTap = NO;
    modalInfo.animation = VDModalInfoAnimationMoveDown;
    modalInfo.alignment = VDModalInfoAlignmentPhonePlayer;
    modalInfo.size = CGSizeMake(280, 44);
    
    modalInfo.textLabel.text = @"Playback speed: original.".ls;
    [modalInfo show];
    
    [self perform:^(id sender) {
        [modalInfo close];
    } afterDelay:1];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [super endTrackingWithTouch:touch withEvent:event];
    
    if (CGRectContainsPoint(self.bounds,  [touch locationInView:self]))
    {
        if ([_trackingDate timeIntervalSinceNow] >= -0.5)
        {
            PlaybackManager* pman = [PlaybackManager playbackManager];
            NSString* announcement = nil;
            
            switch (pman.speedControl) {
                case PlaybackSpeedControlNormalSpeed:
                    pman.speedControl = PlaybackSpeedControlPlusHalfSpeed;
                    announcement = @"Playback set to 1.5x speed.".ls;
                    break;
                case PlaybackSpeedControlPlusHalfSpeed:
                    pman.speedControl = PlaybackSpeedControlDoubleSpeed;
                    announcement = @"Playback set to double speed.".ls;
                    break;
                case PlaybackSpeedControlDoubleSpeed:
                    pman.speedControl = PlaybackSpeedControlTripleSpeed;
                    announcement = @"Playback set to triple speed.".ls;
                    break;
                case PlaybackSpeedControlMinusHalfSpeed:
                    pman.speedControl = PlaybackSpeedControlNormalSpeed;
                    announcement =  @"Playback set to original speed.".ls;
                    break;
                case PlaybackSpeedControlTripleSpeed:
                    pman.speedControl = PlaybackSpeedControlMinusHalfSpeed;
                    announcement = @"Playback set to half speed.".ls;
                    break;
                default:
                    break;
            }
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, announcement);
        }
        
    }
    
    [_longTrackingTimer invalidate];
    _longTrackingTimer = nil;
    
    _trackingDate = nil;
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    return CGRectMake((44-29)/2, (44-18)/2, 29, 18);
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    return CGRectMake((44-29)/2, (44-18)/2, 29, 18);
}
@end
