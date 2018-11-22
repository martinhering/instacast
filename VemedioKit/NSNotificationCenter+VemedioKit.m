//
//  NSNotificationCenter+VemedioKit.m
//  VMFoundation
//
//  Created by Martin Hering on 15.09.11.
//  Copyright (c) 2011 Vemedio. All rights reserved.
//

#import "NSNotificationCenter+VemedioKit.h"
#import "NSObject+VMFoundation.h"

@interface NSNotificationCenterObserver : NSObject
@property (nonatomic, strong) NSNotificationCenter* center;
@property (nonatomic, copy) VMNotificationBlock handler;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) id object;

- (id) initWithHandler:(VMNotificationBlock)handler center:(NSNotificationCenter*)center name:(NSString*)name object:(id)object;
- (void) invalidate;

@end

@implementation NSNotificationCenterObserver

- (id) initWithHandler:(VMNotificationBlock)aHandler center:(NSNotificationCenter*)center name:(NSString*)aName object:(id)anObject
{
    if ((self = [super init]))
    {
        _center = center;
        _handler = aHandler;
        _name = aName;
        _object = anObject;
        
        [_center addObserver:self selector:@selector(notification:) name:aName object:anObject];
    }
    
    return self;
}
- (void) invalidate
{
    [self.center removeObserver:self name:self.name object:self.object];
    self.handler = nil;
}

- (void) notification:(NSNotification*)aNotification
{
    if (self.handler) {
        self.handler(aNotification);
    }
}

@end


@implementation NSNotificationCenter (VemedioKit)

static NSString *kNotificationCenterBlockDictionaryKey = @"VMNotificationCenterBlockHandlers";

- (NSMutableDictionary *)blocks {
    NSMutableDictionary *blocks = [self associatedObjectForKey:kNotificationCenterBlockDictionaryKey];
    if (!blocks) {
        blocks = [NSMutableDictionary dictionary];
        [self setAssociatedObject:blocks forKey:kNotificationCenterBlockDictionaryKey];
    }
    return blocks;
}

#pragma mark -

- (void) addObserver:(id)observer name:(NSString*)name object:(id)object handler:(VMNotificationBlock)handler
{
    NSString* key = [NSString stringWithFormat:@"<%@:%lx>_%@_%lu", NSStringFromClass([observer class]),(unsigned long)observer, name, (unsigned long)[object hash]];
    //DebugLog(@"add notification observer: %@, stack: %@", key, [NSThread callStackSymbols]);
    //DebugLog(@"add notification observer: %@", key);
    
    if (![self.blocks objectForKey:key]) {
        NSNotificationCenterObserver* proxy = [[NSNotificationCenterObserver alloc] initWithHandler:handler center:self name:name object:object];
        [self.blocks setObject:proxy forKey:key];
    } else {
        ErrLog(@"Observer already added: %@", key);
    }
}

- (void) removeHandlerForObserver:(id)observer name:(NSString *)name object:(id)object
{
    NSString* key = [NSString stringWithFormat:@"<%@:%lx>_%@_%lu", NSStringFromClass([observer class]),(unsigned long)observer, name, (unsigned long)[object hash]];
    
    NSNotificationCenterObserver* proxy = [self.blocks objectForKey:key];
    [proxy invalidate];
    
    [self.blocks removeObjectForKey:key];
}

- (void) addObserver:(id)observer name:(NSString*)name object:(id)object seed:(NSString*)seed handler:(VMNotificationBlock)handler
{
    NSString* key = [NSString stringWithFormat:@"<%@(%@):%lx>_%@_%ld", NSStringFromClass([observer class]), seed, (unsigned long)observer, name, (long)[object hash]];
    if (![self.blocks objectForKey:key]) {
        NSNotificationCenterObserver* proxy = [[NSNotificationCenterObserver alloc] initWithHandler:handler center:self name:name object:object];
        [self.blocks setObject:proxy forKey:key];
    } else {
        ErrLog(@"Observer already added: %@", key);
    }
}

- (void) removeHandlerForObserver:(id)observer name:(NSString *)name object:(id)object seed:(NSString*)seed
{
    NSString* key = [NSString stringWithFormat:@"<%@(%@):%lx>_%@_%ld", NSStringFromClass([observer class]), seed, (unsigned long)observer, name, (long)[object hash]];
    
    NSNotificationCenterObserver* proxy = [self.blocks objectForKey:key];
    [proxy invalidate];
    
    [self.blocks removeObjectForKey:key];
}


@end
