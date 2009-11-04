//
//  RawTrackViewController.h
//  Glint
//
//  Created by Jakob Borg on 11/4/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GlintAppDelegate.h"
#import "JBLocationMath.h"

@interface RawTrackViewController : UITableViewController {
	NSArray *locations;
	GlintAppDelegate *delegate;
	NSDateFormatter *formatter;
	JBLocationMath *math;
}

@property (retain, nonatomic) NSArray *locations;

@end