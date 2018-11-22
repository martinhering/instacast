//
//  SubscriptionTableViewCell.m
//  Instacast
//
//  Created by Martin Hering on 29.12.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "SubscriptionTableViewCell.h"

@interface SubscriptionTableViewCell ()
@property (nonatomic, readwrite, strong) UILabel* detailTextLabel2;
@property (nonatomic, readwrite, strong) UILabel* numberLabel;
@property (nonatomic, readwrite, strong) UIImageView* newsModeIndicatorImageView;
@end


@implementation SubscriptionTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier])) {
        // Initialization code
        
        self.selectedBackgroundView = [[UIView alloc] init];
        
		
		//self.selectedBackgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EpisodeSelection"]] autorelease];
        self.textLabel.font = [UIFont systemFontOfSize:15.f];
        
        self.detailTextLabel.font = [UIFont systemFontOfSize:11.f];
        self.detailTextLabel2.font = self.detailTextLabel.font;
        
		self.imageView.backgroundColor = self.backgroundColor;
		self.imageView.opaque = YES;
        
        self.accessoryView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"TableView Disclosure Triangle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
		self.accessoryView.backgroundColor = self.backgroundColor;
		self.accessoryView.opaque = YES;
		
		_detailTextLabel2 = [[UILabel alloc] initWithFrame:CGRectZero];
		_detailTextLabel2.font = [UIFont systemFontOfSize:11.f];
		[self.contentView addSubview:_detailTextLabel2];
        
        _numberLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_numberLabel.font = [UIFont boldSystemFontOfSize:13.f];
		[self.contentView addSubview:_numberLabel];
        
        _newsModeIndicatorImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"Episode News Mode"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _newsModeIndicatorImageView.tintColor = [UIColor colorWithWhite:0.7 alpha:1.f];
        _newsModeIndicatorImageView.hidden = YES;
        [self.contentView addSubview:_newsModeIndicatorImageView];
		
		self.opaque = YES;
    }
    return self;
}

- (void) dealloc
{
    self.objectValue = nil;
    [[ImageCacheManager sharedImageCacheManager] cancelImageCacheOperationsWithSender:self];
}

- (void) prepareForReuse
{
    [super prepareForReuse];
    [[ImageCacheManager sharedImageCacheManager] cancelImageCacheOperationsWithSender:self];

    _objectValue = nil;
}

- (void) _updateUnplayedCount
{
    NSInteger unplayedCount = [self.objectValue unplayedCount];
    self.numberLabel.text = (unplayedCount > 0) ? [@(unplayedCount) stringValue] : nil;
}

- (void) _updateEpisodesNumber
{
    NSInteger n = [self.objectValue episodesCount];
    if (n > 0) {
        self.detailTextLabel2.text = (n==1) ? @"1 Episode".ls :[NSString stringWithFormat:@"%d Episodes".ls, n];
    } else {
        self.detailTextLabel2.text = @"No Episodes".ls;
    }
}

- (void) setObjectValue:(CDFeed *)objectValue
{
    if (_objectValue != objectValue)
    {
        [_objectValue removeTaskObserver:self forKeyPath:@"unplayedCount"];
        [_objectValue removeTaskObserver:self forKeyPath:@"episodesCount"];
        
        _objectValue = objectValue;
        
        if (!objectValue) {
            return;
        }

        self.textLabel.text = objectValue.title;
        self.detailTextLabel.text = objectValue.author;
        
        self.imageView.image = [UIImage imageNamed:@"Podcast Placeholder 56"];
        ImageCacheManager* iman = [ImageCacheManager sharedImageCacheManager];
        [iman imageForURL:objectValue.imageURL  size:56 grayscale:NO sender:self completion:^(UIImage *image) {
            self.imageView.image = image;
        }];
        
        [self _updateUnplayedCount];
        [self _updateEpisodesNumber];
        
        
        __weak SubscriptionTableViewCell* weakSelf = self;
        [objectValue addTaskObserver:self forKeyPath:@"unplayedCount" task:^(id obj, NSDictionary *change) {
            [weakSelf _updateUnplayedCount];
            [weakSelf setNeedsLayout];
        }];
        
        [objectValue addTaskObserver:self forKeyPath:@"episodesCount" task:^(id obj, NSDictionary *change) {
            [weakSelf _updateEpisodesNumber];
            [weakSelf setNeedsLayout];
        }];
    }
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing:editing animated:animated];
	
	[UIView animateWithDuration:0.3 animations:^{
        self.numberLabel.alpha = (editing) ? 0.0f : 1.0f;
    }];
}

- (void) layoutSubviews
{
	[super layoutSubviews];
    
    self.selectedBackgroundView.backgroundColor = ICTableSelectedBackgroundColor;
	self.textLabel.textColor = ICTextColor;
    self.detailTextLabel.textColor = ICTextColor;
    self.accessoryView.tintColor = ICMutedTextColor;
    self.detailTextLabel2.textColor = ICMutedTextColor;
    self.numberLabel.textColor = ICMutedTextColor;
    
    CGRect bounds = self.bounds;
    CGRect cframe = self.contentView.frame;
    
    // make sure the image is not wider than high
    self.imageView.frame = CGRectMake(10, 5, 56, 56);
	
	CGSize numViewSize = [self.numberLabel sizeThatFits:CGSizeZero];
	CGFloat numLeft = CGRectGetMaxX(bounds)-25-numViewSize.width;
	self.numberLabel.frame = CGRectMake(numLeft, floorf((CGRectGetHeight(bounds)-numViewSize.height)/2), numViewSize.width, numViewSize.height);

	
	CGRect textLabelRect = self.textLabel.frame;
    textLabelRect.origin.x = 10+56+10;
	textLabelRect.origin.y = 10;
	textLabelRect.size.height = 18;
    textLabelRect.size.width = CGRectGetWidth(cframe)-CGRectGetMaxX(self.imageView.frame) - 10;
    
	CGRect detailLabelRect = self.detailTextLabel.frame;
    detailLabelRect.origin.x = CGRectGetMinX(textLabelRect);
	detailLabelRect.origin.y = CGRectGetMaxY(textLabelRect)+1;
	detailLabelRect.size.height = 13;
    detailLabelRect.size.width = textLabelRect.size.width;
	
	CGRect detailLabel2Rect = CGRectZero;
	if ([self.detailTextLabel2.text length] > 0) {
		CGSize detailLabelTextSize = [[self.detailTextLabel2 attributedText] size];
		detailLabelTextSize.width = ceilf(MIN(detailLabelTextSize.width, CGRectGetWidth(bounds)-CGRectGetMinX(detailLabelRect)-10));
        detailLabelTextSize.height = ceilf(detailLabelTextSize.height);
		detailLabel2Rect = CGRectMake(CGRectGetMinX(textLabelRect), CGRectGetMaxY(detailLabelRect)+1, detailLabelTextSize.width, CGRectGetHeight(detailLabelRect));
	}

	if (!self.numberLabel.hidden && !self.editing)
	{
		if (CGRectGetMaxX(textLabelRect) > numLeft-10) {
			textLabelRect.size.width -= (CGRectGetMaxX(textLabelRect)-numLeft+10);
		}
		if (CGRectGetMaxX(detailLabelRect) > numLeft-10) {
			detailLabelRect.size.width -= (CGRectGetMaxX(detailLabelRect)-numLeft+10);
		}
		if (CGRectGetMaxX(detailLabel2Rect) > numLeft-10) {
			detailLabel2Rect.size.width -= (CGRectGetMaxX(detailLabel2Rect)-numLeft+10);
		}
	}

	self.textLabel.frame = textLabelRect;
	self.detailTextLabel.frame = detailLabelRect;
	self.detailTextLabel2.frame = detailLabel2Rect;
    
    self.newsModeIndicatorImageView.frame = CGRectMake(CGRectGetMaxX(detailLabel2Rect)+5, CGRectGetMinY(detailLabel2Rect), 10, 13);
    self.newsModeIndicatorImageView.hidden = ![self.objectValue boolForKey:AutoDeleteNewsMode];
    
    CGRect triangleRect = self.accessoryView.frame;
    triangleRect.origin.x += 5;
    self.accessoryView.frame = triangleRect;
}

@end
