//
//  GPXWriter.m
//  Glint
//
//  Created by Jakob Borg on 7/10/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "JBGPXWriter.h"

@implementation JBGPXWriter

@synthesize numPoints;
@synthesize autoCommit;

- (void)dealloc
{
        [filename release];
        [tracks release];
        [last release];
        [super dealloc];
}

- (id)initWithFilename:(NSString*)newFilename
{
        if (self = [self init]) {
                filename = [NSString stringWithString:newFilename];
                [filename retain];
                tracks = [[NSMutableArray alloc] init];
                minLon = minLat = maxLon = maxLat = totalDistance = 0.0;
                numSegs = numPoints = 0;
                last = nil;
                lastCommit = nil;
                autoCommit = NO;
        }
        return self;
}

- (void)addTrackSegment {
        [tracks addObject:[NSMutableArray array]];
        [last release];
        last = nil;
        numSegs++;
}

- (void)addTrackPoint:(CLLocation*)point {
        if (last && [point getDistanceFrom:last] == 0.0) {
                debug_NSLog(@"addTrackPoint: Ignored identical waypoint");
                return;
        }
        
        [[tracks lastObject] addObject:point];
        numPoints++;
        
        minLon = MIN(minLon, point.coordinate.longitude);
        maxLon = MAX(maxLon, point.coordinate.latitude);
        minLat = MIN(minLat, point.coordinate.longitude);
        maxLat = MAX(maxLat, point.coordinate.latitude);

        if (last)
                totalDistance += [point getDistanceFrom:last];
        
        [last release];
        last = [point retain];
        debug_NSLog(@"addTrackPoint: Saved new waypoint");
        
        if (autoCommit && (lastCommit == nil || [[NSDate date] timeIntervalSinceDate:lastCommit] > AUTO_COMMIT_INTERVAL))
                [self performSelectorInBackground:@selector(commit) withObject:nil];
}

- (void)commit {
        if (numPoints < 1)
                return;
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        NSMutableString *gpxData = [NSMutableString string];
        [gpxData appendString:@"<?xml version='1.0' encoding='UTF-8' standalone='yes'?>\n"];
        [gpxData appendString:@"<gpx version='1.1' creator='Glint http://glint.nym.se/' xmlns='http://www.topografix.com/GPX/1/1' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xsi:schemaLocation='http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd'>\n"];
        [gpxData appendFormat:@"  <!-- [numPoints]%d[/numPoints] -->\n", numPoints];
        [gpxData appendFormat:@"  <!-- [totalDistance]%f[/totalDistance] -->\n", totalDistance];
        [gpxData appendFormat:@"  <time>%@</time>\n", [formatter stringFromDate:[NSDate date]]];
        [gpxData appendFormat:@"  <bounds minlat='%f' minlon='%f' maxlat='%f' maxlon='%f'/>\n", minLat, minLon, maxLat, maxLon];
        [gpxData appendString:@"  <trk>\n"];
        for (NSArray *track in tracks) {
                if ([track count] == 0)
                        continue;
                [gpxData appendString:@"    <trkseg>\n"];
                for (CLLocation *point in track) {
                        [gpxData appendFormat:@"      <trkpt lat='%f' lon='%f'>\n", point.coordinate.latitude, point.coordinate.longitude];
                        [gpxData appendFormat:@"        <ele>%f</ele>\n", point.altitude];
                        [gpxData appendFormat:@"        <time>%@</time>\n", [formatter stringFromDate:point.timestamp]];
                        [gpxData appendString:@"      </trkpt>\n"];
                }
                [gpxData appendString:@"    </trkseg>\n"];
        }
        [gpxData appendString:@"  </trk>\n"];
        [gpxData appendString:@"</gpx>\n"];
        [gpxData writeToFile:filename atomically:NO encoding:NSASCIIStringEncoding error:nil];
        [formatter release];
        [lastCommit release];
        lastCommit = [[NSDate date] retain];
}

- (BOOL)isInTrackSegment {
        return ([tracks count] > 0 && [[tracks lastObject] count] > 0);
}

@end
