//
//  GPSManager.h
//  Glint
//
//  Created by Jakob Borg on 9/22/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "JBGPXReader.h"
#import "JBGPXWriter.h"
#import "JBLocationMath.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

@interface LapTime : NSObject
{
	float distance;
	float elapsedTime;
}

- (id)initWithDistance:(float)idistance andTime:(float)ielapsedTime;

@property (readonly) float distance;
@property (readonly) float elapsedTime;

@end

@interface GPSManager : NSObject <CLLocationManagerDelegate> {
	CLLocationManager *locationManager;
	JBLocationMath *math;
	JBGPXWriter *gpxWriter;
	NSMutableArray *passedLapTimes;
	BOOL isPaused;
	BOOL isGPSEnabled;
	BOOL isPrecisionAcceptable;
	NSDate *started;
}

- (NSArray*)queuedLapTimes;
- (void)startRecordingOnFile:(NSString*)fileName;
- (void)resumeRecordingOnFile:(NSString*)fileName;
- (void)stopRecording;
- (void)pauseUpdates;
- (void)resumeUpdates;
- (void)commit;
- (void)clearForUnitTests;
- (void)enableGPS;
- (void)disableGPS;

@property (retain) JBLocationMath *math;
@property (readonly) BOOL isPaused;
@property (readonly) BOOL isGPSEnabled;
@property (readonly) BOOL isPrecisionAcceptable;
@property (readonly) CLLocation *location;
@property (readonly) int numSavedMeasurements;
@property (readonly) BOOL isRecording;

@end
