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

- (void)viewDidLoad {
        delegate = [[UIApplication sharedApplication] delegate];
        self.title = NSLocalizedString(@"Files",nil);
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);	
        documentsDirectory = [paths objectAtIndex:0];
        [documentsDirectory retain];
        files = nil;
        sections = nil;
        [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
        self.navigationItem.rightBarButtonItem = [self editButtonItem];
        [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
        [navigationController setToolbarHidden:YES];
        [super viewWillAppear:animated];
}

- (void) refresh {
        [files release];
        files = [[NSMutableArray alloc] init];
        [sections release];
        sections = [[NSMutableArray alloc] init];
        
        NSArray* fileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
        NSArray* sortedFileList = [fileList sortedArrayUsingSelector:@selector(compare:)];
        NSEnumerator *enumer = [sortedFileList reverseObjectEnumerator];
        
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
        if (section < [sections count])
        return [[files objectAtIndex:section] count];
        else
                return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
        // Always at least one section. If there are no files, the section is used for help text.
        if ([sections count] > 1)
                return [sections count];
        else
                return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
        // Return the section header if there is one, otherwise a blank header for the help text.
        if (section < [sections count])
                return [sections objectAtIndex:section];
        else
                return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
        // Return the help text as footer, or nothing at all if this is a real section.
        if (section == 0 && [sections count] == 0)
                return NSLocalizedString(@"There are currently no saved files. To use saved files, first make a recording from the main screen.",nil);
        else
                return nil;
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
        NSArray *section = [files objectAtIndex:p.section];
        NSString *file = [section objectAtIndex:p.row];                
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
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
        if ([[files objectAtIndex:indexPath.section] count] == 0) {
                [files removeObjectAtIndex:indexPath.section];
                [sections removeObjectAtIndex:indexPath.section];
                // Remove the section, unless it's the last one.
                if ([sections count] > 0)
                        [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationRight];
                else
                        [tableView reloadData];
        }
}

@end
