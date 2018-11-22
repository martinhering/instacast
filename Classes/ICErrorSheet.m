//
//  ICErrorSheet.m
//  Instacast
//
//  Created by Martin Hering on 17.05.14.
//
//

#import "ICErrorSheet.h"
#import "ICErrorSheetViewController.h"

@interface ICErrorSheet ()
@property (copy) void (^completionBlock)();
@property (nonatomic, strong) ICErrorSheetViewController* errorSheetViewController;
@property (nonatomic, strong) id observer;
@property (nonatomic, strong) UITapGestureRecognizer* tapGestureRecognizer;
@end

@implementation ICErrorSheet

+ (instancetype) sheet
{
    return [[self alloc] initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        ICErrorSheetViewController* errorSheetViewController = [ICErrorSheetViewController sheet];
        [self addSubview:errorSheetViewController.view];
        self.errorSheetViewController = errorSheetViewController;
        
        self.backgroundColor = errorSheetViewController.view.backgroundColor;
        
        self.windowLevel = UIWindowLevelStatusBar+1;
        
        __weak ICErrorSheet* weakSelf = self;
        _observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification
                                                                      object:nil
                                                                       queue:nil
                                                                  usingBlock:^(NSNotification *note) {
                                                                      [weakSelf _updateLayoutIfHidden:weakSelf.hidden];
                                                                      //[weakSelf _hideAnimated:NO];
                                                                  }];
        
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:_tapGestureRecognizer];
        
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_observer];
}

- (void) handleTap:(UITapGestureRecognizer*)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_hideSheetAfterDelay) object:nil];
        [self _hideAnimated:YES];
    }
}

- (void) _updateLayoutIfHidden:(BOOL)hidden
{
    UIScreen* screen = [UIScreen mainScreen];
    CGRect screenBounds = screen.bounds;
    
    [self updateContentLayout];
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    CGFloat angle = 0.0;
    CGRect frame = CGRectZero;
    CGFloat sheetWidth = 0;
    CGRect viewRect = self.errorSheetViewController.view.frame;
    CGFloat h = CGRectGetHeight(viewRect);
    
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            angle = M_PI;
            sheetWidth = CGRectGetWidth(screenBounds);
            if (hidden) {
                frame = CGRectMake(floorf((CGRectGetWidth(screenBounds)-sheetWidth)/2), CGRectGetHeight(screenBounds), sheetWidth, h);
            }
            else {
                frame = CGRectMake(floorf((CGRectGetWidth(screenBounds)-sheetWidth)/2), CGRectGetHeight(screenBounds)-64, sheetWidth, h);
            }
            break;
        case UIInterfaceOrientationLandscapeLeft:
            angle = - M_PI / 2.0f;
            sheetWidth = CGRectGetHeight(screenBounds);
            if (hidden) {
                frame = CGRectMake(-h, floorf((CGRectGetHeight(screenBounds)-sheetWidth)/2), h, sheetWidth);
            }
            else {
                frame = CGRectMake(-20, floorf((CGRectGetHeight(screenBounds)-sheetWidth)/2), h, sheetWidth);
            }
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = M_PI / 2.0f;
            sheetWidth = CGRectGetHeight(screenBounds);
            if (hidden) {
                frame = CGRectMake(CGRectGetWidth(screenBounds), floorf((CGRectGetHeight(screenBounds)-sheetWidth)/2), h, sheetWidth);
            }
            else {
                frame = CGRectMake(CGRectGetWidth(screenBounds)-64, floorf((CGRectGetHeight(screenBounds)-sheetWidth)/2), h, sheetWidth);
            }
            break;
        default: // as UIInterfaceOrientationPortrait
            angle = 0.0;
            sheetWidth = CGRectGetWidth(screenBounds);
            if (hidden) {
                frame = CGRectMake(floorf((CGRectGetWidth(screenBounds)-sheetWidth)/2), -h, sheetWidth, h);
            }
            else {
                frame = CGRectMake(floorf((CGRectGetWidth(screenBounds)-sheetWidth)/2), -20, sheetWidth, h);
            }
            break;
    }
    
    self.transform = CGAffineTransformMakeRotation(angle);
    self.frame = frame;
    
    [self updateContentLayout];
}

- (void) updateContentLayout
{
    [self.errorSheetViewController updateViewLayout];
    
    self.errorSheetViewController.titleLabel.text = self.title;
    self.errorSheetViewController.messageLabel.text = self.message;
    
    CGRect vcFrame = self.bounds;
    CGFloat w = MIN(vcFrame.size.width, 540);
    
    CGFloat w2 = [self.errorSheetViewController boundingWidthWithMaxWidth:w];
    
    // only center on iPad
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        vcFrame.origin.x = floorf((vcFrame.size.width - w2) / 2);
    }
    vcFrame.size.width = w2;
    CGRect m = self.errorSheetViewController.messageLabel.frame;
    vcFrame.size.height = CGRectGetMaxY(m)+10;
    
    self.errorSheetViewController.view.frame = vcFrame;
    [self.errorSheetViewController updateViewLayout];
}


- (void) showAnimated:(BOOL)animated dismissAfterDelay:(NSTimeInterval)delay completion:(void (^)())completion
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_hideSheetAfterDelay) object:nil];
    [self performSelector:@selector(_hideSheetAfterDelay) withObject:nil afterDelay:delay];
    
    self.hidden = NO;
    [self _updateLayoutIfHidden:YES];
    
    
    self.completionBlock = completion;
    
    if (animated)
    {
        __weak ICErrorSheet* weakSelf = self;
        
        [UIView animateWithDuration:0.4
                              delay:0.0
             usingSpringWithDamping:0.6f
              initialSpringVelocity:0.0f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [weakSelf _updateLayoutIfHidden:NO];
                         }
                         completion:^(BOOL finished) {
                             
                         }];
    }
    
    else
    {
         [self _updateLayoutIfHidden:NO];
    }
}

- (void) extendDismissingAfterDelay:(NSTimeInterval)delay
{
    [self updateContentLayout];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_hideSheetAfterDelay) object:nil];
    [self performSelector:@selector(_hideSheetAfterDelay) withObject:nil afterDelay:delay];
}

- (void) _hideAnimated:(BOOL)animated
{
    if (animated)
    {
        __weak ICErrorSheet* weakSelf = self;
        [UIView animateWithDuration:0.2
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             
                             [weakSelf _updateLayoutIfHidden:YES];
                             
                         } completion:^(BOOL finished) {
                             
                             if (weakSelf.completionBlock) {
                                 weakSelf.completionBlock();
                                 weakSelf.completionBlock = nil;
                             }
                         }];
    }
    else
    {
        [self _updateLayoutIfHidden:YES];
        if (self.completionBlock) {
            self.completionBlock();
            self.completionBlock = nil;
        }
    }
}

- (void) _hideSheetAfterDelay
{
    [self _hideAnimated:YES];
}

@end
