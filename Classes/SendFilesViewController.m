//
//  SendFilesViewController.m
//  Glint
//
//  Created by Jakob Borg on 7/16/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "SendFilesViewController.h"
#import "GlintAppDelegate.h"
#import "SKPSMTPMessage.h"
#import "NSData+Base64Additions.h"

@interface SendFilesViewController ()
- (int)sectionForFile:(NSString*)fileName;
- (NSString*)sectionDescriptionForFile:(NSString*)fileName;
- (NSString*)formatDistance:(float)distance;
- (NSString*)descriptionForFile:(NSString*)file;
- (NSString*)commentForFile:(NSString*)file;
@end

@implementation SendFilesViewController

@synthesize tableView, emailButton, raceButton, trashButton;

- (void)dealloc {
        [files release];
        [sections release];
        [documentsDirectory release];
        self.tableView = nil;
        [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
        emailButton.title = NSLocalizedString(@"Email",nil);
        raceButton.title = NSLocalizedString(@"Race against",nil);
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);	
        documentsDirectory = [paths objectAtIndex:0];
        [documentsDirectory retain];
        [super viewWillAppear:animated];
}

- (void) refresh {
        files = [[NSMutableArray alloc] init];
        sections = [[NSMutableArray alloc] init];
        
        NSArray* fileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
        fileList = [fileList sortedArrayUsingSelector:@selector(compare:)];
        NSEnumerator *enumer = [fileList reverseObjectEnumerator];

        NSString *fileName;
        while (fileName = [enumer nextObject]) {
                int section = [self sectionForFile:fileName];
                [[files objectAtIndex:section] addObject:fileName];
        }

        [tableView reloadData];
        emailButton.enabled = NO;
        raceButton.enabled = NO;
        trashButton.enabled = NO;
}

/*
 * IBActions
 */

- (IBAction) switchToGPSView:(id)sender {
        [(GlintAppDelegate *)[[UIApplication sharedApplication] delegate] switchToGPSView:sender];
}

- (IBAction) deleteFile:(id)sender {
        if ([tableView indexPathForSelectedRow]) {
                NSIndexPath *p = [tableView indexPathForSelectedRow];
                NSString *file = [[files objectAtIndex:p.section] objectAtIndex:p.row];
                [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", documentsDirectory, file] error:nil];
                [self refresh];
                emailButton.enabled = NO;
                raceButton.enabled = NO;
                trashButton.enabled = NO;
                //[tableView selectRowAtIndexPath:p animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
}

- (IBAction) sendFile:(id)sender {
        if ([tableView indexPathForSelectedRow]) {
                NSString *to = USERPREF_EMAIL_ADDRESS;
                if (!to || [to length] < 4) {
                        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Message failed",nil) message:NSLocalizedString(@"You need to enter a valid email address in Settings.", @"Lacking email address") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil] autorelease];
                        [alert show];
                        return;
                }

                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
                NSIndexPath *p = [tableView indexPathForSelectedRow];
                NSString *file = [[files objectAtIndex:p.section] objectAtIndex:p.row];                
                NSString *fullPath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, file];
                
                SKPSMTPMessage *message = [[SKPSMTPMessage alloc] init];
                message.fromEmail = @"glint@nym.se";
                message.toEmail = to;
                message.relayHost = @"mail1.perspektivbredband.se";
                message.requiresAuth = NO;
                message.subject = NSLocalizedString(@"Recorded track from Glint", @"Email subject");
                message.delegate = self;
                message.relayPorts = [NSArray arrayWithObject:[NSNumber numberWithInt:587]];
                
                NSDictionary *plainPart = [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"text/plain", kSKPSMTPPartContentTypeKey,
                                           NSLocalizedString(@"This message contains an attached GPX file that was recorded in Glint.", @"Email body"), kSKPSMTPPartMessageKey,
                                           @"8bit", kSKPSMTPPartContentTransferEncodingKey,
                                           nil];
                
                NSData *gpxData = [NSData dataWithContentsOfFile:fullPath];
                NSDictionary *gpxPart = [NSDictionary dictionaryWithObjectsAndKeys:
                                         @"text/xml", kSKPSMTPPartContentTypeKey,
                                         [NSString stringWithFormat:@"attachment;\r\n\tfilename=\"%@\"", file], kSKPSMTPPartContentDispositionKey,
                                         [gpxData encodeBase64ForData], kSKPSMTPPartMessageKey,
                                         @"base64", kSKPSMTPPartContentTransferEncodingKey,
                                         nil];
                
                message.parts = [NSArray arrayWithObjects:plainPart, gpxPart, nil];
                [message send];
        }
}

- (IBAction) raceAgainstFile:(id)sender {
        if ([tableView indexPathForSelectedRow]) {
                NSIndexPath *p = [tableView indexPathForSelectedRow];
                NSString *file = [[files objectAtIndex:p.section] objectAtIndex:p.row];
                NSString *fullPath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, file];
                JBGPXReader *reader = [[JBGPXReader alloc] initWithFilename:fullPath];
                [(GlintAppDelegate*) [[UIApplication sharedApplication] delegate] setRaceAgainstLocations:[reader locations]];
                [reader release];
                [[NSUserDefaults standardUserDefaults] setValue:file forKey:@"raceAgainstFile"];
                [self switchToGPSView:sender];
        }
}

/*
 * UITableViewDatasource stuff
 */

- (UITableViewCell *)tableView:(UITableView *)tView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GPXFileItem"];
        if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"GPXFileItem"] autorelease];
        }
        NSString *fileName = [[files objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        cell.textLabel.text = [self descriptionForFile:fileName];
        cell.detailTextLabel.text = [self commentForFile:fileName];
        return cell;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
        return [[files objectAtIndex:section] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
        return [sections count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
        return [sections objectAtIndex:section];
}

/*
 * SKSMTPMessage delegate stuff
 */

- (void)messageSent:(SKPSMTPMessage *)message
{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [message release];
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Message sent", @"Success dialog title") message:NSLocalizedString(@"The message was sent successfully.", @"Email success") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil] autorelease];
        [alert show];
}

- (void)messageFailed:(SKPSMTPMessage *)message error:(NSError *)error
{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [message release];
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Message failed", @"Error dialog title") message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil] autorelease];
        [alert show];
}

/*
 * Private stuff
 */

- (int)sectionForFile:(NSString*)fileName {
        NSString *descr = [self sectionDescriptionForFile:fileName];
        int i;
        for (i = 0; i < [sections count]; i++)
                if ([(NSString*) [sections objectAtIndex:i] compare:descr] == NSOrderedSame)
                        break;
        if (i < [sections count])
                return i;
        
        [sections addObject:descr];
        [files addObject:[NSMutableArray array]];
        return [sections count] - 1;
}

- (NSString*)sectionDescriptionForFile:(NSString*)fileName {
        NSDictionary *attrs = [[NSFileManager defaultManager] fileAttributesAtPath:[NSString stringWithFormat:@"%@/%@", documentsDirectory, fileName] traverseLink:NO];
        NSDate *created = [attrs objectForKey:NSFileModificationDate];
        NSDateComponents *createdComps = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekCalendarUnit | NSDayCalendarUnit fromDate:created];
        NSDateComponents *nowComps = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekCalendarUnit | NSDayCalendarUnit fromDate:[NSDate date]];
        if (createdComps.year == nowComps.year && createdComps.month == nowComps.month) {
                if (createdComps.week == nowComps.week) {
                        if (createdComps.day == nowComps.day)
                                return NSLocalizedString(@"Today",nil);
                        else if (createdComps.day == nowComps.day - 1)
                                return NSLocalizedString(@"Yesterday",nil);
                        else
                                return NSLocalizedString(@"This Week",nil);
                } else if (createdComps.week == nowComps.week - 1)
                        return NSLocalizedString(@"Last Week",nil);
                else
                        return NSLocalizedString(@"This Month",nil);
        } else
                return NSLocalizedString(@"Earlier",nil);
        
        NSString *descr = [created description];
        return descr;
}

- (NSString*)formatDistance:(float)distance {
        static float distFactor = 0.0;
        static NSString *distFormat = nil;
        if (!distFormat) {
                NSString *path=[[NSBundle mainBundle] pathForResource:@"unitsets" ofType:@"plist"];
                NSArray *unitSets = [NSArray arrayWithContentsOfFile:path];
                int unitsetIndex = USERPREF_UNITSET;
                NSDictionary* units = [unitSets objectAtIndex:unitsetIndex];
                distFactor = [[units objectForKey:@"distFactor"] floatValue];
                distFormat = [units objectForKey:@"distFormat"];
                [distFormat retain];
        }
        return [NSString stringWithFormat:distFormat, distance*distFactor];
}

- (NSString*)descriptionForFile:(NSString*)file {
        return file;
}

- (NSString*)commentForFile:(NSString*)file {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, file];
        NSString *fileContents = [NSString stringWithContentsOfFile:fullPath];
        float distance = 0.0;
        int numPoints = 0;
        
        NSRange rangeBegin = [fileContents rangeOfString:@"[totalDistance]"];
        NSRange rangeEnd = [fileContents rangeOfString:@"[/totalDistance]"];
        if (rangeBegin.length > 0)
        {
                NSRange matchRange;
                matchRange.location = rangeBegin.location + rangeBegin.length;
                matchRange.length = rangeEnd.location - rangeBegin.location;
                NSString *matched = [fileContents substringWithRange:matchRange];
                distance = [matched doubleValue];
        }
        
        rangeBegin = [fileContents rangeOfString:@"[numPoints]"];
        rangeEnd = [fileContents rangeOfString:@"[/numPoints]"];
        if (rangeBegin.length > 0)
        {
                NSRange matchRange;
                matchRange.location = rangeBegin.location + rangeBegin.length;
                matchRange.length = rangeEnd.location - rangeBegin.location;
                NSString *matched = [fileContents substringWithRange:matchRange];
                numPoints = [matched intValue];
        }
        
        return [NSString stringWithFormat:@"%@, %d points", [self formatDistance:distance], numPoints];
}

/*
 * UITableViewDelegate stuff
 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
        emailButton.enabled = YES;
        raceButton.enabled = YES;
        trashButton.enabled = YES;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
        emailButton.enabled = NO;
        raceButton.enabled = NO;
        trashButton.enabled = NO;
}

@end

