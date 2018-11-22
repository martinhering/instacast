//
//  BookmarksTableViewCell.m
//  Instacast
//
//  Created by Martin Hering on 13.04.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import "BookmarksTableViewCell.h"
#import "NumberAccessoryView.h"

@interface BookmarksTableViewCell ()
@property (nonatomic, readwrite, strong) UILabel* numberLabel;
@property (nonatomic, readwrite, strong) UILabel* timeLabel;
@end

@implementation BookmarksTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.selectedBackgroundView = [[UIView alloc] init];
        
        self.textLabel.font = [UIFont systemFontOfSize:15.f];
        self.textLabel.textColor = ICTextColor;
        self.textLabel.numberOfLines = 2;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        self.detailTextLabel.font = [UIFont systemFontOfSize:11.f];
        
        _numberLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_numberLabel.font = [UIFont boldSystemFontOfSize:13.f];
		_numberLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
		[self.contentView addSubview:_numberLabel];
        
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _timeLabel.font = [UIFont systemFontOfSize:11.0f];
        _timeLabel.textColor = [UIColor colorWithWhite:0.5f alpha:1.f];
        _timeLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:_timeLabel];
        
        self.accessoryView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"TableView Disclosure Triangle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
		self.accessoryView.backgroundColor = self.backgroundColor;
		self.accessoryView.opaque = YES;
    }
    return self;
}

- (void) dealloc
{
    [[ImageCacheManager sharedImageCacheManager] cancelImageCacheOperationsWithSender:self];
}

- (void) prepareForReuse
{
    [super prepareForReuse];
    [[ImageCacheManager sharedImageCacheManager] cancelImageCacheOperationsWithSender:self];
}


- (void) layoutSubviews
{
    [super layoutSubviews];
    
    self.selectedBackgroundView.backgroundColor = ICTableSelectedBackgroundColor;
    self.textLabel.textColor = ICTextColor;
    self.detailTextLabel.textColor = ICMutedTextColor;
    self.numberLabel.textColor = ICMutedTextColor;
    self.timeLabel.textColor = ICMutedTextColor;
    self.accessoryView.tintColor = ICMutedTextColor;
    
    CGRect bounds = self.bounds;
	CGRect textLabelRect = self.textLabel.frame;
    CGRect detailLabelRect = self.detailTextLabel.frame;
    //CGRect contentRect = self.contentView.frame;
    CGRect imageViewRect = (self.imageView.image) ? CGRectMake(10, 5, 56, 56) : CGRectMake(5, 5, 0, 56);
    
	
	CGSize numViewSize = [self.numberLabel sizeThatFits:CGSizeZero];
	CGFloat numLeft = CGRectGetMaxX(bounds)-30-numViewSize.width;
	self.numberLabel.frame = CGRectMake(numLeft, floorf((CGRectGetHeight(bounds)-numViewSize.height)/2), numViewSize.width, numViewSize.height);

    
    CGFloat timeLeft = CGRectGetMaxX(bounds)-50-15;
    self.timeLabel.frame = CGRectMake(timeLeft, floorf((CGRectGetHeight(bounds)-14)*0.5f), 50, 14);
    self.timeLabel.hidden = (self.timeLabel.text == nil);
    self.timeLabel.alpha = (self.editing) ? 0 : 1;
    
    CGFloat width = (self.timeLabel.hidden) ? numLeft-CGRectGetMaxX(imageViewRect)-10 : timeLeft-CGRectGetMaxX(imageViewRect)-10;
    textLabelRect.origin.x = CGRectGetMaxX(imageViewRect)+10;
    detailLabelRect.origin.x = CGRectGetMaxX(imageViewRect)+10;
    
    
    CGSize textLabelSize = [[self.textLabel attributedText] boundingRectWithSize:CGSizeMake(width, 500) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    IC_SIZE_INTEGRAL(textLabelSize);
    
    textLabelRect.size.width = width;
    textLabelRect.size.height = MIN(textLabelSize.height, 36);
    
    detailLabelRect.size.width = width;
    
    textLabelRect.origin.y = floorf((CGRectGetHeight(bounds) - (CGRectGetHeight(textLabelRect)+CGRectGetHeight(detailLabelRect)+3)) / 2);
    detailLabelRect.origin.y = CGRectGetMaxY(textLabelRect)+3;
    
    self.numberLabel.alpha = (self.editing) ? 0.f : 1.f;
    
    /*
    if (self.editing)
    {
        imageViewRect = CGRectMake(-(CGRectGetWidth(imageViewRect)+CGRectGetMinX(contentRect)), 0, CGRectGetWidth(imageViewRect), CGRectGetHeight(imageViewRect));
		self.imageView.frame = imageViewRect;
        
        CGFloat labelX = (!editControlVisible) ? 10 : 34;
        if (!editControlVisible) {
            textLabelRect.size.width = textLabelRect.size.width + (CGRectGetMinX(textLabelRect)-labelX);
            detailLabelRect.size.width = detailLabelRect.size.width + (CGRectGetMinX(detailLabelRect)-labelX);
        }
        textLabelRect = CGRectMake(labelX, CGRectGetMinY(textLabelRect), CGRectGetWidth(textLabelRect), CGRectGetHeight(textLabelRect));
        detailLabelRect = CGRectMake(labelX, CGRectGetMinY(detailLabelRect), CGRectGetWidth(detailLabelRect), CGRectGetHeight(detailLabelRect));
        
        self.playButton.frame = CGRectMake(-44-floorf((CGRectGetHeight(bounds)-44)/2), floorf((CGRectGetHeight(bounds)-44)/2), 44, 44);
	}
    else {
        self.playButton.frame = CGRectMake(floorf((CGRectGetHeight(bounds)-44)/2), floorf((CGRectGetHeight(bounds)-44)/2)-2, 44, 44);
    }
    */
    self.imageView.frame = imageViewRect;
    self.textLabel.frame = textLabelRect;
    self.detailTextLabel.frame = detailLabelRect;

}

@end
