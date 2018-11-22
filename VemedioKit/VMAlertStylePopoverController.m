//
//  AlertStylePopoverController.m
//  Instacast
//
//  Created by Martin Hering on 03.07.13.
//
//

#import "VMAlertStylePopoverController.h"
#import "VMAlertStylePopoverAnimator.h"

@interface VMAlertStylePopoverController () <UIViewControllerTransitioningDelegate>
@property (nonatomic, strong, readwrite) UIViewController* contentController;
@property (nonatomic, strong, readwrite) UIView* backdropView;
@property (nonatomic, strong) UITapGestureRecognizer* backdropGestureRecognizer;
@end

@implementation VMAlertStylePopoverController

@dynamic cornerRadius;

+ (instancetype) controllerWithContentController:(UIViewController*)contentController;
{
    VMAlertStylePopoverController* c = [[self alloc] initWithNibName:nil bundle:nil];
    c.contentController = contentController;
    return c;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.transitioningDelegate = self;
        self.modalPresentationStyle = UIModalPresentationCustom;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _backdropView = [[UIView alloc] initWithFrame:self.view.bounds];
    _backdropView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _backdropView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
    _backdropView.opaque = NO;
    if (self.enableBackgroundDismiss) {
        [_backdropView addGestureRecognizer:self.backdropGestureRecognizer];
    }
    [self.view addSubview:_backdropView];

    UIInterpolatingMotionEffect *xAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    xAxis.minimumRelativeValue = [NSNumber numberWithFloat:-15.0];
    xAxis.maximumRelativeValue = [NSNumber numberWithFloat:15.0];
    
    UIInterpolatingMotionEffect *yAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    yAxis.minimumRelativeValue = [NSNumber numberWithFloat:-15.0];
    yAxis.maximumRelativeValue = [NSNumber numberWithFloat:15.0];
    
    UIMotionEffectGroup *group = [[UIMotionEffectGroup alloc] init];
    group.motionEffects = @[xAxis, yAxis];
    [self.contentController.view addMotionEffect:group];

    
    CGSize preferredContentSize = self.contentController.preferredContentSize;
    CGRect b = self.view.bounds;
    if (CGSizeEqualToSize(preferredContentSize, CGSizeZero)) {
        CGRect rect = CGRectInset(b, 15, 30);
        self.contentController.view.frame = rect;
        self.contentController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    else
    {
        CGRect rect = CGRectMake(floorf((CGRectGetWidth(b)-preferredContentSize.width)/2), floorf((CGRectGetHeight(b)-preferredContentSize.height)/2), preferredContentSize.width, preferredContentSize.height);
        self.contentController.view.frame = rect;
        self.contentController.view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    }
    
    self.contentController.view.layer.cornerRadius = self.cornerRadius;
    self.contentController.view.layer.masksToBounds = YES;

    [self addChildViewController:self.contentController];
    [self.view addSubview:self.contentController.view];
    [self.contentController didMoveToParentViewController:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setEnableBackgroundDismiss:(BOOL)enableBackgroundDismiss {
    if (_enableBackgroundDismiss != enableBackgroundDismiss) {
        
        if (self.backdropGestureRecognizer) {
            if ([self isViewLoaded]) {
                [self.backdropView removeGestureRecognizer:self.backdropGestureRecognizer];
            }
            self.backdropGestureRecognizer = nil;
        }
        
        _enableBackgroundDismiss = enableBackgroundDismiss;
        
        if (enableBackgroundDismiss) {
            self.backdropGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backdropTap:)];
            if ([self isViewLoaded]) {
                [self.backdropView addGestureRecognizer:self.backdropGestureRecognizer];
            }
        }
    }
}

- (void) backdropTap:(UITapGestureRecognizer*)recognizer {
    if (recognizer.state == UIGestureRecognizerStateRecognized) {
        if (self.shouldDismiss) {
            self.shouldDismiss();
        }
    }
}

- (CGFloat) cornerRadius  {
    return self.contentController.view.layer.cornerRadius;
}

- (void) setCornerRadius:(CGFloat)cornerRadius {
    self.contentController.view.layer.cornerRadius = cornerRadius;
}


- (id <UIViewControllerAnimatedTransitioning>) animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    VMAlertStylePopoverAnimator* animator = [[VMAlertStylePopoverAnimator alloc] init];
    animator.presenting = YES;
    return animator;
}

- (id <UIViewControllerAnimatedTransitioning>) animationControllerForDismissedController:(UIViewController *)dismissed
{
    return [[VMAlertStylePopoverAnimator alloc] init];
}

- (UIViewController*) childViewControllerForStatusBarStyle {
    return self.contentController;
}

- (UIViewController*) childViewControllerForStatusBarHidden {
    return self.contentController;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.presentingViewController supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return [self.presentingViewController preferredInterfaceOrientationForPresentation];
}
@end
