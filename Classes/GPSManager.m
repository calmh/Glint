//
// GPSManager.m
// Glint
//
// Created by Jakob Borg on 9/22/09.
// Copyright 2009 Jakob Borg. All rights reserved.
//

#import "GPSManager.h"

@interface GPSManager ()
- (bool)precisionAcceptable:(CLLocation*)location;
- (void)takeAveragedMeasurement;
#ifdef FAKE_MOVEMENT
- (void)fakeMovement:(NSTimer*)timer;
#endif
@end

@implementation LapTime

@synthesize distance, elapsedTime;

- (id)initWithDistance:(float)idistance andTime:(float)ielapsedTime
{
        if (self = [super init]) {
                distance = idistance;
                elapsedTime = ielapsedTime;
        }
        return self;
}

@end

@implementation GPSManager

@synthesize math, isPrecisionAcceptable, isGPSEnabled;

/*
 * Public methods and properties.
 */

- (id)init
{
        if (self = [super init]) {
                math = [[LocationMath alloc] init];
                gpxWriter = nil;
                isGPSEnabled = NO;
                isPrecisionAcceptable = NO;
                passedLapTimes = [[NSMutableArray alloc] init];

                [self enableGPS];

#ifdef FAKE_MOVEMENT
                NSTimer *faker = [NSTimer timerWithTimeInterval:4.0f target:self selector:@selector(fakeMovement:) userInfo:nil repeats:YES];
                [[NSRunLoop currentRunLoop] addTimer:faker forMode:NSDefaultRunLoopMode];
#endif
        }
        return self;
}

- (NSArray*)queuedLapTimes
{
        NSArray *result = [NSArray arrayWithArray:passedLapTimes];
        [passedLapTimes release];
        passedLapTimes = [[NSMutableArray alloc] init];
        return result;
}

- (void)dealloc
{
        [passedLapTimes release];
        [super dealloc];
}

- (void)startRecordingOnFile:(NSString*)fileName
{
        if (gpxWriter)
                [self stopRecording];
        gpxWriter = [[GPXWriter alloc] initWithFilename:fileName];
        gpxWriter.autoCommit = YES;
        [gpxWriter addTrackSegment];
}

- (void)resumeRecordingOnFile:(NSString*)fileName
{
        if (gpxWriter)
                [self stopRecording];
        GPXReader *reader = [[GPXReader alloc] initWithFilename:fileName];
        [math release];
        math = [[reader locationMath] retain];
        [reader release];

        gpxWriter = [[GPXWriter alloc] initWithFilename:fileName];
        [gpxWriter addTrackSegment];
        for (CLLocation*loc in [math locations]) {
                if ([LocationMath isBreakMarker:loc])
                        [gpxWriter addTrackSegment];
                else
                        [gpxWriter addTrackPoint:loc];
        }
        gpxWriter.autoCommit = YES;
}

- (void)stopRecording
{
        [gpxWriter commit];
        [gpxWriter release];
        gpxWriter = nil;
}

- (CLLocation*)location
{
        return locationManager.location;
}

- (int)numSavedMeasurements
{
        return [gpxWriter numberOfTrackPoints];
}

- (BOOL)isRecording
{
        return gpxWriter != nil;
}

- (void)commit
{
        [gpxWriter commit];
}

- (void)enableGPS
{
        if (!isGPSEnabled) {
                debug_NSLog(@"Starting GPS");

                // Update "started" time. We accept no updates earlier than this timestamp.
                [started release];
                started = [[NSDate date] retain];

                // Start the GPS.
                locationManager = [[CLLocationManager alloc] init];
#ifndef FAKE_MOVEMENT
                locationManager.delegate = self;
#endif
                if (USERPREF_MINIMUM_PRECISION > 0 || ![CLLocationManager significantLocationChangeMonitoringAvailable]) {
                        locationManager.distanceFilter = FILTER_DISTANCE;
                        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
                        [locationManager startUpdatingLocation];
                } else
                        [locationManager startMonitoringSignificantLocationChanges];
                isGPSEnabled = YES;
        }
}

- (void)disableGPS
{
        if (isGPSEnabled) {
                debug_NSLog(@"Stopping GPS");
                locationManager.delegate = nil;
                [locationManager stopUpdatingLocation];
                if ([CLLocationManager significantLocationChangeMonitoringAvailable])
                        [locationManager stopMonitoringSignificantLocationChanges];
                [locationManager autorelease];
                locationManager = nil;
                isGPSEnabled = NO;
        }
}

/*
 * LocationManager Delegate
 */

- (void)locationManager:(CLLocationManager*)manager didUpdateToLocation:(CLLocation*)newLocation fromLocation:(CLLocation*)oldLocation
{
        static int numLaps = 1;
        static float prevLapTime = 0.0f;
        static int lapLength = 0;
        if (lapLength == 0)
                lapLength = USERPREF_LAPLENGTH;
        NSAssert(lapLength, @"lapLength cannot be zero.");

        // Ignore data points that come from before we actually started measuring.
        // This is necessary because the location manager by default reports the last
        // known position immediately, even if it's, say, several days old.
        if ([newLocation.timestamp timeIntervalSinceDate:started] < 0)
                return;

        isPrecisionAcceptable = [self precisionAcceptable:newLocation];
        if (isPrecisionAcceptable) {
                [math updateLocation:newLocation];
                [self takeAveragedMeasurement];
                if ([math totalDistance] >= numLaps * lapLength) {
                        debug_NSLog(@"Adding passed lap time at %f m", [math totalDistance]);
                        float lapTime = [math timeAtLocationByDistance:numLaps * USERPREF_LAPLENGTH];
                        [passedLapTimes addObject:[[[LapTime alloc] initWithDistance:numLaps * USERPREF_LAPLENGTH andTime:lapTime - prevLapTime] autorelease]];
                        numLaps++;
                        prevLapTime = lapTime;
                } else
                        [math updateLocationForDisplayOnly:newLocation];
        }
}

/*
 * Private methods
 */

- (bool)precisionAcceptable:(CLLocation*)location
{
        static float minPrec = 0.0;
        if (minPrec == 0.0)
                minPrec = USERPREF_MINIMUM_PRECISION;
        float currentPrec = location.horizontalAccuracy;
        return minPrec == 0 || (currentPrec > 0.0 && currentPrec <= minPrec);
}

- (void)takeAveragedMeasurement
{
        static NSDate *lastWrittenDate = nil;
        static float averageInterval = 0.0;
        NSDate *now = [NSDate date];

        // Load user preferences the first time we need them.

        if (averageInterval == 0.0)
                averageInterval = USERPREF_MEASUREMENT_INTERVAL;

        // Check if it's time to save a trackpoint, and if we have enough precision.
        // If so, save it. If we dont have enough precision, create a break in the
        // track segment so this is reflected in the saved file.

        CLLocation *current = locationManager.location;
        debug_NSLog(@"%@", [locationManager.location description]);
        if (gpxWriter && (!lastWrittenDate || [now timeIntervalSinceDate:lastWrittenDate] >= averageInterval - MEASUREMENT_THREAD_INTERVAL / 2.0f)) {
                if ([self precisionAcceptable:current]) {
                        debug_NSLog(@"Good precision, saving waypoint");
                        [lastWrittenDate release];
                        lastWrittenDate = [now retain];
                        [gpxWriter addTrackPoint:current];
                } else if ([gpxWriter isInTrackSegment]) {
                        debug_NSLog(@"Bad precision, breaking track segment");
                        [gpxWriter addTrackSegment];
                } else
                        debug_NSLog(@"Bad precision, waiting for waypoint");
        }
}

#ifdef FAKE_MOVEMENT
- (void)fakeMovement:(NSTimer*)timer
{
        static unsigned i = 0;
        static CLLocation *oldLoc = nil;
        static float deltaLat = 0.0f;
        static float deltaLon = 0.0f;
        deltaLat += -0.00011 + 0.00002 * ((float) rand() / RAND_MAX);
        deltaLon += -0.00011 + 0.00002 * ((float) rand() / RAND_MAX);
        CLLocationCoordinate2D coord;
        coord.latitude = [locationManager location].coordinate.latitude + deltaLat;
        coord.longitude = [locationManager location].coordinate.longitude + deltaLon;
        CLLocation *loc = [[CLLocation alloc] initWithCoordinate:coord altitude:23.0f horizontalAccuracy:49.0f verticalAccuracy:163.0f timestamp:[NSDate date]];
        [self locationManager:locationManager didUpdateToLocation:loc fromLocation:oldLoc];
        [oldLoc release];
        oldLoc = loc;
        i++;
}

#endif

@end
