//
//  ICListTitleView.m
//  Instacast
//
//  Created by Martin Hering on 20/07/13.
//
//

#import "ICListTitleView.h"

@implementation ICListTitleView

- (id) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        
        _textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 4, CGRectGetWidth(frame), 21)];
        _textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        _textLabel.font = [UIFont systemFontOfSize:15];
        _textLabel.textColor = ICTextColor;
        _textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _textLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_textLabel];
        
        _detailTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 25, CGRectGetWidth(frame), 13)];
        _detailTextLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        _detailTextLabel.font = [UIFont systemFontOfSize:11];
        _detailTextLabel.textColor = ICMutedTextColor;
        _detailTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _detailTextLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_detailTextLabel];
        
        
//        _textLabel.backgroundColor = [UIColor redColor];
//        _detailTextLabel.backgroundColor = [UIColor greenColor];
    }
    
    return self;
}
/*
- (void) setFrame:(CGRect)frame
{
    frame.origin.y = 11;
    [super setFrame:frame];
}

- (void) setCenter:(CGPoint)center
{
    center.y = 33;
    [super setCenter:center];
}
*/
@end
