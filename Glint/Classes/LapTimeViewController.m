//
//  LapTimeViewController.m
//  Glint
//
//  Created by Jakob Borg on 8/15/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "LapTimeViewController.h"

@interface LapTimeViewController (Private)
- (UITableViewCell*)getInstructionsCell;
- (UITableViewCell*)getInformationCellWithIdentifier:(NSString*)CellIdentifier inTableView:(UITableView*)tableView withPadding:(float)padding;
- (void)setInformationCellValues:(NSIndexPath*)indexPath cell:(UITableViewCell*)cell;
- (void)setInformationCellAbsoluteValues:(UITableViewCell*)cell distance:(float)distance lapTime:(float)lapTime;
- (void)setInformationCellDeltaValues:(UITableViewCell*)cell lapTime:(float)lapTime difference:(float)difference indexPath:(NSIndexPath*)indexPath;
@end


@implementation LapTimeViewController

- (void)dealloc
{
	[times release];
	[distances release];
	[super dealloc];
}

- (void)addLapTime:(float)seconds forDistance:(float)distance
{
	[times addObject:[NSNumber numberWithFloat:seconds]];
	[distances addObject:[NSNumber numberWithFloat:distance]];
	[self.tableView reloadData];
	unsigned int index[] = { 0, [times count] - 1 };
	NSIndexPath *path = [[[NSIndexPath alloc] initWithIndexes:index length:2] autorelease];
	[self.tableView selectRowAtIndexPath:path animated:YES scrollPosition:UITableViewScrollPositionBottom];
}

- (void)clear
{
	[times release];
	[distances release];
	times = [[NSMutableArray alloc] init];
	distances = [[NSMutableArray alloc] init];
	[(UITableView*)self.view reloadData];
}

- (int)numberOfLapTimes
{
	return [times count];
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	delegate = [[UIApplication sharedApplication] delegate];
	self.title = NSLocalizedString(@"Lap Times",nil);
	[self clear];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	if ([times count] > 0)
		return [times count];
	else
		return 1;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	const float maxWidth = 270.f;
	float padding = 0.0f;
	if (tableView.frame.size.width > maxWidth)
		padding = (tableView.frame.size.width - maxWidth) / 2.0f;

	if ([times count] > 0) {
		static NSString *CellIdentifier = @"Cell";
		UITableViewCell *cell = [self getInformationCellWithIdentifier:CellIdentifier inTableView:tableView withPadding:padding];
		[self setInformationCellValues:indexPath cell:cell];
		return cell;
	} else
		return [self getInstructionsCell];
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
	if ([times count] == 0) // Instructions
		return 300.0f;
	else // Normal cell
		return FONTSIZE + 3.0f;
}

/*
 * Private methods
 */

- (UITableViewCell*)getInstructionsCell
{
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"InstructionsCell"] autorelease];
	cell.textLabel.text = NSLocalizedString(@"NoLapTimesInstructions",nil);
	cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
	cell.textLabel.textAlignment = UITextAlignmentCenter;
	cell.textLabel.numberOfLines = 0;
	cell.textLabel.textColor = [UIColor lightTextColor];
	return cell;
}

- (UITableViewCell*)getInformationCellWithIdentifier:(NSString*)CellIdentifier inTableView:(UITableView*)tableView withPadding:(float)padding
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		[cell.textLabel removeFromSuperview];
		[cell.detailTextLabel removeFromSuperview];
		[cell.imageView removeFromSuperview];

		GradientLabel *newLabel;
		newLabel = [[[GradientLabel alloc] initWithFrame:CGRectMake(padding + 0.0f, 5.0f, 80.0f, FONTSIZE)] autorelease];
		newLabel.font = [UIFont fontWithName:@"Helvetica" size:FONTSIZE];
		newLabel.backgroundColor = [UIColor blackColor];
		newLabel.textColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
		newLabel.textAlignment = UITextAlignmentRight;
		[cell.contentView addSubview:newLabel];

		newLabel = [[[GradientLabel alloc] initWithFrame:CGRectMake(padding + 90.0f, 5.0f, 85.0f, FONTSIZE)] autorelease];
		newLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:FONTSIZE];
		newLabel.backgroundColor = [UIColor blackColor];
		newLabel.textColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
		newLabel.textAlignment = UITextAlignmentRight;
		[cell.contentView addSubview:newLabel];

		newLabel = [[[GradientLabel alloc] initWithFrame:CGRectMake(padding + 185.0f, 5.0f, 85.0f, FONTSIZE)] autorelease];
		newLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:FONTSIZE];
		newLabel.backgroundColor = [UIColor blackColor];
		newLabel.textColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
		newLabel.textAlignment = UITextAlignmentRight;
		[cell.contentView addSubview:newLabel];
	}
	return cell;
}

- (void)setInformationCellValues:(NSIndexPath*)indexPath cell:(UITableViewCell*)cell
{
	float lapTime = [[times objectAtIndex:indexPath.row] floatValue];
	float distance = [[distances objectAtIndex:indexPath.row] floatValue];
	float difference = 0.0f;
	if (indexPath.row > 0)
		difference = lapTime - [[times objectAtIndex:indexPath.row - 1] floatValue];

	[self setInformationCellAbsoluteValues:cell distance:distance lapTime:lapTime];
	[self setInformationCellDeltaValues:cell lapTime:lapTime difference:difference indexPath:indexPath];
}

- (void)setInformationCellAbsoluteValues:(UITableViewCell*)cell distance:(float)distance lapTime:(float)lapTime
{
	((GradientLabel*) [cell.contentView.subviews objectAtIndex:0]).text = [delegate formatDistance:distance];
	((GradientLabel*) [cell.contentView.subviews objectAtIndex:1]).text = [delegate formatTimestamp:lapTime maxTime:86400 allowNegatives:NO];
}

- (void)setInformationCellDeltaValues:(UITableViewCell*)cell lapTime:(float)lapTime difference:(float)difference indexPath:(NSIndexPath*)indexPath
{
	if (indexPath.row > 0) {
		NSString *plusOrMinus = [delegate formatTimestamp:difference maxTime:86400 allowNegatives:YES];
		debug_NSLog(@"Lap time delta: %@", plusOrMinus);
		((GradientLabel*) [cell.contentView.subviews objectAtIndex:2]).text = plusOrMinus;
		if (difference > lapTime * 0.05) // Highlight differences of at least 10%, positive and negative
			((GradientLabel*) [cell.contentView.subviews objectAtIndex:2]).textColor = [UIColor colorWithRed:1.0f green:0.5f blue:0.5f alpha:1.0f];
		else if (difference < lapTime * -0.05)
			((GradientLabel*) [cell.contentView.subviews objectAtIndex:2]).textColor = [UIColor colorWithRed:0.5f green:1.0f blue:0.5f alpha:1.0f];
		else
			((GradientLabel*) [cell.contentView.subviews objectAtIndex:2]).textColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
	}
}

@end
