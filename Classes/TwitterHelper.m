//
//  TwitterHelper.m
//  Instacast
//
//  Created by Martin Hering on 05.04.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <Social/Social.h>

#import "TwitterHelper.h"

@implementation TwitterHelper

+ (NSString*) _twitterHost
{
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? @"twitter.com" : @"mobile.twitter.com";
}

+ (BOOL) handleTwitterURL:(NSURL*)url
{
    NSString* fragment = [url fragment];
    if (fragment) {
        NSString* user = [fragment lastPathComponent];
        [TwitterHelper openUserInTwitterApp:user];
    } else
    {
        NSArray* pathComponents = [[[url path] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]] pathComponents];
        if ([pathComponents count] == 1) {
            [TwitterHelper openUserInTwitterApp:pathComponents[0]];
            return YES;
        }
        else if ([pathComponents count] > 2 && ([pathComponents[1] isEqualToString:@"status"] || [pathComponents[1] isEqualToString:@"statuses"])) {
            NSString* tweetId = pathComponents[2];
            NSString* user = pathComponents[0];
            [TwitterHelper openTweetInTwitterApp:tweetId user:user];
            return YES;
        }
    }
    
    return NO;
}

+ (void) openTweetInTwitterApp:(NSString*)tweetId user:(NSString*)user
{
    UIApplication *app = [UIApplication sharedApplication];
    
    // Tweetbot: http://tapbots.com/blog/development/tweetbot-url-scheme
	NSURL *tweetbotURL = [NSURL URLWithString:[NSString stringWithFormat:@"tweetbot:///status/%@", tweetId]];
	if ([app canOpenURL:tweetbotURL])
	{
		[app openURL:tweetbotURL];
		return;
	}
    
    // --- Fallback: Mobile Twitter in Safari
	NSURL *safariURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/%@/statuses/%@", [TwitterHelper _twitterHost], user, tweetId]];
	[app openURL:safariURL];
}

+ (void) openUserInTwitterApp:(NSString*)username
{
    NSString* escapedUsername = [username stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
	
	UIApplication *app = [UIApplication sharedApplication];
    
	// Tweetie: http://developer.atebits.com/tweetie-iphone/protocol-reference/
	NSURL *tweetieURL = [NSURL URLWithString:[NSString stringWithFormat:@"tweetie://user?screen_name=%@", escapedUsername]];
	if ([app canOpenURL:tweetieURL])
	{
		[app openURL:tweetieURL];
		return;
	}
    
    // Tweetbot: http://tapbots.com/blog/development/tweetbot-url-scheme
	NSURL *tweetbotURL = [NSURL URLWithString:[NSString stringWithFormat:@"tweetbot:///user_profile/%@", escapedUsername]];
	if ([app canOpenURL:tweetbotURL])
	{
		[app openURL:tweetbotURL];
		return;
	}
	
	// Birdfeed: http://birdfeed.tumblr.com/post/172994970/url-scheme
	NSURL *birdfeedURL = [NSURL URLWithString:[NSString stringWithFormat:@"x-birdfeed://user?screen_name=%@", escapedUsername]];
	if ([app canOpenURL:birdfeedURL])
	{
		[app openURL:birdfeedURL];
		return;
	}
	
	// Twittelator: http://www.stone.com/Twittelator/Twittelator_API.html
	NSURL *twittelatorURL = [NSURL URLWithString:[NSString stringWithFormat:@"twit:///user?screen_name=%@", escapedUsername]];
	if ([app canOpenURL:twittelatorURL])
	{
		[app openURL:twittelatorURL];
		return;
	}
	
	// Icebird: http://icebirdapp.com/developerdocumentation/
	NSURL *icebirdURL = [NSURL URLWithString:[NSString stringWithFormat:@"icebird://user?screen_name=%@", escapedUsername]];
	if ([app canOpenURL:icebirdURL])
	{
		[app openURL:icebirdURL];
		return;
	}
	
	// Fluttr: no docs
	NSURL *fluttrURL = [NSURL URLWithString:[NSString stringWithFormat:@"fluttr://user/%@", escapedUsername]];
	if ([app canOpenURL:fluttrURL])
	{
		[app openURL:fluttrURL];
		return;
	}
	
	// SimplyTweet: http://motionobj.com/blog/url-schemes-in-simplytweet-23
	NSURL *simplytweetURL = [NSURL URLWithString:[NSString stringWithFormat:@"simplytweet:?link=http://twitter.com/%@", escapedUsername]];
	if ([app canOpenURL:simplytweetURL])
	{
		[app openURL:simplytweetURL];
		return;
	}
	
	// Tweetings: http://tweetings.net/iphone/scheme.html
	NSURL *tweetingsURL = [NSURL URLWithString:[NSString stringWithFormat:@"tweetings:///user?screen_name=%@", escapedUsername]];
	if ([app canOpenURL:tweetingsURL])
	{
		[app openURL:tweetingsURL];
		return;
	}
	
	// Echofon: http://echofon.com/twitter/iphone/guide.html
	NSURL *echofonURL = [NSURL URLWithString:[NSString stringWithFormat:@"echofon:///user_timeline?%@", escapedUsername]];
	if ([app canOpenURL:echofonURL])
	{
		[app openURL:echofonURL];
		return;
	}
	
	// --- Fallback: Mobile Twitter in Safari
	NSURL *safariURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://mobile.twitter.com/%@", escapedUsername]];
	[app openURL:safariURL];
	
}

+ (void) sendMessageInTwitterApp:(NSString*)message
{
    NSString* escapedMessage = [message stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

	UIApplication *app = [UIApplication sharedApplication];
	// Tweetie: http://developer.atebits.com/tweetie-iphone/protocol-reference/
	NSURL *tweetieURL = [NSURL URLWithString:[NSString stringWithFormat:@"tweetie://post?message=%@", escapedMessage]];
	if ([app canOpenURL:tweetieURL])
	{
		[app openURL:tweetieURL];
		return;
	}
    
    // Tweetbot: http://tapbots.com/blog/development/tweetbot-url-scheme
	NSURL *tweetbotURL = [NSURL URLWithString:[NSString stringWithFormat:@"tweetbot:///post?text=%@", escapedMessage]];
	if ([app canOpenURL:tweetbotURL])
	{
        DebugLog(@"%@", [tweetbotURL description]);
		[app openURL:tweetbotURL];
		return;
	}
	
	// Birdfeed: http://birdfeed.tumblr.com/post/172994970/url-scheme
	NSURL *birdfeedURL = [NSURL URLWithString:[NSString stringWithFormat:@"x-birdfeed://post?text=%@", escapedMessage]];
	if ([app canOpenURL:birdfeedURL])
	{
		[app openURL:birdfeedURL];
		return;
	}
	
	// Twittelator: http://www.stone.com/Twittelator/Twittelator_API.html
	NSURL *twittelatorURL = [NSURL URLWithString:[NSString stringWithFormat:@"twit:///post?message=%@", escapedMessage]];
	if ([app canOpenURL:twittelatorURL])
	{
		[app openURL:twittelatorURL];
		return;
	}
	
	// Icebird: http://icebirdapp.com/developerdocumentation/
	NSURL *icebirdURL = [NSURL URLWithString:[NSString stringWithFormat:@"icebird://compose?status=%@", escapedMessage]];
	if ([app canOpenURL:icebirdURL])
	{
		[app openURL:icebirdURL];
		return;
	}
	
	// SimplyTweet: http://motionobj.com/blog/url-schemes-in-simplytweet-23
	NSURL *simplytweetURL = [NSURL URLWithString:[NSString stringWithFormat:@"simplytweet:?text=%@", escapedMessage]];
	if ([app canOpenURL:simplytweetURL])
	{
		[app openURL:simplytweetURL];
		return;
	}
	
	// Tweetings: http://tweetings.net/iphone/scheme.html
	NSURL *tweetingsURL = [NSURL URLWithString:[NSString stringWithFormat:@"tweetings:///post?%@", escapedMessage]];
	if ([app canOpenURL:tweetingsURL])
	{
		[app openURL:tweetingsURL];
		return;
	}
	
	// Echofon: http://echofon.com/twitter/iphone/guide.html
	NSURL *echofonURL = [NSURL URLWithString:[NSString stringWithFormat:@"echofon:///message?%@", escapedMessage]];
	if ([app canOpenURL:echofonURL])
	{
		[app openURL:echofonURL];
		return;
	}
	
	// --- Fallback: Mobile Twitter in Safari
	NSURL *safariURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/?status=%@", [TwitterHelper _twitterHost], escapedMessage]];
	[app openURL:safariURL];
}

+ (void) tweetMessage:(NSString*)message url:(NSURL*)url hostViewController:(UIViewController*)hostViewController
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {    
        SLComposeViewController* composer = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [composer setInitialText:message];
        
        if (url) {
            [composer addURL:url];
        }
        
        __weak SLComposeViewController* weakComposer = composer;
        composer.completionHandler = ^(SLComposeViewControllerResult result) {
            [weakComposer dismissViewControllerAnimated:YES completion:^{}];
        };
        
        [hostViewController presentViewController:composer animated:YES completion:^{}];
        return;
    }
    
    
    NSString* syndicatedMessage = [NSString stringWithFormat:@"%@ %@", message, [url absoluteString]];
    [self sendMessageInTwitterApp:syndicatedMessage];
}

@end
