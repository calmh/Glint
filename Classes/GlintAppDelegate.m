//
//  GlintAppDelegate.m
//  Glint
//
//  Created by Jakob Borg on 6/26/09.
//  Copyright Jakob Borg 2009. All rights reserved.
//

#import "GlintAppDelegate.h"
#import "MainScreenViewController.h"
#import "FilesViewController.h"

@implementation GlintAppDelegate

@synthesize window;
@synthesize mainScreenViewController;
@synthesize sendFilesViewController;
@synthesize navController;

- (void)dealloc {
        [window release];
        [mainScreenViewController release];
        [sendFilesViewController release];
        [super dealloc];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
        // Check if there are any preferences set, and if not, load the defaults.
        float testValue = [[NSUserDefaults standardUserDefaults] doubleForKey:@"gps_minprec"];
        if (testValue == 0.0)
        {
                NSString *pathStr = [[NSBundle mainBundle] bundlePath];
                NSString *settingsBundlePath = [pathStr stringByAppendingPathComponent:@"Settings.bundle"];
                NSString *finalPath = [settingsBundlePath stringByAppendingPathComponent:@"Root.plist"];
                
                NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfFile:finalPath];
                NSArray *prefSpecifierArray = [settingsDict objectForKey:@"PreferenceSpecifiers"];
                
                NSMutableDictionary *defaults = [[NSMutableDictionary alloc] init];
                for (NSDictionary *prefItem in prefSpecifierArray)
                {
                        NSString *keyValueStr = [prefItem objectForKey:@"Key"];
                        id defaultValue = [prefItem objectForKey:@"DefaultValue"];
                        if (keyValueStr && defaultValue) {
                                [defaults setObject:defaultValue forKey:keyValueStr];
                                debug_NSLog(@"Setting preference: %@=%@", keyValueStr, [defaultValue description]);
                        }
                }
                
                [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [defaults release];
        }
        
        [window addSubview:mainScreenViewController.view];
//        [window addSubview:sendFilesViewController.view];
        [window addSubview:navController.view];
        [window bringSubviewToFront:mainScreenViewController.view];
        [window makeKeyAndVisible];

        // TODO: Load this in background instead
        NSString *raceAgainstFile;
        if (raceAgainstFile = [[NSUserDefaults standardUserDefaults] stringForKey:@"raceAgainstFile"]) {
                /*NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);	
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString *fullPath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, raceAgainstFile];*/
                JBGPXReader *reader = [[JBGPXReader alloc] initWithFilename:raceAgainstFile];
                [mainScreenViewController setRaceAgainstLocations:[reader locations]];
                [reader release];
        }
}

- (void)applicationWillTerminate:(UIApplication *)application {
        [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction) switchToSendFilesView:(id)sender {
        [sendFilesViewController refresh];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1.2];
	[UIView setAnimationRepeatAutoreverses:NO];
        [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:window cache:YES];
        [window bringSubviewToFront:navController.view];
	[UIView commitAnimations];
}

- (IBAction) switchToGPSView:(id)sender {
        [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1.2];
	[UIView setAnimationRepeatAutoreverses:NO];
        [UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:window cache:YES];
        [window bringSubviewToFront:mainScreenViewController.view];
	[UIView commitAnimations];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
}

- (void)setRaceAgainstLocations:(NSArray*)locations {
        [[self mainScreenViewController] setRaceAgainstLocations:locations];
}

// Global formatting functions

- (NSString*)formatTimestamp:(float)seconds maxTime:(float)max allowNegatives:(bool)allowNegatives {
        bool negative = NO;
        if (isnan(seconds) || seconds > max || !allowNegatives && seconds < 0)
                return [NSString stringWithFormat:@"?"];
        else {
                if (seconds < 0) {
                        seconds = -seconds;
                        negative = YES;
                }
                int isec = (int) seconds;
                int hour = (int) (isec / 3600);
                int min = (int) ((isec % 3600) / 60);
                int sec = (int) (isec % 60);
                if (hour == 0) {
                if (allowNegatives && !negative)
                        return [NSString stringWithFormat:@"+%02d:%02d", min, sec];
                else if (negative)
                        return [NSString stringWithFormat:@"-%02d:%02d", min, sec];
                else
                        return [NSString stringWithFormat:@"%02d:%02d", min, sec];
                } else {
                        if (allowNegatives && !negative)
                                return [NSString stringWithFormat:@"+%02d:%02d:%02d", hour, min, sec];
                        else if (negative)
                                return [NSString stringWithFormat:@"-%02d:%02d:%02d", hour, min, sec];
                        else
                                return [NSString stringWithFormat:@"%02d:%02d:%02d", hour, min, sec];
                }
        }
}

- (NSString*) formatDMS:(float)latLong {
        int deg = (int) latLong;
        int min = (int) ((latLong - deg) * 60);
        float sec = (float) ((latLong - deg - min / 60.0) * 3600.0);
        return [NSString stringWithFormat:@"%02d° %02d' %02.02f\"", deg, min, sec];
}

- (NSString*)formatLat:(float)lat {
        NSString* sign = lat >= 0 ? @"N" : @"S";
        lat = fabs(lat);
        return [NSString stringWithFormat:@"%@ %@", [self formatDMS:lat], sign]; 
}

- (NSString*)formatLon:(float)lon {
        NSString* sign = lon >= 0 ? @"E" : @"W";
        lon = fabs(lon);
        return [NSString stringWithFormat:@"%@ %@", [self formatDMS:lon], sign]; 
}

- (NSDictionary *) currentUnitset {
  NSString *path=[[NSBundle mainBundle] pathForResource:@"unitsets" ofType:@"plist"];
                NSArray *unitSets = [NSArray arrayWithContentsOfFile:path];
                NSDictionary* units = [unitSets objectAtIndex:USERPREF_UNITSET];
  return units;
}

- (NSString*)formatDistance:(float)distance {
        static float distFactor = 0;
        static NSString* distFormat = nil;
        
        if (distFormat == nil) {
                NSDictionary *units = [self currentUnitset];
                distFactor = [[units objectForKey:@"distFactor"] floatValue];
                distFormat = [units objectForKey:@"distFormat"];
                [distFormat retain];
        }
 
        return [NSString stringWithFormat:distFormat, distance*distFactor];
}

- (NSString*)formatSpeed:(float)speed {
        static float speedFactor = 0;
        static NSString* speedFormat = nil;
        
        if (speedFormat == nil) {
                NSDictionary *units = [self currentUnitset];
                speedFactor = [[units objectForKey:@"speedFactor"] floatValue];
                speedFormat = [units objectForKey:@"speedFormat"];
                [speedFormat retain];
        }

        return [NSString stringWithFormat:speedFormat, speed*speedFactor];
}

@end
