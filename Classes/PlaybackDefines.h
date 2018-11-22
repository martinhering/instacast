/*
 *  PlaybackDefines.h
 *  Instacast
 *
 *  Created by Martin Hering on 01.07.11.
 *  Copyright 2011 Vemedio. All rights reserved.
 *
 */

enum {
	PlaybackSpeedControlNormalSpeed     = 0,
	PlaybackSpeedControlDoubleSpeed     = 1,
	PlaybackSpeedControlMinusHalfSpeed  = 2,
    PlaybackSpeedControlPlusHalfSpeed   = 3,
    PlaybackSpeedControlTripleSpeed     = 4
};
typedef NSInteger PlaybackSpeedControl;

extern NSString* PlaybackManagerDidStartNotification;
extern NSString* PlaybackManagerDidEndNotification;
extern NSString* PlaybackManagerDidUpdateNotification;
extern NSString* PlaybackManagerDidChangeEpisodeNotification;

enum {
    PlaybackStopTimeNoValue = 0,
    PlaybackStopTime5min    = 5,
    PlaybackStopTime10min   = 10,
    PlaybackStopTime15min   = 15,
    PlaybackStopTime30min   = 30,
    PlaybackStopTime60min   = 60
};
typedef NSInteger PlaybackStopTimeValue;

enum {
    ContinuousPlaybackOff,
    ContinuousPlaybackOn,
    ContinuousPlaybackReverse
};
typedef NSInteger ContinuousPlaybackType;