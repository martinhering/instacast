//
//  NSAttributedString+VMFoundation.h
//  VMFoundation
//
//  Created by Martin Hering on 24.04.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (VMFoundation)

#if (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL;
#endif

@end
