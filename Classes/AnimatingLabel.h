//
//  ScrollUpLabel.h
//  Instacast
//
//  Created by Martin Hering on 15.02.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AnimatingLabel : UIControl {
@protected
	UILabel*		_labels[2];
	NSInteger		_currentLabel;
	NSMutableArray*	_queue;
}

- (Class) labelClass;

@property(nonatomic, copy) NSString *text;
@property(nonatomic, strong) UIFont *font;
@property(nonatomic, strong) UIColor *textColor;
@property(nonatomic, strong) UIColor *shadowColor;
@property(nonatomic) CGSize shadowOffset;
@property(nonatomic) NSTextAlignment textAlignment;
@property(nonatomic) NSTimeInterval animationDuration;

- (void) setText:(NSString *)text animate:(BOOL)animate;
@end
