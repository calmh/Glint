//
//  SendFilesViewController.m
//  Glint
//
//  Created by Jakob Borg on 7/16/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "FilesViewController.h"
#import "GlintAppDelegate.h"

@interface FilesViewController ()
- (int)sectionForFile:(NSString*)fileName;
- (NSString*)sectionDescriptionForFile:(NSString*)fileName;
- (NSString*)descriptionForFile:(NSString*)file;
- (NSString*)commentForFile:(NSString*)file;
@end

@implementation FilesViewController

@synthesize tableView, navigationController, detailViewController, doneButton;

- (void)dealloc {
        [files release];
        [sections release];
        [documentsDirectory release];
        self.tableView = nil;
        [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
        delegate = [[UIApplication sharedApplication] delegate];
        self.title = NSLocalizedString(@"Files",nil);
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);	
        documentsDirectory = [paths objectAtIndex:0];
        [documentsDirectory retain];
        [navigationController setToolbarHidden:YES];
        self.navigationItem.rightBarButtonItem = [self editButtonItem];
        [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
        [super viewWillAppear:animated];
}

- (void) refresh {
        files = [[NSMutableArray alloc] init];
        sections = [[NSMutableArray alloc] init];
        
        NSArray* fileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
        fileList = [fileList sortedArrayUsingSelector:@selector(compare:)];
        NSEnumerator *enumer = [fileList reverseObjectEnumerator];
        
        NSString *fileName;
        while (fileName = [enumer nextObject]) {
                int section = [self sectionForFile:fileName];
                [[files objectAtIndex:section] addObject:fileName];
        }
        
        [tableView reloadData];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
        if (![self isEditing])
                [self.navigationItem setLeftBarButtonItem:nil animated:YES];
        else
                [self.navigationItem setLeftBarButtonItem:doneButton animated:YES];
        [super setEditing:editing animated:animated];
}

/*
 * IBActions
 */

- (IBAction) switchToGPSView:(id)sender {
        [(GlintAppDelegate *)[[UIApplication sharedApplication] delegate] switchToGPSView:sender];
}

/*
 * UITableViewDatasource stuff
 */

- (UITableViewCell *)tableView:(UITableView *)tView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GPXFileItem"];
        if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"GPXFileItem"] autorelease];
                //cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        NSString *fileName = [[files objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        cell.textLabel.text = [self descriptionForFile:fileName];
        cell.detailTextLabel.text = [self commentForFile:fileName];
        return cell;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
        return [[files objectAtIndex:section] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
        return [sections count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
        return [sections objectAtIndex:section];
}

/*
 * Private stuff
 */

- (int)sectionForFile:(NSString*)fileName {
        NSString *descr = [self sectionDescriptionForFile:fileName];
        int i;
        for (i = 0; i < [sections count]; i++)
                if ([(NSString*) [sections objectAtIndex:i] compare:descr] == NSOrderedSame)
                        break;
        if (i < [sections count])
                return i;
        
        [sections addObject:descr];
        [files addObject:[NSMutableArray array]];
        return [sections count] - 1;
}

- (NSString*)sectionDescriptionForFile:(NSString*)fileName {
        NSDictionary *attrs = [[NSFileManager defaultManager] fileAttributesAtPath:[NSString stringWithFormat:@"%@/%@", documentsDirectory, fileName] traverseLink:NO];
        NSDate *created = [attrs objectForKey:NSFileModificationDate];
        
        NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekCalendarUnit | NSDayCalendarUnit fromDate:created/* toDate:compare options:0*/];
        NSDateComponents *nowComps = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekCalendarUnit | NSDayCalendarUnit fromDate:[NSDate date]/* toDate:compare options:0*/];
        
        if (comps.year < nowComps.year)
                return NSLocalizedString(@"Earlier",nil);
        else if (comps.month < nowComps.month - 1)
                return NSLocalizedString(@"Earlier",nil);
        else if (comps.month < nowComps.month)
                return NSLocalizedString(@"Last Month",nil);
        else if (comps.day == nowComps.day)
                return NSLocalizedString(@"Today",nil);
        else if (comps.day == nowComps.day - 1)
                return NSLocalizedString(@"Yesterday",nil);
        else if (comps.week == nowComps.week)
                return NSLocalizedString(@"This Week",nil);
        else if (comps.week == nowComps.week - 1)
                return NSLocalizedString(@"Last Week",nil);
        else if (comps.week == nowComps.week - 2)
                return NSLocalizedString(@"Two Weeks Ago",nil);
        else
                return NSLocalizedString(@"This Month",nil);
}

- (NSString*)descriptionForFile:(NSString*)file {
        return [file stringByDeletingPathExtension];
}

- (NSString*)commentForFile:(NSString*)file {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, file];
        NSString *fileContents = [NSString stringWithContentsOfFile:fullPath];
        float distance = 0.0;
        int numPoints = 0;
        
        NSRange rangeBegin = [fileContents rangeOfString:@"[totalDistance]"];
        NSRange rangeEnd = [fileContents rangeOfString:@"[/totalDistance]"];
        if (rangeBegin.length > 0)
        {
                NSRange matchRange;
                matchRange.location = rangeBegin.location + rangeBegin.length;
                matchRange.length = rangeEnd.location - rangeBegin.location;
                NSString *matched = [fileContents substringWithRange:matchRange];
                distance = [matched doubleValue];
        }
        
        rangeBegin = [fileContents rangeOfString:@"[numPoints]"];
        rangeEnd = [fileContents rangeOfString:@"[/numPoints]"];
        if (rangeBegin.length > 0)
        {
                NSRange matchRange;
                matchRange.location = rangeBegin.location + rangeBegin.length;
                matchRange.length = rangeEnd.location - rangeBegin.location;
                NSString *matched = [fileContents substringWithRange:matchRange];
                numPoints = [matched intValue];
        }
        
        return [NSString stringWithFormat:@"%d %@, %@", numPoints, NSLocalizedString(@"points",nil), [delegate formatDistance:distance]];
}

/*
 * UITableViewDelegate stuff
 */

- (void)tableView:(UITableView *)etableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
        NSIndexPath *p = [tableView indexPathForSelectedRow];
        NSString *file = [[files objectAtIndex:p.section] objectAtIndex:p.row];                
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, file];
        [navigationController pushViewController:detailViewController animated:YES];
        [detailViewController performSelectorInBackground:@selector(loadFile:) withObject:fullPath];
}

- (void)tableView:(UITableView *)etableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath {
        NSString *file = [[files objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", documentsDirectory, file] error:nil];
        [[files objectAtIndex:indexPath.section] removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

@end
