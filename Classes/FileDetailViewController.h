//
//  FileDetailViewController.h
//  Glint
//
//  Created by Jakob Borg on 8/2/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "JBGPXReader.h"
#import "JBLocationMath.h"
#import "GlintAppDelegate.h"

@interface FileDetailViewController : UIViewController <MFMailComposeViewControllerDelegate> {
        GlintAppDelegate *delegate;
        JBGPXReader *reader;
        JBLocationMath *math;

        UINavigationController *navigationController;
        UITableView *tableView;
        UITabBarItem *emailButton, *raceButton;
        NSArray *toolbarItems;

        NSString *filename, *startTime, *endTime, *distance, *averageSpeed;
}

@property (retain, nonatomic) IBOutlet UINavigationController *navigationController;
@property (retain, nonatomic) NSArray* toolbarItems;
@property (retain, nonatomic) IBOutlet UITableView *tableView;

- (void)loadFile:(NSString*)newFilename;
- (IBAction) sendFile:(id)sender;
- (IBAction) raceAgainstFile:(id)sender;

@end
