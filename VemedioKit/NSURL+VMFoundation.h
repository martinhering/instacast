//
//  NSURL+VMFoundation.h
//  InstacastSearchIndexer
//
//  Created by Martin Hering on 16.01.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (VMFoundation)
- (NSURL*) URLByDeletingUsernameAndPassword;
- (NSDictionary*) queryParameters;
- (NSURL*) URLByDeletingQuery;
- (NSURL*) URLByAddingQueryParameters:(NSDictionary*)dictionary;
- (NSString*) prettyString;

+ (id) URLWithInsecureString:(NSString*)string;
+ (id) URLWithInsecureString:(NSString *)URLString relativeToURL:(NSURL *)baseURL;

- (BOOL)isEquivalent:(NSURL *)aURL;
@end
