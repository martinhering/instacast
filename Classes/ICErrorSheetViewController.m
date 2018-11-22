//
//  ICErrorSheetViewController.m
//  Instacast
//
//  Created by Martin Hering on 15.05.14.
//
//

#import "ICErrorSheetViewController.h"

@interface ICErrorSheetViewController ()
@property (nonatomic, weak) IBOutlet UILabel* titleLabel;
@property (nonatomic, weak) IBOutlet UILabel* messageLabel;
@property (nonatomic, weak) IBOutlet UIImageView* imageView;
@end

@implementation ICErrorSheetViewController

+ (instancetype) sheet
{
    return [[self alloc] initWithNibName:@"ErrorSheetView" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = ICTintColor;
    
    self.imageView.tintColor = [UIColor whiteColor];
    self.imageView.image = [[UIImage imageNamed:@"Error Icon Skull"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    [self updateViewLayout];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) updateViewLayout
{
    CGRect messageLabelRect = self.messageLabel.frame;
    if (messageLabelRect.size.width == 0) {
        return;
    }
 
    CGRect b = self.view.bounds;
    CGSize messageSize = [self.messageLabel.attributedText boundingRectWithSize:CGSizeMake(CGRectGetWidth(b)-64-15, 200)
                                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                                   context:nil].size;
    IC_SIZE_INTEGRAL(messageSize);
    
    // only 1 line
    if (messageSize.height < 20) {
        self.titleLabel.frame = CGRectMake(64, 37, CGRectGetWidth(b)-64-15, 16);
        self.messageLabel.frame = CGRectMake(64, 55, CGRectGetWidth(b)-64-15, messageSize.height);
    }
    else {
        self.titleLabel.frame = CGRectMake(64, 30, CGRectGetWidth(b)-64-15, 16);
        self.messageLabel.frame = CGRectMake(64, 48, CGRectGetWidth(b)-64-15, messageSize.height);
    }
}

- (CGFloat) boundingWidthWithMaxWidth:(CGFloat)maxWidth
{
    CGSize messageSize = [self.messageLabel.attributedText boundingRectWithSize:CGSizeMake(maxWidth-64-15, 200)
                                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                                        context:nil].size;
    IC_SIZE_INTEGRAL(messageSize);
    
    return 64+messageSize.width+15;
}
@end
