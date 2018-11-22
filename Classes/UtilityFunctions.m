//
//  UIActions.m
//  Instacast
//
//  Created by Martin Hering on 23.09.11.
//  Copyright (c) 2011 Vemedio. All rights reserved.
//

#import "UtilityFunctions.h"

void AddSkipBackupAttributeToFile(NSString* path)
{
    if (!path) {
        return ;
        
    }
    NSURL* url = [NSURL fileURLWithPath:path];
    
    NSError *error = nil;
    [url setResourceValue:@(YES) forKey: NSURLIsExcludedFromBackupKey error:&error];
    if (error) {
        ErrLog(@"error excluding file from backup: %@", error);
    }
}


