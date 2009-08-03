//
//  MainScreenViewController.h
//  Glint
//
//  Created by Jakob Borg on 6/26/09.
//  Copyright Jakob Borg 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "JBSoundEffect.h"
#import "JBLocationMath.h"
#import "CompassView.h"
#import "JBGPXWriter.h"
#import "GlintAppDelegate.h"
#import "JBGradientLabel.h"

typedef enum enumGlintDataSource {
        kGlintDataSourceMovement,
        kGlintDataSourceTimer
} GlintDataSource;

@interface MainScreenViewController : UIViewController  <CLLocationManagerDelegate> {
        GlintAppDelegate *delegate;
        CLLocationManager *locationManager;
        JBLocationMath *math;
        NSArray *unitSets;
        JBGPXWriter *gpxWriter;
        NSDate *firstMeasurementDate;
        NSDate *lastMeasurementDate;
        GlintDataSource currentDataSource;
        JBSoundEffect *goodSound;
        JBSoundEffect *badSound;
        BOOL gpsEnabled;
        NSArray *lockedToolbarItems;
        NSArray *unlockedToolbarItems;
        NSTimer *lockTimer;
        NSArray *raceAgainstLocations;
        BOOL stateGood;

        // Main screen
        
        UIView *containerView, *primaryView, *secondaryView;
        UIPageControl *pager;
        UILabel *signalIndicator, *recordingIndicator, *racingIndicator;
        UIToolbar *toolbar;
        UILabel *measurementsLabel;
        
        // Primary stats page
        
        UILabel *elapsedTimeLabel, *elapsedTimeDescrLabel;
        UILabel *totalDistanceLabel, *totalDistanceDescrLabel;
        UILabel *currentSpeedLabel, *currentSpeedDescrLabel;
        UILabel *averageSpeedLabel, *averageSpeedDescrLabel;
        UILabel *currentTimePerDistanceLabel, *currentTimePerDistanceDescrLabel;
        CompassView *compass;

        // Secondary stats page
        
        UILabel *latitudeLabel, *latitudeDescrLabel;
        UILabel *longitudeLabel, *longitudeDescrLabel;
        UILabel *elevationLabel, *elevationDescrLabel;
        UILabel *horAccuracyLabel, *horAccuracyDescrLabel;
        UILabel *verAccuracyLabel, *verAccuracyDescrLabel;
        UILabel *courseLabel, *courseDescrLabel;
}

@property (nonatomic, retain) IBOutlet UIView *containerView, *primaryView, *secondaryView;
@property (nonatomic, retain) IBOutlet UIPageControl *pager;
@property (nonatomic, retain) IBOutlet UILabel *signalIndicator, *recordingIndicator, *racingIndicator;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UILabel *measurementsLabel;

@property (nonatomic, retain) IBOutlet UILabel *elapsedTimeLabel, *elapsedTimeDescrLabel;
@property (nonatomic, retain) IBOutlet UILabel *totalDistanceLabel, *totalDistanceDescrLabel;
@property (nonatomic, retain) IBOutlet UILabel *currentSpeedLabel, *currentSpeedDescrLabel;
@property (nonatomic, retain) IBOutlet UILabel *averageSpeedLabel, *averageSpeedDescrLabel;
@property (nonatomic, retain) IBOutlet UILabel *currentTimePerDistanceLabel, *currentTimePerDistanceDescrLabel;
@property (nonatomic, retain) IBOutlet CompassView *compass;

@property (nonatomic, retain) IBOutlet UILabel *latitudeLabel, *latitudeDescrLabel;
@property (nonatomic, retain) IBOutlet UILabel *longitudeLabel, *longitudeDescrLabel;
@property (nonatomic, retain) IBOutlet UILabel *elevationLabel, *elevationDescrLabel;
@property (nonatomic, retain) IBOutlet UILabel *horAccuracyLabel, *horAccuracyDescrLabel;        
@property (nonatomic, retain) IBOutlet UILabel *verAccuracyLabel, *verAccuracyDescrLabel;        
@property (nonatomic, retain) IBOutlet UILabel *courseLabel, *courseDescrLabel;

- (void)setRaceAgainstLocations:(NSArray*)locations;

- (IBAction)startStopRecording:(id)sender;
- (IBAction)unlock:(id)sender;
- (IBAction)endRace:(id)sender;
- (IBAction)pageChanged:(id)sender;

@end
