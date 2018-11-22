//
//  FSCrossbucketConnection.h
//  Instacast
//
//  Created by Martin Hering on 10/04/14.
//
//

#import <Foundation/Foundation.h>

@interface FSCrossbucketConnection : NSObject <NSCoding>

@property (nonatomic) NSInteger bucket;
@property (nonatomic, strong) NSString* region;
@property (nonatomic, strong) NSString* uuid;
@property (nonatomic, strong) NSString* accessToken;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* username;
@property (nonatomic, strong) NSString* password;

@end
