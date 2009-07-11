//
//  GlintViewController.m
//  Glint
//
//  Created by Jakob Borg on 6/26/09.
//  Copyright Jakob Borg 2009. All rights reserved.
//

#import "GlintViewController.h"
#define DEBUG

@implementation GlintViewController

@synthesize statusIndicator, positionLabel, elapsedTimeLabel, currentSpeedLabel, currentTimePerDistanceLabel, currentTimePerDistanceDescrLabel;
@synthesize totalDistanceLabel, statusLabel, averageSpeedLabel, bearingLabel, accuracyLabel;
@synthesize compass, playStopButton, unlockButton, recordingIndicator;

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView {
 }
 */

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
        [super viewDidLoad];
        
        locationManager = [[CLLocationManager alloc] init];
        locationManager.distanceFilter = 1.0;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        //locationManager.delegate = self;
        [locationManager startUpdatingLocation];
        [locationManager startUpdatingHeading];
        
        badSound = [[JBSoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Basso" ofType:@"aiff"]];
        goodSound = [[JBSoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Purr" ofType:@"aiff"]];
        averagedMeasurements = 0;
        startedLogging  = nil;
        totalDistance = 0.0;
        currentSpeed = -1.0;
        currentCourse = -1.0;
        gpxWriter = nil;
        
        NSString *path=[[NSBundle mainBundle] pathForResource:@"unitsets" ofType:@"plist"];
        unitSets = [NSArray arrayWithContentsOfFile:path];
        [unitSets retain];
        
        if (USERPREF_DISABLE_IDLE)
                [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        if (USERPREF_ENABLE_PROXIMITY)
                [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
        
        positionLabel.text = @"-";
        accuracyLabel.text = @"-";
        elapsedTimeLabel.text = @"00:00:00";
        
        totalDistanceLabel.text = @"-";
        currentSpeedLabel.text = @"?";
        averageSpeedLabel.text = @"?";
        currentTimePerDistanceLabel.text = @"?";
        NSString* bundleVer = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSString* marketVer = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        statusLabel.text = [NSString stringWithFormat:@"Glint %@ build %@", marketVer, bundleVer];
        
        NSTimer* displayUpdater = [NSTimer timerWithTimeInterval:UPDATE_INTERVAL target:self selector:@selector(updateDisplay:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:displayUpdater forMode:NSDefaultRunLoopMode];
        NSTimer* averagedMeasurementTaker = [NSTimer timerWithTimeInterval:USERPREF_MEASUREMENT_INTERVAL target:self selector:@selector(takeAveragedMeasurement:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:averagedMeasurementTaker forMode:NSDefaultRunLoopMode];
}

- (void)viewWillDisappear:(BOOL)animated
{
        if (gpxWriter.inTrackSegment)
                [gpxWriter endTrackSegment];
        [gpxWriter endFile];
        
        [locationManager stopUpdatingLocation];
        [locationManager stopUpdatingHeading];
        locationManager.delegate = nil;
        
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
        
        [super viewWillDisappear:animated];
}

- (IBAction)unlock:(id)sender
{
        [playStopButton setEnabled:YES];
        [unlockButton setEnabled:NO];
}

- (IBAction)startStopRecording:(id)sender
{
        if (!recording) {
                recording = YES;
                [playStopButton setTitle:@"Stop Recording"];
                [recordingIndicator setHidden:NO];
                [recordingIndicator startAnimating];
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);	
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString* filename = [NSString stringWithFormat:@"%@/track-%@.gpx", documentsDirectory, [[NSDate date] description]];
                gpxWriter = [[GlintGPXWriter alloc] initWithFilename:filename];
                [gpxWriter beginFile];
                [gpxWriter beginTrackSegment];
                averagedMeasurements = 0;
        } else {
                recording = NO;
                [playStopButton setTitle:@"Start Recording"];
                [recordingIndicator setHidden:YES];
                [recordingIndicator stopAnimating];
                if (gpxWriter.inTrackSegment)
                        [gpxWriter endTrackSegment];
                [gpxWriter endFile];
                [gpxWriter release];
                gpxWriter = nil;
        }
        [unlockButton setEnabled:YES];
        [playStopButton setEnabled:NO];
}

- (NSString*)formatTimestamp:(double)seconds maxTime:(double)max {
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

- (NSString*) formatDMS:(double)latLong {
        int deg = (int) latLong;
        int min = (int) ((latLong - deg) * 60);
        double sec = (double) ((latLong - deg - min / 60.0) * 3600.0);
        return [NSString stringWithFormat:@"%02d° %02d' %02.02f\"", deg, min, sec];
}

- (NSString*)formatLat:(double)lat {
        NSString* sign = lat >= 0 ? @"N" : @"S";
        lat = fabs(lat);
        return [NSString stringWithFormat:@"%@ %@", [self formatDMS:lat], sign]; 
}

- (NSString*)formatLon:(double)lon {
        NSString* sign = lon >= 0 ? @"E" : @"W";
        lon = fabs(lon);
        return [NSString stringWithFormat:@"%@ %@", [self formatDMS:lon], sign]; 
}

- (bool)precisionAcceptable:(CLLocation*)location {
        static double minPrec = 0.0;
        if (minPrec == 0.0)
                minPrec = USERPREF_MINIMUM_PRECISION;
        double currentPrec = location.horizontalAccuracy;
        return currentPrec > 0.0 && currentPrec <= minPrec;
}

- (void)takeAveragedMeasurement:(NSTimer*)timer
{
        static bool hasWrittenPoint = NO;
        CLLocation *current = locationManager.location;
        if (recording) {
                if ([self precisionAcceptable:current]) {
                        averagedMeasurements++;
                        if (!gpxWriter.inTrackSegment)
                                [gpxWriter beginTrackSegment];
                        [gpxWriter addPoint:current];
                        hasWrittenPoint = YES;
                } else if (hasWrittenPoint && gpxWriter.inTrackSegment) {
                        [gpxWriter endTrackSegment];
                        hasWrittenPoint = NO;
                }
        }
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
        static CLLocation *last = nil;
        
        if ([self precisionAcceptable:newLocation]) {
                if (last)
                        totalDistance += [last getDistanceFrom:newLocation];
                if (newLocation.course >= 0.0)
                        currentCourse = newLocation.course;
                if (newLocation.speed >= 0.0)
                        currentSpeed = newLocation.speed;
                
                [last release];
                last = newLocation;
                [last retain];
        }
}

- (void)updateDisplay:(NSTimer*)timer
{
        static BOOL prevStateGood = NO;
        static double distFactor = 0.0;
        static double speedFactor = 0.0;
        static NSString *distFormat = nil;
        static NSString *speedFormat = nil;
        
        bool stateGood = [self precisionAcceptable:locationManager.location];
        if (stateGood != prevStateGood) {
                if (stateGood) {
                        [goodSound play];
                        statusIndicator.image = [UIImage imageNamed:@"green-sphere.png"];
                } else {
                        [badSound play];
                        statusIndicator.image = [UIImage imageNamed:@"red-sphere.png"];
                }
                prevStateGood = stateGood;
        }
        
        if (distFactor == 0) {
                int unitsetIndex = USERPREF_UNITSET;
                NSDictionary* units = [unitSets objectAtIndex:unitsetIndex];
                distFactor = [[units objectForKey:@"distFactor"] floatValue];
                speedFactor = [[units objectForKey:@"speedFactor"] floatValue];
                distFormat = [units objectForKey:@"distFormat"];
                speedFormat = [units objectForKey:@"speedFormat"];
        }
        
        CLLocation *current = locationManager.location;
        [current retain];
        
        if (current)
                positionLabel.text = [NSString stringWithFormat:@"%@\n%@\nelev %.0f m", [self formatLat: current.coordinate.latitude], [self formatLon: current.coordinate.longitude], current.altitude];
        if (current.verticalAccuracy < 0)
                accuracyLabel.text = [NSString stringWithFormat:@"±%.0f m h, ±inf v.", current.horizontalAccuracy];
        else
                accuracyLabel.text = [NSString stringWithFormat:@"±%.0f m h, ±%.0f m v.", current.horizontalAccuracy, current.verticalAccuracy];
        
        if (startedLogging != nil)
                elapsedTimeLabel.text =  [self formatTimestamp:[[NSDate date] timeIntervalSinceDate:startedLogging] maxTime:86400];
        
        if (stateGood) {
                if (!startedLogging)
                        startedLogging = [[NSDate date] retain];
                
                double averageSpeed;
                if (!startedLogging)
                        averageSpeed = 0.0;
                else
                        averageSpeed  = totalDistance / -[startedLogging timeIntervalSinceNow];
                averageSpeedLabel.text = [NSString stringWithFormat:speedFormat, averageSpeed*speedFactor];
                
                totalDistanceLabel.text = [NSString stringWithFormat:distFormat, totalDistance*distFactor];
                
                if (currentSpeed >= 0.0)
                        currentSpeedLabel.text = [NSString stringWithFormat:speedFormat, currentSpeed*speedFactor];
                else
                        currentSpeedLabel.text = @"?";
                
                currentTimePerDistanceLabel.text = [self formatTimestamp:USERPREF_ESTIMATE_DISTANCE * 3600.0 / current.speed maxTime:86400];
                currentTimePerDistanceDescrLabel.text = [NSString stringWithFormat:@"per %.2f km", USERPREF_ESTIMATE_DISTANCE];
                
                statusLabel.text = [NSString stringWithFormat:@"%04d measurements", averagedMeasurements];
                
                if (currentCourse >= 0.0)
                        compass.course = currentCourse;
                else
                        compass.course = 0.0;
        }
        [current release];
}

- (void)dealloc {
        [locationManager release];
        [goodSound release];
        [badSound release];
        [super dealloc];
}

@end
