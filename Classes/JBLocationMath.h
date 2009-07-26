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

}

- (float)speedFromLocation:(CLLocation*)locA toLocation:(CLLocation*)locB;
- (float)bearingFromLocation:(CLLocation*)locA toLocation:(CLLocation*)locB;
- (float)distanceAtPointInTime:(float)targetTime inLocations:(NSArray*)locations;
- (float)timeAtLocationByDistance:(float)targetDistance inLocations:(NSArray*)locations;

@end
