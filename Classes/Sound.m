//
//  Sound.m
//  Instacast
//
//  Created by Martin Hering on 18.03.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>

#import "Sound.h"

static void _SystemSoundCompleted (SystemSoundID ssID, void *clientData);

static void _SystemSoundCompleted (SystemSoundID ssID, void *clientData)
{
	AudioServicesRemoveSystemSoundCompletion(ssID);
	AudioServicesDisposeSystemSoundID(ssID);
}

void PlaySoundFile(NSString* name, BOOL vibrate)
{
    // no interface sounds when disabled in settings
	if (![USER_DEFAULTS boolForKey:UISoundEnabled]) {
		return;
	}
    
    // no interface sounds during playback
    if (![PlaybackManager playbackManager].paused) {
        return;
    }
    
#if	TARGET_OS_IPHONE
    // no interface sounds in background
    if ([App applicationState] == UIApplicationStateBackground) {
        return;
    }
#endif
	
	NSString* path = [[NSBundle mainBundle] pathForResource:name ofType:@"caf"];
	if (!path) {
		return;
	}
	
	NSURL* url = [NSURL fileURLWithPath:path];

	SystemSoundID outSystemSoundID;
	OSStatus err;
	
	err = AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &outSystemSoundID);
    
    
	if (err == noErr)
	{
		AudioServicesAddSystemSoundCompletion (outSystemSoundID,
											   NULL,
											   NULL,
											   _SystemSoundCompleted,
											   NULL);
											   
		AudioServicesPlaySystemSound(outSystemSoundID);		
	}

#if	TARGET_OS_IPHONE
	if (vibrate) {
		AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
	}
#endif
}