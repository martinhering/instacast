//
//  ToolbarLabelsViewController.m
//  Instacast
//
//  Created by Martin Hering on 08.04.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import "ToolbarLabelsViewController.h"

@interface ToolbarLabelsViewController ()
@property (nonatomic, weak) IBOutlet UILabel* label1;
@property (nonatomic, weak) IBOutlet UILabel* label2;
@end

@implementation ToolbarLabelsViewController {
    BOOL _observing;
}

+ (id) toolbarLabelsViewController
{
    return [[self alloc] initWithNibName:@"ToolbarLabelsView" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _canDisplayRefreshStatus = NO;
    }
    return self;
}

#pragma mark -

- (void) layout
{
    UIColor* tintColor = ICTextColor;
    CGFloat red, green, blue, alpha;
    [tintColor getRed:&red green:&green blue:&blue alpha:&alpha];
    UIColor* secondTintColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha*0.5f];
    
    self.label1.textColor = tintColor;
    self.label2.textColor = secondTintColor;
    
    
    CGRect b = self.view.bounds;
    
    CGFloat yOffset = 15;

    self.label1.text = self.mainText;
    self.label2.text = self.auxiliaryText;
    

    CGSize label1Size = [self.label1.attributedText size];
    CGSize label2Size = [self.label2.attributedText size];
    
    CGFloat width = label1Size.width;
    if (label2Size.width > 0) {
        width = width + 5 + label2Size.width;
    }

    self.label1.frame = CGRectMake(floorf((CGRectGetWidth(b)-width)/2), yOffset, ceilf(label1Size.width), ceilf(label1Size.height));
    self.label2.frame = CGRectMake(CGRectGetMaxX(self.label1.frame)+5, CGRectGetMinY(self.label1.frame), ceilf(label2Size.width), ceilf(label2Size.height));

}

@end
