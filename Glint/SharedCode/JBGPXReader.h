//
//  GPXReader.h
//  Glint
//
//  Created by Jakob Borg on 7/25/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "JBLocationMath.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

typedef enum {
	Nothing,
	Time,
	Elevation
} CurrentlyReadingEnum;

@interface JBGPXReader : NSObject {
	JBLocationMath *locationMath;

	NSDate *lastReadDate;
	float lastReadLat, lastReadLon, lastReadElevation;
	CurrentlyReadingEnum currentlyReading;
	BOOL shouldAddBreakMarker;
}

- (id)initWithFilename:(NSString*)newFilename;

@property (readonly) NSArray *locations;
@property (readonly) JBLocationMath *locationMath;

@end
