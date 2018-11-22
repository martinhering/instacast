//
//  UIManager.m
//  Instacast
//
//  Created by Martin Hering on 21.08.12.
//
//

#import "UIManager.h"

#if TARGET_OS_IPHONE
#import "InstacastAppDelegate.h"

#else
#import "AudioSession_OSX.h"
#import "ICViewFilterSet.h"
#import "ICActivityManager.h"
#endif

@interface UIManager ()
@property (nonatomic, strong) NSMutableArray* mutableViewFilterSets;
@property (nonatomic, strong, readwrite) NSDictionary* predefinedViewFilters;
#if TARGET_OS_IPHONE
#else
@property (nonatomic, strong) ICActivity* activity;
@property (nonatomic, strong) NSTimer* trialTimer;
#endif
@end

@implementation UIManager

+ (UIManager *)sharedManager
{
    static dispatch_once_t once;
    static UIManager *sharedUIManager;
    dispatch_once(&once, ^ { sharedUIManager = [[UIManager alloc] init]; });
    return sharedUIManager;
}

- (id) init
{
    if ((self = [super init]))
    {
#if !TARGET_OS_IPHONE
        NSString* predefinedViewFiltersFile = [[NSBundle mainBundle] pathForResource:@"PredefinedViewFilters" ofType:@"plist"];
        _predefinedViewFilters = [NSDictionary dictionaryWithContentsOfFile:predefinedViewFiltersFile];
        [self _restoreCustomFilterSets];
#endif

#if !TARGET_OS_IPHONE
#ifndef APP_STORE
        _trialTimer = [NSTimer scheduledTimerWithTimeInterval:600 target:self selector:@selector(heartBeat) userInfo:nil repeats:NO];
#endif
#endif
    }
    
    return self;
}


#pragma mark -

#if !TARGET_OS_IPHONE
#ifndef APP_STORE
- (void) heartBeat
{
    InitTrial();
}
#endif
    
- (NSArray*) viewFilterSets
{
    return [self.mutableViewFilterSets copy];
}

- (NSString*) _pathToCustomFilterSetsPlist
{
    return [[DatabaseManager pathToDocuments] stringByAppendingPathComponent:@"CustomViewFilterSets.plist"];
}

- (void) _restoreCustomFilterSets
{
    self.mutableViewFilterSets = [NSMutableArray array];
    
    NSArray* plist = [[NSArray alloc] initWithContentsOfFile:[self _pathToCustomFilterSetsPlist]];
    
    for(NSDictionary* set in plist) {
        NSString* name = set[@"name"];
        NSData* data = set[@"data"];
        
        ICViewFilterSet* filterSet = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        filterSet.name = name;
        
        [self willChangeValueForKey:@"viewFilterSets"];
        [self.mutableViewFilterSets addObject:filterSet];
        [self didChangeValueForKey:@"viewFilterSets"];
    }
}

- (void) _saveCustomFilterSets
{
    NSMutableArray* plist = [NSMutableArray array];
    
    for(ICViewFilterSet* filterSet in self.viewFilterSets)
    {
        NSData* data = [NSKeyedArchiver archivedDataWithRootObject:filterSet];
        NSDictionary* dict = @{@"data" : data, @"name" : filterSet.name};
        
        [plist addObject:dict];
    }
    
    [plist writeToFile:[self _pathToCustomFilterSetsPlist] atomically:YES];
}

- (void) addViewFilterSet:(ICViewFilterSet*)filterSet
{
    [self willChangeValueForKey:@"viewFilterSets"];
    [self.mutableViewFilterSets addObject:filterSet];
    [self didChangeValueForKey:@"viewFilterSets"];
    
    [self _saveCustomFilterSets];
}

- (void) removeViewFilterSet:(ICViewFilterSet*)filterSet
{
    [self willChangeValueForKey:@"viewFilterSets"];
    [self.mutableViewFilterSets removeObject:filterSet];
    [self didChangeValueForKey:@"viewFilterSets"];
    
    [self _saveCustomFilterSets];
}

- (void) replaceAllViewFilterSetsWithObjectsInArray:(NSArray*)array
{
    [self willChangeValueForKey:@"viewFilterSets"];
    [self.mutableViewFilterSets removeAllObjects];
    [self.mutableViewFilterSets addObjectsFromArray:array];
    [self didChangeValueForKey:@"viewFilterSets"];
    
    [self _saveCustomFilterSets];
}

#endif


@end
