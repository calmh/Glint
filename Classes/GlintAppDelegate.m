//
//  GlintAppDelegate.m
//  Glint
//
//  Created by Jakob Borg on 6/26/09.
//  Copyright Jakob Borg 2009. All rights reserved.
//

#import "GlintAppDelegate.h"
#import "GlintViewController.h"

@implementation GlintAppDelegate

@synthesize window;
@synthesize viewController;
@synthesize sendFilesViewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
        
        double testValue = [[NSUserDefaults standardUserDefaults] doubleForKey:@"gps_minprec"];
        if (testValue == 0.0)
        {
                // no default values have been set, create them here based on what's in our Settings bundle info
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
                        if (keyValueStr && defaultValue)
                                [defaults setObject:defaultValue forKey:keyValueStr];
                }
                
                // since no default values have been set (i.e. no preferences file created), create it here        
                [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [defaults release];
        }
        
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
