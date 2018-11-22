//
//  PlayerInfoHeaderFooterView.m
//  Instacast
//
//  Created by Martin Hering on 03.08.14.
//
//

#import "PlayerInfoHeaderFooterView.h"

@interface PlayerInfoHeaderFooterView ()
@property (nonatomic, strong) UIView* separatorView;
@property (nonatomic, strong) UIView* separatorView2;
@property (nonatomic, strong, readwrite) UIButton* editButton;
@property (nonatomic, strong, readwrite) UIButton* doneButton;
@end

@implementation PlayerInfoHeaderFooterView

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        UIView *customView = [[UIView alloc] initWithFrame:CGRectZero];
        customView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundView = customView;

//        _separatorView = [[UIView alloc] initWithFrame:CGRectZero];
//        [self.backgroundView addSubview:_separatorView];
        
        _separatorView2 = [[UIView alloc] initWithFrame:CGRectZero];
        [self.backgroundView addSubview:_separatorView2];
        
        _editButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _editButton.hidden = YES;
        [_editButton setTitle:@"Edit".ls forState:UIControlStateNormal];
        [_editButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 15, 0, 15)];
        [self.contentView addSubview:_editButton];
        
        _doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _doneButton.hidden = YES;
        [_doneButton setTitle:@"Done".ls forState:UIControlStateNormal];
        [_doneButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 15, 0, 15)];
        _doneButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
        [self.contentView addSubview:_doneButton];
    }
    return self;
}


- (void) layoutSubviews
{
    [super layoutSubviews];
    
    
    self.backgroundView.backgroundColor = ICTransparentBackdropColor;
    self.textLabel.textColor = ICTextColor;
    self.separatorView.backgroundColor = ICTableSeparatorColor;
    self.separatorView2.backgroundColor = ICTableSeparatorColor;
    
    self.textLabel.font = [UIFont boldSystemFontOfSize:15];
    
    CGRect b = self.bounds;
    CGFloat yOffset = 0;
    
    CGRect textRect = self.textLabel.frame;
    textRect.origin.x = 15;
    textRect.origin.y = yOffset + floorf((44-CGRectGetHeight(textRect))/2);
    
    if (textRect.size.width > 0 && textRect.size.height > 0) {
        self.textLabel.frame = textRect;
    }
    
    CGFloat separatorHeight = (self.window.screen.scale == 1) ? 1.0 : 0.5;
    self.separatorView.frame = CGRectMake(0, 0, CGRectGetWidth(b), separatorHeight);
    self.separatorView2.frame = CGRectMake(0, CGRectGetHeight(b)-separatorHeight, CGRectGetWidth(b), separatorHeight);
    
    [self.editButton sizeToFit];
    CGRect buttonFrame = self.editButton.frame;
    buttonFrame.size.width += 30;
    self.editButton.frame = CGRectMake(CGRectGetWidth(b)-CGRectGetWidth(buttonFrame), yOffset, CGRectGetWidth(buttonFrame), CGRectGetHeight(b)-yOffset);
    
    [self.doneButton sizeToFit];
    buttonFrame = self.doneButton.frame;
    buttonFrame.size.width += 30;
    self.doneButton.frame = CGRectMake(CGRectGetWidth(b)-CGRectGetWidth(buttonFrame), yOffset, CGRectGetWidth(buttonFrame), CGRectGetHeight(b)-yOffset);
}

- (void) setCanEdit:(BOOL)canEdit
{
    if (_canEdit != canEdit) {
        _canEdit = canEdit;
        
        if (!canEdit) {
            self.editButton.hidden = YES;
            self.doneButton.hidden = YES;
        }
        else {
            self.editButton.hidden = self.editing;
            self.doneButton.hidden = !self.editing;
        }
    }
}

- (void) setEditing:(BOOL)editing
{
    if (_editing != editing) {
        _editing = editing;
        
        if (!self.canEdit) {
            self.editButton.hidden = YES;
            self.doneButton.hidden = YES;
        }
        else {
            self.editButton.hidden = editing;
            self.doneButton.hidden = !editing;
        }
    }
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated
{
    if (!animated) {
        [self setEditing:editing];
    }
    else
    {
        if (!self.canEdit) {
            self.editButton.hidden = YES;
            self.doneButton.hidden = YES;
        }
        else {
            [UIView animateWithDuration:0.3
                             animations:^{
                                 
                                 self.editButton.alpha = (editing) ? 0 : 1;
                                 self.doneButton.alpha = (editing) ? 1 : 0;
                                 
                             } completion:^(BOOL finished) {
                                 self.editButton.hidden = editing;
                                 self.doneButton.hidden = !editing;
                                 
                                 self.editButton.alpha = 1;
                                 self.doneButton.alpha = 1;
                             }];
        }
    }
}

@end
