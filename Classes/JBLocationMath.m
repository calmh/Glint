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
        
        float bearing;
        bearing = [self bearingFromLocation:locN toLocation:locS];
        NSAssert(bearing == 180.0, @"Bearing N-S incorrect");
        bearing = [self bearingFromLocation:locS toLocation:locN];
        NSAssert(bearing == 0.0, @"Bearing S-N incorrect");
        bearing = [self bearingFromLocation:locE toLocation:locW];
        NSAssert(bearing == 270.0, @"Bearing E-W incorrect");
        bearing = [self bearingFromLocation:locW toLocation:locE];
        NSAssert(bearing == 90.0, @"Bearing W-E incorrect");
        bearing = [self bearingFromLocation:locSW toLocation:locNE];
        NSAssert(bearing > 44.0 && bearing < 46.0, @"Bearing SW-NE incorrect");
        bearing = [self bearingFromLocation:locNE toLocation:locSW];
        NSAssert(bearing > 224.0 && bearing < 226.0, @"Bearing SW-NE incorrect");
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
        float b = t / M_PI * 180.0 + 360.0;
        if (b >= 360.0)
                b -= 360.0;
        return b;
}

- (float)distanceAtPointInTime:(float)targetTime inLocations:(NSArray*)locations {
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
