//
//  GPSManager.m
//  Glint
//
//  Created by Jakob Borg on 9/22/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "GPSManager.h"

@interface GPSManager ()
- (void)enableGPS;
- (void)disableGPS;
- (bool)precisionAcceptable:(CLLocation*)location;
- (void)takeAveragedMeasurement:(NSTimer*)timer;
@end

@implementation LapTime

@synthesize distance, elapsedTime;

- (id)initWithDistance:(float)idistance andTime:(float)ielapsedTime {
        if (self = [super init]) {
                distance = idistance;
                elapsedTime = ielapsedTime;
        }
        return self;
}

@end

@implementation GPSManager

@synthesize math, isPaused, isPrecisionAcceptable, isGPSEnabled;

/*
 * Public methods and properties.
 */

- (id)init {
        if (self = [super init]) {
                math = [[JBLocationMath alloc] init];
                gpxWriter = nil;
                isGPSEnabled = NO;
                isPrecisionAcceptable = NO;
                isPaused = NO;
                passedLapTimes = [[NSMutableArray alloc] init];
        }
        [self enableGPS];
        NSTimer* averagedMeasurementTaker = [NSTimer timerWithTimeInterval:MEASUREMENT_THREAD_INTERVAL target:self selector:@selector(takeAveragedMeasurement:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:averagedMeasurementTaker forMode:NSDefaultRunLoopMode];
        return self;
}

- (NSArray*)queuedLapTimes {
        NSArray *result = [NSArray arrayWithArray:passedLapTimes];
        [passedLapTimes release];
        passedLapTimes = [[NSMutableArray alloc] init];
        return result;
}

- (void)dealloc {
        [passedLapTimes release];
        [super dealloc];
}

- (void)startRecordingOnFile:(NSString*)fileName {
        if (gpxWriter)
                [self stopRecording];
        gpxWriter = [[JBGPXWriter alloc] initWithFilename:fileName];
        gpxWriter.autoCommit = YES;
        [gpxWriter addTrackSegment];
}

- (void)resumeRecordingOnFile:(NSString*)fileName {
        if (gpxWriter)
                [self stopRecording];
        JBGPXReader *reader = [[JBGPXReader alloc] initWithFilename:fileName];
        [math release];
        math = [[reader locationMath] retain];
        [reader release];
        
        gpxWriter = [[JBGPXWriter alloc] initWithFilename:fileName];
        [gpxWriter addTrackSegment];
        for (CLLocation *loc in [math locations]) {
                if ([JBLocationMath isBreakMarker:loc])
                        [gpxWriter addTrackSegment];
                else
                        [gpxWriter addTrackPoint:loc];
        }
        gpxWriter.autoCommit = YES;
        [gpxWriter addTrackSegment];
}

- (void)stopRecording {
        [gpxWriter commit];
        [gpxWriter release];
        gpxWriter = nil;
}

- (void)pauseUpdates {
        if (!isPaused) {
                isPaused = YES;
                [math insertBreakMarker];
                if (gpxWriter)
                        [gpxWriter addTrackSegment];
                [self disableGPS];
        }
}

- (void)resumeUpdates {
        isPaused = NO;
        [self enableGPS];
}

- (CLLocation*)location {
        return locationManager.location;
}

- (int)numSavedMeasurements {
        return [gpxWriter numberOfTrackPoints];
}

- (BOOL)isRecording {
        return gpxWriter != nil;
}

- (void)commit {
        [gpxWriter commit];
}

/*
 * LocationManager Delegate
 */

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
        static int numLaps = 1;
        static float prevLapTime = 0.0f;
        
        isPrecisionAcceptable = [self precisionAcceptable:newLocation];
        if (isPrecisionAcceptable) {
                if (!isPaused) {
                        [math updateLocation:newLocation];
                        if ([math totalDistance] >= numLaps*USERPREF_LAPLENGTH) {
                                debug_NSLog(@"Adding passed lap time at %f m", [math totalDistance]);
                                float lapTime = [math timeAtLocationByDistance:numLaps*USERPREF_LAPLENGTH];
                                [passedLapTimes addObject:[[[LapTime alloc] initWithDistance:numLaps*USERPREF_LAPLENGTH andTime:lapTime-prevLapTime] autorelease]];
                                numLaps++;
                                prevLapTime = lapTime;                                
                        }
                } else {
                        [math updateLocationForDisplayOnly:newLocation];
                }
        }
}

/*
 * Private methods
 */

- (void)enableGPS {
        debug_NSLog(@"Starting GPS");
        locationManager = [[CLLocationManager alloc] init];
        locationManager.distanceFilter = FILTER_DISTANCE;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.delegate = self;
        [locationManager startUpdatingLocation];
        isGPSEnabled = YES;
}

- (void)disableGPS {
        debug_NSLog(@"Stopping GPS");
        locationManager.delegate = nil;
        [locationManager stopUpdatingLocation];
        [locationManager release];
        locationManager = nil;
        isGPSEnabled = NO;
}

- (bool)precisionAcceptable:(CLLocation*)location {
        static float minPrec = 0.0;
        if (minPrec == 0.0)
                minPrec = USERPREF_MINIMUM_PRECISION;
        float currentPrec = location.horizontalAccuracy;
        return currentPrec > 0.0 && currentPrec <= minPrec;
}

- (void)takeAveragedMeasurement:(NSTimer*)timer
{
        static NSDate *lastWrittenDate = nil;
        static float averageInterval = 0.0;
        static BOOL powersave = NO;
        NSDate *now = [NSDate date];
        
        // Load user preferences the first time we need them.
        
        if (averageInterval == 0.0) {
                averageInterval = USERPREF_MEASUREMENT_INTERVAL;
                powersave = USERPREF_POWERSAVE;
        }
        
        // If we are paused, do nothing.
        if (isPaused)
                return;
        
        // Check if the GPS is disabled, and if so if we should enable it to do a measurement.
        if (!isGPSEnabled // The GPS is off
            && gpxWriter // We are recording
            && [now timeIntervalSinceDate:lastWrittenDate] > averageInterval-10) { // It is soon time for a new measurement
                [self enableGPS];
                return;
        }
        
        // Check if it's time to save a trackpoint, and if we have enough precision.
        // If so, save it. If we dont have enough precision, create a break in the
        // track segment so this is reflected in the saved file.
        
        CLLocation *current = locationManager.location;
        debug_NSLog(@"%@", [locationManager.location description]);
        if (gpxWriter && (!lastWrittenDate || [now timeIntervalSinceDate:lastWrittenDate] >= averageInterval - MEASUREMENT_THREAD_INTERVAL/2.0f )) {
                if ([self precisionAcceptable:current]) {
                        debug_NSLog(@"Good precision, saving waypoint");
                        [lastWrittenDate release];
                        lastWrittenDate = [now retain];
                        [gpxWriter addTrackPoint:current];
                } else if ([gpxWriter isInTrackSegment]) {
                        debug_NSLog(@"Bad precision, breaking track segment");
                        [gpxWriter addTrackSegment];
                } else {
                        debug_NSLog(@"Bad precision, waiting for waypoint");
                }
        }
        
        if (powersave // Power saving is enabled
            && isGPSEnabled // The GPS is enabled
            && gpxWriter // We are recording
            && averageInterval >= 30 // Recording interval is at least 30 seconds
            && lastWrittenDate // We have written at least one position
            && [now timeIntervalSinceDate:lastWrittenDate] < averageInterval-10) // It is less than averageInterval-10 seconds since the last measurement
                [self disableGPS];
}

- (void)clearForUnitTests {
        [math release];
        math = [[JBLocationMath alloc] init];
}

@end
