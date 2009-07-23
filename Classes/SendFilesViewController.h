//
//  SendFilesViewController.h
//  Glint
//
//  Created by Jakob Borg on 7/16/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SKPSMTPMessage.h"

@interface SendFilesViewController : UIViewController <SKPSMTPMessageDelegate> {
        NSMutableArray *files;
        NSMutableArray *sections;
        NSString *documentsDirectory;
        UITableView *tableView;
}

@property (retain, nonatomic) IBOutlet UITableView *tableView;

- (IBAction) switchToGPSView:(id)sender;
- (IBAction) deleteFile:(id)sender;
- (IBAction) sendFile:(id)sender;
- (void) refresh;

@end
