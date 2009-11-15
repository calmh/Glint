//
//  GPXReader.m
//  Glint
//
//  Created by Jakob Borg on 7/25/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "GPXReader.h"

@implementation GPXReader

@synthesize locationMath;

- (void)dealloc
{
	[locationMath release];
	[super dealloc];
}

- (id)initWithFilename:(NSString*)filename
{
	if (self = [self init]) {
		locationMath = [[LocationMath alloc] init];
		lastReadLat = lastReadLon = 0.0;
		lastReadDate = nil;
		currentlyReading = Nothing;
		shouldAddBreakMarker = NO;

		// NSXMLParser can't handle encoding='ASCII' that I used when writing GPX files.
		// So we change it to encoding='UTF-8'. The files are anyway guaranteed not to contain other characters.
		NSString *fileContents = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil];
		NSString *verifiedContents = [fileContents stringByReplacingOccurrencesOfString:@"encoding='ASCII'" withString:@"encoding='UTF-8'"];

		NSData *data = [verifiedContents dataUsingEncoding:NSUTF8StringEncoding];
		NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
		[parser setShouldProcessNamespaces:NO];
		[parser setShouldResolveExternalEntities:NO];
		[parser setDelegate:self];
		if (![parser parse])
			debug_NSLog(@"%@", [[parser parserError] description]);
		[parser release];
		// Release any left over stuff from parsing a strange file
		[lastReadDate release];
	}
	return self;
}

- (NSArray*)locations
{
	return [locationMath locations];
}

/*
 * NSXMLParser delegate stuff
 */

- (void)parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qualifiedName attributes:(NSDictionary*)attributeDict
{
	//debug_NSLog(@"JBGPXReader didStartElement: %@",elementName);
	if ([elementName isEqualToString:@"time"])
		currentlyReading = Time;
	if ([elementName isEqualToString:@"ele"])
		currentlyReading = Elevation;
	else if ([elementName isEqualToString:@"trkpt"]) {
		lastReadLat = [[attributeDict objectForKey:@"lat"] doubleValue];
		lastReadLon = [[attributeDict objectForKey:@"lon"] doubleValue];
	}
}

- (void)parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qName
{
	if ([elementName isEqualToString:@"time"])
		currentlyReading = Nothing;
	else if ([elementName isEqualToString:@"ele"])
		currentlyReading = Nothing;
	else if ([elementName isEqualToString:@"trkseg"])
		shouldAddBreakMarker = YES;
	else if ([elementName isEqualToString:@"trkpt"]) {
		if (shouldAddBreakMarker) {
			// We have just ended a trk segment, so obviously we are now in a new segment.
			// We should therefore add a marker to keep track of the break.
			//[locations addObject:[[CLLocation alloc] initWithLatitude:360.0f longitude:360.0f]];
			[locationMath insertBreakMarker];
			shouldAddBreakMarker = NO;
		}
		CLLocationCoordinate2D coord;
		coord.latitude = lastReadLat;
		coord.longitude = lastReadLon;
		CLLocation *loc = [[CLLocation alloc] initWithCoordinate:coord altitude:lastReadElevation horizontalAccuracy:50.0f verticalAccuracy:50.0f timestamp:lastReadDate];
		[locationMath updateLocation:loc];
		[loc release];
		[lastReadDate release];
		lastReadDate = nil;
		lastReadLat = lastReadLon = 0.0;
	}
}

- (void)parser:(NSXMLParser*)parser foundCharacters:(NSString*)string
{
	if (currentlyReading == Time) {
		NSDateFormatter *form = [[NSDateFormatter alloc] init];
		[form setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		[form setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
		lastReadDate = [[form dateFromString:string] retain];
		[form release];
	} else if (currentlyReading == Elevation)
		lastReadElevation = [string floatValue];
}

@end
