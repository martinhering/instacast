//
//  UIManager.h
//  Instacast
//
//  Created by Martin Hering on 21.08.12.
//
//

#import <Foundation/Foundation.h>

@class ICViewFilterSet;
@class CDEpisode;

@interface UIManager : NSObject

+ (UIManager *)sharedManager;

#if !TARGET_OS_IPHONE
#ifndef APP_STORE
- (void) heartBeat;
#endif
#endif

#if TARGET_OS_IPHONE
@property (nonatomic, strong) UIViewController* mainViewController;
@property (nonatomic, strong) UIViewController* currentMainSplitViewController;
#endif

#if !TARGET_OS_IPHONE
@property (nonatomic, readonly) NSArray* viewFilterSets;
@property (nonatomic, strong, readonly) NSDictionary* predefinedViewFilters;

- (void) addViewFilterSet:(ICViewFilterSet*)filterSet;
- (void) removeViewFilterSet:(ICViewFilterSet*)filterSet;

- (void) replaceAllViewFilterSetsWithObjectsInArray:(NSArray*)array;
#endif
@end
