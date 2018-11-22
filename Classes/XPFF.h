//
//  XPFF.h
//  Instacast
//
//  Created by Martin Hering on 11.04.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>


NSData* XPFFDataWithBookmarks(NSArray* bookmarks);
NSData* XPFFDataWithBookmarksFilterHashes(NSArray* bookmarks, NSSet* filterHashes);

BOOL XPFFImportData(NSData* data, void(^completion)(NSArray* bookmarks, NSError* error));