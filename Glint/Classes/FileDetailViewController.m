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

@synthesize navigationController, toolbarItems, tableView, lapTimeController, routeController, rawTrackController;

- (void)dealloc
{
	[reader dealloc];
	[math dealloc];
	[super dealloc];
}

- (void)awakeFromNib
{
	debug_NSLog(@"FileDetailViewController.awakeFromNib start");
	delegate = [[UIApplication sharedApplication] delegate];
	self.title = NSLocalizedString(@"File Details",nil);
	math = nil;
	reader = nil;
	filename = nil;
	startTime = nil;
	endTime = nil;
	distance = nil;
	averageSpeed = nil;
	emailButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Email",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(sendFile:)];
	raceButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Race against",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(raceAgainstFile:)];
	[self disableButtons];
	self.toolbarItems = [NSArray arrayWithObjects:emailButton, raceButton, nil];
	debug_NSLog(@"FileDetailViewController.awakeFromNib end");
}

- (void)viewWillAppear:(BOOL)animated
{
	debug_NSLog(@"FileDetailViewController.viewWillAppear start");
	navigationController.navigationBar.barStyle = UIBarStyleDefault;
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
	[navigationController setToolbarHidden:NO];
	debug_NSLog(@"FileDetailViewController.viewWillAppear end");
}

- (void)enableButtons
{
	[emailButton setEnabled:YES];
	[raceButton setEnabled:YES];
}

- (void)disableButtons
{
	[emailButton setEnabled:NO];
	[raceButton setEnabled:NO];
}

- (void)prepareForLoad:(NSString*)newFilename
{
	debug_NSLog(@"FileDetailViewController.prepareForLoad start");
	loading = YES;
	[self disableButtons];
	[filename release];
	filename = [newFilename retain];
	[startTime release];
	startTime = NSLocalizedString(@"Loading...",nil);
	[endTime release];
	endTime = NSLocalizedString(@"Loading...",nil);
	[distance release];
	distance = NSLocalizedString(@"Loading...",nil);
	[averageSpeed release];
	averageSpeed = NSLocalizedString(@"Loading...",nil);

	[tableView reloadData];
	debug_NSLog(@"FileDetailViewController.prepareForLoad end");
}

- (void)loadFile:(NSString*)newFilename
{
	debug_NSLog(@"FileDetailViewController.loadFile start");
	self.navigationController.title = NSLocalizedString(@"File",nil);
	[reader release];
	[math release];
	reader = [[JBGPXReader alloc] initWithFilename:newFilename];
	math = [[reader locationMath] retain];

	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
	NSArray *dates = [math startAndFinishTimesInArray:[reader locations]];
	if ([dates count] == 2) {
		startTime = [formatter stringFromDate:[dates objectAtIndex:0]];
		[startTime retain];
	} else
		startTime = @"-";
	[formatter release];

	endTime = [delegate formatTimestamp:[math elapsedTime] maxTime:86400.0f allowNegatives:NO];
	[endTime retain];
	distance = [delegate formatDistance:[math totalDistance]];
	[distance retain];
	averageSpeed = [delegate formatSpeed:[math averageSpeed]];
	[averageSpeed retain];
	loading = NO;

	[tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
	[self performSelectorOnMainThread:@selector(enableButtons) withObject:nil waitUntilDone:YES];
	debug_NSLog(@"FileDetailViewController.loadFile end");
}

- (IBAction)sendFile:(id)sender
{
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

- (IBAction)raceAgainstFile:(id)sender
{
	NSArray *raceLocs = [reader locations];
	[(GlintAppDelegate*) [[UIApplication sharedApplication] delegate] setRaceAgainstLocations:raceLocs];
	[[NSUserDefaults standardUserDefaults] setValue:filename forKey:@"raceAgainstFile"];
	[delegate switchToGPSView:sender];
	[navigationController popViewControllerAnimated:NO];
}

- (void)viewLapTimes
{
	[lapTimeController clear];
	float lap = USERPREF_LAPLENGTH;
	float dist = lap;
	float prevLapTime = 0.0f;
	float lapTime;
	while ((lapTime = [math timeAtLocationByDistance:dist]) && !isnan(lapTime)) {
		[lapTimeController addLapTime:lapTime - prevLapTime forDistance:dist];
		prevLapTime = lapTime;
		dist += lap;
	}

	[navigationController setToolbarHidden:YES];
	navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
	[navigationController pushViewController:lapTimeController animated:YES];
}

- (void)viewOnMap
{
	[routeController setLocations:[math interpolatedLocations]];
	[navigationController setToolbarHidden:YES];
	//navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
	//[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
	[navigationController pushViewController:routeController animated:YES];
}

- (void)viewRawPositions
{
	[rawTrackController setLocations:[reader locations]];
	[navigationController setToolbarHidden:YES];
	//navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
	//[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
	[navigationController pushViewController:rawTrackController animated:YES];
}

/*
 * MFMailComposerViewController delegate stuff
 */

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
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

- (UITableViewCell*)tableView:(UITableView*)tView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FileDetailItem"];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"FileDetailItem"] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}

	NSString *shortFilename;
	NSArray *fileParts;
	switch (indexPath.row + 5 * indexPath.section) {
	case 0:
		fileParts = [filename componentsSeparatedByString:@"/"];
		shortFilename = [[fileParts objectAtIndex:[fileParts count] - 1] stringByDeletingPathExtension];
		cell.textLabel.text = NSLocalizedString(@"File Name",nil);
		cell.detailTextLabel.text = shortFilename;
		break;
	case 1:
		cell.textLabel.text = NSLocalizedString(@"Start Time",nil);
		cell.detailTextLabel.text = startTime;
		break;
	case 2:
		cell.textLabel.text = NSLocalizedString(@"Elapsed Time",nil);
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
	case 5:
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DisclosureItem"] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		cell.textLabel.text = NSLocalizedString(@"Lap Times",nil);
		break;
	case 6:
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DisclosureItem"] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		cell.textLabel.text = NSLocalizedString(@"View On Map",nil);
		break;
	case 7:
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DisclosureItem"] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		cell.textLabel.text = NSLocalizedString(@"View Raw Data",nil);
		break;
	default:
		cell.textLabel.text = @"What?";
		cell.detailTextLabel.text = @"No!";
		break;
	}
	return cell;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0)
		return 5;
	else if (section == 1 && !loading)
		return 3;
	else
		return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	if (!loading)
		return 2;
	else
		return 1;
}

- (void)tableView:(UITableView*)etableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	[etableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 1 && indexPath.row == 0)
		[self viewLapTimes];
	else if (indexPath.section == 1 && indexPath.row == 1)
		[self viewOnMap];
	else if (indexPath.section == 1 && indexPath.row == 2)
		[self viewRawPositions];
}

/*
   - (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
   return [sections objectAtIndex:section];
   }
 */

@end
