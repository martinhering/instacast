//
//  NSObject+VMFoundation.m
//  Instacast
//
//  Created by Martin Hering on 07.01.13.
//
//

#import <objc/runtime.h>

#import "NSObject+VMFoundation.h"
#import "NSString+VMFoundation.h"

@implementation NSObject (VMPerform)

- (void) coalescedPerformSelector:(SEL)sel
{
    [self coalescedPerformSelector:sel afterDelay:0.0];
}

- (void) coalescedPerformSelector:(SEL)sel afterDelay:(NSTimeInterval)delay
{
    [self coalescedPerformSelector:sel object:nil afterDelay:delay];
}

- (void) coalescedPerformSelector:(SEL)sel object:(id)object afterDelay:(NSTimeInterval)delay
{
    // Cancel any previous perform requests to keep calls from piling up.
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:sel object:object];
    
    // Schedule the call, it will hit during the next turn of the current run loop
    [self performSelector:sel withObject:object afterDelay:delay];
}

@end

#pragma mark -

@implementation NSObject (VMAssociatedObjects)

static char staticAccociatedObjectKey;

- (void)setAssociatedObject:(id)value forKey:(NSString*)key
{
    NSMutableDictionary* dict;
    @synchronized(self) {
        dict = objc_getAssociatedObject(self, &staticAccociatedObjectKey);
        if (!dict) {
            dict = [[NSMutableDictionary alloc] init];
            objc_setAssociatedObject(self, &staticAccociatedObjectKey, dict, OBJC_ASSOCIATION_RETAIN);
        }
    }
    if (value) {
        [dict setObject:value forKey:key];
    }
    else {
        [dict removeObjectForKey:key];
    }
}

- (void)setAssociatedObjectCopy:(id)value forKey:(NSString*)key
{
    value = [value copy];
    [self setAssociatedObject:value forKey:key];
}


- (id)associatedObjectForKey:(NSString *)key {
    
    NSMutableDictionary* dict = objc_getAssociatedObject(self, &staticAccociatedObjectKey);
    return [dict objectForKey:key];
}


- (NSMutableDictionary *)associatedObjects
{
    return objc_getAssociatedObject(self, &staticAccociatedObjectKey);
}

@end


#pragma mark -

@implementation NSObject (VMRuntimeInspection)

- (NSArray*) arrayFromMethodList
{
    return [[self class] arrayFromMethodList];
}

+ (NSArray*) arrayFromMethodList
{
    NSMutableArray * result = [NSMutableArray array];
    unsigned int methodCount = 0;
    Method *mlist = class_copyMethodList([self class], &methodCount);
    if (mlist != NULL)
    {
        int i;
        for (i = 0; i < methodCount; ++i)
        {
            NSString * aName = NSStringFromSelector(method_getName(mlist[i]));
            [result addObject:aName];
        }
    }
    
    return result;
}

+ (BOOL) implementsSelector:(SEL)selector
{
    return [[self arrayFromMethodList] containsObject:NSStringFromSelector(selector)];
}

+ (BOOL) implementsClassSelector:(SEL)selector {
    Method method = class_getClassMethod([self class], selector);
    return (method != nil);
}

+ (void)swizzleSelector:(SEL)oldSel withSelector:(SEL)newSel
{
    Class class = [self class];
    Method oldMethod = class_getInstanceMethod(class, oldSel);
    Method newMethod = class_getInstanceMethod(class, newSel);
    method_exchangeImplementations(oldMethod, newMethod);
}

@end


#pragma mark -

static NSString* kAssociatedObjectBlockTimers = @"object_block_timers";

@implementation NSObject (VMAsyncBlocks)

- (NSString*) perform:(void (^)(id sender))block afterDelay:(NSTimeInterval)delay
{
    NSMutableDictionary* timers = [self associatedObjectForKey:kAssociatedObjectBlockTimers];
    
	if (!timers) {
		timers = [[NSMutableDictionary alloc] init];
        [self setAssociatedObject:timers forKey:kAssociatedObjectBlockTimers];
	}
	
    NSString* identifier = [NSString uuid];
	
	dispatch_queue_t queue = dispatch_get_main_queue();
	dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
													 queue);
	
	dispatch_source_set_timer(timer,
							  dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC),
							  DISPATCH_TIME_FOREVER, 0);
	
	dispatch_source_set_event_handler(timer, ^{
		block(self);
		dispatch_source_cancel(timer);
		[timers removeObjectForKey:identifier];
	});

    [timers setObject:[NSValue valueWithPointer:(__bridge const void *)(timer)] forKey:identifier];
    dispatch_resume(timer);
    
	return identifier;
}

- (void) cancelPerformBlockWithIdentifier:(NSString*)identifier
{
    NSMutableDictionary* timers = [self associatedObjectForKey:kAssociatedObjectBlockTimers];
    
	id obj = [timers objectForKey:identifier];
    if (obj) {
        dispatch_source_t timer = [obj pointerValue];
        dispatch_source_cancel(timer);
        [timers removeObjectForKey:identifier];
    }
}

- (void) cancelPerformBlocks
{
    NSMutableDictionary* timers = [self associatedObjectForKey:kAssociatedObjectBlockTimers];
    
	[[timers copy] enumerateKeysAndObjectsUsingBlock:^(id identifier, id obj, BOOL *stop) {
		dispatch_source_t timer = [obj pointerValue];
		dispatch_source_cancel(timer);
		[timers removeObjectForKey:identifier];
	}];
}

@end


#pragma mark -

@interface VMObserver : NSObject
@property (nonatomic, weak) id observee;
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, copy) VMObservationBlock task;
@property (nonatomic, weak) NSThread* thread;
+ (VMObserver *)trampolineWithObservingObject:(id)obj keyPath:(NSString *)newKeyPath thread:(NSThread*)thread task:(VMObservationBlock)newTask;
@end

static char *kBKBlockObservationContext = "BKBlockObservationContext";

@implementation VMObserver

+ (VMObserver *)trampolineWithObservingObject:(id)obj keyPath:(NSString *)newKeyPath thread:(NSThread*)thread task:(VMObservationBlock)newTask {
    VMObserver *instance = [VMObserver new];
    instance.task = newTask;
    instance.keyPath = newKeyPath;
    instance.observee = obj;
    instance.thread = thread;
    return instance;
}

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    VMObservationBlock block = self.task;
    if (self.task && context == kBKBlockObservationContext)
        block(object, change);
}

- (void) setObservee:(id)observee {
    if (_observee != observee) {

        [_observee removeObserver:self forKeyPath:self.keyPath];

        _observee = observee;

        if (observee) {
            [observee addObserver:self forKeyPath:self.keyPath options:0 context:kBKBlockObservationContext];
        }
    }
}

- (void)dealloc {
    self.observee = nil;
    self.task = nil;
    self.keyPath = nil;
}
@end

static NSString *kObserverBlocksKey = @"BKKeyValueObservers";


@implementation NSObject (VMBlockObservation)

- (NSDictionary*) blockObservationInfo {
    return [[self associatedObjectForKey:kObserverBlocksKey] copy];
}

- (NSString *)addObserverForKeyPath:(NSString *)keyPath task:(VMObservationBlock)task {
    NSString *token = [[NSProcessInfo processInfo] globallyUniqueString];
    [self addObserverForKeyPath:keyPath identifier:token task:task];
    return token;
}

- (void)addObserverForKeyPath:(NSString *)keyPath identifier:(NSString *)identifier task:(VMObservationBlock)task
{
    NSString *token = [NSString stringWithFormat:@"%@_%@", keyPath, identifier];
    
    NSMutableDictionary *dict = [self associatedObjectForKey:kObserverBlocksKey];
    if (!dict) {
        dict = [NSMutableDictionary dictionary];
        [self setAssociatedObject:dict forKey:kObserverBlocksKey];
    }
    
    [dict setObject:[VMObserver trampolineWithObservingObject:self keyPath:keyPath thread:[NSThread currentThread] task:task] forKey:token];
}

- (void)removeAllBlockObservers
{
    NSMutableDictionary *dict = [self associatedObjectForKey:kObserverBlocksKey];
    for(NSString* token in dict) {
        VMObserver *trampoline = [dict objectForKey:token];
        trampoline.task = nil;
        if ([NSThread currentThread] != trampoline.thread) {
            NSLog(@"***threading mismatch");
        }
    }
    if (dict) {
        [self setAssociatedObject:nil forKey:kObserverBlocksKey];
    }
}

#pragma mark -

- (void)addTaskObserver:(id)observer forKeyPath:(NSString *)keyPath task:(VMObservationBlock)task
{
    NSString* identifier = [NSString stringWithFormat:@"%@_%lx", NSStringFromClass([observer class]),(long)observer];
    [self addObserverForKeyPath:keyPath identifier:identifier task:task];
}

- (void)removeObserverForKeyPath:(NSString *)keyPath identifier:(NSString *)identifier
{
    NSString *token = [NSString stringWithFormat:@"%@_%@", keyPath, identifier];
    NSMutableDictionary *dict = [self associatedObjectForKey:kObserverBlocksKey];
    VMObserver *trampoline = [dict objectForKey:token];
    
    trampoline.task = nil;
    trampoline.observee = nil;
    
    if (!trampoline || ![trampoline.keyPath isEqualToString:keyPath]) {
        return;
    }

    if ([NSThread currentThread] != trampoline.thread) {
        NSLog(@"***threading mismatch");
    }

    [dict removeObjectForKey:token];
    
    if (!dict.count)
        [self setAssociatedObject:nil forKey:kObserverBlocksKey];
}

- (void)removeTaskObserver:(id)observer forKeyPath:(NSString *)keyPath
{
    NSString* identifier = [NSString stringWithFormat:@"%@_%lx", NSStringFromClass([observer class]),(long)observer];
    [self removeObserverForKeyPath:keyPath identifier:identifier];
}

- (void)addTaskObserver:(id)observer forKeyPathes:(NSArray<NSString*> *)keyPathes task:(VMObservationBlock)task
{
    for(NSString* keyPath in keyPathes) {
        [self addTaskObserver:observer forKeyPath:keyPath task:task];
    }

}
- (void)removeTaskObserver:(id)observer forKeyPathes:(NSArray<NSString*> *)keyPathes
{
    for(NSString* keyPath in keyPathes) {
        [self removeTaskObserver:observer forKeyPath:keyPath];
    }
}

@end

#if (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))

@implementation NSObject (VMBindings)

-(void) propagateValue:(id)value forBinding:(NSString*)binding;
{
    NSParameterAssert(binding != nil);

    //WARNING: bindingInfo contains NSNull, so it must be accounted for
    NSDictionary* bindingInfo = [self infoForBinding:binding];
    if(!bindingInfo)
        return; //there is no binding

    //apply the value transformer, if one has been set
    NSDictionary* bindingOptions = [bindingInfo objectForKey:NSOptionsKey];
    if(bindingOptions){
        NSValueTransformer* transformer = [bindingOptions valueForKey:NSValueTransformerBindingOption];
        if(!transformer || (id)transformer == [NSNull null]){
            NSString* transformerName = [bindingOptions valueForKey:NSValueTransformerNameBindingOption];
            if(transformerName && (id)transformerName != [NSNull null]){
                transformer = [NSValueTransformer valueTransformerForName:transformerName];
            }
        }

        if(transformer && (id)transformer != [NSNull null]){
            if([[transformer class] allowsReverseTransformation]){
                value = [transformer reverseTransformedValue:value];
            } else {
                NSLog(@"WARNING: binding \"%@\" has value transformer, but it doesn't allow reverse transformations in %s", binding, __PRETTY_FUNCTION__);
            }
        }
    }

    id boundObject = [bindingInfo objectForKey:NSObservedObjectKey];
    if(!boundObject || boundObject == [NSNull null]){
        NSLog(@"ERROR: NSObservedObjectKey was nil for binding \"%@\" in %s", binding, __PRETTY_FUNCTION__);
        return;
    }

    NSString* boundKeyPath = [bindingInfo objectForKey:NSObservedKeyPathKey];
    if(!boundKeyPath || (id)boundKeyPath == [NSNull null]){
        NSLog(@"ERROR: NSObservedKeyPathKey was nil for binding \"%@\" in %s", binding, __PRETTY_FUNCTION__);
        return;
    }

    [boundObject setValue:value forKeyPath:boundKeyPath];
}

@end

#endif
