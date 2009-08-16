//
//  MainScreenViewController.h
//  Glint
//
//  Created by Jakob Borg on 6/26/09.
//  Copyright Jakob Borg 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "JBSoundEffect.h"
#import "JBLocationMath.h"
#import "JBGPXWriter.h"
#import "JBGradientLabel.h"
#import "CompassView.h"
#import "GlintAppDelegate.h"
#import "SlideView.h"
#import "LapTimeViewController.h"

typedef enum enumGlintDataSource {
        kGlintDataSourceMovement,
        kGlintDataSourceTimer
} GlintDataSource;

@interface MainScreenViewController : UIViewController  <CLLocationManagerDelegate, SlideViewDelegate> {
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
        NSArray *toolbarItems;
        NSTimer *lockTimer;
        NSArray *raceAgainstLocations;
        BOOL stateGood;
        
        CGPoint touchStartPoint;
        NSDate *touchStartTime;

        // Main screen
        
        UIView *containerView, *primaryView, *secondaryView, *tertiaryView;
        UIPageControl *pager;
        UILabel *signalIndicator, *recordingIndicator, *racingIndicator;
        UIToolbar *toolbar;
        UILabel *measurementsLabel;
        SlideView *slider;
        
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
        
        // Tertiary page
        LapTimeViewController *lapTimeController;
        
}

@property (nonatomic, retain) IBOutlet UIView *containerView, *primaryView, *secondaryView, *tertiaryView;
@property (nonatomic, retain) IBOutlet UIPageControl *pager;
@property (nonatomic, retain) IBOutlet UILabel *signalIndicator, *recordingIndicator, *racingIndicator;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UILabel *measurementsLabel;
@property (nonatomic, retain) IBOutlet SlideView *slider;

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

@property (nonatomic, retain) IBOutlet LapTimeViewController *lapTimeController;

- (void)setRaceAgainstLocations:(NSArray*)locations;

- (IBAction)startStopRecording:(id)sender;
- (void)slided:(id)sender;
- (IBAction)unlock:(id)sender;
- (IBAction)endRace:(id)sender;
- (IBAction)pageChanged:(id)sender;

@end
