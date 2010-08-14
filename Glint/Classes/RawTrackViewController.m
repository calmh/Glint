//
//  RawTrackViewController.m
//  Glint
//
//  Created by Jakob Borg on 11/4/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "RawTrackViewController.h"


@implementation RawTrackViewController

@synthesize locations;

- (void)dealloc
{
	self.locations = nil;
	[formatter release];
	[math release];
	[super dealloc];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	delegate = [[UIApplication sharedApplication] delegate];
	formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	math = [[LocationMath alloc] init];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	self.locations = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	[(UITableView*) self.view reloadData];
	[(UITableView*) self.view scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	if (locations)
		return locations.count;
	else
		return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	static NSString *CellIdentifier = @"PositionCell";

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		cell.textLabel.font = [UIFont fontWithName:cell.textLabel.font.fontName size:14.0f];
	}

	CLLocation *loc = [locations objectAtIndex:indexPath.row];
	if ([LocationMath isBreakMarker:loc]) {
		cell.textLabel.text = NSLocalizedString(@"Break in recording",nil);
		cell.detailTextLabel.text = NSLocalizedString(@"Paused or lost GPS reception",nil);
	} else {
		cell.textLabel.text = [NSString stringWithFormat:@"%@; %@; %@", [delegate formatLat:loc.coordinate.latitude], [delegate formatLon:loc.coordinate.longitude], [delegate formatShortDistance:loc.altitude]];

		if (indexPath.row == 0 || [LocationMath isBreakMarker:[locations objectAtIndex:indexPath.row - 1]])
			cell.detailTextLabel.text = [NSString stringWithFormat:@"#%d; %@", indexPath.row + 1, [formatter stringFromDate:loc.timestamp]];
		else {
			CLLocation *prev_loc = [locations objectAtIndex:indexPath.row - 1];
			cell.detailTextLabel.text = [NSString stringWithFormat:@"#%d; %@; %@; %.0f°", indexPath.row + 1, [formatter stringFromDate:loc.timestamp], [delegate formatShortDistance:[loc distanceFromLocation:prev_loc]], [math bearingFromLocation:prev_loc toLocation:loc]];
		}
	}

	return cell;
}

@end
