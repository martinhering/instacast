//
//  ICSearchBar.m
//  Instacast
//
//  Created by Martin Hering on 28.08.14.
//
//

#import "ICSearchBar.h"
#import "ImageFunctions.h"
#import "CircleProgressView.h"

@interface ICSearchBar ()
@property (nonatomic, strong) CircleProgressView* activityView;
@end

@implementation ICSearchBar

- (void) appearanceDidChange
{
    // search style update
    self.tintColor = ICTableSeparatorColor;
    [self setScopeBarButtonTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithWhite:0.58f alpha:1.f]} forState:UIControlStateNormal];
    [self setScopeBarButtonTitleTextAttributes:@{NSForegroundColorAttributeName : ICTintColor} forState:UIControlStateSelected];
    
    UIImage* backgroundImage = ICImageFromByDrawingInContextWithScale(CGSizeMake(28, 28), NO, self.window.screen.scale, ^{
        
        UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(0, 0, 28, 28) cornerRadius:6];
        [ICGroupCellBackgroundColor setFill];
        [rectanglePath fill];
    });
    backgroundImage = [backgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(6, 6, 6, 6)];
    
    [self setSearchFieldBackgroundImage:backgroundImage forState:UIControlStateNormal];
    
    for (UIView *subView in self.subviews)
    {
        for (UIView *secondLevelSubview in subView.subviews){
            if ([secondLevelSubview isKindOfClass:[UITextField class]])
            {
                UITextField *searchBarTextField = (UITextField *)secondLevelSubview;
                searchBarTextField.textColor = ICTextColor;
                searchBarTextField.tintColor = ICTintColor;
                break;
            }
        }
    }
    
    self.searchTextPositionAdjustment = UIOffsetMake(5, 0);
}

- (void) setShowsActivity:(BOOL)showsActivity
{
    if (_showsActivity != showsActivity) {
        _showsActivity = showsActivity;
        
        if (showsActivity) {
            self.activityView = [[CircleProgressView alloc] initWithFrame:CGRectZero];
            self.activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            [self addSubview:self.activityView];
        }
        else {
            [self.activityView removeFromSuperview];
            self.activityView = nil;
        }
    }
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGRect b = self.bounds;
    self.activityView.frame = CGRectMake(CGRectGetWidth(b)-33, 12, 20, 20);
}
@end
