//
//  MainSegments.h
//  Instacast
//
//  Created by Martin Hering on 03.04.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

enum {
    MainSegmentSubscriptions,
    MainSegmentPlaylists,
    MainSegmentBookmarks,
};
typedef NSInteger MainSegment;

@class VDSegmentedControl;

@protocol MainSegmentViewController
@property (nonatomic, retain) VDSegmentedControl* segmentedControl;
@end