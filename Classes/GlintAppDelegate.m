//
//  GlintAppDelegate.m
//  Glint
//
//  Created by Jakob Borg on 6/26/09.
//  Copyright Jakob Borg 2009. All rights reserved.
//

#import "GlintAppDelegate.h"
#import "GlintViewController.h"
#import "SendFilesViewController.h"

@implementation GlintAppDelegate

@synthesize window;
@synthesize viewController;
@synthesize sendFilesViewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
        float testValue = [[NSUserDefaults standardUserDefaults] doubleForKey:@"gps_minprec"];
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
                        if (keyValueStr && defaultValue) {
                                [defaults setObject:defaultValue forKey:keyValueStr];
                                NSLog(@"Setting preference: %@=%@", keyValueStr, [defaultValue description]);
                        }
                }
                
                // since no default values have been set (i.e. no preferences file created), create it here        
                [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [defaults release];
        }
        
        // Override point for customization after app launch    
        [window addSubview:viewController.view];
        [window addSubview:sendFilesViewController.view];
        [window bringSubviewToFront:viewController.view];
        [window makeKeyAndVisible];
}

- (IBAction) switchToSendFilesView:(id)sender {
        [sendFilesViewController refresh];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1.2];
	[UIView setAnimationRepeatAutoreverses:NO];
        [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:window cache:YES];
        [window bringSubviewToFront:sendFilesViewController.view];
	[UIView commitAnimations];
}

- (IBAction) switchToGPSView:(id)sender {
        [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1.2];
	[UIView setAnimationRepeatAutoreverses:NO];
        [UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:window cache:YES];
        [window bringSubviewToFront:viewController.view];
	[UIView commitAnimations];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
}

- (void)dealloc {
        [viewController release];
        [window release];
        [super dealloc];
}


@end
