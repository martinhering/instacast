//
//  VMViewController.m
//  SlidingViewController
//
//  Created by Martin Hering on 24.06.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import "VMSlidingViewController.h"
#import "ICSidebarPanGestureRecognizer.h"

@interface VMSlidingViewController () <UIGestureRecognizerDelegate>
@property (nonatomic) BOOL revealing;
@end

@implementation VMSlidingViewController {
    NSInteger                           _peekWidth;
    UIPushBehavior*                     _pushBehavior;
    UIAttachmentBehavior*               _attachmentBehavior;
    UIDynamicAnimator*                  _dynamicAnimator;
    ICSidebarPanGestureRecognizer*      _revealPanGestureRecognizer;
    UITapGestureRecognizer*             _revealTapGestureRecognizer;
    UIScreenEdgePanGestureRecognizer*   _showPanGestureRecognizer;
    UIImageView*                        _shadowImageView;
    UIBarButtonItem*                    _revealBarButtonItem;
    BOOL                                _didWillAppear;
}

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        _peekWidth = 40;
        
        _revealBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Sidebar Item"]
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(revealButtonTapped:)];
        
        _shadowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Sidebar Shadow"]];
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGRect b = self.view.bounds;
    _peekWidth = CGRectGetWidth(b)-280;
    
	
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    
    _revealPanGestureRecognizer = [[ICSidebarPanGestureRecognizer alloc] initWithTarget:self action:@selector(recognizeRevealPan:)];
    _revealPanGestureRecognizer.viewOfLocationCoordinateSystem = self.view;
    _revealPanGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:_revealPanGestureRecognizer];
    
    _revealTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(recognizeRevealTap:)];
    _revealTapGestureRecognizer.delegate = self;
    [_revealTapGestureRecognizer requireGestureRecognizerToFail:_revealPanGestureRecognizer];
    [self.view addGestureRecognizer:_revealTapGestureRecognizer];
}



- (UIViewController*) childViewControllerForStatusBarStyle {
    return (self.sidebarShown || self.revealing) ? self.sidebarViewController : self.contentViewController;
}

- (UIViewController*) childViewControllerForStatusBarHidden {
    //DebugLog(@"childViewControllerForStatusBarHidden %d: %@", self.revealed, (self.revealed) ? self.sidebarViewController : self.contentViewController);
    return (self.sidebarShown || self.revealing) ? self.sidebarViewController : self.contentViewController;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    CGRect b = self.view.bounds;
    _peekWidth = CGRectGetWidth(b)-280;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _didWillAppear = YES;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _didWillAppear = NO;
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (_didWillAppear) {
        self.contentViewController.view.frame = [self rectForContentControllerWhenShown:self.sidebarShown];
    }
}

#pragma mark -


- (CGRect) rectForContentControllerWhenShown:(BOOL)shown
{
    CGRect b = self.view.bounds;
    if (shown) {
        return CGRectMake(CGRectGetWidth(b)-_peekWidth, 0, CGRectGetWidth(b), CGRectGetHeight(b));
    }
    
    return CGRectMake(0, 0, CGRectGetWidth(b), CGRectGetHeight(b));
}

- (void) setNeedsContentControllerLayoutUpdateAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3f animations:^{
            self.contentViewController.view.frame = [self rectForContentControllerWhenShown:self.sidebarShown];
        }];
    }
    else {
        self.contentViewController.view.frame = [self rectForContentControllerWhenShown:self.sidebarShown];
    }
}

- (void) _showMenuViewController:(BOOL)show
{
    if (show) {
        [self addChildViewController:_sidebarViewController];
        if (_contentViewController.view) {
            [self.view insertSubview:_sidebarViewController.view belowSubview:_contentViewController.view];
        }
        else {
            [self.view addSubview:_sidebarViewController.view];
        }
        [_sidebarViewController didMoveToParentViewController:self];
    }
    else
    {
        [_sidebarViewController.view removeFromSuperview];
        [_sidebarViewController willMoveToParentViewController:nil];
        [_sidebarViewController removeFromParentViewController];
    }
}


- (void) setSidebarViewController:(UIViewController *)sidebarViewController
{
    if (self.sidebarShown) {
        [NSException raise:NSInternalInconsistencyException format:@"can not change menu view controller when visible"];
    }
    
    if (_sidebarViewController != sidebarViewController) {
        _sidebarViewController = sidebarViewController;
        
        
        [sidebarViewController.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        sidebarViewController.view.frame = self.view.frame;
    }
}

- (void) setContentViewController:(UIViewController *)contentViewController
{
    if (_contentViewController != contentViewController)
    {
        CGRect lastFrame = [self rectForContentControllerWhenShown:NO];
        if (_contentViewController.view) {
            lastFrame = _contentViewController.view.frame;
        }
        
        [_shadowImageView removeFromSuperview];
        
        [_contentViewController.view removeGestureRecognizer:_showPanGestureRecognizer];
        _showPanGestureRecognizer = nil;
        
        [_contentViewController.view removeFromSuperview];
        [_contentViewController willMoveToParentViewController:nil];
        [_contentViewController removeFromParentViewController];
        
        _contentViewController = contentViewController;
        
        if (contentViewController) {
            [contentViewController.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
            contentViewController.view.frame = [self rectForContentControllerWhenShown:NO];
            
            _shadowImageView.frame = CGRectMake(-5, 0, 5, CGRectGetHeight(contentViewController.view.frame));
            [contentViewController.view addSubview:_shadowImageView];
            
            [self addChildViewController:contentViewController];
            if (_sidebarViewController.view) {
                [self.view insertSubview:contentViewController.view aboveSubview:_sidebarViewController.view];
            } else {
                [self.view addSubview:contentViewController.view];
            }
            [contentViewController didMoveToParentViewController:self];
            [contentViewController.view setFrame:lastFrame];
            
            _showPanGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(recognizeShowPan:)];
            _showPanGestureRecognizer.edges = UIRectEdgeLeft;
            _showPanGestureRecognizer.delegate = self;
            _showPanGestureRecognizer.enabled = !self.sidebarShown;
            [self.contentViewController.view addGestureRecognizer:_showPanGestureRecognizer];

        }
        
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (void) revealButtonTapped:(id)sender
{
    [self setSidebarShown:YES animated:YES];
}

- (void) setSidebarShown:(BOOL)sidebarShown
{
    [self setSidebarShown:sidebarShown animated:NO];
}

- (void) setSidebarShown:(BOOL)sidebarShown animated:(BOOL)animated
{
    if (_sidebarShown != sidebarShown) {
        _sidebarShown = sidebarShown;
        
        [self cancelDynamics];

        if (sidebarShown)
        {
            [self _showMenuViewController:YES];
            
            [self willShowSidebar:sidebarShown animated:animated];
            
            self.contentViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
            self.contentViewController.view.userInteractionEnabled = NO;
            
            _showPanGestureRecognizer.enabled = NO;
            _revealPanGestureRecognizer.enabled = YES;
            _revealTapGestureRecognizer.enabled = YES;
            
            if (!animated)
            {
                [self setNeedsStatusBarAppearanceUpdate];
                self.contentViewController.view.frame = [self rectForContentControllerWhenShown:YES];
                self.sidebarViewController.view.transform = CGAffineTransformIdentity;
                
                [self didShowSidebar:sidebarShown animated:animated];
            }
            else
            {
                [UIView animateWithDuration:0.3 animations:^{
                    [self setNeedsStatusBarAppearanceUpdate];
                }];
                
                [UIView animateWithDuration:0.3f
                                      delay:0.0f
                     usingSpringWithDamping:1.0f
                      initialSpringVelocity:0.0f
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     self.contentViewController.view.frame = [self rectForContentControllerWhenShown:YES];
                                     self.sidebarViewController.view.transform = CGAffineTransformIdentity;
                                     
                                     [self animateAdditionalSidebarViewsDuringShow:sidebarShown];
                                 } completion:^(BOOL finished) {
                                     if (finished) {
                                         [self didShowSidebar:sidebarShown animated:animated];
                                     }
                                 }];
            }
        }
        else
        {
            [self willShowSidebar:sidebarShown animated:animated];
            
            // XXX Workaround status bar bug
            CGRect coveringRect = self.contentViewController.view.frame;
            self.contentViewController.view.frame = [self rectForContentControllerWhenShown:NO];
            
            self.contentViewController.view.frame = coveringRect;
            
            
            self.contentViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
            self.contentViewController.view.userInteractionEnabled = YES;
            
            _showPanGestureRecognizer.enabled = YES;
            _revealPanGestureRecognizer.enabled = NO;
            _revealTapGestureRecognizer.enabled = NO;

            
            if (!animated)
            {
                self.contentViewController.view.frame = [self rectForContentControllerWhenShown:NO];
                //self.sidebarViewController.view.transform = CGAffineTransformMakeScale(0.9f, 0.9f);
                
                [self _showMenuViewController:NO];
                [self didShowSidebar:sidebarShown animated:animated];
                [self setNeedsStatusBarAppearanceUpdate];
            }
            else
            {
                [UIView animateWithDuration:0.3f
                                      delay:0.0f
                     usingSpringWithDamping:1.0f
                      initialSpringVelocity:0.0f
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     self.contentViewController.view.frame = [self rectForContentControllerWhenShown:NO];
                                     //self.sidebarViewController.view.transform = CGAffineTransformMakeScale(0.9f, 0.9f);
                                     [self animateAdditionalSidebarViewsDuringShow:sidebarShown];
                                 } completion:^(BOOL finished) {
                                     if (finished) {
                                         [self _showMenuViewController:NO];
                                         [self didShowSidebar:sidebarShown animated:animated];
                                     }
                                     else {
                                         self.sidebarViewController.view.transform = CGAffineTransformIdentity;
                                     }
                                     
                                     [UIView animateWithDuration:0.3 animations:^{
                                         [self setNeedsStatusBarAppearanceUpdate];
                                     }];
                                 }];
            }
        }
        
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == _revealPanGestureRecognizer) {
        CGPoint firstLocation = ((ICSidebarPanGestureRecognizer*)gestureRecognizer).firstTouchLocation;
        return (self.sidebarShown && CGRectContainsPoint(self.contentViewController.view.frame, firstLocation));
    }

    else if (gestureRecognizer == _revealTapGestureRecognizer) {
        CGPoint location = [gestureRecognizer locationInView:self.contentViewController.view];
        return (self.sidebarShown && CGRectContainsPoint(self.contentViewController.view.bounds, location));
    }
    
    else if (gestureRecognizer == _showPanGestureRecognizer) {
        return !self.sidebarShown;
    }
    
    
    return YES;
}

- (void) recognizeRevealPan:(UIPanGestureRecognizer*)recognizer
{
    CGPoint translation = [recognizer translationInView:self.view];
    CGPoint velocity = [recognizer velocityInView:self.view];
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            if (!_pushBehavior) {
                _pushBehavior = [[UIPushBehavior alloc] initWithItems:@[self.contentViewController.view] mode:UIPushBehaviorModeContinuous];
                _pushBehavior.angle = 0;
                [_dynamicAnimator addBehavior:_pushBehavior];
            }
            if (!_attachmentBehavior) {
                CGPoint ap = [self.view convertPoint:self.contentViewController.view.center fromView:self.contentViewController.view];
                _attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.contentViewController.view attachedToAnchor:ap];
                _attachmentBehavior.frequency = 4.0;
                _attachmentBehavior.damping = 1.0;
                [_dynamicAnimator addBehavior:_attachmentBehavior];
            }
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            if (_pushBehavior)
            {
                _pushBehavior.magnitude = translation.x*80;

                if (-translation.x > 320*0.7f) {
                    [self setSidebarShown:NO animated:YES];
                }
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            if (velocity.x < -500) {
                [self setSidebarShown:NO animated:YES];
            }
            else {
                _pushBehavior.magnitude = 0;
                
                [self perform:^(id sender) {
                    [self cancelDynamics];
                } afterDelay:0.5f];
            }
            self.revealing = NO;
            break;
        }
        case UIGestureRecognizerStateCancelled:
        {
            _pushBehavior.magnitude = 0;
            break;
        }
        default:
            break;
    }
}

- (void) setRevealing:(BOOL)revealing
{
    if (_revealing != revealing) {
        _revealing = revealing;
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (void) recognizeRevealTap:(UIPanGestureRecognizer*)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self setSidebarShown:NO animated:YES];
    }
}

- (void) recognizeShowPan:(UIScreenEdgePanGestureRecognizer*)recognizer
{
    CGPoint translation = [recognizer translationInView:self.view];
    CGPoint velocity = [recognizer velocityInView:self.view];
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            self.revealing = YES;
            self.sidebarViewController.view.transform = CGAffineTransformIdentity;
            [self _showMenuViewController:YES];
            
            if (!_pushBehavior) {
                _pushBehavior = [[UIPushBehavior alloc] initWithItems:@[self.contentViewController.view] mode:UIPushBehaviorModeContinuous];
                _pushBehavior.angle = 0;
                [_dynamicAnimator addBehavior:_pushBehavior];
            }
            if (!_attachmentBehavior) {
                CGPoint ap = [self.view convertPoint:self.contentViewController.view.center fromView:self.contentViewController.view];
                _attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.contentViewController.view attachedToAnchor:ap];
                _attachmentBehavior.frequency = 4.0;
                _attachmentBehavior.damping = 0.5;
                [_dynamicAnimator addBehavior:_attachmentBehavior];
            }
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            if (_pushBehavior)
            {
                _pushBehavior.magnitude = translation.x*80;
                
                if (translation.x > 320*0.7f) {
                    [self setSidebarShown:YES animated:YES];
                }
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            if (velocity.x > 500) {
                [self setSidebarShown:YES animated:YES];
            }
            else {
                _pushBehavior.magnitude = 0;
                
                [self perform:^(id sender) {
                    [self cancelDynamics];
                    [self _showMenuViewController:NO];
                } afterDelay:0.5f];
            }
            self.revealing = NO;
            break;
        }
        case UIGestureRecognizerStateCancelled:
        {
            _pushBehavior.magnitude = 0;
            self.revealing = NO
            ;
            break;
        }
        default:
            break;
    }
}

- (void) cancelDynamics
{
    [_dynamicAnimator removeBehavior:_pushBehavior];
    _pushBehavior = nil;
    [_dynamicAnimator removeBehavior:_attachmentBehavior];
    _attachmentBehavior = nil;
}

- (UIBarButtonItem*) sidebarMenuItem
{
    return [[UIBarButtonItem alloc] initWithImage:_revealBarButtonItem.image
                                            style:UIBarButtonItemStylePlain
                                           target:_revealBarButtonItem.target
                                           action:_revealBarButtonItem.action];
}


- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
//    if ( event.subtype == UIEventSubtypeMotionShake ) {
//        [ICAppearanceManager sharedManager].nightMode = ![ICAppearanceManager sharedManager].nightMode;
//	}
}

#pragma mark -

- (void) willShowSidebar:(BOOL)reveal animated:(BOOL)animated
{
    
}

- (void) didShowSidebar:(BOOL)reveal animated:(BOOL)animated
{
    
}

- (void) animateAdditionalSidebarViewsDuringShow:(BOOL)reveal
{
    
}
@end
