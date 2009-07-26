//
//  SendFilesViewController.h
//  Glint
//
//  Created by Jakob Borg on 7/16/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "JBGPXReader.h"

@interface SendFilesViewController : UIViewController <MFMailComposeViewControllerDelegate> {
        NSMutableArray *files;
        NSMutableArray *sections;
        NSString *documentsDirectory;
        UITableView *tableView;
        UIBarButtonItem *emailButton, *raceButton, *trashButton;
}

@property (retain, nonatomic) IBOutlet UITableView *tableView;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *emailButton;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *raceButton;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *trashButton;

- (IBAction) switchToGPSView:(id)sender;
- (IBAction) deleteFile:(id)sender;
- (IBAction) sendFile:(id)sender;
- (IBAction) raceAgainstFile:(id)sender;
- (void) refresh;

@end
