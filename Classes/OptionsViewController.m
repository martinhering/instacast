//
//  OptionsViewController.m
//  Instacast
//
//  Created by Martin Hering on 07.11.11.
//  Copyright (c) 2011 Vemedio. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import <StoreKit/StoreKit.h>

#import "ICManagedObjectContext.h"
#import "OptionsViewController.h"

#import "SubscriptionManager.h"
#import "TwitterHelper.h"
#import "UtilityFunctions.h"
#import "XPFF.h"
#import "VDModalInfo.h"
#import "FeedOptionsViewController.h"
#import "NotificationSettingsViewController.h"
#import "MediaFilesViewController.h"
#import "GeneralSettingsViewController.h"
#import "UITableViewController+Settings.h"


@interface OptionsViewController () <MFMailComposeViewControllerDelegate, UIDocumentInteractionControllerDelegate>
@property (nonatomic, strong) UIDocumentInteractionController* interactionController;
@end


enum {
    kOptionsSectionSettings,
    kOptionsSectionIO,
    kNumberOfSections
};


@implementation OptionsViewController


+ (OptionsViewController*) optionsViewController
{
    return [[self alloc] initWithStyle:UITableViewStyleGrouped];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.clearsSelectionOnViewWillAppear = YES;
    self.navigationItem.title = @"Settings".ls;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setScrollView:self.tableView contentInsets:UIEdgeInsetsZero byAdjustingForStandardBars:YES];
    
    self.tableView.backgroundColor = ICBackgroundColor;
    self.tableView.separatorColor = ICGroupCellSelectedBackgroundColor;
    
    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case kOptionsSectionSettings:
            return 4;
        case kOptionsSectionIO:
            return 2;
        default:
            break;
    }
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case kOptionsSectionSettings:
        {
            UITableViewCell* cell = [self detailCell];
            
            if (indexPath.row == 0) {
                cell.textLabel.text = @"General".ls;
                cell.detailTextLabel.text = nil;
            }
            else if (indexPath.row == 1)
            {
                cell.textLabel.text = @"Subscriptions".ls;
                cell.detailTextLabel.text = nil;
            }
            else if (indexPath.row == 2)
            {
                cell.textLabel.text = @"Notifications".ls;
                cell.detailTextLabel.text = nil;
            }
            else if (indexPath.row == 3)
            {
                cell.textLabel.text = @"Offline Storage".ls;
                cell.detailTextLabel.text = [NSByteCountFormatter stringFromByteCount:[[CacheManager sharedCacheManager] numberOfDownloadedBytes] countStyle:NSByteCountFormatterCountStyleMemory];
            }
            return cell;
        }

        case kOptionsSectionIO:
        { 
            UITableViewCell* cell = [self buttonCell];
            cell.detailTextLabel.text = nil;
            
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Export Data".ls;
                    break;
                case 1:
                    cell.textLabel.text = @"Send Data as Email".ls;
                    if (![MFMailComposeViewController canSendMail]) {
                        cell.textLabel.textColor = [UIColor colorWithWhite:0.7f alpha:1.f];
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    }
                    break;
                default:
                    break;
            }
            return cell;
        }
            
        default:
            break;
    }

    
    return nil;
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == kNumberOfSections-1) {
        return [NSString stringWithFormat:@"\nVersion %@ (%@)\n© Martin Hering 2011-2016.\nAll rights reserved.", [NSBundle appVersion], [NSBundle buildVersion]];
    }
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section)
    {
        case kOptionsSectionSettings:
        {
            if (indexPath.row == 0) {
                GeneralSettingsViewController* controller = [GeneralSettingsViewController viewController];
                [self.navigationController pushViewController:controller animated:YES];
            }
            else if (indexPath.row == 1) {
                FeedOptionsViewController* controller = [FeedOptionsViewController viewController];
                [self.navigationController pushViewController:controller animated:YES];
            }
            else if (indexPath.row == 2) {
                NotificationSettingsViewController* controller = [NotificationSettingsViewController viewController];
                [self.navigationController pushViewController:controller animated:YES];
            }
            else if (indexPath.row == 3) {
                MediaFilesViewController* controller = [MediaFilesViewController viewController];
                [self.navigationController pushViewController:controller animated:YES];
            }
            
            break;
        }

            
        case kOptionsSectionIO:
            switch (indexPath.row) {
                case 0:
                    [self exportToDropboxAction:nil];
                    break;
                case 1:
                    [self sendEmailAction:nil];
                    break;
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == kNumberOfSections-1) {
        return 100;
    }
    
    return 0.0f;
}

#pragma mark -

- (void) sendEmailAction:(id)sender
{
    if (![MFMailComposeViewController canSendMail]) {
        [self presentAlertControllerWithTitle:@"Email not configured.".ls
                                      message:@"Please configure email on this device.".ls
                                       button:@"OK".ls
                                     animated:YES
                                   completion:NULL];
        return;
    }
    
    NSString* deviceName = [UIDevice currentDevice].name;
    
    WEAK_SELF
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Export Data".ls
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Subscriptions".ls
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                [self perform:^(id sender) {

                                                    NSData* data = [[SubscriptionManager sharedSubscriptionManager] opmlData];
                                                    NSString* fileName = [NSString stringWithFormat:@"%@-%@.opml", @"Subscriptions".ls, deviceName];
                                                    
                                                    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
                                                    picker.mailComposeDelegate = self;
                                                    [picker setSubject:[NSString stringWithFormat:@"Instacast Subscriptions from %@".ls, deviceName]];
                                                    [picker addAttachmentData:data mimeType:@"text/x-opml" fileName:fileName];
                                                    [self presentViewController:picker animated:YES completion:NULL];

                                                    
                                                } afterDelay:0.3];
                                                self.alertController = nil;
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Bookmarks".ls
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                [self perform:^(id sender) {
                                                    
                                                    NSData* data = XPFFDataWithBookmarks(DMANAGER.bookmarks);
                                                    NSString* fileName = [NSString stringWithFormat:@"%@-%@.xpff", @"Bookmarks".ls, deviceName];
                                                    
                                                    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
                                                    picker.mailComposeDelegate = self;
                                                    [picker setSubject:[NSString stringWithFormat:@"Instacast Bookmarks from %@".ls, deviceName]];
                                                    [picker addAttachmentData:data mimeType:@"text/x-xpff" fileName:fileName];
                                                    [self presentViewController:picker animated:YES completion:NULL];

                                                } afterDelay:0.3];
                                                self.alertController = nil;
                                            }]];
   
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel".ls
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                self.alertController = nil;
                                            }]];
    
    self.alertController = alert;
    [self presentAlertControllerAnimated:YES completion:NULL];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:^{
    }];
	
	if (error) {
		[self presentError:error];
	}
}

- (void) exportToDropboxAction:(id)sender
{
    WEAK_SELF
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Export Data".ls
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Subscriptions".ls
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                [self perform:^(id sender) {
                                                    
                                                    NSData* data = [[SubscriptionManager sharedSubscriptionManager] opmlData];
                                                    
                                                    NSString* fileName = [NSString stringWithFormat:@"%@-%@.opml", @"Subscriptions".ls, [UIDevice currentDevice].name];
                                                    NSString* documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                                                    NSURL* url = [NSURL fileURLWithPath:[documentsDir stringByAppendingPathComponent:fileName]];
                                                    
                                                    [data writeToURL:url atomically:YES];
                                                    
                                                    self.interactionController = [UIDocumentInteractionController interactionControllerWithURL:url];
                                                    self.interactionController.delegate = self;
                                                    self.interactionController.name = fileName;
                                                    self.interactionController.UTI = @"instacast.opml";
                                                    if (![self.interactionController presentOpenInMenuFromRect:CGRectZero inView:self.navigationController.view animated:YES]) {
                                                        self.interactionController = nil;
                                                    }
                                                    
                                                } afterDelay:0.3];
                                                self.alertController = nil;
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Bookmarks".ls
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                [self perform:^(id sender) {
                                                    
                                                    NSData* data = XPFFDataWithBookmarks(DMANAGER.bookmarks);
                                                    
                                                    NSString* fileName = [NSString stringWithFormat:@"%@-%@.xpff", @"Bookmarks".ls, [UIDevice currentDevice].name];
                                                    NSString* documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                                                    NSURL* url = [NSURL fileURLWithPath:[documentsDir stringByAppendingPathComponent:fileName]];
                                                    
                                                    [data writeToURL:url atomically:YES];
                                                    
                                                    self.interactionController = [UIDocumentInteractionController interactionControllerWithURL:url];
                                                    self.interactionController.delegate = self;
                                                    self.interactionController.name = fileName;
                                                    self.interactionController.UTI = @"com.vemedio.xpff";
                                                    if (![self.interactionController presentOpenInMenuFromRect:CGRectZero inView:self.navigationController.view animated:YES]) {
                                                        self.interactionController = nil;
                                                    }

                                                    
                                                } afterDelay:0.3];
                                                self.alertController = nil;
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel".ls
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * action) {
                                                STRONG_SELF
                                                self.alertController = nil;
                                            }]];
    
    self.alertController = alert;
    [self presentAlertControllerAnimated:YES completion:NULL];
}


#pragma mark -

- (void) documentInteractionControllerDidDismissOpenInMenu: (UIDocumentInteractionController *) controller
{
    self.interactionController = nil;
}

@end
