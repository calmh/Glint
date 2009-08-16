//
//  LapTimeViewController.h
//  Glint
//
//  Created by Jakob Borg on 8/15/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JBGradientLabel.h"
#import "GlintAppDelegate.h"

@interface LapTimeViewController : UITableViewController {
        NSMutableArray *times, *distances;
        GlintAppDelegate *delegate;
}

- (void)addLapTime:(float)seconds forDistance:(float)distance;

@end
