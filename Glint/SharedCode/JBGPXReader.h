//
//  GPXReader.h
//  Glint
//
//  Created by Jakob Borg on 7/25/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "JBLocationMath.h"

@interface JBGPXReader : NSObject {
        JBLocationMath *locationMath;

        NSDate *lastReadDate;
        float lastReadLat, lastReadLon;
        BOOL currentlyReadingTime;
        BOOL shouldAddBreakMarker;
}

- (id)initWithFilename:(NSString*)newFilename;

@property (readonly) NSArray *locations;
@property (readonly) JBLocationMath *locationMath;

@end
