//
//  FileDetailViewController.m
//  Glint
//
//  Created by Jakob Borg on 8/2/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "FileDetailViewController.h"

@interface FileDetailViewController ()

- (void)enableButtons;
- (void)disableButtons;

@end


@implementation FileDetailViewController

@synthesize navigationController, toolbarItems, tableView;

- (void)dealloc {
        [reader dealloc];
        [math dealloc];
        [super dealloc];
}

- (void)viewDidLoad {
        delegate = [[UIApplication sharedApplication] delegate];
        self.title = NSLocalizedString(@"File Details",nil);
        math = nil;
        reader = nil;
        filename = nil;
        startTime = nil;
        endTime = nil;
        distance = nil;
        averageSpeed = nil;
}

- (void)viewWillAppear:(BOOL)animated {
        emailButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Email",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(sendFile:)];
        raceButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Race against",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(raceAgainstFile:)];
        self.toolbarItems = [NSArray arrayWithObjects:emailButton, raceButton, nil];
        [self disableButtons];
        [navigationController setToolbarHidden:NO];
        [startTime release];
        startTime = NSLocalizedString(@"Loading...",nil);
        [endTime release];
        endTime = NSLocalizedString(@"Loading...",nil);
        [distance release];
        distance = NSLocalizedString(@"Loading...",nil);
        [averageSpeed release];
        averageSpeed = NSLocalizedString(@"Loading...",nil);
}

- (void)enableButtons {
        [emailButton setEnabled:YES];
        [raceButton setEnabled:YES];
}

- (void)disableButtons {
        [emailButton setEnabled:NO];
        [raceButton setEnabled:NO];
}

- (void)loadFile:(NSString*)newFilename {
        //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        debug_NSLog(@"Starting loadFile:");
        [filename release];
        filename = [newFilename retain];
        [tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];        
        
        self.navigationController.title = NSLocalizedString(@"File",nil);
        [reader release];
        [math release];
        reader = [[JBGPXReader alloc] initWithFilename:newFilename];
        math = [[JBLocationMath alloc] init];
        for (CLLocation *loc in [reader locations])
                [math updateLocation:loc];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        NSArray *dates = [math startAndFinishTimesInArray:[reader locations]];
        if ([dates count] == 2) {
                startTime = [formatter stringFromDate:[dates objectAtIndex:0]];
                [startTime retain];
                endTime = [formatter stringFromDate:[dates objectAtIndex:1]];
                [endTime retain];
        } else {
                startTime = @"-";
                endTime = @"-";
        }
        [formatter release];
        
        distance = [delegate formatDistance:[math totalDistance]];
        [distance retain];
        averageSpeed = [delegate formatSpeed:[math averageSpeed]];
        [averageSpeed retain];
        [tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];        
        [self performSelectorOnMainThread:@selector(enableButtons) withObject:nil waitUntilDone:YES];
        debug_NSLog(@"Finished loadFile:");
        //[pool release];
}

- (IBAction) sendFile:(id)sender {
        if (![MFMailComposeViewController canSendMail]) {
                UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Message failed",nil) message:NSLocalizedString(@"You need to configure a valid email account to send email.", @"Lacking email address") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil] autorelease];
                [alert show];
                return;
        }
        
        NSData *gpxData = [NSData dataWithContentsOfFile:filename];
        MFMailComposeViewController *mfmail = [[MFMailComposeViewController alloc] init];
        if (USERPREF_EMAIL_ADDRESS)
                [mfmail setToRecipients:[NSArray arrayWithObject:USERPREF_EMAIL_ADDRESS]];
        [mfmail setSubject:NSLocalizedString(@"Recorded track from Glint", @"Email subject")];
        [mfmail setMessageBody:NSLocalizedString(@"This message contains an attached GPX file that was recorded in Glint.", @"Email body") isHTML:NO];
        NSArray *fileParts = [filename componentsSeparatedByString:@"/"];
        [mfmail addAttachmentData:gpxData mimeType:@"text/xml" fileName:[fileParts objectAtIndex:[fileParts count] - 1]];
        [mfmail setMailComposeDelegate:self];
        [self presentModalViewController:mfmail animated:YES];
}

- (IBAction) raceAgainstFile:(id)sender {
        [(GlintAppDelegate*) [[UIApplication sharedApplication] delegate] setRaceAgainstLocations:[reader locations]];
        [[NSUserDefaults standardUserDefaults] setValue:filename forKey:@"raceAgainstFile"];
        [delegate switchToGPSView:sender];
        [navigationController popViewControllerAnimated:NO];
}

/*
 * MFMailComposerViewController delegate stuff
 */

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error {
        [self dismissModalViewControllerAnimated:YES];
        if (error) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Message failed",nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
                [alertView autorelease];
                [alertView show];
        }
}

/*
 * UITableViewDatasource stuff
 */

- (UITableViewCell *)tableView:(UITableView *)tView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FileDetailItem"];
        if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"FileDetailItem"] autorelease];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        NSArray *fileParts;
        switch (indexPath.row) {
                case 0:
                        fileParts = [filename componentsSeparatedByString:@"/"];
                        cell.textLabel.text = NSLocalizedString(@"File Name",nil);
                        cell.detailTextLabel.text = [[fileParts objectAtIndex:[fileParts count] - 1] stringByDeletingPathExtension];
                        break;
                case 1:
                        cell.textLabel.text = NSLocalizedString(@"Start Time",nil);
                                cell.detailTextLabel.text = startTime;
                        break;
                case 2:
                        cell.textLabel.text = NSLocalizedString(@"End Time",nil);
                                cell.detailTextLabel.text = endTime;
                        break;
                case 3:
                        cell.textLabel.text = NSLocalizedString(@"Total Distance",nil);
                        cell.detailTextLabel.text = distance;
                        break;
                case 4:
                        cell.textLabel.text = NSLocalizedString(@"Average Speed",nil);
                        cell.detailTextLabel.text = averageSpeed;
                        break;
                default:
                        cell.textLabel.text = @"What?";
                        cell.detailTextLabel.text =@"No!";
                        break;
        }
        return cell;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
        return 5;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
        return 1;
}

/*
 - (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
 return [sections objectAtIndex:section];
 }
 */

@end
