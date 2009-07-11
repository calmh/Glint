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
        bool inTrackSegment;
        bool inFile;
}

- (id)initWithFilename:(NSString*)newFilename;
- (void)beginFile;
- (void)endFile;
- (void)beginTrackSegment;
- (void)endTrackSegment;
- (void)addPoint:(CLLocation*)loc;

@property (readonly) bool inTrackSegment;
@property (readonly) bool inFile;

@end
