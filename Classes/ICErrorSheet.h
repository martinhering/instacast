//
//  ICErrorSheet.h
//  Instacast
//
//  Created by Martin Hering on 17.05.14.
//
//

#import <UIKit/UIKit.h>

@interface ICErrorSheet : UIWindow

+ (instancetype) sheet;

@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* message;

- (void) showAnimated:(BOOL)animated dismissAfterDelay:(NSTimeInterval)delay completion:(void (^)())completion;
- (void) extendDismissingAfterDelay:(NSTimeInterval)delay;

@end
