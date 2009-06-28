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

@interface GlintViewController : UIViewController  <CLLocationManagerDelegate> {
        CLLocationManager *locationManager;
        NSArray *unitSets;
        int unitSetIndex;
        
        NSMutableArray *locations;
        NSString *filename;
        NSDate *startTime;
        double distance;
        JBSoundEffect *goodSound;
        JBSoundEffect *badSound;
        bool stateGood;
        int averagedMeasurements;
        CLLocation* lastLocation;
        CLLocation* currentLocation;
        NSMutableArray* directMeasurements;
        int lastSampleSize;
        
        UIImageView *statusIndicator;
        UILabel *positionLabel;
        UILabel *elapsedTimeLabel;
        UILabel *currentSpeedLabel;
        UILabel *averageSpeedLabel;
        UILabel *currentTimePerKmLabel;
        UILabel *totalDistanceLabel;
        UILabel *statusLabel;
        UILabel *slopeLabel;
        UILabel *accuracyLabel;
        UIProgressView* averageProgress;
}

@property (retain) CLLocationManager *locationManager;
@property (retain) IBOutlet UIImageView *statusIndicator;
@property (retain) IBOutlet UILabel *positionLabel;
@property (retain) IBOutlet UILabel *elapsedTimeLabel;
@property (retain) IBOutlet UILabel *currentSpeedLabel;
@property (retain) IBOutlet UILabel *averageSpeedLabel;
@property (retain) IBOutlet UILabel *currentTimePerKmLabel;
@property (retain) IBOutlet UILabel *totalDistanceLabel;
@property (retain) IBOutlet UILabel *totalDistanceUnitLabel;
@property (retain) IBOutlet UILabel *statusLabel;
@property (retain) IBOutlet UILabel *slopeLabel;
@property (retain) IBOutlet UILabel *accuracyLabel;
@property (retain) IBOutlet UIProgressView* averageProgress;
@property (retain) CLLocation* lastLocation;
@property (retain) CLLocation* currentLocation;

@end


