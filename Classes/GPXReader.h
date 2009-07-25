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

@property (readonly) NSArray *locations;

- (id)initWithFilename:(NSString*)newFilename;

@end
