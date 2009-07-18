//
//  GlingGPXWriter.m
//  Glint
//
//  Created by Jakob Borg on 7/10/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "GlintGPXWriter.h"

@implementation GlintGPXWriter

@synthesize inTrackSegment, inFile;

- (void)dealloc
{
        [filename release];
        [super dealloc];
}

- (id)initWithFilename:(NSString*)newFilename
{
        if (self = [self init]) {
                inTrackSegment = NO;
                totalDistance = 0.0;
                numPoints = 0;
                filename = [NSString stringWithString:newFilename];
                [filename retain];
        }
        return self;
}

- (void) appendToGPX: (NSString *) data  {
        NSFileHandle *aFileHandle;
        aFileHandle = [NSFileHandle fileHandleForWritingAtPath:filename];
        [aFileHandle truncateFileAtOffset:[aFileHandle seekToEndOfFile]];
        [aFileHandle writeData:[data dataUsingEncoding:NSASCIIStringEncoding]];
        [aFileHandle closeFile];
}

- (void)beginFile {
        NSString* start = @"<?xml version=\"1.0\" encoding=\"ASCII\" standalone=\"yes\"?>\n<gpx\n  version=\"1.1\"\n  creator=\"Glint http://noncommer.cial.se/glint\"\n  xmlns=\"http://www.topografix.com/GPX/1/1\"\n  xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n  xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd\">\n  <trk>\n";
        [start writeToFile:filename atomically:NO encoding:NSASCIIStringEncoding error:nil];
        inFile = YES;
}

- (void)endFile {
        NSString* end = [NSString stringWithFormat: @"  </trk>\n</gpx>\n<!-- totalDistance:%f numPoints:%d -->\n", totalDistance, numPoints];
        [self appendToGPX: end];
        inFile = NO;
}

- (void)beginTrackSegment {
        NSString* start = @"    <trkseg>\n";
        [self appendToGPX: start];
        inTrackSegment = YES;
}

- (void)endTrackSegment {
        NSString* end = @"    </trkseg>\n";
        [self appendToGPX: end];
        inTrackSegment = NO;
}

- (void)addPoint:(CLLocation*)loc {
        static CLLocation *last = nil;
        
        NSString* ts = [loc.timestamp descriptionWithCalendarFormat:@"%Y-%m-%dT%H:%M:%SZ" timeZone:nil locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
        
        NSString* data = [NSString stringWithFormat:@"      <trkpt lat=\"%f\" lon=\"%f\">\n        <ele>%f</ele>\n        <time>%@</time>\n      </trkpt>\n",
                          loc.coordinate.latitude, loc.coordinate.longitude, loc.altitude, ts];
        
        [self appendToGPX: data];
        numPoints ++;
        totalDistance += [last getDistanceFrom:loc];
        [last release];
        last = [loc retain];
}


@end
