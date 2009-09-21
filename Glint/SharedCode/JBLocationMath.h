//
//  JBLocationMath.h
//  Glint
//
//  Created by Jakob Borg on 7/26/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface JBLocationMath : NSObject {
        float currentSpeed;
        float currentCourse;
        float totalDistance;
        float elapsedTime;
        NSDate *firstMeasurement;
        CLLocation *lastKnownPosition;
        NSMutableArray *locations;
}

@property (readonly) float currentSpeed;
@property (readonly) float averageSpeed;
@property (readonly) float currentCourse;
@property (readonly) float totalDistance;
@property (readonly) float elapsedTime;
@property (retain) CLLocation *lastKnownPosition;
@property (readonly) CLLocation *lastRecordedPosition;
@property (readonly) NSArray *locations;

+ (BOOL)isBreakMarker:(CLLocation*)location;
- (void)updateLocation:(CLLocation*)location;
- (void)insertBreakMarker;
- (void)updateLocationForDisplayOnly:(CLLocation*)location;
- (float)speedFromLocation:(CLLocation*)locA toLocation:(CLLocation*)locB;
- (float)bearingFromLocation:(CLLocation*)locA toLocation:(CLLocation*)locB;
- (float)distanceAtPointInTime:(float)targetTime;
- (float)timeAtLocationByDistance:(float)targetDistance;
- (float)distanceAtPointInTime:(float)targetTime inLocations:(NSArray*)locations;
- (float)timeAtLocationByDistance:(float)targetDistance inLocations:(NSArray*)locations;
- (float)totalDistanceOverArray:(NSArray*)locations;
- (NSArray*)startAndFinishTimesInArray:(NSArray*)locations;
- (float)estimatedTotalDistanceAtTime:(NSDate*)when;
- (float)estimatedTotalDistance;

@end
