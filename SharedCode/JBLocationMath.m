//
//  JBLocationMath.m
//  Glint
//
//  Created by Jakob Borg on 7/26/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "JBLocationMath.h"

@interface JBLocationMath ()
- (void)tests;
@end

@implementation JBLocationMath

- (id)init {
        if (self = [super init]) {
                [self tests];
        }
        return self;
}

- (void)tests {
        CLLocation *locN = [[[CLLocation alloc] initWithLatitude:10.0 longitude:0.0] autorelease]; // 10.0 N
        CLLocation *locS = [[[CLLocation alloc] initWithLatitude:-10.0 longitude:0.0] autorelease]; // 10.0 S
        CLLocation *locE = [[[CLLocation alloc] initWithLatitude:0.0 longitude:10.0] autorelease]; // 10.0 E
        CLLocation *locW = [[[CLLocation alloc] initWithLatitude:0.0 longitude:-10.0] autorelease]; // 10.0 W
        CLLocation *locNE = [[[CLLocation alloc] initWithLatitude:10.0 longitude:10.0] autorelease]; // 10.0 N, 10.0 E
        CLLocation *locSW = [[[CLLocation alloc] initWithLatitude:-10.0 longitude:-10.0] autorelease]; // 10.0 S, 10.0 W
        float result;
        
        // Check basic bearings
        result = [self bearingFromLocation:locN toLocation:locS];
        NSAssert(result == 180.0, @"Bearing N-S incorrect");
        result = [self bearingFromLocation:locS toLocation:locN];
        NSAssert(result == 0.0, @"Bearing S-N incorrect");
        result = [self bearingFromLocation:locE toLocation:locW];
        NSAssert(result == 270.0, @"Bearing E-W incorrect");
        result = [self bearingFromLocation:locW toLocation:locE];
        NSAssert(result == 90.0, @"Bearing W-E incorrect");
        result = [self bearingFromLocation:locSW toLocation:locNE];
        NSAssert(result > 44.0 && result < 46.0, @"Bearing SW-NE incorrect");
        result = [self bearingFromLocation:locNE toLocation:locSW];
        NSAssert(result > 224.0 && result < 226.0, @"Bearing SW-NE incorrect");
        
        // Check random bearings from actual data
        JBGPXReader *reader = [[JBGPXReader alloc] initWithFilename:[[NSBundle mainBundle] pathForResource:@"reference" ofType:@"gpx"]];
        NSArray *locations = [reader locations];
        NSAssert([locations count] == 47, @"Wrong number of trackpoints in reference.gpx");
        result = [self bearingFromLocation:[locations objectAtIndex:0] toLocation:[locations objectAtIndex:1]];
        NSAssert(result > 276.0 && result < 278.0, @"Bearing [0]-[1] incorrect");
        result = [self bearingFromLocation:[locations objectAtIndex:1] toLocation:[locations objectAtIndex:46]];
        NSAssert(result > 110.0 && result < 112.0, @"Bearing [1]-[46] incorrect");
        
        // Check distance->time interpolation
        result  = [self timeAtLocationByDistance:200.0 inLocations:locations];
        NSAssert(result > 173.0 && result < 175.0, @"Time to 200 m incorrect");
        result  = [self timeAtLocationByDistance:400.0 inLocations:locations];
        NSAssert(result > 371.0 && result < 373.0, @"Time to 400 m incorrect");
        result  = [self timeAtLocationByDistance:500.0 inLocations:locations];
        NSAssert(result > 520.0 && result < 522.0, @"Time to 500 m incorrect");
        result  = [self timeAtLocationByDistance:600.0 inLocations:locations];
        NSAssert(isnan(result), @"Time to 600 m incorrect");
        
        // Check time->distance interpolation
        result  = [self distanceAtPointInTime:174 inLocations:locations];
        NSAssert(result > 199.0 && result < 201.0, @"Distance at 174 sek incorrect");
        result  = [self distanceAtPointInTime:521 inLocations:locations];
        NSAssert(result > 499.0 && result < 501.0, @"Distance at 521 sek incorrect");
        result  = [self distanceAtPointInTime:900 inLocations:locations];
        NSAssert(isnan(result), @"Distance at 900 sek incorrect");

        NSLog(@"JBLocationMath tests passed.");
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
        float y1 = locA.coordinate.latitude / 180.0 * M_PI;
        float x1 = locA.coordinate.longitude / 180.0 * M_PI;
        float y2 = locB.coordinate.latitude / 180.0 * M_PI;
        float x2 = locB.coordinate.longitude / 180.0 * M_PI;
        float y = cos(x1) * sin(x2) - sin(x1) * cos(x2) * cos(y2-y1);
        float x = sin(y2-y1) * cos(x2);
        float t = atan2(y, x);
        float bearing = t / M_PI * 180.0 + 360.0;
        if (bearing >= 360.0)
                bearing -= 360.0;
        return bearing;
}

- (float)distanceAtPointInTime:(float)targetTime inLocations:(NSArray*)locations {
        if (isnan(targetTime) || targetTime < 0.0)
                return NAN;
        
        CLLocation *pointOne = nil, *pointTwo = nil;
        float distance = 0.0;
        float time = 0.0;
        
        for (CLLocation *point in locations) {
                if (pointOne) {
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

- (float)timeAtLocationByDistance:(float)targetDistance inLocations:(NSArray*)locations {
        if (isnan(targetDistance) || targetDistance < 0.0)
                return NAN;
        
        CLLocation *pointOne = nil, *pointTwo = nil;
        float time = 0.0;
        float distance = 0.0;
        
        for (CLLocation *point in locations) {
                if (pointOne) {
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
        
        float remainingDistance = targetDistance - distance;
        float factor = remainingDistance / [pointTwo getDistanceFrom:pointOne];
        float targetTime = time + factor * [pointTwo.timestamp timeIntervalSinceDate:pointOne.timestamp];
        return targetTime;
}

@end
