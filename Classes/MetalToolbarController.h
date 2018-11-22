//
//  MetalToolbarController.h
//  Instacast
//
//  Created by Martin Hering on 12.05.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    MetalToolbarTypeMain,
    MetalToolbarTypeEditing,
};

typedef NSInteger MetalToolbarType;

enum {
    MetalToolbarButtonTypeAdd,
    MetalToolbarButtonTypeEdit,
    MetalToolbarButtonTypeAction,
    MetalToolbarButtonTypeVolume,
    MetalToolbarButtonTypeDone,
    MetalToolbarButtonTypeTrash,
    MetalToolbarButtonTypeRefresh,
    MetalToolbarButtonTypeDownloads,
    
    MetalToolbarButtonTypeStarred,
    MetalToolbarButtonTypeAll,
    MetalToolbarButtonTypeCached,
};
typedef NSInteger MetalToolbarButtonType;

@protocol MetalToolbarControllerDelegate;

@interface MetalToolbarController : UIViewController {

}

+ (MetalToolbarController*) metalToolbarController;

@property (nonatomic, assign) id<MetalToolbarControllerDelegate> delegate;

@property (nonatomic, assign) MetalToolbarType toolbarType;
- (void) setToolbarType:(MetalToolbarType)type animated:(BOOL)animated;

- (UIButton*) buttonWithType:(MetalToolbarButtonType)buttonType toolbarType:(MetalToolbarType)toolbarType; 
- (void) setSelected:(BOOL)selected button:(MetalToolbarButtonType)buttonType toolbarType:(MetalToolbarType)toolbarType;

@property (nonatomic, assign, getter = isHidden) BOOL hidden;
- (void) setHidden:(BOOL)hidden animate:(BOOL)animate;

@end

@protocol MetalToolbarControllerDelegate
- (void) metalToolbarController:(MetalToolbarController*)controller didTriggerActionOnButtonWithType:(MetalToolbarButtonType)buttonType toolbarType:(MetalToolbarType)toolbarType;
@end