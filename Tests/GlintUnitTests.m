//
// TestCases.m
// Glint
//
// Created by Jakob Borg on 7/27/09.
// Copyright 2009 Jakob Borg. All rights reserved.
//

#import "GlintUnitTests.h"
#import <unistd.h>

@interface GlintUnitTests ()

#ifdef LONG_UNIT_TESTS
- (void)fakeMovementForGPSManager:(GPSManager*)manager duringSeconds:(int)seconds atSpeed:(double)speed;
#endif
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

- (void)testLocationMathBearings
{
        for (float latOffset = -45.0f; latOffset <= 45.0f; latOffset += 45.0f) {
                for (float lonOffset = -150.0f; lonOffset <= 150.0f; lonOffset += 50.0f) {
                        CLLocation *locN = [[[CLLocation alloc] initWithLatitude:latOffset + 1.0 longitude:lonOffset + 0.0] autorelease];
                        CLLocation *locS = [[[CLLocation alloc] initWithLatitude:latOffset - 1.0 longitude:lonOffset + 0.0] autorelease];
                        CLLocation *locE = [[[CLLocation alloc] initWithLatitude:latOffset + 0.0 longitude:lonOffset + 1.0] autorelease];
                        CLLocation *locW = [[[CLLocation alloc] initWithLatitude:latOffset + 0.0 longitude:lonOffset - 1.0] autorelease];
                        CLLocation *locNE = [[[CLLocation alloc] initWithLatitude:latOffset + 1.0 longitude:lonOffset + 1.0] autorelease];
                        CLLocation *locSW = [[[CLLocation alloc] initWithLatitude:latOffset - 1.0 longitude:lonOffset - 1.0] autorelease];

                        LocationMath *math = [[LocationMath alloc] init];
                        float result;
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

- (void)testLocationMathDistanceAtPointInTime
{
        LocationMath *math = [[LocationMath alloc] init];
        NSMutableArray *locations = [[NSMutableArray alloc] init];
        CLLocationCoordinate2D coord;
        coord.latitude = 0.0; // We need to stay close to the equator for this test to succeed
        coord.longitude = 50.0;
        NSDate *baseDate = [NSDate date];
        // Add 100 points at a speed of .001 degree per minute
        // i is time in minutes
        for (int i = 0; i < 100; i++) {
                [locations addObject:[[CLLocation alloc] initWithCoordinate:coord altitude:0.0 horizontalAccuracy:10.0f verticalAccuracy:10.0 timestamp:[baseDate dateByAddingTimeInterval:i * 60]]];
                coord.latitude += sin(0.3) * 0.001;
                coord.longitude += cos(0.3) * 0.001;
        }
        // Check a few points
        // i is time in tenths of minutes
        for (int i = 5; i < 900; i += 2) {
                float dist = [math distanceAtPointInTime:i * 6 inLocations:locations];
                float expected = i * 185.2 * 60.0 * 0.001;
                STAssertFalse(isnan(expected), @"");
                STAssertEqualsWithAccuracy(dist, expected, 20.0, @"");
        }
}

- (void)testLocationMathTimeAtDistance
{
        LocationMath *math = [[LocationMath alloc] init];
        NSMutableArray *locations = [[NSMutableArray alloc] init];
        CLLocationCoordinate2D coord;
        coord.latitude = 0.0; // We need to stay close to the equator for this test to succeed
        coord.longitude = 50.0;
        NSDate *baseDate = [NSDate date];
        // Add 100 points at a speed of .001 degree per minute.
        // i is time in minutes
        for (int i = 0; i < 100; i++) {
                [locations addObject:[[CLLocation alloc] initWithCoordinate:coord altitude:0.0 horizontalAccuracy:10.0f verticalAccuracy:10.0 timestamp:[baseDate dateByAddingTimeInterval:i * 60]]];
                coord.latitude += sin(0.3) * 0.001;
                coord.longitude += cos(0.3) * 0.001;
        }
        // Check a few points
        // i is time in seconds
        for (int i = 5; i < 99 * 60; i += 14) {
                float distance = i * 1852.0 * 0.001;
                float time = [math timeAtLocationByDistance:distance inLocations:locations];
                STAssertFalse(isnan(time), @"");
                STAssertEqualsWithAccuracy(time, (float) i, 15.0, @"");
        }
}

- (void)testGPXReaderWriter
{
        NSString *filename = [NSString stringWithFormat:@"%@/reference2.gpx", [self bundlePath]];
        GPXReader *reader = [[GPXReader alloc] initWithFilename:filename];
        GPXWriter *writer = [[GPXWriter alloc] initWithFilename:@"/tmp/unittest.gpx"];

        [writer addTrackSegment];
        for (CLLocation*loc in [reader locations])
                if ([LocationMath isBreakMarker:loc])
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
        LocationMath *math = [[LocationMath alloc] init];
        NSString *filename = [NSString stringWithFormat:@"%@/reference0.gpx", [self bundlePath]];
        GPXReader *reader = [[GPXReader alloc] initWithFilename:filename];
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

- (void)testGPSManagerBasics
{
        GPSManager *manager = [[GPSManager alloc] init];
        CLLocationCoordinate2D coord;
        CLLocation *loc, *oldLoc;
        oldLoc = nil;

        // Send an update with an old timestamp (60 seconds ago).
        // It should be ignored.
        coord.latitude = 10.0f;
        coord.longitude = 10.0f;
        loc = [[[CLLocation alloc] initWithCoordinate:coord altitude:0.0f horizontalAccuracy:50.0f verticalAccuracy:0.0f timestamp:[NSDate dateWithTimeIntervalSinceNow:-60]] autorelease];
        [manager locationManager:nil didUpdateToLocation:loc fromLocation:oldLoc];
        STAssertFalse([manager isPrecisionAcceptable], @"Precision cannot be acceptable");
        STAssertEquals([[manager math] totalDistance], 0.0f, @"Distance travelled must be zero");
        sleep(0.1);

        // Send an update with a new location.
        oldLoc = loc;
        coord.latitude = 11.0f;
        loc = [[[CLLocation alloc] initWithCoordinate:coord altitude:0.0f horizontalAccuracy:50.0f verticalAccuracy:0.0f timestamp:[NSDate date]] autorelease];
        [manager locationManager:nil didUpdateToLocation:loc fromLocation:oldLoc];
        STAssertTrue([manager isPrecisionAcceptable], @"Precision must be acceptable");
        float result = [[manager math] totalDistance];
        STAssertEquals(result, 0.0f, @"Distance travelled must be zero (%f)", result);
        sleep(0.1);

        // Another update, to test distance calculation.
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

#ifdef LONG_UNIT_TESTS

- (void)fakeMovementForGPSManager:(GPSManager*)manager duringSeconds:(int)seconds atSpeed:(double)speed
{
        static CLLocation *oldLoc = nil;
        static float lat = 0.0f; // Starting position.
        static float lon = -0.0f;
        float direction = 0.23; // In radians. Doesn't really matter.
        speed /= 60 * 1852.0; // meters/seconds to degrees/second, roughly. This is only true close to the equator, so chose the starting position accordingly.

        for (int i = 0; i <= seconds; i++) {
                lat += speed * sin(direction);
                lon += speed * cos(direction);

                CLLocationCoordinate2D coord;
                coord.latitude = lat;
                coord.longitude = lon;
                CLLocation *loc = [[CLLocation alloc] initWithCoordinate:coord altitude:23.0f horizontalAccuracy:49.0f verticalAccuracy:163.0f timestamp:[NSDate date]];
                [manager locationManager:nil didUpdateToLocation:loc fromLocation:oldLoc];
                [oldLoc release];
                oldLoc = loc;
                sleep(1);
        }
}

#endif

@end
