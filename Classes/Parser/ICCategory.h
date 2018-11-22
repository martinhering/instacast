//
//  ICCategory.h
//  ICFeedParser
//
//  Created by Martin Hering on 16.07.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//


@interface ICCategory : NSObject

+ (id) category;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) ICCategory* parent;
@end
