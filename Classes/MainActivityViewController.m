//
//  MainActivityViewController.m
//  Instacast
//
//  Created by Martin Hering on 25.07.14.
//
//

#import "MainActivityViewController.h"
#import "PlaybackViewController.h"
#import "ICNowPlayingActivityViewController.h"
#import "ICNowPlayingActivityControl.h"

@interface MainActivityViewController ()
@property (nonatomic, strong) ICNowPlayingActivityViewController* nowPlayingController;

@property (nonatomic, readwrite) BOOL visible;
@end

@implementation MainActivityViewController {
    BOOL _observing;
}

+ (instancetype) viewController
{
    return [[self alloc] initWithNibName:nil bundle:nil];
}

- (void) dealloc
{
    [self _setObserving:NO];
}

- (void) _setObserving:(BOOL)observing
{
    if (observing && !_observing)
    {        
//        [self addTaskObserver:self forKeyPath:@"nowPlayingController.visible" task:^(id obj, NSDictionary *change) {
//            [weakSelf _updateScrollViewContentAnimated:YES];
//        }];
        
        _observing = YES;
    }
    else if (!observing && _observing) {
//        [self removeTaskObserver:self forKeyPath:@"nowPlayingController.visible"];
        
        _observing = NO;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGRect b = self.view.bounds;
    
    self.nowPlayingController = [[ICNowPlayingActivityViewController alloc] initWithNibName:nil bundle:nil];
    self.nowPlayingController.view.frame = b;
    self.nowPlayingController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addChildViewController:self.nowPlayingController];
    [self.view addSubview:self.nowPlayingController.view];
    [self.nowPlayingController didMoveToParentViewController:self];

    [self _setObserving:YES];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //[self _updateScrollViewContentAnimated:NO];
}

- (UIControl*) nowPlayingControl {
    return (UIControl*)self.nowPlayingController.nowPlayingControl;
}


+ (NSSet*) keyPathsForValuesAffectingVisible {
    return [[NSSet alloc] initWithObjects:@"nowPlayingController.visible", nil];
}


- (BOOL) visible {
    return (self.nowPlayingController.visible);
}

@end
