//
//  GPXReader.h
//  Glint
//
//  Created by Jakob Borg on 7/25/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface GPXReader : NSObject {
        NSMutableArray *locations;
        
        NSDate *lastReadDate;
        float lastReadLat, lastReadLon;
        BOOL currentlyReadingTime;
}

- (id)initWithFilename:(NSString*)newFilename;
- (NSArray*)locations;

@end
