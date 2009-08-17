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
        NSIndexPath *path = [[NSIndexPath alloc] initWithIndexes:index length:2];
        [self.tableView selectRowAtIndexPath:path animated:YES scrollPosition:UITableViewScrollPositionBottom];
}

- (id)initWithStyle:(UITableViewStyle)style {
        // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
        if (self = [super initWithStyle:style]) {
                delegate = [[UIApplication sharedApplication] delegate];
                times = [[NSMutableArray alloc] init];
                distances = [[NSMutableArray alloc] init];
        }
        return self;
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

/*
 - (void)viewWillAppear:(BOOL)animated {
 [super viewWillAppear:animated];
 }
 */
/*
 - (void)viewDidAppear:(BOOL)animated {
 [super viewDidAppear:animated];
 }
 */
/*
 - (void)viewWillDisappear:(BOOL)animated {
 [super viewWillDisappear:animated];
 }
 */
/*
 - (void)viewDidDisappear:(BOOL)animated {
 [super viewDidDisappear:animated];
 }
 */

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
        [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
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
                [cell.textLabel removeFromSuperview];
                [cell.detailTextLabel removeFromSuperview];
                [cell.imageView removeFromSuperview];
                
                JBGradientLabel *newLabel = [[JBGradientLabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 70.0f, 44.0f)];
                newLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:28.0f];
                newLabel.backgroundColor = [UIColor blackColor];
                newLabel.textColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
                [cell.contentView addSubview:newLabel];
                newLabel = [[JBGradientLabel alloc] initWithFrame:CGRectMake(80.0f, 0.0f, 200.0f, 44.0f)];
                newLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:28.0f];
                newLabel.backgroundColor = [UIColor blackColor];
                newLabel.textColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
                [cell.contentView addSubview:newLabel];
        }
        
        float lapTime = [[times objectAtIndex:indexPath.row] floatValue];
        float distance = [[distances objectAtIndex:indexPath.row] floatValue];
        float difference = 0.0f;
        if (indexPath.row > 0)
                difference = lapTime - [[times objectAtIndex:indexPath.row-1] floatValue];
        ((JBGradientLabel*) [cell.contentView.subviews objectAtIndex:0]).text = [delegate formatDistance:distance];
        ((JBGradientLabel*) [cell.contentView.subviews objectAtIndex:1]).text = [NSString stringWithFormat:@"%@ (%@)",
                                                                                 [delegate formatTimestamp:lapTime maxTime:86400 allowNegatives:NO],
                                                                                 [delegate formatTimestamp:difference maxTime:86400 allowNegatives:YES]];
        if (difference > 0.5f)
                ((JBGradientLabel*) [cell.contentView.subviews objectAtIndex:1]).textColor = [UIColor colorWithRed:1.0f green:0.5f blue:0.5f alpha:1.0f];
	else
                ((JBGradientLabel*) [cell.contentView.subviews objectAtIndex:1]).textColor = [UIColor colorWithRed:0.5f green:1.0f blue:0.5f alpha:1.0f];
                
        return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
        // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }   
 }
 */


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */


/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

@end

