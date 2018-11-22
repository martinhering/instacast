    //
//  MetalToolbarController.m
//  Instacast
//
//  Created by Martin Hering on 12.05.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import "MetalToolbarController.h"
#import "PadMainToolbarVolumeView.h"
#import "PadRefreshButton.h"

@interface MetalToolbarController ()

@property (nonatomic, readwrite, retain) UIView* mainToolbarView;

@property (nonatomic, readwrite, retain) UIButton* addButton;
@property (nonatomic, readwrite, retain) UIButton* volumeButton;
@property (nonatomic, readwrite, retain) PadMainToolbarVolumeView* airPlayButton;
@property (nonatomic, readwrite, retain) UIButton* actionButton;
@property (nonatomic, readwrite, retain) UIButton* refreshButton;
@property (nonatomic, readwrite, retain) UIButton* downloadsButton;

@property (nonatomic, readwrite, retain) UIButton* starredButton;
@property (nonatomic, readwrite, retain) UIButton* allButton;
@property (nonatomic, readwrite, retain) UIButton* cachedButton;


@property (nonatomic, readwrite, retain) UIView* editingToolbarView;
@property (nonatomic, readwrite, retain) UIButton* editingDoneButton;
@property (nonatomic, readwrite, retain) UIButton* editingTrashButton;

@end

@implementation MetalToolbarController

+ (MetalToolbarController*) metalToolbarController
{
	return [[[self alloc] initWithNibName:nil bundle:nil] autorelease];
}

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

@synthesize toolbarType;
@synthesize editingToolbarView;

@synthesize mainToolbarView;
@synthesize addButton;
@synthesize starredButton;
@synthesize allButton;
@synthesize cachedButton;
@synthesize volumeButton;
@synthesize airPlayButton;
@synthesize actionButton;
@synthesize refreshButton;
@synthesize editingDoneButton;
@synthesize editingTrashButton;
@synthesize downloadsButton;
@synthesize delegate;


- (void)dealloc {
	[addButton release];
	[actionButton release];
	[starredButton release];
	[allButton release];
	[cachedButton release];
    [volumeButton release];
    [airPlayButton release];
    [refreshButton release];
    [editingToolbarView release];
    [editingDoneButton release];
    [editingTrashButton release];
    [downloadsButton release];
    [super dealloc];
}


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
	CGRect applicationBounds = [UIScreen mainScreen].bounds;
	self.view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, CGRectGetHeight(applicationBounds))] autorelease];
	self.view.clipsToBounds = NO;
	
	UIImageView* topImageView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)] autorelease];
	topImageView.image = [UIImage imageNamed:@"PadToolbarTop.png"];
	topImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
	[self.view addSubview:topImageView];
	
	UIImageView* bottomImageView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(applicationBounds)-44, 44, 44)] autorelease];
	bottomImageView.image = [UIImage imageNamed:@"PadToolbarBottom.png"];
	bottomImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
	[self.view addSubview:bottomImageView];
	
	UIView* middleImageView = [[[UIView alloc] initWithFrame:CGRectMake(0, 44, 44, CGRectGetHeight(applicationBounds)-88)] autorelease];
	UIColor* patternColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"PadToolbarTrack.png"]];
	middleImageView.backgroundColor = patternColor;
	middleImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:middleImageView];
	
	UIView* shadowView = [[[UIView alloc] initWithFrame:CGRectMake(44, 0, 5, CGRectGetHeight(applicationBounds))] autorelease];
    shadowView.backgroundColor = [UIColor clearColor];
    shadowView.opaque = NO;
	shadowView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"PadMainToolbarShadow.png"]];
	shadowView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:shadowView];

    // main toolbar
    self.mainToolbarView = [[[UIView alloc] initWithFrame:self.view.bounds] autorelease];
    mainToolbarView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:mainToolbarView];
    toolbarType = MetalToolbarTypeMain;
    

	self.addButton = [UIButton buttonWithType:UIButtonTypeCustom];
	addButton.frame = CGRectMake(0, 0, 44, 44);
	addButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
	[addButton setImage:[UIImage imageNamed:@"PadToolbarAddButton.png"] forState:UIControlStateNormal];
	addButton.showsTouchWhenHighlighted = YES;
    [addButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
	[self.mainToolbarView addSubview:addButton];
    
    self.refreshButton = [PadRefreshButton buttonWithType:UIButtonTypeCustom];
	refreshButton.frame = CGRectMake(0, 44+11, 44, 44);
	refreshButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
	[refreshButton setImage:[UIImage imageNamed:@"PadToolbarRefreshButton.png"] forState:UIControlStateNormal];
    [refreshButton setImage:[UIImage imageNamed:@"PadToolbarRefreshing.png"] forState:UIControlStateDisabled];
	refreshButton.showsTouchWhenHighlighted = YES;
    [refreshButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
	[self.mainToolbarView addSubview:refreshButton];
    
    self.downloadsButton = [UIButton buttonWithType:UIButtonTypeCustom];
	downloadsButton.frame = CGRectMake(0, 88+22, 44, 44);
	downloadsButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
	[downloadsButton setImage:[UIImage imageNamed:@"PadToolbarDownloadsButton.png"] forState:UIControlStateNormal];
	downloadsButton.showsTouchWhenHighlighted = YES;
    [downloadsButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
	[self.mainToolbarView addSubview:downloadsButton];
    
    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
	actionButton.frame = CGRectMake(0, CGRectGetHeight(applicationBounds)-44, 44, 44);
	actionButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
	[actionButton setImage:[UIImage imageNamed:@"PadToolbarActionButton.png"] forState:UIControlStateNormal];
	actionButton.showsTouchWhenHighlighted = YES;
    [actionButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
	[self.mainToolbarView addSubview:actionButton];
    
    self.volumeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    volumeButton.imageEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
	volumeButton.frame = CGRectMake(0, CGRectGetHeight(applicationBounds)-88-11, 44, 44);
	volumeButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
	[volumeButton setImage:[UIImage imageNamed:@"PadToolbarVolumeButton.png"] forState:UIControlStateNormal];
	volumeButton.showsTouchWhenHighlighted = YES;
    [volumeButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
	[self.mainToolbarView addSubview:volumeButton];
    
    
    self.airPlayButton = [[[PadMainToolbarVolumeView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(applicationBounds)-132-22, 44, 44)] autorelease];
    airPlayButton.showsRouteButton = YES;
    airPlayButton.showsVolumeSlider = NO;
	airPlayButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
	[self.mainToolbarView addSubview:airPlayButton];
    
    
	UIView* selectorView = [[[UIView alloc] initWithFrame:CGRectMake(0, floorf((CGRectGetHeight(applicationBounds)-132)*0.5f), 44, 44*3)] autorelease];
	selectorView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
	[self.mainToolbarView addSubview:selectorView];
	
	self.starredButton = [UIButton buttonWithType:UIButtonTypeCustom];
	starredButton.frame = CGRectMake(0, 0, 44, 44);
	[starredButton setImage:[UIImage imageNamed:@"PadTBStarred.png"] forState:UIControlStateNormal];
    [starredButton setImage:[UIImage imageNamed:@"PadTBStarredH.png"] forState:UIControlStateDisabled];
	starredButton.showsTouchWhenHighlighted = YES;
    starredButton.adjustsImageWhenDisabled = YES;
    [starredButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
	[selectorView addSubview:starredButton];
	
	self.allButton = [UIButton buttonWithType:UIButtonTypeCustom];
	allButton.frame = CGRectMake(0, 44, 44, 44);
	[allButton setImage:[UIImage imageNamed:@"PadTBAll.png"] forState:UIControlStateNormal];
    [allButton setImage:[UIImage imageNamed:@"PadTBAllH.png"] forState:UIControlStateDisabled];
	allButton.showsTouchWhenHighlighted = YES;
    allButton.adjustsImageWhenDisabled = YES;
    [allButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
	[selectorView addSubview:allButton];
	
	self.cachedButton = [UIButton buttonWithType:UIButtonTypeCustom];
	cachedButton.frame = CGRectMake(0, 44*2, 44, 44);
	[cachedButton setImage:[UIImage imageNamed:@"PadTBCached.png"] forState:UIControlStateNormal];
    [cachedButton setImage:[UIImage imageNamed:@"PadTBCachedH.png"] forState:UIControlStateDisabled];
	cachedButton.showsTouchWhenHighlighted = YES;
    cachedButton.adjustsImageWhenDisabled = YES;
    [cachedButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
	[selectorView addSubview:cachedButton];
    
    
    
    // editing toolbar
    self.editingToolbarView = [[[UIView alloc] initWithFrame:self.view.bounds] autorelease];
    editingToolbarView.hidden = YES;
    editingToolbarView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:editingToolbarView];
    
    self.editingDoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
	editingDoneButton.frame = CGRectMake(0, CGRectGetHeight(applicationBounds)-44, 44, 44);
	editingDoneButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
	[editingDoneButton setImage:[UIImage imageNamed:@"PadToolbarDoneButton.png"] forState:UIControlStateNormal];
	editingDoneButton.showsTouchWhenHighlighted = YES;
    [editingDoneButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
	[self.editingToolbarView addSubview:editingDoneButton];
    
    self.editingTrashButton = [UIButton buttonWithType:UIButtonTypeCustom];
	editingTrashButton.frame = CGRectMake(0, 0, 44, 44);
	editingTrashButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
	[editingTrashButton setImage:[UIImage imageNamed:@"PadToolbarTrashButton.png"] forState:UIControlStateNormal];
	editingTrashButton.showsTouchWhenHighlighted = YES;
    editingTrashButton.enabled = NO;
    [editingTrashButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
	[self.editingToolbarView addSubview:editingTrashButton];

}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.mainToolbarView = nil;
	self.addButton = nil;
	self.actionButton = nil;
	self.starredButton = nil;
	self.allButton = nil;
	self.cachedButton = nil;
    self.volumeButton = nil;
    self.editingDoneButton = nil;
    self.editingTrashButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}




#pragma mark -

- (UIButton*) buttonWithType:(MetalToolbarButtonType)myButtonType toolbarType:(MetalToolbarType)myToolbarType
{
    switch (myToolbarType) {
        case MetalToolbarTypeMain:
        {
            switch (myButtonType) {
                case MetalToolbarButtonTypeAdd:
                    return self.addButton;
                
                case MetalToolbarButtonTypeRefresh:
                    return self.refreshButton;
                    
                case MetalToolbarButtonTypeAction:
                    return self.actionButton;
                    
                case MetalToolbarButtonTypeVolume:
                    return self.volumeButton;
                    
                case MetalToolbarButtonTypeStarred:
                    return self.starredButton;
                    
                case MetalToolbarButtonTypeAll:
                    return self.allButton;
                    
                case MetalToolbarButtonTypeCached:
                    return self.cachedButton;
                case MetalToolbarButtonTypeDownloads:
                    return self.downloadsButton;
                default:
                    break;
            }
        }
            break;
        case MetalToolbarTypeEditing:
        {
            switch (myButtonType) {
                case MetalToolbarButtonTypeDone:
                    return self.editingDoneButton;
                case MetalToolbarButtonTypeTrash:
                    return self.editingTrashButton;
                default:
                    break;
            }
        }
            break;
            
        default:
            break;
    }
    return nil;
}

- (void) setSelected:(BOOL)selected button:(MetalToolbarButtonType)myButtonType toolbarType:(MetalToolbarType)myToolbarType
{
    UIButton* button = [self buttonWithType:myButtonType toolbarType:myToolbarType];
    [button setEnabled:!selected];
}

- (void) setToolbarType:(MetalToolbarType)type animated:(BOOL)animated
{
    UIView* fromView = nil;
    UIView* toView = nil;
    
    switch (self.toolbarType) {
        case MetalToolbarTypeMain:
            fromView = self.mainToolbarView;
            break;
        case MetalToolbarTypeEditing:
            fromView = self.editingToolbarView;
            break;
        default:
            break;
    }
    
    switch (type) {
        case MetalToolbarTypeMain:
            toView = self.mainToolbarView;
            break;
        case MetalToolbarTypeEditing:
            toView = self.editingToolbarView;
            break;
        default:
            break;
    }
    
    toView.hidden = NO;
    
    [UIView animateWithDuration:0.3f animations:^{
        fromView.alpha = 0.0f;
        toView.alpha = 1.0f;
        
    } completion:^(BOOL finished) {
        fromView.hidden = YES;
    }];
    
    self.toolbarType = type;
}

- (void) buttonAction:(id)sender
{
    if (self.delegate)
    {
        MetalToolbarType myToolbarType = 0;
        MetalToolbarButtonType buttonType = 0;
        
        NSArray* mainToolbarButtons = [NSArray arrayWithObjects:self.addButton, self.actionButton, self.starredButton, self.allButton, self.cachedButton, self.volumeButton, self.refreshButton, self.downloadsButton, nil];
        
        if ([mainToolbarButtons containsObject:sender]) {
            myToolbarType = MetalToolbarTypeMain;
        } else {
            myToolbarType = MetalToolbarTypeEditing;
        }
        
        if (sender == self.addButton) {
            buttonType = MetalToolbarButtonTypeAdd;
        }
        else if (sender == self.actionButton) {
            buttonType = MetalToolbarButtonTypeAction;
        }
        else if (sender == self.starredButton) {
            buttonType = MetalToolbarButtonTypeStarred;
        }
        else if (sender == self.allButton) {
            buttonType = MetalToolbarButtonTypeAll;
        }
        else if (sender == self.cachedButton) {
            buttonType = MetalToolbarButtonTypeCached;
        }
        else if (sender == self.volumeButton) {
            buttonType = MetalToolbarButtonTypeVolume;
        }
        else if (sender == self.refreshButton) {
            buttonType = MetalToolbarButtonTypeRefresh;
        }
        else if (sender == self.editingTrashButton) {
            buttonType = MetalToolbarButtonTypeTrash;
        }
        else if (sender == self.editingDoneButton) {
            buttonType = MetalToolbarButtonTypeDone;
        }
        else if (sender == self.downloadsButton) {
            buttonType = MetalToolbarButtonTypeDownloads;
        }
        
        [self.delegate metalToolbarController:self didTriggerActionOnButtonWithType:buttonType toolbarType:myToolbarType];
    }
}

#pragma mark -

@synthesize hidden;

- (void) setHidden:(BOOL)flag {
    [self setHidden:flag animate:NO];
}

- (void) _setViewFrameForHiddenFlag:(BOOL)flag
{
    CGRect frame = self.view.frame;
    CGFloat x = (flag) ? -50 : 0;
    self.view.frame = CGRectMake(x, 0, 44, CGRectGetHeight(frame));
}

- (void) setHidden:(BOOL)flag animate:(BOOL)animate
{
    if (hidden != flag)
    {
        hidden = flag;
        
        if (animate) {
            self.view.hidden = NO;
            [UIView animateWithDuration:0.3
                             animations:^{
                                 [self _setViewFrameForHiddenFlag:flag];
                             }
                             completion:^(BOOL finished) {
                                 self.view.hidden = flag;
                             }];
        } else {
            self.view.hidden = flag;
            [self _setViewFrameForHiddenFlag:flag];
        }
    }
}

@end
