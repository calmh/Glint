//
//  TestCases.m
//  Glint
//
//  Created by Jakob Borg on 7/27/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "TestCases.h"

@interface TestCases ()

- (void)privateTestGPXReader:(JBGPXReader*)reader;
- (JBGPXReader*)getDefaultGPXReader;
- (NSString*) bundlePath;

@end

@implementation TestCases

- (void)testLocationMath {
        CLLocation *locN = [[[CLLocation alloc] initWithLatitude:10.0 longitude:0.0] autorelease]; // 10.0 N
        CLLocation *locS = [[[CLLocation alloc] initWithLatitude:-10.0 longitude:0.0] autorelease]; // 10.0 S
        CLLocation *locE = [[[CLLocation alloc] initWithLatitude:0.0 longitude:10.0] autorelease]; // 10.0 E
        CLLocation *locW = [[[CLLocation alloc] initWithLatitude:0.0 longitude:-10.0] autorelease]; // 10.0 W
        CLLocation *locNE = [[[CLLocation alloc] initWithLatitude:10.0 longitude:10.0] autorelease]; // 10.0 N, 10.0 E
        CLLocation *locSW = [[[CLLocation alloc] initWithLatitude:-10.0 longitude:-10.0] autorelease]; // 10.0 S, 10.0 W
        
        JBLocationMath *math = [[JBLocationMath alloc] init];
        float result;        
        // Check basic bearings
        result = [math bearingFromLocation:locN toLocation:locS];
        STAssertEquals(result, 180.0f, @"Bearing N-S incorrect");
        result = [math bearingFromLocation:locS toLocation:locN];
        STAssertEquals(result, 0.0f, @"Bearing S-N incorrect");
        result = [math bearingFromLocation:locE toLocation:locW];
        STAssertEquals(result, 270.0f, @"Bearing E-W incorrect");
        result = [math bearingFromLocation:locW toLocation:locE];
        STAssertEquals(result, 90.0f, @"Bearing W-E incorrect");
        result = [math bearingFromLocation:locSW toLocation:locNE];
        STAssertEqualsWithAccuracy(result, 44.0f, 1.0f, @"Bearing SW-NE incorrect");
        result = [math bearingFromLocation:locNE toLocation:locSW];
        STAssertEqualsWithAccuracy(result, 225.0f, 1.0f, @"Bearing SW-NE incorrect");
        
        [math release];
}

- (void)testGPXWriter {
        JBGPXReader *reader = [self getDefaultGPXReader];
        JBGPXWriter *writer = [[JBGPXWriter alloc] initWithFilename:@"/tmp/unittest.gpx"];

        [writer addTrackSegment];
        for (CLLocation *loc in [reader locations])
                [writer addTrackPoint:loc];
        [writer commit];
        [writer release];
        
        [reader release];
        
        reader = [[JBGPXReader alloc] initWithFilename:@"/tmp/unittest.gpx"];
        [self privateTestGPXReader:reader];
}

- (void)testInterpolation {
        JBLocationMath *math = [[JBLocationMath alloc] init];
        JBGPXReader *reader = [self getDefaultGPXReader];
        NSArray *locations = [reader locations];
        
        float result;
        // Check distance->time interpolation
        result  = [math timeAtLocationByDistance:200.0f inLocations:locations];
        STAssertEqualsWithAccuracy(result, 174.0f, 1.0f, @"Time to 200 m incorrect");
        result  = [math timeAtLocationByDistance:400.0 inLocations:locations];
        STAssertEqualsWithAccuracy(result, 372.0f, 1.0f, @"Time to 400 m incorrect");
        result  = [math timeAtLocationByDistance:500.0 inLocations:locations];
        STAssertEqualsWithAccuracy(result, 521.0f, 1.0f, @"Time to 500 m incorrect");
        result  = [math timeAtLocationByDistance:600.0f inLocations:locations];
        STAssertTrue(isnan(result), @"Time to 600 m incorrect");
        
        // Check time->distance interpolation
        result  = [math distanceAtPointInTime:174.0f inLocations:locations];
        STAssertTrue(result > 199.0f && result < 201.0f, @"Distance at 174 sek incorrect");
        result  = [math distanceAtPointInTime:521.0f inLocations:locations];
        STAssertTrue(result > 499.0f && result < 501.0f, @"Distance at 521 sek incorrect");
        result  = [math distanceAtPointInTime:900.0f inLocations:locations];
        STAssertTrue(isnan(result), @"Distance at 900 sek incorrect");
        
        [reader release];
        [math release];
}

- (void)privateTestGPXReader:(JBGPXReader*)reader {
        STAssertNotNil(reader, @"Reader cannot be nil");
        
        JBLocationMath *math = [[JBLocationMath alloc] init];
        NSArray *locations = [reader locations];
        STAssertNotNil(locations, @"Got no locations");
        if (locations) {
                // Reference file contains 47 measurements
                int numLocations = [locations count];
                STAssertEquals(numLocations, 47, @"Wrong number of trackpoints in locations");
                
                // Check known bearings within the file
                float result;
                result = [math bearingFromLocation:[locations objectAtIndex:0] toLocation:[locations objectAtIndex:1]];
                STAssertEqualsWithAccuracy(result, 277.0f, 1.0f, @"Bearing [0]-[1] incorrect");
                result = [math bearingFromLocation:[locations objectAtIndex:1] toLocation:[locations objectAtIndex:46]];
                STAssertEqualsWithAccuracy(result, 111.0f, 1.0f, @"Bearing [1]-[46] incorrect");
                
                // Check that the total distance is correct
                result = [math totalDistanceOverArray:locations];
                STAssertEqualsWithAccuracy(result, 596.0f, 1.0f, @"Total distance incorrect");
                
                // Check that we get start and end times.
                // TODO: Verify that they are correct.
                NSArray *times = [math startAndFinishTimesInArray:locations];
                STAssertNotNil(times, @"Start and finish times cannot be nil");
                int num = [times count];
                STAssertEquals(num, 2, @"startAndFinishTimesInArray: should return exactly two objects");
                
                // Check speed & course calculations
                CLLocation *loc = nil;
                for (loc in locations)
                        [math updateLocation:loc];
                // A few extra updates, in case we might have lost signal and got it back
                // If it isn't checked for, this might cause a division by zero and crash the test rig
                loc = [locations objectAtIndex:[locations count] - 1];
                [math updateLocation:loc];
                [math updateLocation:loc];
                
                result = [math currentSpeed];
                STAssertEqualsWithAccuracy(result, 1.29f, 0.1f, @"currentSpeed incorrect");
                result = [math totalDistance];
                STAssertEqualsWithAccuracy(result, 596.0f, 0.1f, @"totalDistance incorrect");
                result = [math currentCourse];
                STAssertEqualsWithAccuracy(result, 90.0f, 0.1f, @"currentCourse incorrect");
                result = [math averageSpeed];
                STAssertEqualsWithAccuracy(result, 1.0f, 0.1f, @"averageSpeed incorrect");
                NSDate *futureDate = [[math lastKnownPosition].timestamp addTimeInterval:300];
                result = [math estimatedTotalDistanceAtTime:futureDate];
                STAssertEqualsWithAccuracy(result, 982.8f, 0.1f, @"estimatedTotalDistance incorrect");
        }
        [reader release];
        [math release];
}

- (JBGPXReader*)getDefaultGPXReader {
        NSString *filename = [NSString stringWithFormat:@"%@/reference.gpx", [self bundlePath]];
        
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:filename];
        STAssertTrue(exists, @"Reference GPX file %@ not found", filename);
        
        JBGPXReader *reader = [[JBGPXReader alloc] initWithFilename:filename];
        return reader;
}

- (NSString*) bundlePath {
        NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
        NSString *bundlePath = [myBundle bundlePath];
        return bundlePath;
}

@end
