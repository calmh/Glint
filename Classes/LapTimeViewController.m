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
        
#ifdef SCREENSHOT 
        [self addLapTime:345 forDistance:1000.0f];
        [self addLapTime:354 forDistance:2000.0f];
        [self addLapTime:340 forDistance:3000.0f];
        [self addLapTime:340 forDistance:4000.0f];
#endif
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
        return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
        return [times count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
        
        static NSString *CellIdentifier = @"Cell";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                [cell.textLabel removeFromSuperview];
                [cell.detailTextLabel removeFromSuperview];
                [cell.imageView removeFromSuperview];
                
                JBGradientLabel *newLabel;
                newLabel = [[[JBGradientLabel alloc] initWithFrame:CGRectMake(0.0f, 5.0f, 90.0f, 25.0f)] autorelease];
                newLabel.font = [UIFont fontWithName:@"Helvetica" size:28.0f];
                newLabel.backgroundColor = [UIColor blackColor];
                newLabel.textColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
                newLabel.textAlignment = UITextAlignmentRight;
                [cell.contentView addSubview:newLabel];

                newLabel = [[[JBGradientLabel alloc] initWithFrame:CGRectMake(102.0f, 5.0f, 70.0f, 25.0f)] autorelease];
                newLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:28.0f];
                newLabel.backgroundColor = [UIColor blackColor];
                newLabel.textColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
                newLabel.textAlignment = UITextAlignmentRight;
                [cell.contentView addSubview:newLabel];

                newLabel = [[[JBGradientLabel alloc] initWithFrame:CGRectMake(182.0f, 5.0f, 88.0f, 25.0f)] autorelease];
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
        ((JBGradientLabel*) [cell.contentView.subviews objectAtIndex:2]).text = [delegate formatTimestamp:difference maxTime:86400 allowNegatives:YES];
        if (difference > 0.5f)
                ((JBGradientLabel*) [cell.contentView.subviews objectAtIndex:2]).textColor = [UIColor colorWithRed:1.0f green:0.5f blue:0.5f alpha:1.0f];
	else
                ((JBGradientLabel*) [cell.contentView.subviews objectAtIndex:2]).textColor = [UIColor colorWithRed:0.5f green:1.0f blue:0.5f alpha:1.0f];
                
        return cell;
}

@end

