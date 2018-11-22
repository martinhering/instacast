//
//  RedPillNumberView.h
//  Instacast
//
//  Created by Martin Hering on 19.10.12.
//
//

#import <UIKit/UIKit.h>

@interface RedPillNumberView : UIView

@property (nonatomic) NSInteger number;

- (CGSize) sizeThatFits:(CGSize)size;
@end
