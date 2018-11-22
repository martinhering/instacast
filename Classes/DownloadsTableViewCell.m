//
//  DownloadsTableViewCell.m
//  Instacast
//
//  Created by Martin Hering on 04.09.12.
//
//

#import "DownloadsTableViewCell.h"
#import "EpisodePlayComboButton.h"


@interface DownloadsTableViewCell ()
@property (nonatomic, readwrite, strong) UIProgressView* progressView;
@property (nonatomic, readwrite, strong) UILabel* sizeLabel;
@property (nonatomic, readwrite, strong) UILabel* timeLabel;

@property (nonatomic, strong, readwrite) EpisodePlayComboButton* playAccessoryButton;
@end


@implementation DownloadsTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        self.textLabel.font = [UIFont systemFontOfSize:13];
        
        // Initialization code.
		_progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
		[self.contentView addSubview:_progressView];
		
		_sizeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_sizeLabel.font = [UIFont systemFontOfSize:11];
		[self.contentView addSubview:_sizeLabel];
		
		_timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_timeLabel.font = [UIFont systemFontOfSize:11];
		_timeLabel.textAlignment = NSTextAlignmentRight;
		[self.contentView addSubview:_timeLabel];
		
        _playAccessoryButton = [EpisodePlayComboButton button];
        _playAccessoryButton.frame = CGRectMake(0, 0, 44, 44);
        _playAccessoryButton.comboState = kEpisodePlayButtonComboStateHolding;
        [self.contentView addSubview:_playAccessoryButton];
        
    }
    return self;
}


- (void) layoutSubviews
{
	[super layoutSubviews];
    
    self.textLabel.textColor = ICTextColor;
    self.sizeLabel.textColor = ICMutedTextColor;
    self.timeLabel.textColor = ICMutedTextColor;
	
    CGRect bounds = self.bounds;
	CGRect textLabelRect = self.textLabel.frame;
    CGRect imageViewRect = CGRectMake(10, 7, 56, 56);
    

    self.imageView.frame = imageViewRect;
	CGFloat width = CGRectGetWidth(bounds)-CGRectGetMaxX(imageViewRect)-55;
    
    textLabelRect.origin.x = CGRectGetMaxX(imageViewRect) + 10;
	textLabelRect.origin.y = 10;
    textLabelRect.size.width = width;
    
	self.textLabel.frame = textLabelRect;
	

	self.progressView.frame = CGRectMake(CGRectGetMinX(textLabelRect), 34, width, 10);
    
	if ([self.timeLabel.text length] == 0) {
		self.sizeLabel.frame = CGRectMake(CGRectGetMinX(textLabelRect), 47, width, 13);
		self.timeLabel.hidden = YES;
	} else {
		self.sizeLabel.frame = CGRectMake(CGRectGetMinX(textLabelRect), 47, width/2+20, 13);
		self.timeLabel.frame = CGRectMake(CGRectGetMinX(textLabelRect)+floorf(width/2)+20, 47, floorf(width/2)-20, 13);
		self.timeLabel.hidden = NO;
	}
	
    self.playAccessoryButton.frame = CGRectMake(CGRectGetMaxX(bounds)-44, floorf((CGRectGetHeight(bounds)-44)/2), 44, 44);
}


@end
