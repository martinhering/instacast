//
//  ICAppearanceManager.h
//  Instacast
//
//  Created by Martin Hering on 26.07.14.
//
//

#import <Foundation/Foundation.h>


@protocol ICAppearance <NSObject>
@property (nonatomic, readonly) UIColor* tintColor;
@property (nonatomic, readonly) UIColor* textColor;
@property (nonatomic, readonly) UIColor* mutedTextColor;
@property (nonatomic, readonly) UIColor* placeholderTextColor;
@property (nonatomic, readonly) UIColor* backgroundColor;
@property (nonatomic, readonly) UIColor* lightBackgroundColor;
@property (nonatomic, readonly) UIColor* darkBackgroundColor;
@property (nonatomic, readonly) UIColor* transparentBackdropColor;
@property (nonatomic, readonly) UIColor* tableSeparatorColor;
@property (nonatomic, readonly) UIColor* tableSelectedBackgroundColor;
@property (nonatomic, readonly) UIColor* groupCellBackgroundColor;
@property (nonatomic, readonly) UIColor* groupCellSelectedBackgroundColor;
@property (nonatomic, readonly) UIStatusBarStyle statusBarStyle;
@property (nonatomic, readonly) UIScrollViewIndicatorStyle scrollIndicatorStyle;
@property (nonatomic, readonly) NSString* cssFile;
@property (nonatomic, readonly) UIKeyboardAppearance keyboardAppearance;
@property (nonatomic, readonly) UIActivityIndicatorViewStyle activityIndicatorStyle;
@end

extern NSString* ICAppearanceManagerDidUpdateAppearanceNotification;


@interface ICAppearanceManager : NSObject

+ (instancetype) sharedManager;

@property (nonatomic, strong) id<ICAppearance> appearance;

@property (nonatomic) BOOL switchesNightModeAutomatically;
@property (nonatomic) BOOL nightMode;

- (BOOL) switchNightModeAutomaticallyNow;
- (void) updateAppearance;
- (BOOL) updateLocation;

@end

#define ICTintColor                         ([ICAppearanceManager sharedManager].appearance.tintColor)
#define ICTextColor                         ([ICAppearanceManager sharedManager].appearance.textColor)
#define ICMutedTextColor                    ([ICAppearanceManager sharedManager].appearance.mutedTextColor)
#define ICPlaceholderTextColor              ([ICAppearanceManager sharedManager].appearance.placeholderTextColor)
#define ICBackgroundColor                   ([ICAppearanceManager sharedManager].appearance.backgroundColor)
#define ICTableSeparatorColor               ([ICAppearanceManager sharedManager].appearance.tableSeparatorColor)
#define ICTableSelectedBackgroundColor      ([ICAppearanceManager sharedManager].appearance.tableSelectedBackgroundColor)
#define ICTransparentBackdropColor          ([ICAppearanceManager sharedManager].appearance.transparentBackdropColor)
#define ICLightBackgroundColor               ([ICAppearanceManager sharedManager].appearance.lightBackgroundColor)
#define ICDarkBackgroundColor               ([ICAppearanceManager sharedManager].appearance.darkBackgroundColor)
#define ICGroupCellBackgroundColor          ([ICAppearanceManager sharedManager].appearance.groupCellBackgroundColor)
#define ICGroupCellSelectedBackgroundColor  ([ICAppearanceManager sharedManager].appearance.groupCellSelectedBackgroundColor)

@interface ICDaylightAppearance : NSObject <ICAppearance>
@end


@interface ICNightAppearance : NSObject <ICAppearance>
@end
