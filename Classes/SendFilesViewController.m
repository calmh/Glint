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

@implementation SendFilesViewController

@synthesize tableView;

- (void)dealloc {
        [files release];
        [documentsDirectory release];
        self.tableView = nil;
        [super dealloc];
}

- (IBAction) switchToGPSView:(id)sender {
        [(GlintAppDelegate *)[[UIApplication sharedApplication] delegate] switchToGPSView:sender];
}

- (void) refresh {
        files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
        [files retain];
        [tableView reloadData];

}

- (void)viewWillAppear:(BOOL)animated {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);	
        documentsDirectory = [paths objectAtIndex:0];
        [documentsDirectory retain];
        [super viewWillAppear:animated];
}

- (NSString*)formatDistance:(double)distance {
        static double distFactor = 0.0;
        static NSString *distFormat = nil;
        if (!distFormat) {
                NSString *path=[[NSBundle mainBundle] pathForResource:@"unitsets" ofType:@"plist"];
                NSArray *unitSets = [NSArray arrayWithContentsOfFile:path];
                int unitsetIndex = USERPREF_UNITSET;
                NSDictionary* units = [unitSets objectAtIndex:unitsetIndex];
                distFactor = [[units objectForKey:@"distFactor"] floatValue];
                distFormat = [units objectForKey:@"distFormat"];
        }
        return [NSString stringWithFormat:distFormat, distance*distFactor];
}

- (NSString*)descriptionForFile:(NSString*)file {
        return file;
}

- (NSString*)commentForFile:(NSString*)file {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, file];
        NSString *fileContents = [NSString stringWithContentsOfFile:fullPath];
        double distance = 0.0;
        int numPoints = 0;
        
        NSRange rangeBegin = [fileContents rangeOfString:@"totalDistance:"];
        if (rangeBegin.length > 0)
        {
                rangeBegin.location += rangeBegin.length;
                rangeBegin.length = [fileContents length] - rangeBegin.location;
                NSRange range = [fileContents rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"01234567890."] options:kNilOptions range:rangeBegin];
                distance = [[fileContents substringWithRange:range] doubleValue];
        }

        rangeBegin = [fileContents rangeOfString:@"numPoints:"];
        if (rangeBegin.length > 0)
        {
                rangeBegin.location += rangeBegin.length;
                rangeBegin.length = [fileContents length] - rangeBegin.location;
                NSRange range = [fileContents rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"01234567890"] options:kNilOptions range:rangeBegin];
                numPoints = [[fileContents substringWithRange:range] intValue];
        }
        
        return [NSString stringWithFormat:@"%@, %d points", [self formatDistance:distance], numPoints];
}

- (IBAction) deleteFile:(id)sender {
        if ([tableView indexPathForSelectedRow]) {
                NSIndexPath *p = [tableView indexPathForSelectedRow];
                NSString *file = [files objectAtIndex:[tableView indexPathForSelectedRow].row];
                [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", documentsDirectory, file] error:nil];
                [self refresh];
                [tableView selectRowAtIndexPath:p animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
}

- (IBAction) sendFile:(id)sender {
        if ([tableView indexPathForSelectedRow]) {
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
                NSString *to = USERPREF_EMAIL_ADDRESS;
                if (!to || [to length] < 4) {
                        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Message failed",nil) message:NSLocalizedString(@"You need to enter a valid email address in Settings.", @"Lacking email address") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil] autorelease];
                        [alert show];
                        return;
                }
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
                NSString *file = [files objectAtIndex:[tableView indexPathForSelectedRow].row];
                
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

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyIdentifier"];
        if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MyIdentifier"] autorelease];
        }
        cell.textLabel.text = [self descriptionForFile:[files objectAtIndex:indexPath.row]];
        cell.detailTextLabel.text = [self commentForFile:[files objectAtIndex:indexPath.row]];
        return cell;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
        return [files count];
}

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

@end
