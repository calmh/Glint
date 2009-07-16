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

- (void)viewWillAppear:(BOOL)animated {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);	
        documentsDirectory = [paths objectAtIndex:0];
        [documentsDirectory retain];
        files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
        [files retain];
        [super viewWillAppear:animated];
}

- (IBAction) deleteFile:(id)sender {
        if ([tableView indexPathForSelectedRow]) {
                NSString *file = [files objectAtIndex:[tableView indexPathForSelectedRow].row];
                [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", documentsDirectory, file] error:nil];
                [files release];
                files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
                [files retain];
                [tableView reloadData];
        }
}

- (IBAction) sendFile:(id)sender {
        if ([tableView indexPathForSelectedRow]) {
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
                NSString *file = [files objectAtIndex:[tableView indexPathForSelectedRow].row];
                
                NSString *fullPath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, file];
                
                SKPSMTPMessage *message = [[SKPSMTPMessage alloc] init];
                message.fromEmail = USERPREF_EMAIL_ADDRESS;
                message.toEmail = USERPREF_EMAIL_ADDRESS;
                message.relayHost = @"acro.nym.se";
                message.requiresAuth = NO;
                message.subject = @"Recorded track from Glint";
                
                NSDictionary *plainPart = [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"text/plain", kSKPSMTPPartContentTypeKey,
                                           @"This message contains an attached GPX file that was recorded in Glint.", kSKPSMTPPartMessageKey,
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
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyIdentifier"];
        if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MyIdentifier"] autorelease];
        }
        cell.textLabel.text = [files objectAtIndex:indexPath.row];
        cell.detailTextLabel.text = @"A GPX file";
        return cell;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
        return [files count];
}

@end
