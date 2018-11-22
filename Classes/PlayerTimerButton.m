//
//  PlayerTimerButton.m
//  Instacast
//
//  Created by Martin Hering on 10.01.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import "PlayerTimerButton.h"
#import "VDModalInfo.h"

@interface PlayerTimerButton ()
@property (nonatomic, strong) UIImageView* clockStepsImageView;
@property (nonatomic, assign) PlaybackStopTimeValue timerValue;
@property (nonatomic, strong) VDModalInfo* modalInfo;
@end

@implementation PlayerTimerButton {
    BOOL        _observing;
    NSDate*     _trackingDate;
    NSTimer*    _longTrackingTimer;
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    if (newWindow && !self.clockStepsImageView)
    {
        [self update];

        [[AudioSession sharedAudioSession] addTaskObserver:self forKeyPath:@"timerRemainingTime" task:^(id obj, NSDictionary *change) {
            [self update];
        }];
        _observing = YES;
    }
    else if (!newWindow && self.clockStepsImageView)
    {
        if (_observing) {
            [[AudioSession sharedAudioSession] removeTaskObserver:self forKeyPath:@"timerRemainingTime"];
            _observing = NO;
        }
    }
}

- (void) update
{
    AudioSession* session = [AudioSession sharedAudioSession];

    if (session.timerValue == PlaybackStopTimeNoValue) {
        [self setImage:[[UIImage imageNamed:@"Player Timer Outline"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
              forState:UIControlStateNormal];
        
        [self setTitle:nil forState:UIControlStateNormal];
    }
    else
    {
        NSTimeInterval tRem = session.timerRemainingTime;

        [self setImage:[[UIImage imageNamed:@"Player Timer Fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
              forState:UIControlStateNormal];
        
        [self setTitle:[NSString stringWithFormat:@"%ld", (long)(tRem/60)+1] forState:UIControlStateNormal];
    }
    
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self setTitleColor:ICBackgroundColor forState:UIControlStateNormal];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    _trackingDate = [NSDate date];
    
    _longTrackingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_longTrackingTimer:) userInfo:nil repeats:NO];
    
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (void) _longTrackingTimer:(NSTimer*)timer
{
    [AudioSession sharedAudioSession].timerValue = PlaybackStopTimeNoValue;
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Sleep Timer disabled.".ls);
    
    VDModalInfo* modalInfo = [VDModalInfo modalInfo];
    modalInfo.closableByTap = NO;
    modalInfo.animation = VDModalInfoAnimationMoveDown;
    modalInfo.alignment = VDModalInfoAlignmentPhonePlayer;
    modalInfo.size = CGSizeMake(280, 44);
    
    modalInfo.textLabel.text = @"Sleep Timer disabled.".ls;
    [modalInfo show];
    
    [self perform:^(id sender) {
        [modalInfo close];
    } afterDelay:1];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [super endTrackingWithTouch:touch withEvent:event];
    
    CGRect b = CGRectInset(self.bounds, -10, -10);
    if (CGRectContainsPoint(b,  [touch locationInView:self]))
    {
        if ([_trackingDate timeIntervalSinceNow] >= -0.5)
        {
            AudioSession* session = [AudioSession sharedAudioSession];
            
            NSString* announcement = nil;
            
            switch (session.timerValue) {
                case PlaybackStopTimeNoValue:
                    session.timerValue = PlaybackStopTime5min;
                    announcement = [NSString stringWithFormat:@"Sleep Timer set to %d minutes.".ls, 5];
                    break;
                case PlaybackStopTime5min:
                    session.timerValue = PlaybackStopTime10min;
                    announcement = [NSString stringWithFormat:@"Sleep Timer set to %d minutes.".ls, 10];
                    break;
                case PlaybackStopTime10min:
                    session.timerValue = PlaybackStopTime15min;
                    announcement = [NSString stringWithFormat:@"Sleep Timer set to %d minutes.".ls, 15];
                    break;
                case PlaybackStopTime15min:
                    session.timerValue = PlaybackStopTime30min;
                    announcement = [NSString stringWithFormat:@"Sleep Timer set to %d minutes.".ls, 30];
                    break;
                case PlaybackStopTime30min:
                    session.timerValue = PlaybackStopTime60min;
                    announcement = [NSString stringWithFormat:@"Sleep Timer set to %d minutes.".ls, 60];
                    break;
                default:
                case PlaybackStopTime60min:
                    session.timerValue = PlaybackStopTimeNoValue;
                    announcement = @"Sleep Timer disabled.".ls;
                    break;
            }
            
            [self update];
        
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, announcement);
        }
    }
    
    [_longTrackingTimer invalidate];
    _longTrackingTimer = nil;
    
    _trackingDate = nil;
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    return CGRectMake((44-25)/2, (44-25)/2, 25, 25);
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    return CGRectMake((44-25)/2, (44-25)/2, 25, 25);
}
@end
