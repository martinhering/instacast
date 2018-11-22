//
//  ICMedia.h
//  ICFeedParser
//
//  Created by Martin Hering on 16.07.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//


@interface ICMedia : NSObject

+ (id) media;

@property (nonatomic, strong) NSURL* fileURL;
@property (nonatomic) unsigned long long byteSize;
@property (nonatomic, strong) NSString* mimeType;

@end
