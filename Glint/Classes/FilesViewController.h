//
//  SendFilesViewController.h
//  Glint
//
//  Created by Jakob Borg on 7/16/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JBGPXReader.h"
#import "FileDetailViewController.h"
#import "GlintAppDelegate.h"

@interface FilesViewController : UITableViewController {
        GlintAppDelegate *delegate;
        NSMutableArray *files;
        NSMutableArray *sections;
        NSString *documentsDirectory;
        UINavigationController *navigationController;
        FileDetailViewController *detailViewController;
        UITableView *tableView;
        UIBarButtonItem *doneButton;
}

@property (retain, nonatomic) IBOutlet UINavigationController *navigationController;
@property (retain, nonatomic) IBOutlet UIViewController *detailViewController;
@property (retain, nonatomic) IBOutlet UITableView *tableView;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *doneButton;

- (IBAction) switchToGPSView:(id)sender;
- (void) refresh;

@end
