//
//  ICRefreshControl.m
//  Instacast
//
//  Created by Martin Hering on 04.08.13.
//
//

#import "ICRefreshControl.h"
#import "CircleProgressView.h"

typedef NS_ENUM(NSInteger, ICRefreshState) {
    kICRefreshStateClosed = 0,
    kICRefreshStateDragging,
    kICRefreshStateRefreshing,
    kICRefreshStateClosing,
};


@interface ICRefreshControl ()
@property (nonatomic, strong) CircleProgressView* progressView;
@property (nonatomic) ICRefreshState refreshState;
@property (nonatomic, strong) UILabel* titleLabel;
@property (nonatomic, strong) UILabel* detailLabel;
@end

@implementation ICRefreshControl

- (id) init
{
    if ((self = [super init]))
    {
        _progressView = [[CircleProgressView alloc] initWithFrame:CGRectZero];
        _progressView.style = CircleProgressStyleFillingOutline;
        [self addSubview:_progressView];
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:13.0f];
        _titleLabel.textColor = ICTextColor;
        [self addSubview:_titleLabel];
        
        _detailLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _detailLabel.font = [UIFont systemFontOfSize:11.0f];
        _detailLabel.textColor = ICMutedTextColor;
        [self addSubview:_detailLabel];
    }
    
    return self;
}


- (void) beginRefreshing
{
    [super beginRefreshing];
    
    self.progressView.style = CircleProgressStyleStandard;
    self.progressView.progress = -1;
    
    self.refreshState = kICRefreshStateRefreshing;
}

- (void) endRefreshing
{
    [super endRefreshing];
    
    self.refreshState = kICRefreshStateClosing;
}

- (void) setRefreshState:(ICRefreshState)refreshState
{
    if (_refreshState != refreshState) {
        _refreshState = refreshState;
        
        [self setNeedsLayout];
    }
}


- (void) _updateProgress
{
    if (!self.refreshing)
    {
        UIScrollView* scrollView = (UIScrollView*)self.superview;
        CGPoint contentOffset = scrollView.contentOffset;
        CGFloat yDelta = contentOffset.y + 44;
        
        CGFloat progress = MAX(0, MIN(yDelta*-1 / 140, 0.85));
        self.progressView.style = CircleProgressStyleFillingOutline;
        self.progressView.progress = progress;
        
        if (self.refreshState == kICRefreshStateClosed && (NSInteger)yDelta != 0) {
            self.refreshState = kICRefreshStateDragging;
        }
        else if (yDelta == 0) {
            self.refreshState = kICRefreshStateClosed;
        }
        
        //DebugLog(@"yDelta %lf %lf", yDelta, contentInsets.top);
    }
    else {
        self.progressView.style = CircleProgressStyleStandard;
        self.progressView.progress = -1;
    }
}

- (void) setFrame:(CGRect)frame
{
    // correct frame
    frame.origin.y = -frame.size.height;
    [super setFrame:frame];

    [self _updateProgress];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGRect b = self.bounds;
    
    //self.backgroundColor = [UIColor colorWithWhite:0.92f alpha:1.f];
    
    self.titleLabel.textColor = ICTextColor;
    self.detailLabel.textColor = ICMutedTextColor;
    
    for(UIView* subview in self.subviews) {
        if ([NSStringFromClass([subview class]) hasPrefix:@"_UIRefresh"]) {
            subview.hidden = YES;
        }
    }
    
    self.progressView.frame = CGRectMake(floorf((76-37)/2), CGRectGetMidY(b)-floorf(37/2), 37, 37);
    
    self.titleLabel.text = (self.refreshState == kICRefreshStateDragging && self.pulldownText) ? self.pulldownText : self.refreshText;
    self.titleLabel.frame = CGRectMake(76, CGRectGetMinY(self.progressView.frame), CGRectGetWidth(b)-76-15, 17);
    
    self.detailLabel.text = self.idleText;
    self.detailLabel.frame = CGRectMake(76, CGRectGetMaxY(self.titleLabel.frame)+2, CGRectGetWidth(b)-76-15, 15);
}

@end
