//
//  BookmarkTableViewCell.m
//  Instacast
//
//  Created by Martin Hering on 04.01.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import "PlayerBookmarksTableViewCell.h"

@interface PlayerBookmarksTableViewCell ()
@property (nonatomic, readwrite, strong) UILabel* timeLabel;
@end

@implementation PlayerBookmarksTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectedBackgroundView = [[UIView alloc] init];
        
        self.textLabel.font = [UIFont systemFontOfSize:15.f];
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.textLabel.numberOfLines = 20;
        
        // Initialization code.
		_timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_timeLabel.font = [UIFont systemFontOfSize:13.f];
		_timeLabel.textColor = [UIColor colorWithWhite:0.5f alpha:1.0f];
		_timeLabel.textAlignment = NSTextAlignmentRight;
		[self.contentView addSubview:_timeLabel];
    }
    return self;
}


- (void) layoutSubviews
{
	[super layoutSubviews];
    
    self.selectedBackgroundView.backgroundColor = ICTableSelectedBackgroundColor;
    self.textLabel.textColor = ICTextColor;
    self.timeLabel.textColor = ICMutedTextColor;

    CGRect b = self.bounds;
    
    CGSize titleSize = [self.textLabel.attributedText boundingRectWithSize:CGSizeMake(CGRectGetWidth(b)-15-15-15-55, 200)
                                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                                   context:nil].size;
    IC_SIZE_INTEGRAL(titleSize);
    
    CGFloat editingOffset = (self.editing) ? 30 : 0;
    
    CGRect titleRect = CGRectMake(15+editingOffset, 11, CGRectGetWidth(b)-15-15-15-55, titleSize.height);
    self.textLabel.frame = [self.contentView convertRect:titleRect fromView:self];
    

    CGRect timeRect = CGRectMake(CGRectGetWidth(b)-15-55+editingOffset, 12.f, 55, 17.f);
    self.timeLabel.frame = [self.contentView convertRect:timeRect fromView:self];
    self.timeLabel.alpha = (self.editing) ? 0 : 1;
}

+ (CGFloat) proposedHeightWithTitle:(NSString*)title tableBounds:(CGRect)tableBounds
{
    if (!title) {
        return 44;
    }
    
    CGFloat width = CGRectGetWidth(tableBounds);
    UIFont* font = [UIFont systemFontOfSize:15.f];
    
    NSAttributedString* attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName : font}];
    
    CGSize titleSize = [attributedTitle boundingRectWithSize:CGSizeMake(width-15-15-15-55, 200)
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                     context:nil].size;
    IC_SIZE_INTEGRAL(titleSize);
    
    return titleSize.height + 22;
}


@end
