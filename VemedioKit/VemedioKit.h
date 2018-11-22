//
//  VMFoundationTouch.h
//  VMFoundationTouch
//
//  Created by Martin Hering on 07.09.15.
//  Copyright (c) 2015 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for VemedioKit.
FOUNDATION_EXPORT double VemedioKitTouchVersionNumber;

//! Project version string for VemedioKit.
FOUNDATION_EXPORT const unsigned char VemedioKitTouchVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <VMFoundationTouch/PublicHeader.h>


// Foundation
#import "NSObject+VMFoundation.h"
#import "NSString+VMFoundation.h"
#import "NSArray+VMFoundation.h"
#import "NSDictionary+VMFoundation.h"
#import "NSURL+VMFoundation.h"
#import "NSURL+IDN.h"
#import "NSNotificationCenter+VemedioKit.h"
#import "NSAttributedString+VMFoundation.h"
#import "Foundation+Localization.h"
#import "NSBundle+VMFoundation.h"
#import "NSData+VMFoundation.h"
#import "VMHTTPOperation.h"
#import "NSUndoManager+VMFoundation.h"
#import "VMUppercaseValueTransformer.h"
#import "VMTimecodeValueTransformer.h"
#import "VMArbitraryDateParser.h"
#import "VMDrawing.h"

// UIKit
#import "UIImage+VMFoundation.h"
#import "UIViewController+VMFoundation.h"
#import "UIColor+VMFoundation.h"
#import "UIScreen+VemedioKit.h"
#import "VMAlertStylePopoverController.h"
#import "VMAlertStylePopoverAnimator.h"

#import "GTMDefines.h"
#import "GTMNSString+HTML.h"
#import "GTMLogger.h"
