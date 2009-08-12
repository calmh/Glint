//
//  MainScreenViewController.m
//  Glint
//
//  Created by Jakob Borg on 6/26/09.
//  Copyright Jakob Borg 2009. All rights reserved.
//

#import "MainScreenViewController.h"

/*
 * Private methods
 */
@interface MainScreenViewController ()
- (bool)precisionAcceptable:(CLLocation*)location;
- (void)enableGPS;
- (void)disableGPS;
- (float)timeDifferenceInRace;
- (float)distDifferenceInRace;
- (void)positiveIndicator:(UILabel*)indicator;
- (void)negativeIndicator:(UILabel*)indicator;
- (void)disabledIndicator:(UILabel*)indicator;
@end

/*
 * Background threads
 */
@interface MainScreenViewController (backgroundThreads)
- (void)updateDisplay:(NSTimer*)timer;
- (void)takeAveragedMeasurement:(NSTimer*)timer;
@end

@implementation MainScreenViewController

@synthesize containerView, primaryView, secondaryView;
@synthesize pager;
@synthesize signalIndicator, recordingIndicator, racingIndicator;
@synthesize toolbar;
@synthesize measurementsLabel;

@synthesize elapsedTimeLabel, elapsedTimeDescrLabel;
@synthesize totalDistanceLabel, totalDistanceDescrLabel;
@synthesize currentSpeedLabel, currentSpeedDescrLabel;
@synthesize averageSpeedLabel, averageSpeedDescrLabel;
@synthesize currentTimePerDistanceLabel, currentTimePerDistanceDescrLabel;
@synthesize compass;

@synthesize latitudeLabel, latitudeDescrLabel;
@synthesize longitudeLabel, longitudeDescrLabel;
@synthesize elevationLabel, elevationDescrLabel;
@synthesize horAccuracyLabel, horAccuracyDescrLabel;
@synthesize verAccuracyLabel, verAccuracyDescrLabel;
@synthesize courseLabel, courseDescrLabel;

- (void)dealloc {
        [locationManager release];
        [math release];
        [goodSound release];
        [badSound release];
        [firstMeasurementDate release];
        [lastMeasurementDate release];
        [raceAgainstLocations release];
        [super dealloc];
}

- (void)viewDidLoad {
        [super viewDidLoad];
        
        delegate = [[UIApplication sharedApplication] delegate];
        
        [containerView addSubview:primaryView];
        [containerView addSubview:secondaryView];
        [containerView bringSubviewToFront:primaryView];
        
        math = [[JBLocationMath alloc] init];
        badSound = [[JBSoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Basso" ofType:@"aiff"]];
        goodSound = [[JBSoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Purr" ofType:@"aiff"]];
        firstMeasurementDate  = nil;
        lastMeasurementDate = nil;
        gpxWriter = nil;
        lockTimer = nil;
        gpsEnabled = YES;
        raceAgainstLocations = nil;
        
        [self disabledIndicator:signalIndicator];
        [self disabledIndicator:recordingIndicator];
        [self disabledIndicator:racingIndicator];
        
        UIBarButtonItem *unlockButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Unlock",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(unlock:)];
        UIBarButtonItem *sendButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Files",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(sendFiles:)];
        UIBarButtonItem *playButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Record",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(startStopRecording:)];
        UIBarButtonItem *stopRaceButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"End Race",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(endRace:)];
        lockedToolbarItems = [[NSArray arrayWithObject:unlockButton] retain];
        unlockedToolbarItems = [[NSArray arrayWithObjects:sendButton, playButton, stopRaceButton, nil] retain];
        [toolbar setItems:unlockedToolbarItems animated:YES];
        
        if (USERPREF_DISABLE_IDLE)
                [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        if (USERPREF_ENABLE_PROXIMITY)
                [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
        
        //self.measurementsLabel.text = @"-";
        
        // Primary page
        
        self.elapsedTimeLabel.text = @"00:00:00";
        self.totalDistanceLabel.text = @"-";
        self.currentSpeedLabel.text = @"?";
        self.averageSpeedLabel.text = @"?";
        self.currentTimePerDistanceLabel.text = @"?";
        self.elapsedTimeDescrLabel.text = NSLocalizedString(@"elapsed", nil);
        self.totalDistanceDescrLabel.text = NSLocalizedString(@"total distance", nil);
        self.currentSpeedDescrLabel.text = NSLocalizedString(@"cur speed", nil);
        
        // Secondary page
        
        self.latitudeLabel.text = @"-";
        self.longitudeLabel.text = @"-";
        self.elevationLabel.text = @"-";
        self.horAccuracyLabel.text = @"-";
        self.verAccuracyLabel.text = @"-";
        self.courseLabel.text = @"?";
        self.latitudeDescrLabel.text = NSLocalizedString(@"latitude", nil);
        self.longitudeDescrLabel.text = NSLocalizedString(@"longitude", nil);
        self.elevationDescrLabel.text = NSLocalizedString(@"altitude", nil);
        self.horAccuracyDescrLabel.text = NSLocalizedString(@"h. accuracy", nil);
        self.verAccuracyDescrLabel.text = NSLocalizedString(@"v. accuracy", nil);
        self.courseDescrLabel.text = NSLocalizedString(@"course", nil);
        
        NSString* bundleVer = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSString* marketVer = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        self.measurementsLabel.text = [NSString stringWithFormat:@"Glint %@ (%@)", marketVer, bundleVer];
        
        NSTimer* displayUpdater = [NSTimer timerWithTimeInterval:DISPLAY_THREAD_INTERVAL target:self selector:@selector(updateDisplay:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:displayUpdater forMode:NSDefaultRunLoopMode];
        NSTimer* averagedMeasurementTaker = [NSTimer timerWithTimeInterval:MEASUREMENT_THREAD_INTERVAL target:self selector:@selector(takeAveragedMeasurement:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:averagedMeasurementTaker forMode:NSDefaultRunLoopMode];
        
        [self enableGPS];
}

- (void)viewWillDisappear:(BOOL)animated
{
        [gpxWriter commit];
        [locationManager stopUpdatingLocation];
        locationManager.delegate = nil;
        
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
        
        [super viewWillDisappear:animated];
}

- (void)setRaceAgainstLocations:(NSArray*)locations {
        if (raceAgainstLocations != locations) {
                [raceAgainstLocations release];
                if (locations && [locations count] > 1) {
                        raceAgainstLocations = [locations retain];
                        [self positiveIndicator:racingIndicator];
                }
                else {
                        raceAgainstLocations = nil;
                }
        }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
        UITouch* touch = [touches anyObject];
        if (touch.view == containerView && touch.tapCount == 1) {
                pager.currentPage = (pager.currentPage + 1) % pager.numberOfPages;
                [self pageChanged:nil];
        }
}

/*
 * LocationManager Delegate
 */

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
        stateGood = [self precisionAcceptable:newLocation];
        if (stateGood) {
                if (!firstMeasurementDate) {
                        firstMeasurementDate = [[NSDate date] retain];
                } else {
                        // Update the position if it's previously unknown or if we've travelled a distance
                        // that exceeds half the average horizontal inaccuracy. This is to avoid too noisy movement.
                        CLLocation *last = [math lastKnownPosition];
                        if (!last || [last getDistanceFrom:newLocation] > (last.horizontalAccuracy + newLocation.horizontalAccuracy)/4.0f) {
                                [math updateLocation:newLocation];
                                currentDataSource = kGlintDataSourceMovement;
                        }
                }
        }
}

/*
 * IBActions
 */

- (void)slided:(id)sender {
        [self unlock:sender];
}

- (IBAction)unlock:(id)sender
{
        @synchronized (self) {
                debug_NSLog(@"unlock: start");
                //[toolbar setItems:unlockedToolbarItems animated:NO];
                
                if (gpxWriter)
                        [(UIBarButtonItem*) [unlockedToolbarItems objectAtIndex:1] setTitle:NSLocalizedString(@"End Recording", nil)];
                else
                        [(UIBarButtonItem*) [unlockedToolbarItems objectAtIndex:1] setTitle:NSLocalizedString(@"Record", nil)];
                
                if (raceAgainstLocations)
                        [(UIBarButtonItem*) [unlockedToolbarItems objectAtIndex:2] setEnabled:YES];
                else
                        [(UIBarButtonItem*) [unlockedToolbarItems objectAtIndex:2] setEnabled:NO];
                
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration:0.3];
                CGRect rect = slider.frame;
                rect.origin.y = self.view.frame.size.height + 1;
                [slider setFrame:rect];
                [UIView commitAnimations];
                //[slider setHidden:YES];
                
                if (lockTimer) {
                        [lockTimer invalidate];
                        [lockTimer release];
                }
                lockTimer = [NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(lock:) userInfo:nil repeats:NO];
                [lockTimer retain];
                [[NSRunLoop currentRunLoop] addTimer:lockTimer forMode:NSDefaultRunLoopMode];
                debug_NSLog(@"unlock: done");
        }
}

- (IBAction)lock:(id)sender
{
        @synchronized (self) {
                debug_NSLog(@"lock: start");
                if (lockTimer) {
                        [lockTimer invalidate];
                        [lockTimer release];
                        lockTimer = nil;
                }
                [slider reset];
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration:0.3];
                CGRect rect = slider.frame;
                rect.origin.y = self.view.frame.size.height - slider.frame.size.height;
                [slider setFrame:rect];
                [UIView commitAnimations];
                //[slider setHidden:NO];
                //[toolbar setItems:lockedToolbarItems animated:NO];
                debug_NSLog(@"lock: done");
        }
}

- (IBAction)sendFiles:(id)sender {
        [(GlintAppDelegate *)[[UIApplication sharedApplication] delegate] switchToSendFilesView:sender];
        [self lock:sender];
}

- (IBAction)startStopRecording:(id)sender
{
        if (!gpxWriter) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyyMMdd-HHmmss"];
                [self positiveIndicator:recordingIndicator];
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);	
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString* filename = [NSString stringWithFormat:@"%@/track-%@.gpx", documentsDirectory, [formatter stringFromDate:[NSDate date]]];
                gpxWriter = [[JBGPXWriter alloc] initWithFilename:filename];
                [gpxWriter addTrackSegment];
        } else {
                [self disabledIndicator:recordingIndicator];
                [gpxWriter commit];
                [gpxWriter release];
                gpxWriter = nil;
        }
        [self lock:sender];
}

- (IBAction)endRace:(id)sender {
        [raceAgainstLocations release];
        raceAgainstLocations = nil;
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"raceAgainstFile"];
        [self disabledIndicator:racingIndicator];
        [toolbar setItems:lockedToolbarItems animated:YES];
}

- (IBAction)pageChanged:(id)sender {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:1.2];
        [UIView setAnimationRepeatAutoreverses:NO];
        if (pager.currentPage == 0) {
                [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:containerView cache:YES];
                [containerView bringSubviewToFront:primaryView];
        } else if (pager.currentPage == 1) {
                [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:containerView cache:YES];
                [containerView bringSubviewToFront:secondaryView];
        }
        [UIView commitAnimations];
}

/*
 * Background threads
 */

- (void)takeAveragedMeasurement:(NSTimer*)timer
{
        static NSDate *lastWrittenDate = nil;
        static float averageInterval = 0.0;
        static BOOL powersave = NO;
        NSDate *now = [NSDate date];
        
        // Load user preferences the first time we need them.
        
        if (averageInterval == 0.0) {
                averageInterval = USERPREF_MEASUREMENT_INTERVAL;
                powersave = USERPREF_POWERSAVE;
        }
        
        // Check if the GPS is disabled, and if so if we should enable it to do a measurement.
        
        if (!gpsEnabled) {
                if ([now timeIntervalSinceDate:lastWrittenDate] > averageInterval-10 // It is soon time for a new measurement
                    || !gpxWriter) // Or, we are not recording
                        [self enableGPS];
                return;
        }
        
        // Check if it's time to save a trackpoint, and if we have enough precision.
        // If so, save it. If we dont have enough precision, create a break in the
        // track segment so this is reflected in the saved file.
        
        CLLocation *current = locationManager.location;
        debug_NSLog([locationManager.location description]);
        if (gpxWriter && (!lastWrittenDate || [now timeIntervalSinceDate:lastWrittenDate] >= averageInterval - MEASUREMENT_THREAD_INTERVAL/2.0 )) {
                if ([self precisionAcceptable:current]) {
                        debug_NSLog(@"Good precision, saving waypoint");
                        [lastWrittenDate release];
                        lastWrittenDate = [now retain];
                        [gpxWriter addTrackPoint:current];
                } else if ([gpxWriter isInTrackSegment]) {
                        debug_NSLog(@"Bad precision, breaking track segment");
                        [gpxWriter addTrackSegment];
                } else {
                        debug_NSLog(@"Bad precision, waiting for waypoint");                        
                }
        }
        
        // If the main screen statistics haven't been updated for a long time, do so now.
        
        if ([math lastKnownPosition] && [[math lastKnownPosition].timestamp timeIntervalSinceNow] < -FORCE_POSITION_UPDATE_INTERVAL && [self precisionAcceptable:current]) {
                [math updateLocation:current];
        }
        
        if (powersave // Power saving is enabled
            && gpsEnabled // The GPS is enabled
            && gpxWriter // We are recording
            && averageInterval >= 30 // Recording interval is at least 30 seconds
            && lastWrittenDate // We have written at least one position
            && [now timeIntervalSinceDate:lastWrittenDate] < averageInterval-10) // It is less than averageInterval-10 seconds since the last measurement
                [self disableGPS];
}

- (void)updateDisplay:(NSTimer*)timer
{
        static BOOL prevStateGood = NO;
        
        // Don't update the display if it's turned off by the proximity sensor.
        // Saves CPU cycles and battery time, I hope.
        
        if ([[UIDevice currentDevice] proximityState])
                return;
        
#ifdef SCREENSHOT
        stateGood = YES;
#endif
        
        // Update color of signal indicator, play sound on change
        
        if (!gpsEnabled)
                [self disabledIndicator:signalIndicator];
        else {
                if (stateGood)
                        [self positiveIndicator:signalIndicator];
                else
                        [self negativeIndicator:signalIndicator];
                
                if (USERPREF_SOUNDS && prevStateGood != stateGood) {
                        if (stateGood)
                                [goodSound play];
                        else
                                [badSound play];
                }
                prevStateGood = stateGood;
        }
        
        CLLocation *current = locationManager.location;
        [current retain];
        
        // Position and accuracy
        
        if (current) {
                //self.positionLabel.text = [NSString stringWithFormat:@"%@\n%@\nelev %.0f m", [delegate formatLat: current.coordinate.latitude], [delegate formatLon: current.coordinate.longitude], current.altitude];
                self.latitudeLabel.text = [delegate formatLat: current.coordinate.latitude];
                self.longitudeLabel.text = [delegate formatLon: current.coordinate.longitude];
                self.elevationLabel.text = [NSString stringWithFormat:@"%.0f m", current.altitude];
                //self.positionLabel.textColor = [UIColor whiteColor];
                if (current.horizontalAccuracy >= 0)
                        self.horAccuracyLabel.text = [NSString stringWithFormat:@"±%.0f m", current.horizontalAccuracy];
                else
                        self.horAccuracyLabel.text = @"±inf m";
                
                if (current.verticalAccuracy >= 0)
                        self.verAccuracyLabel.text = [NSString stringWithFormat:@"±%.0f m", current.verticalAccuracy];
                else
                        self.verAccuracyLabel.text = @"±inf m";
#ifdef SCREENSHOT
                self.horAccuracyLabel.text = @"±17 m";
                self.verAccuracyLabel.text = @"±inf m";
#endif
        }
        
        // Timer
        
        if (firstMeasurementDate)
                self.elapsedTimeLabel.text =  [delegate formatTimestamp:[[NSDate date] timeIntervalSinceDate:firstMeasurementDate] maxTime:86400 allowNegatives:NO];
#ifdef SCREENSHOT
        self.elapsedTimeLabel.text = [delegate formatTimestamp:945 maxTime:86400 allowNegatives:NO];
#endif
        // Total distance
        
        self.totalDistanceLabel.text = [delegate formatDistance:[math totalDistance]];
#ifdef SCREENSHOT
        self.totalDistanceLabel.text = [delegate formatDistance:3347];
#endif                
        // Current speed
        
        if ([math currentSpeed] >= 0.0)
                self.currentSpeedLabel.text = [delegate formatSpeed:[math currentSpeed]];
        else
                self.currentSpeedLabel.text = @"?";
#ifdef SCREENSHOT
        self.currentSpeedLabel.text = [delegate formatSpeed:3425.0f/945.0f];
#endif                
        
        //if (currentDataSource == kGlintDataSourceMovement)
        //        self.currentSpeedLabel.textColor = [UIColor colorWithRed:0xCC/255.0 green:0xFF/255.0 blue:0x66/255.0 alpha:1.0];
        //else if (currentDataSource == kGlintDataSourceTimer)
        //        self.currentSpeedLabel.textColor = [UIColor colorWithRed:0xA0/255.0 green:0xB5/255.0 blue:0x66/255.0 alpha:1.0];
        
        if (!raceAgainstLocations) {
                self.averageSpeedLabel.textColor = [UIColor colorWithRed:0xFF/255.0f green:0x80/255.0f blue:0x00/255.0f alpha:1.0f];
                self.currentTimePerDistanceLabel.textColor = [UIColor colorWithRed:0x66/255.0f green:0xFF/255.0f blue:0x66/255.0f alpha:1.0f];

                // Average speed and time per configured distance
                
                self.averageSpeedLabel.text = [delegate formatSpeed:[math averageSpeed]];
                self.averageSpeedDescrLabel.text = NSLocalizedString(@"avg speed", nil);
                
                float secsPerEstDist = USERPREF_ESTIMATE_DISTANCE * 1000.0 / [math currentSpeed];
                self.currentTimePerDistanceLabel.text = [delegate formatTimestamp:secsPerEstDist maxTime:86400 allowNegatives:NO];
                NSString *distStr = [delegate formatDistance:USERPREF_ESTIMATE_DISTANCE*1000.0];
                self.currentTimePerDistanceDescrLabel.text = [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"per", @"... per (distance)"), distStr];
#ifdef SCREENSHOT
                self.averageSpeedLabel.text = [delegate formatSpeed:3300.0f/945.0f];
                self.currentTimePerDistanceLabel.text = [delegate formatTimestamp:USERPREF_ESTIMATE_DISTANCE * 1000.0 / (3425.0f/945.0f) maxTime:86400 allowNegatives:NO];
#endif                
        } else {
                // Difference in time and distance against raceAgainstLocations.
                
                float distDiff = [self distDifferenceInRace];
                if (!isnan(distDiff)) {
                        NSString *distString = [delegate formatDistance:distDiff];
                        self.averageSpeedLabel.text = [distDiff < 0.0 ? @"" : @"+" stringByAppendingString:distString];
                } else {
                        self.averageSpeedLabel.text = @"?";
                }
                self.averageSpeedDescrLabel.text = NSLocalizedString(@"dist diff", nil);
                if (distDiff < 0.0)
                        self.averageSpeedLabel.textColor = [UIColor colorWithRed:0xFF/255.0 green:0x40/255.0 blue:0x40/255.0 alpha:1.0];
                else
                        self.averageSpeedLabel.textColor = [UIColor colorWithRed:0x40/255.0 green:0xFF/255.0 blue:0x40/255.0 alpha:1.0];
                
                float timeDiff = [self timeDifferenceInRace];
                self.currentTimePerDistanceLabel.text = [delegate formatTimestamp:timeDiff maxTime:86400 allowNegatives:YES];
                self.currentTimePerDistanceDescrLabel.text = NSLocalizedString(@"time diff", nil);
                if (timeDiff > 0.0)
                        self.currentTimePerDistanceLabel.textColor = [UIColor colorWithRed:0xFF/255.0 green:0x40/255.0 blue:0x40/255.0 alpha:1.0];
                else
                        self.currentTimePerDistanceLabel.textColor = [UIColor colorWithRed:0x40/255.0 green:0xFF/255.0 blue:0x40/255.0 alpha:1.0];
        }
        
        // Number of saved measurements
        
#ifdef SCREENSHOT
        self.measurementsLabel.text = [NSString stringWithFormat:@"%d %@", 67, NSLocalizedString(@"measurements", nil)];
#else
        if (gpxWriter)
                self.measurementsLabel.text = [NSString stringWithFormat:@"%d %@", [gpxWriter numberOfTrackPoints], NSLocalizedString(@"measurements", nil)];
#endif
        
        // Current course
        
#ifdef SCREENSHOT
        self.compass.course = 233.0f;
        self.courseLabel.text = [NSString stringWithFormat:@"%.0f°", 233.0f];
#else
        self.compass.course = [math currentCourse];
        self.courseLabel.text = [NSString stringWithFormat:@"%.0f°", [math currentCourse]];
#endif   
        [current release];
}

/*
 * Private methods
 */

- (void)enableGPS {
        debug_NSLog(@"Starting GPS");
        locationManager = [[CLLocationManager alloc] init];
        locationManager.distanceFilter = FILTER_DISTANCE;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.delegate = self;
        [locationManager startUpdatingLocation];
        gpsEnabled = YES;
}

- (void)disableGPS {
        debug_NSLog(@"Stopping GPS");
        locationManager.delegate = nil;
        [locationManager stopUpdatingHeading];
        [locationManager release];
        locationManager = nil;
        gpsEnabled = NO;
}

// How far ahead (-) or behind (+) in time we are.
- (float)timeDifferenceInRace {
#ifdef SCREENSHOT
        float raceTime = [math timeAtLocationByDistance:3425.0f inLocations:raceAgainstLocations];
        return 945.0f - raceTime;
#else
        float raceTime = [math timeAtLocationByDistance:[math estimatedTotalDistance] inLocations:raceAgainstLocations];
        return [[NSDate date] timeIntervalSinceDate:firstMeasurementDate] - raceTime;
#endif
}

// How far ahead (+) or behind (-) in position we are.
- (float)distDifferenceInRace {
#ifdef SCREENSHOT
        float raceDist = [math distanceAtPointInTime:945.0f inLocations:raceAgainstLocations];
        return 3425.0f - raceDist;
#else
        float raceDist = [math distanceAtPointInTime:[[NSDate date] timeIntervalSinceDate:firstMeasurementDate] inLocations:raceAgainstLocations];
        return [math estimatedTotalDistance] - raceDist;
#endif   
}

// Color the specified UILabel green
- (void)positiveIndicator:(UILabel*)indicator {
        indicator.backgroundColor = [UIColor colorWithRed:0.4 green:1.0 blue:0.4 alpha:1.0];
        indicator.textColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:1.0];
}

// Color the specified UILabel red
- (void)negativeIndicator:(UILabel*)indicator {
        indicator.backgroundColor = [UIColor colorWithRed:1.0 green:0.4 blue:0.4 alpha:1.0];
        indicator.textColor = [UIColor colorWithRed:0.5 green:0.0 blue:0.0 alpha:1.0];
}

// Color the specified UILabel gray
- (void)disabledIndicator:(UILabel*)indicator {
        indicator.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
        indicator.textColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0];
}

- (bool)precisionAcceptable:(CLLocation*)location {
        static float minPrec = 0.0;
        if (minPrec == 0.0)
                minPrec = USERPREF_MINIMUM_PRECISION;
        float currentPrec = location.horizontalAccuracy;
        return currentPrec > 0.0 && currentPrec <= minPrec;
}

@end
