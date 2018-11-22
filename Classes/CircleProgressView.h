//
//  CircleProgressView.h
//  Instacast
//
//  Created by Martin Hering on 21.12.12.
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CircleProgressStyle) {
    CircleProgressStyleStandard,
    CircleProgressStyleFillingOutline,
};

IB_DESIGNABLE

@interface CircleProgressView : UIView

@property (nonatomic) IBInspectable NSInteger style;
@property (nonatomic) IBInspectable double progress;
@end
