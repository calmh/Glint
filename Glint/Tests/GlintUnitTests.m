//
//  TestCases.m
//  Glint
//
//  Created by Jakob Borg on 7/27/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "GlintUnitTests.h"

@interface GlintUnitTests ()

- (NSString*)bundlePath;

@end

@implementation GlintUnitTests

- (void)setUp
{
	// Set lap length to 100m so we get about five laps on the coming run
	[[NSUserDefaults standardUserDefaults] setFloat:100.0f forKey:@"lap_length"];
	// Set required GPS precision to 100m so the read values are Ok
	[[NSUserDefaults standardUserDefaults] setFloat:100.0f forKey:@"gps_minprec"];
}

- (void)testLocationMath
{
	for (float latOffset = -45.0f; latOffset <= 45.0f; latOffset += 45.0f) {
		for (float lonOffset = -150.0f; lonOffset <= 150.0f; lonOffset += 50.0f) {
			CLLocation *locN = [[[CLLocation alloc] initWithLatitude:latOffset + 1.0 longitude:lonOffset + 0.0] autorelease]; // 10.0 N
			CLLocation *locS = [[[CLLocation alloc] initWithLatitude:latOffset - 1.0 longitude:lonOffset + 0.0] autorelease]; // 10.0 S
			CLLocation *locE = [[[CLLocation alloc] initWithLatitude:latOffset + 0.0 longitude:lonOffset + 1.0] autorelease]; // 10.0 E
			CLLocation *locW = [[[CLLocation alloc] initWithLatitude:latOffset + 0.0 longitude:lonOffset - 1.0] autorelease]; // 10.0 W
			CLLocation *locNE = [[[CLLocation alloc] initWithLatitude:latOffset + 1.0 longitude:lonOffset + 1.0] autorelease]; // 10.0 N, 10.0 E
			CLLocation *locSW = [[[CLLocation alloc] initWithLatitude:latOffset - 1.0 longitude:lonOffset - 1.0] autorelease]; // 10.0 S, 10.0 W

			JBLocationMath *math = [[JBLocationMath alloc] init];
			float result;
			// Check basic bearings
			result = [math bearingFromLocation:locN toLocation:locS];
			STAssertEqualsWithAccuracy(result, 180.0f, 15.0f, @"Bearing N-S incorrect (%f)", result);
			result = [math bearingFromLocation:locS toLocation:locN];
			if (result > 350.0f)
				result -= 360.0f;
			STAssertEqualsWithAccuracy(result, 0.0f, 15.0f, @"Bearing S-N incorrect (%f)", result);
			result = [math bearingFromLocation:locE toLocation:locW];
			STAssertEqualsWithAccuracy(result, 270.0f, 15.0f, @"Bearing E-W incorrect (%f)", result);
			result = [math bearingFromLocation:locW toLocation:locE];
			STAssertEqualsWithAccuracy(result, 90.0f, 15.0f, @"Bearing W-E incorrect (%f)", result);
			result = [math bearingFromLocation:locSW toLocation:locNE];
			STAssertEqualsWithAccuracy(result, 45.0f, 15.0f, @"Bearing SW-NE incorrect (%f)", result);
			result = [math bearingFromLocation:locNE toLocation:locSW];
			STAssertEqualsWithAccuracy(result, 225.0f, 15.0f, @"Bearing NE-SW incorrect (%f)", result);
			[math release];
		}
	}
}

- (void)testGPXReaderWriter
{
	NSString *filename = [NSString stringWithFormat:@"%@/reference2.gpx", [self bundlePath]];
	JBGPXReader *reader = [[JBGPXReader alloc] initWithFilename:filename];
	JBGPXWriter *writer = [[JBGPXWriter alloc] initWithFilename:@"/tmp/unittest.gpx"];

	[writer addTrackSegment];
	for (CLLocation*loc in [reader locations])
		if ([JBLocationMath isBreakMarker:loc])
			[writer addTrackSegment];
		else
			[writer addTrackPoint:loc];
	[writer commit];

	[writer release];
	[reader release];

	NSString *fileDataOriginal = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil];
	NSString *fileDataNew = [NSString stringWithContentsOfFile:@"/tmp/unittest.gpx" encoding:NSUTF8StringEncoding error:nil];
	STAssertEquals([fileDataOriginal compare:fileDataNew], 0, @"");
}

- (void)testInterpolation
{
	JBLocationMath *math = [[JBLocationMath alloc] init];
	NSString *filename = [NSString stringWithFormat:@"%@/reference0.gpx", [self bundlePath]];
	JBGPXReader *reader = [[JBGPXReader alloc] initWithFilename:filename];
	NSArray *locations = [reader locations];

	float result;
	// Check distance->time interpolation
	result  = [math timeAtLocationByDistance:200.0f inLocations:locations];
	STAssertEqualsWithAccuracy(result, 174.0f, 1.0f, @"Time to 200 m incorrect");
	result  = [math timeAtLocationByDistance:400.0 inLocations:locations];
	STAssertEqualsWithAccuracy(result, 372.0f, 1.0f, @"Time to 400 m incorrect");
	result  = [math timeAtLocationByDistance:500.0 inLocations:locations];
	STAssertEqualsWithAccuracy(result, 520.0f, 1.0f, @"");
	result  = [math timeAtLocationByDistance:600.0f inLocations:locations];
	STAssertTrue(isnan(result), @"Time to 600 m incorrect");

	// Check time->distance interpolation
	result  = [math distanceAtPointInTime:174.0f inLocations:locations];
	STAssertEqualsWithAccuracy(result, 200.0f, 1.0f, @"Distance at 174 sek incorrect");
	result  = [math distanceAtPointInTime:521.0f inLocations:locations];
	STAssertEqualsWithAccuracy(result, 500.0f, 1.0f, @"Distance at 521 sek incorrect");
	result  = [math distanceAtPointInTime:900.0f inLocations:locations];
	STAssertTrue(isnan(result), @"Distance at 900 sek incorrect");

	[reader release];
	[math release];
}

- (void)testGPSManager
{
	GPSManager *manager = [[GPSManager alloc] init];
	CLLocationCoordinate2D coord;
	CLLocation *loc, *oldLoc;
	oldLoc = nil;
	coord.latitude = 10.0f;
	coord.longitude = 10.0f;
	loc = [[[CLLocation alloc] initWithCoordinate:coord altitude:0.0f horizontalAccuracy:50.0f verticalAccuracy:0.0f timestamp:[NSDate dateWithTimeIntervalSinceNow:-60]] autorelease];
	[manager locationManager:nil didUpdateToLocation:loc fromLocation:oldLoc];
	STAssertFalse([manager isPrecisionAcceptable], @"Precision cannot be acceptable");
	STAssertEquals([[manager math] totalDistance], 0.0f, @"Distance travelled must be zero");
	sleep(0.1);

	oldLoc = loc;
	coord.latitude = 11.0f;
	loc = [[[CLLocation alloc] initWithCoordinate:coord altitude:0.0f horizontalAccuracy:50.0f verticalAccuracy:0.0f timestamp:[NSDate date]] autorelease];
	[manager locationManager:nil didUpdateToLocation:loc fromLocation:oldLoc];
	STAssertTrue([manager isPrecisionAcceptable], @"Precision must be acceptable");
	float result = [[manager math] totalDistance];
	STAssertEquals(result, 0.0f, @"Distance travelled must be zero (%f)", result);
	sleep(0.1);

	oldLoc = loc;
	coord.latitude = 12.0f;
	loc = [[[CLLocation alloc] initWithCoordinate:coord altitude:0.0f horizontalAccuracy:50.0f verticalAccuracy:0.0f timestamp:[NSDate date]] autorelease];
	[manager locationManager:nil didUpdateToLocation:loc fromLocation:oldLoc];
	STAssertTrue([manager isPrecisionAcceptable], @"Precision must be acceptable");
	result = [[manager math] totalDistance];
	STAssertEqualsWithAccuracy(result, 1852.0f * 60.0f, 200.0f, @"Distance travelled is wrong (%f)", result);
	[manager locationManager:nil didUpdateToLocation:loc fromLocation:oldLoc];
}

- (NSString*)bundlePath
{
	NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
	NSString *bundlePath = [myBundle bundlePath];
	return bundlePath;
}

@end
