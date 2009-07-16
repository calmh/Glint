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
#import "GlintGPXWriter.h"

@interface GlintViewController : UIViewController  <CLLocationManagerDelegate> {
        CLLocationManager *locationManager;
        NSArray *unitSets;
        GlintGPXWriter *gpxWriter;
        NSDate *firstMeasurement;
        NSDate *lastMeasurement;
        double totalDistance;
        JBSoundEffect *goodSound;
        JBSoundEffect *badSound;
        int averagedMeasurements;
        bool recording;
        double currentCourse;
        double currentSpeed;
        NSArray *lockedToolbarItems;
        NSArray *recordingToolbarItems;
        NSArray *pausedToolbarItems;
        NSTimer *lockTimer;

        // Properties
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
        UILabel *recordingIndicator;
        UILabel *signalIndicator;
        UIToolbar *toolbar;
        GlintCompassView *compass;
}

@property (nonatomic, retain) IBOutlet UIImageView *statusIndicator;
@property (nonatomic, retain) IBOutlet UILabel *positionLabel;
@property (nonatomic, retain) IBOutlet UILabel *elapsedTimeLabel;
@property (nonatomic, retain) IBOutlet UILabel *currentSpeedLabel;
@property (nonatomic, retain) IBOutlet UILabel *averageSpeedLabel;
@property (nonatomic, retain) IBOutlet UILabel *currentTimePerDistanceLabel;
@property (nonatomic, retain) IBOutlet UILabel *currentTimePerDistanceDescrLabel;
@property (nonatomic, retain) IBOutlet UILabel *totalDistanceLabel;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;
@property (nonatomic, retain) IBOutlet UILabel *bearingLabel;
@property (nonatomic, retain) IBOutlet UILabel *accuracyLabel;
@property (nonatomic, retain) IBOutlet UILabel *recordingIndicator;
@property (nonatomic, retain) IBOutlet UILabel *signalIndicator;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet GlintCompassView *compass;

- (IBAction)startStopRecording:(id)sender;
- (IBAction)unlock:(id)sender;

@end


