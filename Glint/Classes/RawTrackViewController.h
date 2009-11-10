//
//  RawTrackViewController.h
//  Glint
//
//  Created by Jakob Borg on 11/4/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "GlintAppDelegate.h"
#import "LocationMath.h"
#import <UIKit/UIKit.h>

@interface RawTrackViewController : UITableViewController {
	NSArray *locations;
	GlintAppDelegate *delegate;
	NSDateFormatter *formatter;
	LocationMath *math;
}

@property (retain, nonatomic) NSArray *locations;

@end
