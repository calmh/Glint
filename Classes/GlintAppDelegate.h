//
//  GlintAppDelegate.h
//  Glint
//
//  Created by Jakob Borg on 6/26/09.
//  Copyright Jakob Borg 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MainScreenViewController;
@class FilesViewController;

@interface GlintAppDelegate : NSObject <UIApplicationDelegate> {
        UIWindow *window;
        MainScreenViewController *mainScreenViewController;
        FilesViewController *sendFilesViewController;
        UINavigationController *navController;
        NSOperationQueue *queue;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MainScreenViewController *mainScreenViewController;
@property (nonatomic, retain) IBOutlet FilesViewController *sendFilesViewController;
@property (nonatomic, retain) IBOutlet UINavigationController *navController;
@property (nonatomic, retain) NSOperationQueue *queue;

- (IBAction) switchToSendFilesView:(id)sender;
- (IBAction) switchToGPSView:(id)sender;
- (void)setRaceAgainstLocations:(NSArray*)locations;
- (NSString*)formatTimestamp:(float)seconds maxTime:(float)max allowNegatives:(bool)allowNegatives;
- (NSString*) formatDMS:(float)latLong;
- (NSString*)formatLat:(float)lat;
- (NSString*)formatLon:(float)lon;
- (NSString*)formatDistance:(float)distance;
- (NSString*)formatSpeed:(float)speed;

@end

