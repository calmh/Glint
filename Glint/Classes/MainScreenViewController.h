//
// MainScreenViewController.h
// Glint
//
// Created by Jakob Borg on 6/26/09.
// Copyright Jakob Borg 2009. All rights reserved.
//

#import "CompassView.h"
#import "GPSManager.h"
#import "GlintAppDelegate.h"
#import "GradientLabel.h"
#import "LapTimeViewController.h"
#import "LocationMath.h"
#import "SlideView.h"
#import "SoundEffect.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>

@interface MainScreenViewController : UIViewController  <CLLocationManagerDelegate, SlideViewDelegate> {
        GlintAppDelegate *delegate;
        GPSManager *gpsManager;

        NSArray *unitSets;
        NSDate *firstMeasurementDate;
        NSDate *lastMeasurementDate;
        SoundEffect *goodSound, *badSound, *lapSound;
        NSArray *toolbarItems;
        NSTimer *lockTimer;

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

        UILabel *primaryScreenDescription;
        UILabel *elapsedTimeLabel, *elapsedTimeDescrLabel;
        UILabel *totalDistanceLabel, *totalDistanceDescrLabel;
        UILabel *currentSpeedLabel, *currentSpeedDescrLabel;
        UILabel *averageSpeedLabel, *averageSpeedDescrLabel;
        UILabel *currentTimePerDistanceLabel, *currentTimePerDistanceDescrLabel;
        CompassView *compass;

        // Secondary stats page

        UILabel *secondaryScreenDescription;
        UILabel *latitudeLabel, *latitudeDescrLabel;
        UILabel *longitudeLabel, *longitudeDescrLabel;
        UILabel *elevationLabel, *elevationDescrLabel;
        UILabel *horAccuracyLabel, *horAccuracyDescrLabel;
        UILabel *verAccuracyLabel, *verAccuracyDescrLabel;
        UILabel *courseLabel, *courseDescrLabel;

        // Tertiary page
        UILabel *tertiaryScreenDescription;
        LapTimeViewController *lapTimeController;
}

@property (nonatomic, retain) IBOutlet UIView *containerView, *primaryView, *secondaryView, *tertiaryView;
@property (nonatomic, retain) IBOutlet UIPageControl *pager;
@property (nonatomic, retain) IBOutlet UILabel *signalIndicator, *recordingIndicator, *racingIndicator;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UILabel *measurementsLabel;
@property (nonatomic, retain) IBOutlet SlideView *slider;

@property (nonatomic, retain) IBOutlet UILabel *primaryScreenDescription;
@property (nonatomic, retain) IBOutlet UILabel *elapsedTimeLabel, *elapsedTimeDescrLabel;
@property (nonatomic, retain) IBOutlet UILabel *totalDistanceLabel, *totalDistanceDescrLabel;
@property (nonatomic, retain) IBOutlet UILabel *currentSpeedLabel, *currentSpeedDescrLabel;
@property (nonatomic, retain) IBOutlet UILabel *averageSpeedLabel, *averageSpeedDescrLabel;
@property (nonatomic, retain) IBOutlet UILabel *currentTimePerDistanceLabel, *currentTimePerDistanceDescrLabel;
@property (nonatomic, retain) IBOutlet CompassView *compass;

@property (nonatomic, retain) IBOutlet UILabel *secondaryScreenDescription;
@property (nonatomic, retain) IBOutlet UILabel *latitudeLabel, *latitudeDescrLabel;
@property (nonatomic, retain) IBOutlet UILabel *longitudeLabel, *longitudeDescrLabel;
@property (nonatomic, retain) IBOutlet UILabel *elevationLabel, *elevationDescrLabel;
@property (nonatomic, retain) IBOutlet UILabel *horAccuracyLabel, *horAccuracyDescrLabel;
@property (nonatomic, retain) IBOutlet UILabel *verAccuracyLabel, *verAccuracyDescrLabel;
@property (nonatomic, retain) IBOutlet UILabel *courseLabel, *courseDescrLabel;

@property (nonatomic, retain) IBOutlet UILabel *tertiaryScreenDescription;
@property (nonatomic, retain) IBOutlet LapTimeViewController *lapTimeController;

- (void)playPause:(id)sender;
- (void)startStopRecording:(id)sender;
- (void)resumeRecordingOnFile:(NSString*)filename;
- (void)slided:(id)sender;
- (void)endRace:(id)sender;
- (IBAction)pageChanged:(id)sender;
- (void)updateStatus:(NSTimer*)timer;
- (void)updateDisplay:(NSTimer*)timer;
@end
