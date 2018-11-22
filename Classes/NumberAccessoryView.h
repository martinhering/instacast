//
//  NumberAccessoryView.h
//  SnowMobile
//
//  Created by Martin Hering on 15.02.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    NumberAccessoryViewStyleNoOutline,
    NumberAccessoryViewStyleRoundedOutline,
    NumberAccessoryViewStyleEdgyOutline
};
typedef NSInteger NumberAccessoryViewStyle;


@interface NumberAccessoryView : UIControl {
@protected

}

- (id)initWithStyle:(NumberAccessoryViewStyle)style;

@property (nonatomic, assign) NSUInteger num;

@property (nonatomic, assign) NumberAccessoryViewStyle style;
@property (nonatomic, assign) BOOL showOutline;
@property (nonatomic, assign) CGFloat borderRadius;
@property (nonatomic, strong) UIFont* font;
@property (nonatomic, strong) UIColor* outlineColor;
@property (nonatomic, assign) UIEdgeInsets insets;
@property (nonatomic, assign) CGFloat minWidth;
@end
