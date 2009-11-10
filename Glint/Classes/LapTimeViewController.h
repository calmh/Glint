//
//  LapTimeViewController.h
//  Glint
//
//  Created by Jakob Borg on 8/15/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "GlintAppDelegate.h"
#import "GradientLabel.h"
#import <UIKit/UIKit.h>

@interface LapTimeViewController : UITableViewController {
	NSMutableArray *times, *distances;
	GlintAppDelegate *delegate;
}

- (void)addLapTime:(float)seconds forDistance:(float)distance;
- (void)clear;
- (int)numberOfLapTimes;

@end

#define FONTSIZE 28.0f
