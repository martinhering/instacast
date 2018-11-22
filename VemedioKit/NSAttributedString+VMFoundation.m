//
//  NSAttributedString+VMFoundation.m
//  VMFoundation
//
//  Created by Martin Hering on 24.04.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import "NSAttributedString+VMFoundation.h"

@implementation NSAttributedString (VMFoundation)

#if (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))

+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL
{
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: inString];
    NSRange range = NSMakeRange(0, [attrString length]);
    
    [attrString beginEditing];
    [attrString addAttribute:NSLinkAttributeName value:[aURL absoluteString] range:range];
    [attrString addAttribute:NSCursorAttributeName value:[NSCursor pointingHandCursor] range:range];

    // make the text appear in blue
    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
    
    // next make the text appear with an underline
    [attrString addAttribute: NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:range];
    
    [attrString endEditing];
    
    return attrString;
}

#endif
@end
