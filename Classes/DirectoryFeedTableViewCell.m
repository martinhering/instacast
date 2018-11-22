//
//  DirectoryFeedTableViewCell.m
//  Instacast
//
//  Created by Martin Hering on 04.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import "DirectoryFeedTableViewCell.h"


@implementation DirectoryFeedTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        self.selectedBackgroundView = [[UIView alloc] init];
        
        
		_videoIndicator = [[UIImageView alloc] initWithFrame:CGRectZero];
        _videoIndicator.image = [[UIImage imageNamed:@"Episode Video"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		_videoIndicator.backgroundColor = self.backgroundColor;
        _videoIndicator.tintColor = [UIColor colorWithWhite:0.6f alpha:1.f];
		[self.contentView addSubview:_videoIndicator];
        
        self.textLabel.font = [UIFont systemFontOfSize:15.f];
        self.detailTextLabel.font = [UIFont systemFontOfSize:11.f];

        self.accessoryView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"TableView Disclosure Triangle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
		self.accessoryView.backgroundColor = self.backgroundColor;
		self.accessoryView.opaque = YES;
    }
    return self;
}

- (void) layoutSubviews
{
	[super layoutSubviews];
    
    self.selectedBackgroundView.backgroundColor = ICTableSelectedBackgroundColor;
    self.textLabel.textColor = ICTextColor;
    self.detailTextLabel.textColor = ICMutedTextColor;
    self.accessoryView.tintColor = ICMutedTextColor;
	
	CGRect bounds = self.bounds;
	
	self.imageView.frame = CGRectMake(10, 5, 56, 56);
	self.detailTextLabel.numberOfLines = 0;
    
    
    CGSize textSize = ([self.textLabel.text length] > 0) ? [self.textLabel.attributedText size] : CGSizeZero;
    IC_SIZE_INTEGRAL(textSize);
    
	CGSize detailTextSize = ([self.detailTextLabel.text length] > 0) ? [self.detailTextLabel.attributedText size] : CGSizeZero;
    IC_SIZE_INTEGRAL(detailTextSize);
    
	CGRect textLabelRect = self.textLabel.frame;
	textLabelRect.origin.x = CGRectGetMaxX(self.imageView.frame)+10;
	textLabelRect.origin.y = 10;
    textLabelRect.size.height = textSize.height;
	
	CGRect detailLabelRect = self.detailTextLabel.frame;
	detailLabelRect.origin.x = CGRectGetMinX(textLabelRect);
	detailLabelRect.origin.y = CGRectGetMaxY(textLabelRect);
	detailLabelRect.size.height = 0;
	

    CGFloat w = CGRectGetWidth(bounds)-CGRectGetWidth(self.imageView.frame)-10-10-((self.video)?50:30);
    textLabelRect.size.width = w;
    detailLabelRect.size.width = w;
    detailLabelRect.size.height = (detailTextSize.width > w) ? 30 : 15;

	
	self.textLabel.frame = textLabelRect;
	self.detailTextLabel.frame = detailLabelRect;
	
	self.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
	
	_videoIndicator.hidden = !self.video;
    _videoIndicator.frame = CGRectMake(CGRectGetMaxX(bounds)-15-21, ceilf((CGRectGetHeight(bounds)-9)/2), 10, 9);
    
    CGRect triangleRect = self.accessoryView.frame;
    triangleRect.origin.x += 5;
    self.accessoryView.frame = triangleRect;
}


@end
