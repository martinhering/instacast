//
//  ICMonospaceTextField.m
//  Instacast
//
//  Created by Martin Hering on 11.02.16.
//  Copyright © 2016 Vemedio. All rights reserved.
//

#import "ICMonospaceLabel.h"

@implementation ICMonospaceLabel

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    self.font = [UIFont monospacedDigitSystemFontOfSize:self.font.pointSize weight:UIFontWeightRegular];
}
@end
