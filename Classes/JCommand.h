//
//  JCommand.h
//  Instacast
//
//  Created by Martin Hering on 22.12.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* API1PopularAudioPodcastsCommand;
extern NSString* API1PopularVideoPodcastsCommand;
extern NSString* API1EnhancedAudioPodcastsCommand;
extern NSString* API1EnhancedVideoPodcastsCommand;
extern NSString* API1EnhancedPodcastsCommand;
extern NSString* API1CategoriesCommand;
extern NSString* API1AuthorsCommand;
extern NSString* API1AuthorPodcastsCommand;

@interface JCommand : VMHTTPOperation {
@protected
	NSURLConnection*	_connection;
	NSMutableData*		_data;
}

+ (NSString*) baseForCommand:(NSString*)command;

- (id) initWithCommand:(NSString*)command arguments:(NSDictionary*)arguments;
- (id) initWithCommand:(NSString*)command arguments:(NSDictionary*)arguments delegate:(id)delegate;

@property (nonatomic, readonly, weak) id delegate;
@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, readonly, strong) NSDictionary* arguments;
@property (nonatomic, copy) void (^didReturnWithObjectBlock)(id object);
@property (nonatomic, copy) void (^didReturnWithErrorBlock)(NSError* error);

@end


@interface NSObject (JCommandDelegate)
- (void) command:(JCommand*)command didReturnWithObject:(id)object;
- (void) command:(JCommand*)command didReturnWithError:(NSError*)error;
@end