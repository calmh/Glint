//
//  JBLocationMath.m
//  Glint
//
//  Created by Jakob Borg on 7/26/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "JBLocationMath.h"

@interface JBLocationMath ()
- (void)updateCurrentSpeed:(float)newSpeed;
- (NSArray*)interpolatedSegmentForLocations:(NSArray*)locationSegment;
- (float*)hermiteInterpolate1dWithSteps:(int)steps y0:(float)y0 y1:(float)y1 y2:(float)y2 y3:(float)y3;
- (NSArray*)hermiteCurveFromSource:(CLLocation*)origin toDestination:(CLLocation*)destination fromPrev:(CLLocation*)prev toNext:(CLLocation*)next;
@end

@implementation JBLocationMath

@synthesize currentSpeed, currentCourse, totalDistance, lastKnownPosition, locations, elapsedTime, raceLocations;

+ (BOOL)isBreakMarker:(CLLocation *)location {
        return (!location || location.coordinate.latitude == 360.0f);
}

- (id)init {
        if (self = [super init]) {
                currentSpeed = 0.0f;
                currentCourse = 0.0f;
                totalDistance = 0.0f;
                lastKnownPosition = nil;
                firstMeasurement = nil;
                raceLocations = nil;
                locations = [[NSMutableArray alloc] init];
        }
        return self;
}

- (void)dealloc {
        [locations release];
        [super dealloc];
}

- (void)updateLocation:(CLLocation*)location {
        if (!location)
                return;

        if ([JBLocationMath isBreakMarker:location])
        {
                [self insertBreakMarker];
                return;
        }

        @synchronized (self) {
                if (!firstMeasurement)
                        firstMeasurement = [location.timestamp retain];

                CLLocation *reference = self.lastRecordedPosition;
                if (![JBLocationMath isBreakMarker:reference] && [location.timestamp timeIntervalSinceDate:reference.timestamp] > 0.0f) {
                        float dist = [reference getDistanceFrom:location];
                        totalDistance += dist;
                        [self updateCurrentSpeed:dist / [location.timestamp timeIntervalSinceDate:reference.timestamp]];
                        currentCourse = [self bearingFromLocation:reference toLocation:location];
                        elapsedTime += [location.timestamp timeIntervalSinceDate:reference.timestamp];
                }

                self.lastKnownPosition = location;

                [locations addObject:location];
        }
}

- (void)insertBreakMarker {
        CLLocation *marker = [[CLLocation alloc] initWithLatitude:360.0f longitude:360.0f];
        [locations addObject:marker];
        [marker release];
}

// Only updates location and current course
- (void)updateLocationForDisplayOnly:(CLLocation*)location {
        if (!location)
                return;

        if (lastKnownPosition && [location.timestamp timeIntervalSinceDate:lastKnownPosition.timestamp] > 0.0f) {
                currentCourse = [self bearingFromLocation:lastKnownPosition toLocation:location];
        }

        self.lastKnownPosition = location;
}

- (float)speedFromLocation:(CLLocation*)locA toLocation:(CLLocation*)locB {
        float td = [locA.timestamp timeIntervalSinceDate:locB.timestamp];
        if (td < 0.0)
                td = -td;
        if (td == 0.0)
                return 0.0;
        float dist = [locA getDistanceFrom:locB];
        return dist / td;
}

- (float)bearingFromLocation:(CLLocation*)locA toLocation:(CLLocation*)locB {
        float x1 = locA.coordinate.latitude / 180.0 * M_PI;
        float y1 = locA.coordinate.longitude / 180.0 * M_PI;
        float x2 = locB.coordinate.latitude / 180.0 * M_PI;
        float y2 = locB.coordinate.longitude / 180.0 * M_PI;
        float x = cos(x1) * sin(x2) - sin(x1) * cos(x2) * cos(y2-y1);
        float y = sin(y2-y1) * cos(x2);
        float t = atan2(y, x);
        float bearing = t / M_PI * 180.0 + 360.0;
        if (bearing >= 360.0)
                bearing -= 360.0;
        return bearing;
}

- (float)distanceAtPointInTime:(float)targetTime {
        return [self distanceAtPointInTime:targetTime inLocations:locations];
}

- (float)distanceAtPointInTime:(float)targetTime inLocations:(NSArray*)locationList {
        if (isnan(targetTime) || targetTime < 0.0)
                return NAN;

        CLLocation *pointOne = nil, *pointTwo = nil;
        float distance = 0.0;
        float time = 0.0;

        for (CLLocation *point in locationList) {
                if (![JBLocationMath isBreakMarker:pointOne] && ![JBLocationMath isBreakMarker:point]) {
                        time += [point.timestamp timeIntervalSinceDate:pointOne.timestamp];
                        distance += [pointOne getDistanceFrom:point];
                }
                if (time <= targetTime)
                        pointOne = point;
                else {
                        pointTwo = point;
                        break;
                }
        }

        float remainingTime = targetTime - time;
        float timeBetweenP1andP2 = [pointTwo.timestamp timeIntervalSinceDate:pointOne.timestamp];
        float factor = remainingTime / timeBetweenP1andP2;
        float targetDistance = distance + factor * [pointTwo getDistanceFrom:pointOne];
        return targetDistance;
}

- (float)timeAtLocationByDistance:(float)targetDistance {
        return [self timeAtLocationByDistance:targetDistance inLocations:locations];
}

- (float)timeAtLocationByDistance:(float)targetDistance inLocations:(NSArray*)locationList {
        if (isnan(targetDistance) || targetDistance < 0.0)
                return NAN;

        CLLocation *pointOne = nil, *pointTwo = nil;
        float time = 0.0;
        float distance = 0.0;

        for (CLLocation *point in locationList) {
                if (![JBLocationMath isBreakMarker:point] && ![JBLocationMath isBreakMarker:pointOne]) {
                        time += [point.timestamp timeIntervalSinceDate:pointOne.timestamp];
                        distance += [pointOne getDistanceFrom:point];
                }
                if (distance <= targetDistance)
                        pointOne = point;
                else {
                        pointTwo = point;
                        break;
                }
        }

        if (pointTwo == nil)
                return NAN;

        float remainingDistance = targetDistance - distance;
        float factor = remainingDistance / [pointTwo getDistanceFrom:pointOne];
        float targetTime = time + factor * [pointTwo.timestamp timeIntervalSinceDate:pointOne.timestamp];
        return targetTime;
}

- (float)totalDistanceOverArray:(NSArray*)locationList {
        float distance = 0.0;
        CLLocation *last = nil;
        for (CLLocation *loc in locationList) {
                if (![JBLocationMath isBreakMarker:last] && ![JBLocationMath isBreakMarker:loc])
                        distance += [loc getDistanceFrom:last];
                last = loc;
        }
        return distance;
}

- (NSArray*)startAndFinishTimesInArray:(NSArray*)locationList {
        NSDate *start = ((CLLocation*) [locationList objectAtIndex:0]).timestamp;
        NSDate *finish = ((CLLocation*) [locationList objectAtIndex:[locationList count]-1]).timestamp;
        return [NSArray arrayWithObjects:start, finish, nil];
}

// Estimated total distance, based on known totalDistance, currentSpeed, and interval since last measurement.
- (float)estimatedTotalDistanceAtTime:(NSDate*)when {
        float estimate = currentSpeed * [when timeIntervalSinceDate:lastKnownPosition.timestamp];
        return totalDistance + estimate;
}

- (float)estimatedTotalDistance {
        return [self estimatedTotalDistanceAtTime:[NSDate date]];
}

- (float)averageSpeed {
        if (elapsedTime > 0.0f)
                return totalDistance / elapsedTime;
        else
                return 0.0f;

}

- (float)estimatedElapsedTime {
        CLLocation *reference = self.lastRecordedPosition;
        if (![JBLocationMath isBreakMarker:reference])
                return elapsedTime + [[NSDate date] timeIntervalSinceDate:reference.timestamp];
        else
                return elapsedTime;
}

- (CLLocation*)lastRecordedPosition {
        if ([locations count] == 0)
                return nil;
        else
                return [locations lastObject];
}

// How far ahead (-) or behind (+) in time we are.
- (float)timeDifferenceInRace {
        float raceTime = [self timeAtLocationByDistance:totalDistance inLocations:raceLocations];
        return elapsedTime - raceTime;
}

// How far ahead (+) or behind (-) in position we are.
- (float)distDifferenceInRace {
        float raceDist = [self distanceAtPointInTime:elapsedTime inLocations:raceLocations];
        return totalDistance - raceDist;
}

- (NSArray*)interpolatedLocations {
        NSMutableArray *interpolated = [[[NSMutableArray alloc] initWithCapacity:[locations count]*10] autorelease];
	
        NSMutableArray *tmp = [[[NSMutableArray alloc] init] autorelease];
        for (int i = 0; i < [locations count]; i++) {
                CLLocation *current = [locations objectAtIndex:i];
                if ([JBLocationMath isBreakMarker:current]) {
                        [interpolated addObjectsFromArray:[self interpolatedSegmentForLocations:tmp]];
                        [interpolated addObject:[locations objectAtIndex:i]];
                        tmp = [[[NSMutableArray alloc] init] autorelease];
                } else {
                        [tmp addObject:current];
                }
        }
        [interpolated addObjectsFromArray:[self interpolatedSegmentForLocations:tmp]];
        return interpolated;
}

/*
 * Private methods
 */

- (void)updateCurrentSpeed:(float)newSpeed {
        float weightFactor = 0.65f;
        currentSpeed = (weightFactor * newSpeed + currentSpeed) / (1 + weightFactor);
}

- (NSArray*)interpolatedSegmentForLocations:(NSArray*)locationSegment {
        if ([locationSegment count] < 4)
                return locationSegment;

        CLLocation *prev = nil, *orig = nil, *dest = nil, *next = nil;
        NSMutableArray *interpolated = [[[NSMutableArray alloc] initWithCapacity:[locationSegment count]*10] autorelease];

        prev = [locationSegment objectAtIndex:0];
        orig = [locationSegment objectAtIndex:0];
        dest = [locationSegment objectAtIndex:1];
        next = [locationSegment objectAtIndex:2];
        [interpolated addObject:orig];
        [interpolated addObjectsFromArray:[self hermiteCurveFromSource:orig toDestination:dest fromPrev:prev toNext:next]];

        for (int i = 3; i < [locationSegment count]; i++) {
                prev = orig;
                orig = dest;
                dest = next;
                next = [locationSegment objectAtIndex:i];
                [interpolated addObject:orig];
                [interpolated addObjectsFromArray:[self hermiteCurveFromSource:orig toDestination:dest fromPrev:prev toNext:next]];
        }

        prev = orig;
        orig = dest;
        dest = next;
        [interpolated addObject:orig];
        [interpolated addObjectsFromArray:[self hermiteCurveFromSource:orig toDestination:dest fromPrev:prev toNext:next]];
        [interpolated addObject:dest];
        return interpolated;
}

- (float*)hermiteInterpolate1dWithSteps:(int)steps y0:(float)y0 y1:(float)y1 y2:(float)y2 y3:(float)y3
{
        float tension = 0.0f;
        float bias = 0.0f;
        float m0,m1,mu2,mu3;
        float a0,a1,a2,a3;
        float *result = (float*)malloc(steps*sizeof(float));
        float mu = 1.0f / (steps + 1);
        for (int i = 0; i < steps; i++) {
                mu2 = mu * mu;
                mu3 = mu2 * mu;
                m0  = (y1-y0)*(1+bias)*(1-tension)/2;
                m0 += (y2-y1)*(1-bias)*(1-tension)/2;
                m1  = (y2-y1)*(1+bias)*(1-tension)/2;
                m1 += (y3-y2)*(1-bias)*(1-tension)/2;
                a0 =  2*mu3 - 3*mu2 + 1;
                a1 =    mu3 - 2*mu2 + mu;
                a2 =    mu3 -   mu2;
                a3 = -2*mu3 + 3*mu2;
                result[i] = a0*y1+a1*m0+a2*m1+a3*y2;
                mu += 1.0f / (steps + 1);
        }
        return result;
}

- (NSArray*)hermiteCurveFromSource:(CLLocation*)origin toDestination:(CLLocation*)destination fromPrev:(CLLocation*)prev toNext:(CLLocation*)next {
        int steps = (int)([destination getDistanceFrom:origin] / 5) + 1;
        NSMutableArray *result = [[[NSMutableArray alloc] initWithCapacity:steps] autorelease];
        float *lat = [self hermiteInterpolate1dWithSteps:steps y0:prev.coordinate.latitude y1:origin.coordinate.latitude y2:destination.coordinate.latitude y3:next.coordinate.latitude];
        float *lon = [self hermiteInterpolate1dWithSteps:steps y0:prev.coordinate.longitude y1:origin.coordinate.longitude y2:destination.coordinate.longitude y3:next.coordinate.longitude];
        for (int i = 0; i < steps; i++) {
                CLLocationCoordinate2D coord;
                coord.latitude = lat[i];
                coord.longitude = lon[i];
                CLLocation *loc = [[[CLLocation alloc] initWithCoordinate:coord altitude:0.0f horizontalAccuracy:-1.0f verticalAccuracy:-1.0f timestamp:origin.timestamp] autorelease];
                [result addObject:loc];
                debug_NSLog(@"%@", loc);

        }
        free(lat);
        free(lon);
        return result;
}

@end
