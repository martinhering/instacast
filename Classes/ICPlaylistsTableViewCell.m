//
//  ICPlaylistsTableViewCell.m
//  Instacast
//
//  Created by Martin Hering on 10.08.13.
//
//

#import "ICPlaylistsTableViewCell.h"
#import "NumberAccessoryView.h"

@interface ICPlaylistsTableViewCell ()
@property (nonatomic, readwrite, strong) UILabel* numberLabel;
@end

@implementation ICPlaylistsTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectedBackgroundView = [[UIView alloc] init];
        self.textLabel.font = [UIFont systemFontOfSize:15.f];
        
        
        _numberLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_numberLabel.font = [UIFont boldSystemFontOfSize:13.f];
		
		[self.contentView addSubview:_numberLabel];
        
        self.accessoryView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"TableView Disclosure Triangle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
		self.accessoryView.backgroundColor = self.backgroundColor;
		self.accessoryView.opaque = YES;
        
    }
    return self;
}

- (void) dealloc {
    self.objectValue = nil;
}

- (void) prepareForReuse
{
    [super prepareForReuse];
    self.imageYOffset = 0;
    self.objectValue = nil;
}

- (void) setObjectValue:(CDList *)objectValue
{
    if (_objectValue != objectValue)
    {
        [_objectValue removeTaskObserver:self forKeyPath:@"numberOfEpisodes"];
        [_objectValue removeTaskObserver:self forKeyPath:@"name"];
        [_objectValue removeTaskObserver:self forKeyPath:@"image"];
        
        _objectValue = objectValue;
        
        self.textLabel.text = objectValue.name;
        self.imageView.image = objectValue.image;
        
        NSInteger number = [objectValue numberOfEpisodes];
        self.numberLabel.text = (number > 0) ? [NSString stringWithFormat:@"%ld", (long)number] : nil;
        
        if (!objectValue) {
            return;
        }
        
        WEAK_SELF
        [objectValue addTaskObserver:self forKeyPath:@"numberOfEpisodes" task:^(id obj, NSDictionary *change) {
            NSInteger number = [weakSelf.objectValue numberOfEpisodes];
            weakSelf.numberLabel.text = (number > 0) ? [NSString stringWithFormat:@"%ld", (long)number] : nil;
            [weakSelf setNeedsLayout];
        }];
        
        [objectValue addTaskObserver:self forKeyPath:@"name" task:^(id obj, NSDictionary *change) {
            weakSelf.textLabel.text = weakSelf.objectValue.name;
            [weakSelf setNeedsLayout];
        }];
        
        [objectValue addTaskObserver:self forKeyPath:@"image" task:^(id obj, NSDictionary *change) {
            weakSelf.imageView.image = weakSelf.objectValue.image;
        }];
    }
    
    
    
//    [objectValue calculateNumberOfEpisodesCompletion:^(NSUInteger numberOfEpisodes) {
//        self.numberLabel.text = (numberOfEpisodes > 0) ? [NSString stringWithFormat:@"%ld", (long)numberOfEpisodes] : nil;
//        [self setNeedsLayout];
//    }];
}


- (void) layoutSubviews
{
	[super layoutSubviews];
    
    self.selectedBackgroundView.backgroundColor = ICTableSelectedBackgroundColor;
    self.textLabel.textColor = ICTextColor;
    self.numberLabel.textColor = ICMutedTextColor;
    self.accessoryView.tintColor = ICMutedTextColor;
    
	CGRect bounds = self.bounds;
	
	CGSize numViewSize = [self.numberLabel sizeThatFits:CGSizeZero];
	CGFloat numLeft = CGRectGetMaxX(bounds)-25-numViewSize.width;
	self.numberLabel.frame = CGRectMake(numLeft, floorf((CGRectGetHeight(bounds)-numViewSize.height)/2), numViewSize.width, numViewSize.height);
    self.numberLabel.alpha = (self.editing) ? 0 : 1;
    
    CGRect imageRect = self.imageView.frame;
    imageRect.origin.x = 12;
    imageRect.origin.y += self.imageYOffset;
    self.imageView.frame = imageRect;
    
    CGRect textLabelRect = self.textLabel.frame;
    textLabelRect.origin.x = 50;
    textLabelRect.size.width -= numViewSize.width;
    self.textLabel.frame = textLabelRect;
    
    CGRect triangleRect = self.accessoryView.frame;
    triangleRect.origin.x += 5;
    self.accessoryView.frame = triangleRect;
}

@end
