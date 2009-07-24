//
//  MainScreenViewController.m
//  Glint
//
//  Created by Jakob Borg on 6/26/09.
//  Copyright Jakob Borg 2009. All rights reserved.
//

#import "MainScreenViewController.h"

//
// Private methods
//
@interface MainScreenViewController ()
- (NSString*)formatTimestamp:(float)seconds maxTime:(float)max;
- (NSString*) formatDMS:(float)latLong;
- (NSString*)formatLat:(float)lat;
- (NSString*)formatLon:(float)lon;
- (bool)precisionAcceptable:(CLLocation*)location;
- (float) speedFromLocation:(CLLocation*)locA toLocation:(CLLocation*)locB;
- (float) bearingFromLocation:(CLLocation*)loc1 toLocation:(CLLocation*)loc2;
- (void)enableGPS;
- (void)disableGPS;
- (void)tests;
@end

//
// Background threads
//
@interface MainScreenViewController (backgroundThreads)
- (void)updateDisplay:(NSTimer*)timer;
- (void)takeAveragedMeasurement:(NSTimer*)timer;
@end

@implementation MainScreenViewController
@synthesize positionLabel, elapsedTimeLabel, currentSpeedLabel, currentTimePerDistanceLabel, totalDistanceLabel, statusLabel, averageSpeedLabel, bearingLabel, accuracyLabel;
@synthesize elapsedTimeDescrLabel, totalDistanceDescrLabel, currentTimePerDistanceDescrLabel, currentSpeedDescrLabel, averageSpeedDescrLabel;
@synthesize toolbar, compass, recordingIndicator, signalIndicator;

- (void)dealloc {
        self.positionLabel = nil;
        self.elapsedTimeLabel = nil;
        self.currentSpeedLabel = nil;
        self.currentTimePerDistanceLabel = nil;
        self.totalDistanceLabel = nil;
        self.statusLabel = nil;
        self.averageSpeedLabel = nil;
        self.bearingLabel = nil;
        self.accuracyLabel = nil;
        self.compass = nil;
        self.recordingIndicator = nil;
        self.elapsedTimeDescrLabel = nil;
        self.totalDistanceDescrLabel = nil;
        self.currentTimePerDistanceDescrLabel = nil;
        self.currentSpeedDescrLabel = nil;
        self.averageSpeedDescrLabel = nil;
        
        [locationManager release];
        [goodSound release];
        [badSound release];
        [firstMeasurementDate release];
        [lastMeasurementDate release];
        [previousMeasurement release];
        [super dealloc];
}

- (void)viewDidLoad {
        [super viewDidLoad];
        
        badSound = [[JBSoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Basso" ofType:@"aiff"]];
        goodSound = [[JBSoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Purr" ofType:@"aiff"]];
        firstMeasurementDate  = nil;
        lastMeasurementDate = nil;
        totalDistance = 0.0;
        currentSpeed = -1.0;
        currentCourse = -1.0;
        gpxWriter = nil;
        lockTimer = nil;
        previousMeasurement = nil;
        gpsEnabled = YES;
        
        UIBarButtonItem *unlockButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Unlock", @"Unlock") style:UIBarButtonItemStyleBordered target:self action:@selector(unlock:)];
        UIBarButtonItem *disabledUnlockButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Unlock", @"Unlock") style:UIBarButtonItemStyleBordered target:self action:@selector(unlock:)];
        UIBarButtonItem *sendButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Files", @"Files") style:UIBarButtonItemStyleBordered target:self action:@selector(sendFiles:)];
        UIBarButtonItem *playButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Record", @"Record") style:UIBarButtonItemStyleBordered target:self action:@selector(startStopRecording:)];
        UIBarButtonItem *stopButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Stop Recording", @"Stop Recording") style:UIBarButtonItemStyleBordered target:self action:@selector(startStopRecording:)];
        [disabledUnlockButton setEnabled:NO];
        lockedToolbarItems = [[NSArray arrayWithObject:unlockButton] retain];
        recordingToolbarItems = [[NSArray arrayWithObjects:disabledUnlockButton, sendButton, stopButton, nil] retain];
        pausedToolbarItems = [[NSArray arrayWithObjects:disabledUnlockButton, sendButton, playButton, nil] retain];
        [toolbar setItems:lockedToolbarItems animated:YES];
        
        NSString *path=[[NSBundle mainBundle] pathForResource:@"unitsets" ofType:@"plist"];
        unitSets = [NSArray arrayWithContentsOfFile:path];
        [unitSets retain];
        
        if (USERPREF_DISABLE_IDLE)
                [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        if (USERPREF_ENABLE_PROXIMITY)
                [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
        
        self.elapsedTimeDescrLabel.text = NSLocalizedString(@"elapsed", nil);
        self.totalDistanceDescrLabel.text = NSLocalizedString(@"total distance", nil);
        self.currentSpeedDescrLabel.text = NSLocalizedString(@"cur speed", nil);
        self.averageSpeedDescrLabel.text = NSLocalizedString(@"avg speed", nil);
        
        self.positionLabel.text = @"-";
        self.accuracyLabel.text = @"-";
        self.elapsedTimeLabel.text = @"00:00:00";
        
        self.totalDistanceLabel.text = @"-";
        self.currentSpeedLabel.text = @"?";
        self.averageSpeedLabel.text = @"?";
        self.currentTimePerDistanceLabel.text = @"?";
        NSString* bundleVer = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSString* marketVer = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        self.statusLabel.text = [NSString stringWithFormat:@"Glint %@ (%@)", marketVer, bundleVer];
        
        NSTimer* displayUpdater = [NSTimer timerWithTimeInterval:DISPLAY_THREAD_INTERVAL target:self selector:@selector(updateDisplay:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:displayUpdater forMode:NSDefaultRunLoopMode];
        NSTimer* averagedMeasurementTaker = [NSTimer timerWithTimeInterval:MEASUREMENT_THREAD_INTERVAL target:self selector:@selector(takeAveragedMeasurement:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:averagedMeasurementTaker forMode:NSDefaultRunLoopMode];
        
        [self enableGPS];
        
        [self tests];
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

/*
 * LocationManager Delegate
 */

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
#ifdef SCREENSHOT
        totalDistance = 5632.0;
        currentCourse = 275.0;
        currentSpeed = 3.2;
        currentDataSource = kGlintDataSourceMovement;
        NSDateComponents *comps = [[NSDateComponents alloc] init];
        [comps setMinute:-29];
        firstMeasurementDate = [[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:[NSDate date] options:0];
        [firstMeasurementDate retain];
#else
        if ([self precisionAcceptable:newLocation]) {
                @synchronized (self) {
                        if (!firstMeasurementDate)
                                firstMeasurementDate = [[NSDate date] retain];
                        if (!previousMeasurement) {
                                previousMeasurement = [newLocation retain];
                        } else {
                                float dist = [previousMeasurement getDistanceFrom:newLocation];
                                if (dist > 25.0) {
                                        totalDistance += dist;
                                        currentCourse = [self bearingFromLocation:previousMeasurement toLocation:newLocation];
                                        currentSpeed = [self speedFromLocation:previousMeasurement toLocation:newLocation];
                                        [previousMeasurement release];
                                        previousMeasurement = [newLocation retain];
                                        currentDataSource = kGlintDataSourceMovement;
                                        //[locationManager setDistanceFilter:2*previousMeasurement.horizontalAccuracy];
                                }
                        }
                }
        }
#endif
        [lastMeasurementDate release];
        lastMeasurementDate = [[NSDate date] retain];
}

/*
 * IBActions
 */

- (IBAction)unlock:(id)sender
{
        if (gpxWriter)
                [toolbar setItems:recordingToolbarItems animated:YES];
        else
                [toolbar setItems:pausedToolbarItems animated:YES];
        
        if (lockTimer) {
                [lockTimer invalidate];
                [lockTimer release];
                lockTimer = nil;
        }
        lockTimer = [NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(lock:) userInfo:nil repeats:NO];
        [lockTimer retain];
        [[NSRunLoop currentRunLoop] addTimer:lockTimer forMode:NSDefaultRunLoopMode];
}

- (IBAction)lock:(id)sender
{
        [toolbar setItems:lockedToolbarItems animated:YES];
        if (lockTimer) {
                [lockTimer invalidate];
                [lockTimer release];
                lockTimer = nil;
        }
}

- (IBAction)sendFiles:(id)sender {
        [self lock:sender];
        [(GlintAppDelegate *)[[UIApplication sharedApplication] delegate] switchToSendFilesView:sender];
}

- (IBAction)startStopRecording:(id)sender
{
        if (!gpxWriter) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyyMMdd-HHmmss"];
                self.recordingIndicator.textColor = [UIColor greenColor];
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);	
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString* filename = [NSString stringWithFormat:@"%@/track-%@.gpx", documentsDirectory, [formatter stringFromDate:[NSDate date]]];
                gpxWriter = [[GPXWriter alloc] initWithFilename:filename];
                [gpxWriter addTrackSegment];
        } else {
                self.recordingIndicator.textColor = [UIColor grayColor];
                [gpxWriter commit];
                [gpxWriter release];
                gpxWriter = nil;
        }
        [toolbar setItems:lockedToolbarItems animated:YES];
}

//
// Private methods
//

- (NSString*)formatTimestamp:(float)seconds maxTime:(float)max {
        if (seconds > max || seconds < 0)
                return [NSString stringWithFormat:@"?"];
        else {
                int isec = (int) seconds;
                int hour = (int) (isec / 3600);
                int min = (int) ((isec % 3600) / 60);
                int sec = (int) (isec % 60);
                return [NSString stringWithFormat:@"%02d:%02d:%02d", hour, min, sec];
        }
}

- (NSString*) formatDMS:(float)latLong {
        int deg = (int) latLong;
        int min = (int) ((latLong - deg) * 60);
        float sec = (float) ((latLong - deg - min / 60.0) * 3600.0);
        return [NSString stringWithFormat:@"%02d° %02d' %02.02f\"", deg, min, sec];
}

- (NSString*)formatLat:(float)lat {
        NSString* sign = lat >= 0 ? @"N" : @"S";
        lat = fabs(lat);
        return [NSString stringWithFormat:@"%@ %@", [self formatDMS:lat], sign]; 
}

- (NSString*)formatLon:(float)lon {
        NSString* sign = lon >= 0 ? @"E" : @"W";
        lon = fabs(lon);
        return [NSString stringWithFormat:@"%@ %@", [self formatDMS:lon], sign]; 
}

- (bool)precisionAcceptable:(CLLocation*)location {
        static float minPrec = 0.0;
        if (minPrec == 0.0)
                minPrec = USERPREF_MINIMUM_PRECISION;
        float currentPrec = location.horizontalAccuracy;
        return currentPrec > 0.0 && currentPrec <= minPrec;
}

- (float) speedFromLocation:(CLLocation*)locA toLocation:(CLLocation*)locB {
        float td = [locA.timestamp timeIntervalSinceDate:locB.timestamp];
        if (td < 0.0)
                td = -td;
        if (td == 0.0)
                return 0.0;
        float dist = [locA getDistanceFrom:locB];
        return dist / td;
}

- (float) bearingFromLocation:(CLLocation*)loc1 toLocation:(CLLocation*)loc2 {
        float y1 = loc1.coordinate.latitude / 180.0 * M_PI;
        float x1 = loc1.coordinate.longitude / 180.0 * M_PI;
        float y2 = loc2.coordinate.latitude / 180.0 * M_PI;
        float x2 = loc2.coordinate.longitude / 180.0 * M_PI;
        float y = cos(x1) * sin(x2) - sin(x1) * cos(x2) * cos(y2-y1);
        float x = sin(y2-y1) * cos(x2);
        float t = atan2(y, x);
        float b = t / M_PI * 180.0 + 360.0;
        if (b >= 360.0)
                b -= 360.0;
        return b;
}

//
// Background threads
//

- (void)takeAveragedMeasurement:(NSTimer*)timer
{
        static NSDate *lastWrittenDate = nil;
        static float averageInterval = 0.0;
        static BOOL powersave = NO;
        NSDate *now = [NSDate date];
        
        if (averageInterval == 0.0) {
                averageInterval = USERPREF_MEASUREMENT_INTERVAL;
                powersave = USERPREF_POWERSAVE;
        }
        
        if (!gpsEnabled) {
                if ([now timeIntervalSinceDate:lastWrittenDate] > averageInterval-10 // It is soon time for a new measurement
                    || !gpxWriter) // Or, we are not recording
                        [self enableGPS];
                return;
        }
        
        CLLocation *current = locationManager.location;
        NSLog([locationManager.location description]);
        if (gpxWriter && (!lastWrittenDate || [now timeIntervalSinceDate:lastWrittenDate] >= averageInterval - MEASUREMENT_THREAD_INTERVAL/2.0 )) {
                if ([self precisionAcceptable:current]) {
                        NSLog(@"Good precision, saving waypoint");
                        [lastWrittenDate release];
                        lastWrittenDate = [now retain];
                        [gpxWriter addTrackPoint:current];
                } else if ([gpxWriter isInTrackSegment]) {
                        NSLog(@"Bad precision, breaking track segment");
                        [gpxWriter addTrackSegment];
                } else {
                        NSLog(@"Bad precision, waiting for waypoint");                        
                }
        }
        
        if (previousMeasurement && [previousMeasurement.timestamp timeIntervalSinceNow] < -FORCE_POSITION_UPDATE_INTERVAL && [self precisionAcceptable:current]) {
                @synchronized (self) {
                        totalDistance += [previousMeasurement getDistanceFrom:current];
                        currentSpeed = [self speedFromLocation:previousMeasurement toLocation:current];
                        [previousMeasurement release];
                        previousMeasurement = [current retain];
                        currentDataSource = kGlintDataSourceTimer;
                }
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
        static float distFactor = 0.0;
        static float speedFactor = 0.0;
        static NSString *distFormat = nil;
        static NSString *speedFormat = nil;
        static BOOL sounds;
        
        if ([[UIDevice currentDevice] proximityState])
                return;
        
        if (distFactor == 0) {
                int unitsetIndex = USERPREF_UNITSET;
                NSDictionary* units = [unitSets objectAtIndex:unitsetIndex];
                distFactor = [[units objectForKey:@"distFactor"] floatValue];
                speedFactor = [[units objectForKey:@"speedFactor"] floatValue];
                distFormat = [units objectForKey:@"distFormat"];
                speedFormat = [units objectForKey:@"speedFormat"];
                sounds = USERPREF_SOUNDS;
        }
        
#ifdef SCREENSHOT
        bool stateGood = YES;
#else
        bool stateGood = [self precisionAcceptable:locationManager.location];
#endif
        if (!gpsEnabled)
                self.signalIndicator.textColor = [UIColor grayColor];
        else {
                if (stateGood)
                        self.signalIndicator.textColor = [UIColor greenColor];
                else
                        self.signalIndicator.textColor = [UIColor redColor];
                
                if (sounds && prevStateGood != stateGood) {
                        if (stateGood)
                                [goodSound play];
                        else
                                [badSound play];
                }
                prevStateGood = stateGood;
        }
        
        CLLocation *current = locationManager.location;
        [current retain];
        
        if (current) {
                self.positionLabel.text = [NSString stringWithFormat:@"%@\n%@\nelev %.0f m", [self formatLat: current.coordinate.latitude], [self formatLon: current.coordinate.longitude], current.altitude];
                self.positionLabel.textColor = [UIColor whiteColor];
                if (current.verticalAccuracy < 0)
                        self.accuracyLabel.text = [NSString stringWithFormat:@"±%.0f m h, ±inf v.", current.horizontalAccuracy];
                else
                        self.accuracyLabel.text = [NSString stringWithFormat:@"±%.0f m h, ±%.0f m v.", current.horizontalAccuracy, current.verticalAccuracy];
                self.accuracyLabel.textColor = [UIColor whiteColor];
        } else {
                self.positionLabel.textColor = [UIColor grayColor];
                self.accuracyLabel.textColor = [UIColor grayColor];
        }
        
        if (firstMeasurementDate)
                self.elapsedTimeLabel.text =  [self formatTimestamp:[[NSDate date] timeIntervalSinceDate:firstMeasurementDate] maxTime:86400];
        
        float averageSpeed = 0.0;
        if (firstMeasurementDate && lastMeasurementDate)
                averageSpeed  = totalDistance / [lastMeasurementDate timeIntervalSinceDate:firstMeasurementDate];
        self.averageSpeedLabel.text = [NSString stringWithFormat:speedFormat, averageSpeed*speedFactor];
        
        self.totalDistanceLabel.text = [NSString stringWithFormat:distFormat, totalDistance*distFactor];
        
        if (currentSpeed >= 0.0)
                self.currentSpeedLabel.text = [NSString stringWithFormat:speedFormat, currentSpeed*speedFactor];
        else
                self.currentSpeedLabel.text = @"?";
        
        if (currentDataSource == kGlintDataSourceMovement)
                self.currentSpeedLabel.textColor = [UIColor colorWithRed:0xCC/255.0 green:0xFF/255.0 blue:0x66/255.0 alpha:1.0];
        else if (currentDataSource == kGlintDataSourceTimer)
                self.currentSpeedLabel.textColor = [UIColor colorWithRed:0xA0/255.0 green:0xB5/255.0 blue:0x66/255.0 alpha:1.0];
        
        float secsPerEstDist = USERPREF_ESTIMATE_DISTANCE * 1000.0 / currentSpeed;
        self.currentTimePerDistanceLabel.text = [self formatTimestamp:secsPerEstDist maxTime:86400];
        NSString *distStr = [NSString stringWithFormat:distFormat, USERPREF_ESTIMATE_DISTANCE*distFactor*1000.0];
        self.currentTimePerDistanceDescrLabel.text = [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"per", @"... per (distance)"), distStr];
        
        if (gpxWriter)
                self.statusLabel.text = [NSString stringWithFormat:@"%04d %@", [gpxWriter numberOfTrackPoints], NSLocalizedString(@"measurements", @"measurements")];
        
        if (currentCourse >= 0.0)
                self.compass.course = currentCourse;
        else
                self.compass.course = 0.0;
        
        [current release];
}

/*
 * Private methods
 */

- (void)tests {
        CLLocation *locN = [[[CLLocation alloc] initWithLatitude:10.0 longitude:0.0] autorelease]; // 10.0 N
        CLLocation *locS = [[[CLLocation alloc] initWithLatitude:-10.0 longitude:0.0] autorelease]; // 10.0 S
        CLLocation *locE = [[[CLLocation alloc] initWithLatitude:0.0 longitude:10.0] autorelease]; // 10.0 E
        CLLocation *locW = [[[CLLocation alloc] initWithLatitude:0.0 longitude:-10.0] autorelease]; // 10.0 W
        CLLocation *locNE = [[[CLLocation alloc] initWithLatitude:10.0 longitude:10.0] autorelease]; // 10.0 N, 10.0 E
        CLLocation *locSW = [[[CLLocation alloc] initWithLatitude:-10.0 longitude:-10.0] autorelease]; // 10.0 S, 10.0 W
        
        float bearing;
        bearing = [self bearingFromLocation:locN toLocation:locS];
        NSAssert(bearing == 180.0, @"Bearing N-S incorrect");
        bearing = [self bearingFromLocation:locS toLocation:locN];
        NSAssert(bearing == 0.0, @"Bearing S-N incorrect");
        bearing = [self bearingFromLocation:locE toLocation:locW];
        NSAssert(bearing == 270.0, @"Bearing E-W incorrect");
        bearing = [self bearingFromLocation:locW toLocation:locE];
        NSAssert(bearing == 90.0, @"Bearing W-E incorrect");
        bearing = [self bearingFromLocation:locSW toLocation:locNE];
        NSAssert(bearing > 44.0 && bearing < 46.0, @"Bearing SW-NE incorrect");
        bearing = [self bearingFromLocation:locNE toLocation:locSW];
        NSAssert(bearing > 224.0 && bearing < 226.0, @"Bearing SW-NE incorrect");
}


- (void)enableGPS {
        NSLog(@"Starting GPS");
        locationManager = [[CLLocationManager alloc] init];
        locationManager.distanceFilter = FILTER_DISTANCE;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.delegate = self;
        [locationManager startUpdatingLocation];
        gpsEnabled = YES;
}

- (void)disableGPS {
        NSLog(@"Stopping GPS");
        locationManager.delegate = nil;
        [locationManager stopUpdatingHeading];
        [locationManager release];
        locationManager = nil;
        gpsEnabled = NO;
}

@end
