//
//  LapTimeViewController.m
//  Glint
//
//  Created by Jakob Borg on 8/15/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "LapTimeViewController.h"


@implementation LapTimeViewController

- (void)addLapTime:(float)seconds forDistance:(float)distance {
        [times addObject:[NSNumber numberWithFloat:seconds]];
        [distances addObject:[NSNumber numberWithFloat:distance]];
        [self.tableView reloadData];
        unsigned int index[] = { 0, [times count]-1 };
        NSIndexPath *path = [[[NSIndexPath alloc] initWithIndexes:index length:2] autorelease];
        [self.tableView selectRowAtIndexPath:path animated:YES scrollPosition:UITableViewScrollPositionBottom];
}

- (void)clear {
        [times release];
        [distances release];
        times = [[NSMutableArray alloc] init];
        distances = [[NSMutableArray alloc] init];
        [(UITableView*)self.view reloadData];
}

- (void)dealloc {
        [times release];
        [distances release];
        [super dealloc];
}

- (void)viewDidLoad {
        [super viewDidLoad];
        delegate = [[UIApplication sharedApplication] delegate];
        times = [[NSMutableArray alloc] init];
        distances = [[NSMutableArray alloc] init];
        self.title = NSLocalizedString(@"Lap Times",nil);
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
        return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
        if ([times count] > 0)
                return [times count];
        else
                return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

        if ([times count] > 0) {
                static NSString *CellIdentifier = @"Cell";
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                if (cell == nil) {
                        // The usual data cell.

                        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                        [cell.textLabel removeFromSuperview];
                        [cell.detailTextLabel removeFromSuperview];
                        [cell.imageView removeFromSuperview];

                        JBGradientLabel *newLabel;
                        newLabel = [[[JBGradientLabel alloc] initWithFrame:CGRectMake(10.0f, 5.0f, 100.0f, 28.0f)] autorelease];
                        newLabel.font = [UIFont fontWithName:@"Helvetica" size:28.0f];
                        newLabel.backgroundColor = [UIColor blackColor];
                        newLabel.textColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
                        newLabel.textAlignment = UITextAlignmentRight;
                        [cell.contentView addSubview:newLabel];

                        newLabel = [[[JBGradientLabel alloc] initWithFrame:CGRectMake(122.0f, 5.0f, 80.0f, 28.0f)] autorelease];
                        newLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:28.0f];
                        newLabel.backgroundColor = [UIColor blackColor];
                        newLabel.textColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
                        newLabel.textAlignment = UITextAlignmentRight;
                        [cell.contentView addSubview:newLabel];

                        newLabel = [[[JBGradientLabel alloc] initWithFrame:CGRectMake(212.0f, 5.0f, 98.0f, 28.0f)] autorelease];
                        newLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:28.0f];
                        newLabel.backgroundColor = [UIColor blackColor];
                        newLabel.textColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
                        newLabel.textAlignment = UITextAlignmentRight;
                        [cell.contentView addSubview:newLabel];
                }

                float lapTime = [[times objectAtIndex:indexPath.row] floatValue];
                float distance = [[distances objectAtIndex:indexPath.row] floatValue];
                float difference = 0.0f;
                if (indexPath.row > 0)
                        difference = lapTime - [[times objectAtIndex:indexPath.row-1] floatValue];
                ((JBGradientLabel*) [cell.contentView.subviews objectAtIndex:0]).text = [delegate formatDistance:distance];
                ((JBGradientLabel*) [cell.contentView.subviews objectAtIndex:1]).text = [delegate formatTimestamp:lapTime maxTime:86400 allowNegatives:NO];
                if (indexPath.row > 0) {
                        ((JBGradientLabel*) [cell.contentView.subviews objectAtIndex:2]).text = [delegate formatTimestamp:difference maxTime:86400 allowNegatives:YES];
                        if (difference > lapTime * 0.05) // Highlight differences of at least 10%, positive and negative
                                ((JBGradientLabel*) [cell.contentView.subviews objectAtIndex:2]).textColor = [UIColor colorWithRed:1.0f green:0.5f blue:0.5f alpha:1.0f];
                        else if (difference < lapTime * -0.05)
                                ((JBGradientLabel*) [cell.contentView.subviews objectAtIndex:2]).textColor = [UIColor colorWithRed:0.5f green:1.0f blue:0.5f alpha:1.0f];
                }

                return cell;
        } else {
                // Instructions cell.

                UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"InstructionsCell"] autorelease];
                cell.textLabel.text = NSLocalizedString(@"NoLapTimesInstructions",nil);
                cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
                cell.textLabel.textAlignment = UITextAlignmentCenter;
                cell.textLabel.numberOfLines = 0;
                cell.textLabel.textColor = [UIColor lightTextColor];
                return cell;

        }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
        if ([times count] == 0) // Instructions
                return 300.0f;
        else // Normal cell
                return 33.0f;

}

- (int)numberOfLapTimes {
        return [times count];
}

@end

