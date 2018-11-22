//
//  UIViewController+PresentationEnqueuing.m
//  Instacast
//
//  Created by Martin Hering on 19.09.13.
//
//

#import "UIViewController+PresentationEnqueuing.h"

@implementation UIViewController (PresentationEnqueuing)


- (NSMutableOrderedSet*) presentationQueue
{
    NSMutableOrderedSet* queue = [self associatedObjectForKey:@"presentationQueue"];
    if (!queue) {
        queue = [[NSMutableOrderedSet alloc] init];
        [self setAssociatedObject:queue forKey:@"presentationQueue"];
    }
    return queue;
}


- (void) enqueuePresentationOfViewController:(UIViewController*)viewController animated:(BOOL)animated completion:(void (^)())completion
{
    NSMutableDictionary* entry = [@{ @"viewController" : viewController, @"animated" : @(animated)} mutableCopy];
    if (completion) {
        [entry setObject:[completion copy] forKey:@"completion"];
    }
    [[self presentationQueue] addObject:entry];
    
    [self coalescedPerformSelector:@selector(_presentFromQueue)];
}

- (void) _presentFromQueue
{
    if (self.presentedViewController) {
        return;
    }
    
    NSDictionary* entry = [[self presentationQueue] firstObject];
    if (!entry) {
        return;
    }
    
    UIViewController* viewController = entry[@"viewController"];
    BOOL animated = [entry[@"animated"] boolValue];
    void (^completion)() = entry[@"completion"];
    
    [self presentViewController:viewController animated:animated completion:completion];
    
    [[self presentationQueue] removeObject:entry];
}

- (void) presentNextViewController
{
    [self _presentFromQueue];
}

- (void) clearViewControllerPresentationQueue
{
    [[self presentationQueue] removeAllObjects];
}

@end
