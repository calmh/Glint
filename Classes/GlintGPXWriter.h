//
//  GlingGPXWriter.h
//  Glint
//
//  Created by Jakob Borg on 7/10/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface GlintGPXWriter : NSObject {
        NSString *filename;
        NSMutableArray *tracks;
        float minLon, minLat, maxLon, maxLat;
        int numSegs, numPoints;
        float totalDistance;
        CLLocation *last;
}

- (id)initWithFilename:(NSString*)newFilename;
- (void)addTrackPoint:(CLLocation*)loc;
- (void)addTrackSegment;
- (void)commit;
- (BOOL)isInTrackSegment;

@property (readonly, getter=numberOfTrackPoints) int numPoints;

@end
