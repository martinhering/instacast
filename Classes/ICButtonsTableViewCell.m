//
//  ICButtonsTableViewCell.m
//  Instacast
//
//  Created by Martin Hering on 19.08.14.
//
//

#import "ICButtonsTableViewCell.h"
#import "ImageFunctions.h"
#import "ICTableViewButton.h"

@interface ICButtonsTableViewCell ()
@property (nonatomic, strong, readwrite) UIScrollView* contentScrollView;
@property (nonatomic) BOOL firstLayout;
@end

@implementation ICButtonsTableViewCell {
    BOOL _firstLayout;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
    {
        _firstLayout = YES;
        
        self.selectedBackgroundView = [[UIView alloc] init];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _contentScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];

        [self.contentView addSubview:_contentScrollView];
    }
    return self;
}

- (void) prepareForReuse
{
    [super prepareForReuse];
    
    self.buttons = nil;
    self.firstLayout = YES;
}

+ (UIButton*) configuredButtonWithTitle:(NSString*)title imageNamed:(NSString*)imageName
{
    ICTableViewButton* button = [ICTableViewButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundImage:ICImageFromByDrawingInContext(CGSizeMake(1, 1), ^() {
        [ICGroupCellBackgroundColor set];
        UIRectFill(CGRectMake(0, 0, 1, 1));
    }) forState:UIControlStateNormal];
    
    UIImage* tintedBackgroundImage = ICImageFromByDrawingInContext(CGSizeMake(1, 1), ^() {
        [ICTintColor set];
        UIRectFill(CGRectMake(0, 0, 1, 1));
    });
                                                                   
    [button setBackgroundImage:tintedBackgroundImage forState:UIControlStateSelected];
    [button setBackgroundImage:tintedBackgroundImage forState:UIControlStateHighlighted];
    [button setBackgroundImage:tintedBackgroundImage forState:UIControlStateSelected|UIControlStateHighlighted];
    
    [button setTitleColor:ICTextColor forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected|UIControlStateHighlighted];
    
    if (imageName)
    {
        UIImage* image = [[UIImage imageNamed:imageName] imageWithColor:ICTintColor];
        UIImage* highlightedImage = [[UIImage imageNamed:imageName] imageWithColor:[UIColor whiteColor]];
        [button setImage:image forState:UIControlStateNormal];
        [button setImage:highlightedImage forState:UIControlStateHighlighted];
        [button setImage:highlightedImage forState:UIControlStateSelected];
        [button setImage:highlightedImage forState:UIControlStateSelected|UIControlStateHighlighted];
    }
    if (title) {
        [button setTitle:title forState:UIControlStateNormal];
    }
    
    button.titleLabel.font = [UIFont systemFontOfSize:12];
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    return button;
}

- (void) setButtons:(NSArray *)buttons
{
    if (_buttons != buttons) {
     
        for(UIView* subview in [self.contentScrollView subviews]) {
            [subview removeFromSuperview];
        }
        
        _buttons = buttons;
     
        for(UIButton* button in buttons)
        {
            [self.contentScrollView addSubview:button];
            [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (void) buttonAction:(UIButton*)sender
{
    if (!self.allowsMultiSelection) {
        for (UIButton* button in self.buttons) {
            if (button != sender) {
                button.selected = NO;
                button.tintColor = ICTintColor;
            }
        }
    }
    
    if (sender.selected && self.allowsEmptySelection) {
        sender.selected = NO;
    }
    else if (sender.selected)
    {
        NSInteger selectedButtons = 0;
        for (UIButton* button in self.buttons) {
            selectedButtons += (button.selected) ? 1 : 0;
        }
        
        if (selectedButtons > 1) {
            sender.selected = NO;
        }
    }
    else {
        sender.selected = YES;
    }
    
    sender.tintColor = (sender.selected) ? [UIColor whiteColor] : ICTintColor;
    
    NSInteger index = [self.buttons indexOfObject:sender];
    if (index != NSNotFound && self.buttonTappedAtIndex) {
        self.buttonTappedAtIndex(sender, index);
    }
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGRect b = self.contentView.bounds;
    
    self.contentScrollView.backgroundColor = self.backgroundColor;
    self.contentScrollView.frame = b;
    
    CGFloat x = 0;
    for(UIView* subview in [self.contentScrollView subviews])
    {
        if ([subview isKindOfClass:[UIButton class]]) {
            subview.frame = CGRectMake(x, 0, CGRectGetHeight(b), CGRectGetHeight(b));
            x += CGRectGetHeight(b) + 1;
        }
    }
    
    self.contentScrollView.contentSize = CGSizeMake(x-1, CGRectGetHeight(b));
    
    if (self.firstLayout) {
        for(UIButton* button in [self.contentScrollView subviews]) {
            if ([button isKindOfClass:[UIButton class]]) {
                if (button.selected) {
                    [self.contentScrollView scrollRectToVisible:button.frame animated:NO];
                    break;
                }
            }
        }
    }
    
    self.firstLayout = NO;
    
//    // center if necessary
//    if (x-1 < CGRectGetWidth(b)) {
//        self.contentScrollView.contentInset = UIEdgeInsetsMake(0, floorf((CGRectGetWidth(b)-(x-1))/2), 0, 0);
//    }
//    else {
//        self.contentScrollView.contentInset = UIEdgeInsetsZero;
//    }
}
@end
