//
//  GlintAppDelegate.h
//  Glint
//
//  Created by Jakob Borg on 6/26/09.
//  Copyright Jakob Borg 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GlintViewController;
@class SendFilesViewController;

@interface GlintAppDelegate : NSObject <UIApplicationDelegate> {
        UIWindow *window;
        GlintViewController *viewController;
        SendFilesViewController *sendFilesViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet GlintViewController *viewController;
@property (nonatomic, retain) IBOutlet SendFilesViewController *sendFilesViewController;

- (IBAction) switchToSendFilesView:(id)sender;
- (IBAction) switchToGPSView:(id)sender;

@end

