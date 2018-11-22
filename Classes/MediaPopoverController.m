//
//  MediaPopoverController.m
//  Instacast
//
//  Created by Martin Hering on 25.10.11.
//  Copyright (c) 2011 Vemedio. All rights reserved.
//

#import "MediaPopoverController.h"

@interface MediaPopoverController ()

@end

@implementation MediaPopoverController

@synthesize contentViewController;
@synthesize popoverContentSize;
@synthesize popoverOffset;
@synthesize didDismissBlock;
@synthesize valueChangedBlock;

- (id) initWithContentViewController:(UIViewController*)viewController
{
    if ((self = [super initWithNibName:nil bundle:nil])) {
        contentViewController = [viewController retain];
    }
    return self;
}

- (void) dealloc
{
    [contentViewController release];
    [didDismissBlock release];
    [valueChangedBlock release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    self.view = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
    self.view.backgroundColor = [UIColor clearColor];
    
    [self.contentViewController willMoveToParentViewController:self];
    [self.view addSubview:self.contentViewController.view];
    [self addChildViewController:self.contentViewController];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark -

- (void)presentPopoverFromRect:(CGRect)rect inView:(UIView *)view
{
    UIViewController* rootViewController = view.window.rootViewController;
    if (rootViewController.presentedViewController) {
        rootViewController = rootViewController.presentedViewController;
    } else if (rootViewController.modalViewController) {
        rootViewController = rootViewController.modalViewController;
    }
    
	UIView* rootView = rootViewController.view;
	
	self.view.frame = rootView.bounds;
	[rootView addSubview:self.view];
	
	CGRect convertedRect = [self.view convertRect:rect fromView:view];
    CGFloat w = self.popoverContentSize.width;
    CGFloat h = self.popoverContentSize.height;
    
    CGRect popoverRect = CGRectMake(floorf(CGRectGetMidX(convertedRect) - w/2)+popoverOffset.x,
                                    floorf(CGRectGetMidY(convertedRect) - h/2)+popoverOffset.y, w, h);
	self.contentViewController.view.frame = popoverRect;
}

- (void)dismissPopoverAnimated:(BOOL)animated
{
	if (animated)
	{
		[UIView animateWithDuration:0.3f
						 animations:^{
							 self.view.alpha = 0.0f;
						 }
						 completion:^(BOOL finished) {
							 [self.view removeFromSuperview];
							 
							 if (self.didDismissBlock) {
								 self.didDismissBlock();
                                 self.didDismissBlock = nil;
							 }
						 }];
	}
	else
	{
		[self.view removeFromSuperview];
		
		if (self.didDismissBlock) {
			self.didDismissBlock();
            self.didDismissBlock = nil;
		}
	}
    
    self.valueChangedBlock = nil;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint location = [[touches anyObject] locationInView:self.view];
	
	if (!CGRectContainsPoint(self.contentViewController.view.frame, location)) {
		[self dismissPopoverAnimated:YES];
	}
}

@end
