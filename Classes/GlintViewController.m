//
//  GlintViewController.m
//  Glint
//
//  Created by Jakob Borg on 6/26/09.
//  Copyright Jakob Borg 2009. All rights reserved.
//

#import "GlintViewController.h"

@implementation GlintViewController

@synthesize locationManager;
@synthesize statusIndicator, positionLabel, elapsedTimeLabel, currentSpeedLabel, currentTimePerKmLabel;
@synthesize totalDistanceLabel, statusLabel, averageSpeedLabel, slopeLabel, accuracyLabel;
@synthesize averageProgress, lastLocation, currentLocation;

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView {
 }
 */


- (void)beginGPX {
        NSString* start = @"<?xml version=\"1.0\" encoding=\"ASCII\" standalone=\"yes\"?>\n<gpx\n  version=\"1.1\"\n  creator=\"TrailRunner http://www.TrailRunnerx.com\"\n  xmlns=\"http://www.topografix.com/GPX/1/1\"\n  xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n  xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd\">\n  <trk>\n    <trkseg>\n";
        [start writeToFile:filename atomically:NO encoding:NSASCIIStringEncoding error:nil];
}

- (void)endGPX {
        NSString* end = @"    </trkseg>\n  </trk>\n</gpx>\n";
        NSFileHandle *aFileHandle;
        aFileHandle = [NSFileHandle fileHandleForWritingAtPath:filename];
        [aFileHandle truncateFileAtOffset:[aFileHandle seekToEndOfFile]];
        [aFileHandle writeData:[end dataUsingEncoding:NSASCIIStringEncoding]];
        [aFileHandle closeFile];
}

- (void)pointInGPX:(CLLocation*)loc {
        NSString* ts = [loc.timestamp descriptionWithCalendarFormat:@"%Y-%m-%dT%H:%M:%SZ" timeZone:nil locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
        
        NSString* data = [NSString stringWithFormat:@"      <trkpt lat=\"%f\" lon=\"%f\">\n        <ele>%f</ele>\n        <time>%@</time>\n      </trkpt>\n",
                          loc.coordinate.latitude, loc.coordinate.longitude, loc.altitude, ts];
        
        NSFileHandle *aFileHandle;
        aFileHandle = [NSFileHandle fileHandleForWritingAtPath:filename];
        [aFileHandle truncateFileAtOffset:[aFileHandle seekToEndOfFile]];
        [aFileHandle writeData:[data dataUsingEncoding:NSASCIIStringEncoding]];
        [aFileHandle closeFile];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
        [super viewDidLoad];
        
        badSound = [[JBSoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Basso" ofType:@"aiff"]];
        goodSound = [[JBSoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Purr" ofType:@"aiff"]];
        stateGood = NO;
        directMeasurements = [[NSMutableArray alloc] init];
        averagedMeasurements = 0;
        startTime  = nil;
        distance = 0;
        
        NSDictionary *metric = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                @"%.01f km/h", @"speedFormat",
                                @"%.02f km", @"distFormat",
                                [NSNumber numberWithFloat:1.0], @"distFactor",
                                [NSNumber numberWithFloat:1.0], @"speedFactor",
                                nil
                                ];
        NSDictionary *nautical = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  @"%.01f kn", @"speedFormat",
                                  @"%.02f M", @"distFormat",
                                  [NSNumber numberWithFloat:1.0/1.852], @"distFactor",
                                  [NSNumber numberWithFloat:1.0/1.852], @"speedFactor",
                                  nil
                                  ];
        
        unitSets = [NSArray arrayWithObjects:metric, nautical, nil];
        [unitSets retain];
        unitSetIndex = 0;
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);	
	NSString *documentsDirectory = [paths objectAtIndex:0];
	filename = [NSString stringWithFormat:@"%@/track-%@.gpx", documentsDirectory, [[NSDate date] description]];
        [filename retain];
        
        locations = [[NSMutableArray alloc] init];
        self.locationManager = [[[CLLocationManager alloc] init] autorelease];
        //self.locationManager.distanceFilter = FILTER_DISTANCE;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.delegate = self;
        [self.locationManager startUpdatingLocation];
        
        if (DISABLE_IDLE)
                [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        if (ENABLE_PROXIMITY)
                [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
        
        [self beginGPX];
        
        NSTimer* displayUpdater = [NSTimer timerWithTimeInterval:UPDATE_INTERVAL target:self selector:@selector(updateDisplay:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:displayUpdater forMode:NSDefaultRunLoopMode];
        NSTimer* measurementTaker = [NSTimer timerWithTimeInterval:MEASUREMENT_INTERVAL target:self selector:@selector(takeAveragedMeasurement:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:measurementTaker forMode:NSDefaultRunLoopMode];
}

- (void) viewWillDisappear:(BOOL)animated
{
        [self endGPX];
        
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
        
        [self.locationManager stopUpdatingLocation];
        self.locationManager.delegate = nil;
        
        [super viewWillDisappear:animated];
}

- (double) distanceBetweenLocation:(CLLocation*)loc1 andLocation:(CLLocation*)loc2 {
        if (!loc1 || !loc2)
                return 0.0;
        
        double a1 = loc1.coordinate.latitude / 180.0 * M_PI;
        double b1 = loc1.coordinate.longitude / 180.0 * M_PI;
        double a2 = loc2.coordinate.latitude / 180.0 * M_PI;
        double b2 = loc2.coordinate.longitude / 180.0 * M_PI;
        return fabs(acos(cos(a1)*cos(b1)*cos(a2)*cos(b2) + cos(a1)*sin(b1)*cos(a2)*sin(b2) + sin(a1)*sin(a2)) * 6378);
        
}

- (double) averageSlopeOverLast:(int)averagePoints {
        double dslope = 0;
        int segments = 0;
        
        if ([locations count] < averagePoints)
                return 0.0;
        
        int start = 0;
        int end = [locations count] - 1;
        if (end - start > averagePoints)
                start = end - averagePoints;
        
        CLLocation *last = nil;
        for (int i = start; i <= end; i++) {
                CLLocation *loc = [locations objectAtIndex:i];
                if (loc.altitude == 0 || loc.verticalAccuracy == -1)
                        continue;
                if (last) {
                        double dist = [self distanceBetweenLocation:last andLocation:loc] * 1000.0;
                        double delta = loc.altitude - last.altitude;
                        dslope += delta / dist;
                        segments++;
                }
                last = loc;
        }
        if (segments == 0)
                return 0;
        return dslope / segments;
}

- (double) averageSpeedOverLast:(int)averagePoints {
        double dspeed = 0;
        int segments = 0;
        
        if ([locations count] < averagePoints)
                return 0.0;
        
        int start = 0;
        int end = [locations count] - 1;
        if (end - start > averagePoints)
                start = end - averagePoints;
        
        CLLocation *last = nil;
        for (int i = start; i <= end; i++) {
                CLLocation *loc = [locations objectAtIndex:i];
                if (last) {
                        double td = [loc.timestamp timeIntervalSinceDate:last.timestamp] / 3600.0;
                        NSLog([NSString stringWithFormat:@"time diff %f", td]);
                        if (td < 0.0) // Not bloody reasonable
                                continue;
                        double sp = [self distanceBetweenLocation:last andLocation:loc];
                        NSLog([NSString stringWithFormat:@"pre div %f", sp]);
                        sp /= td;
                        NSLog([NSString stringWithFormat:@"aft div %f", sp]);
                        dspeed += sp;
                        segments++;
                }
                last = loc;
        }
        
        if (segments == 0)
                return 0.0;
        return dspeed / segments;
}

- (double) averageSpeed {
        int averagePoints = [locations count];
        if (averagePoints > 20)
                averagePoints = 20;
        else if (averagePoints < 3)
                averagePoints = 3;
        return [self averageSpeedOverLast:averagePoints];
}


- (NSString*) formatTimestamp:(double)seconds maxTime:(double)max {
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

- (NSString*) formatLat:(double)lat {
        NSString* sign = lat >= 0 ? @"N" : @"S";
        lat = fabs(lat);
        return [NSString stringWithFormat:@"%@ %@", [self formatDMS:lat], sign]; 
}

- (NSString*) formatLon:(double)lon {
        NSString* sign = lon >= 0 ? @"E" : @"W";
        lon = fabs(lon);
        return [NSString stringWithFormat:@"%@ %@", [self formatDMS:lon], sign]; 
}

- (CLLocation*) averageLocationFromArray:(NSArray*)arrayOfLocations {
        double lat = 0, lon = 0, alt = 0;
        for (CLLocation *loc in arrayOfLocations) {
                lat += loc.coordinate.latitude;
                lon += loc.coordinate.longitude;
                alt += loc.altitude;
        }
        
        int numLocations = [arrayOfLocations count];
        CLLocationCoordinate2D coord;
        coord.latitude = lat / numLocations;
        coord.longitude = lon / numLocations;
        CLLocation *averageLocation = [[[CLLocation alloc] initWithCoordinate:coord altitude:alt/numLocations horizontalAccuracy:0 verticalAccuracy:0 timestamp:[NSDate date]] autorelease];
        return averageLocation;
}

// Called when the location is updated
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
        // Save it so it can be displayed etc.
        self.currentLocation = newLocation;
        
        // Update the state (good = we have enough precision).
        stateGood = (newLocation.horizontalAccuracy <= MINIMUM_PRECISION);
        
        // If we don't have the required accuracy, end things here.
        if (newLocation.horizontalAccuracy < 0 || newLocation.horizontalAccuracy > MINIMUM_PRECISION)
                return;
        
        // Set the start time if we haven't
        if (!startTime)
                startTime = [[NSDate date] retain];
        
        // Save a "direct measurement"
        [directMeasurements addObject:newLocation];
}

// Called when the location is updated
- (void)takeAveragedMeasurement:(NSTimer*)timer
{
        if ([directMeasurements count] < MINIMUM_MULTIPLIER)
                return;
        
        lastSampleSize = [directMeasurements count];
        
        // Get the average position from the array, and release the array
        CLLocation *location = [self averageLocationFromArray:directMeasurements];
        [directMeasurements release];
        directMeasurements = [[NSMutableArray alloc] init];                
        averagedMeasurements++;
        
        // distanceBetweenLocation:andLocation will return 0.0 for any nil argument
        distance += [self distanceBetweenLocation:self.lastLocation andLocation:location];
        
        // Save the averaged reading
        [locations addObject:location];
        self.lastLocation = location;
        
        [self pointInGPX:location];
}

- (void)updateDisplay:(NSTimer*)timer
{
        static BOOL prevStateGood = NO;
        
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
        
        positionLabel.text = [NSString stringWithFormat:@"%@\n%@\nelev %.0f m", [self formatLat: self.currentLocation.coordinate.latitude], [self formatLon: self.currentLocation.coordinate.longitude], self.currentLocation.altitude];
        if (currentLocation.verticalAccuracy < 0)
                accuracyLabel.text = [NSString stringWithFormat:@"±%.0f m h, ±inf v.", currentLocation.horizontalAccuracy];
        else
                accuracyLabel.text = [NSString stringWithFormat:@"±%.0f m h, ±%.0f m v.", currentLocation.horizontalAccuracy, currentLocation.verticalAccuracy];
        
        if (startTime != nil)
                elapsedTimeLabel.text =  [self formatTimestamp:[[NSDate date] timeIntervalSinceDate:startTime] maxTime:86400];
        
        NSDictionary* units = [unitSets objectAtIndex:UNITSET];
        double distFactor = [[units objectForKey:@"distFactor"] floatValue];
        double speedFactor = [[units objectForKey:@"speedFactor"] floatValue];
        NSString* distFormat = [units objectForKey:@"distFormat"];
        NSString* speedFormat = [units objectForKey:@"speedFormat"];
        
        // Calculate our current speed and slope
        double curSpeed = [self averageSpeedOverLast:3];
        double curSlope = [self averageSlopeOverLast:3];
        if (isnan(curSlope))
                curSlope = 0.0;
        double progress = ((double) lastSampleSize / DESIRED_MULTIPLIER);
        if (progress > 1.0)
                progress = 1.0;
        
        totalDistanceLabel.text = [NSString stringWithFormat:distFormat, distance*distFactor];
        currentSpeedLabel.text = [NSString stringWithFormat:speedFormat, curSpeed*speedFactor];
        averageSpeedLabel.text = [NSString stringWithFormat:speedFormat, [self averageSpeed]*speedFactor];
        currentTimePerKmLabel.text = [self formatTimestamp:10 * 3600.0 / curSpeed maxTime:86400];
        slopeLabel.text = [NSString stringWithFormat:@"%.01f %%", curSlope * 100];
        statusLabel.text = [NSString stringWithFormat:@"%04d measurements", averagedMeasurements];
        averageProgress.progress = progress;
}

- (void)didReceiveMemoryWarning {
        [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
        // Release anything that's not essential, such as cached data
}


- (void)dealloc {
        [super dealloc];
}

@end
