//
//  IOS8FixedSeparatorTableViewCell.m
//  Instacast
//
//  Created by Martin Hering on 27.08.14.
//
//

#import "IOS8FixedSeparatorTableViewCell.h"

@implementation IOS8FixedSeparatorTableViewCell

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    
    Class separatorViewClass = NSClassFromString([@[@"_",@"UITableViewCell",@"SeparatorView"] componentsJoinedByString:@""]);
    for(UIView* subview in self.subviews) {
        if ([subview isKindOfClass:separatorViewClass]) {
            CGRect separatorRect = subview.frame;
            separatorRect.origin.x = 0;
            separatorRect.size.width = CGRectGetWidth(bounds);
            subview.frame = separatorRect;
            break;
        }
    }
}

@end
