//
//  NSObject+VMFoundation.h
//  Instacast
//
//  Created by Martin Hering on 07.01.13.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (VMPerformCalescing)
- (void) coalescedPerformSelector:(SEL)sel;
- (void) coalescedPerformSelector:(SEL)sel afterDelay:(NSTimeInterval)delay;
- (void) coalescedPerformSelector:(SEL)sel object:(id)object afterDelay:(NSTimeInterval)delay;
@end

#pragma mark -

@interface NSObject (VMAssociatedObjects)
- (void)setAssociatedObject:(id)value forKey:(NSString *)key;
- (void)setAssociatedObjectCopy:(id)value forKey:(NSString*)key;
- (id)associatedObjectForKey:(NSString *)key;
- (NSMutableDictionary *)associatedObjects;
@end

#pragma mark -

@interface NSObject (VMRuntimeInspection)
- (NSArray*) arrayFromMethodList;
+ (NSArray*) arrayFromMethodList;
+ (BOOL) implementsSelector:(SEL)selector;
+ (BOOL) implementsClassSelector:(SEL)selector;
+ (void)swizzleSelector:(SEL)oldSel withSelector:(SEL)newSel;
@end

#pragma mark -

@interface NSObject (VMAsyncBlocks)
- (NSString*) perform:(void (^)(id sender))block afterDelay:(NSTimeInterval)delay;
- (void) cancelPerformBlockWithIdentifier:(NSString*)identifier;
- (void) cancelPerformBlocks;
@end

#pragma mark -

typedef void(^VMObservationBlock)(id obj, NSDictionary *change);

@interface NSObject (VMBlockObservation)
/*
- (NSString *)addObserverForKeyPath:(NSString *)keyPath task:(VMObservationBlock)task;
- (void)addObserverForKeyPath:(NSString *)keyPath identifier:(NSString *)identifier task:(VMObservationBlock)task;
- (void)removeObserverForKeyPath:(NSString *)inKeyPath identifier:(NSString *)token;
*/

- (void)addTaskObserver:(id)observer forKeyPath:(NSString *)keyPath task:(VMObservationBlock)task;
- (void)removeTaskObserver:(id)observer forKeyPath:(NSString *)keyPath;

- (void)addTaskObserver:(id)observer forKeyPathes:(NSArray<NSString*> *)keyPathes task:(VMObservationBlock)task;
- (void)removeTaskObserver:(id)observer forKeyPathes:(NSArray<NSString*> *)keyPathes;

- (void)removeAllBlockObservers;
@property (readonly) NSDictionary* blockObservationInfo;
@end

#if (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))
@interface NSObject (VMBindings)
-(void) propagateValue:(id)value forBinding:(NSString*)binding;
@end
#endif
