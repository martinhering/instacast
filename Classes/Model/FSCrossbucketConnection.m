//
//  FSCrossbucketConnection.m
//  Instacast
//
//  Created by Martin Hering on 10/04/14.
//
//

#import "FSCrossbucketConnection.h"

@implementation FSCrossbucketConnection

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [self init]))
    {
        _bucket  = [decoder decodeIntegerForKey:@"bucket"];
        _region = [decoder decodeObjectForKey:@"region"];
        _uuid = [decoder decodeObjectForKey:@"uuid"];
        _accessToken = [decoder decodeObjectForKey:@"accessToken"];
        _name = [decoder decodeObjectForKey:@"name"];
        _username = [decoder decodeObjectForKey:@"username"];
        _password = [decoder decodeObjectForKey:@"password"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
}

@end
