//
//  GlintViewController.h
//  Glint
//
//  Created by Jakob Borg on 6/26/09.
//  Copyright Jakob Borg 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "JBSoundEffect.h"
#import "GlintCompassView.h"

@interface GlintViewController : UIViewController  <CLLocationManagerDelegate> {
        CLLocationManager *locationManager;
        NSArray *unitSets;
        
        NSMutableArray *locations;
        NSString *filename;
        NSDate *startTime;
        double distance;
        JBSoundEffect *goodSound;
        JBSoundEffect *badSound;
        bool stateGood;
        int averagedMeasurements;
        CLLocation* currentLocation;
        NSMutableArray* directMeasurements;
        int lastSampleSize;
        bool inTrackSegment;
        
        UIImageView *statusIndicator;
        UILabel *positionLabel;
        UILabel *elapsedTimeLabel;
        UILabel *currentSpeedLabel;
        UILabel *averageSpeedLabel;
        UILabel *currentTimePerDistanceLabel;
        UILabel *currentTimePerDistanceDescrLabel;
        UILabel *totalDistanceLabel;
        UILabel *statusLabel;
        UILabel *bearingLabel;
        UILabel *accuracyLabel;
        UIProgressView *averageProgress;
        GlintCompassView *compass;
}

@property (retain) CLLocationManager *locationManager;
@property (retain) IBOutlet UIImageView *statusIndicator;
@property (retain) IBOutlet UILabel *positionLabel;
@property (retain) IBOutlet UILabel *elapsedTimeLabel;
@property (retain) IBOutlet UILabel *currentSpeedLabel;
@property (retain) IBOutlet UILabel *averageSpeedLabel;
@property (retain) IBOutlet UILabel *currentTimePerDistanceLabel;
@property (retain) IBOutlet UILabel *currentTimePerDistanceDescrLabel;
@property (retain) IBOutlet UILabel *totalDistanceLabel;
@property (retain) IBOutlet UILabel *statusLabel;
@property (retain) IBOutlet UILabel *bearingLabel;
@property (retain) IBOutlet UILabel *accuracyLabel;
@property (retain) IBOutlet UIProgressView* averageProgress;
@property (retain) CLLocation* currentLocation;
@property (retain) IBOutlet GlintCompassView *compass;

@end


