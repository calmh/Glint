//
//  GlintViewController.m
//  Glint
//
//  Created by Jakob Borg on 6/26/09.
//  Copyright Jakob Borg 2009. All rights reserved.
//

#import "GlintViewController.h"
//#define DEBUG

@implementation GlintViewController

@synthesize locationManager;
@synthesize statusIndicator, positionLabel, elapsedTimeLabel, currentSpeedLabel, currentTimePerDistanceLabel, currentTimePerDistanceDescrLabel;
@synthesize totalDistanceLabel, statusLabel, averageSpeedLabel, bearingLabel, accuracyLabel;
@synthesize averageProgress, currentLocation, compass;

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView {
 }
 */


- (void) appendToGPX: (NSString *) data  {
        NSFileHandle *aFileHandle;
        aFileHandle = [NSFileHandle fileHandleForWritingAtPath:filename];
        [aFileHandle truncateFileAtOffset:[aFileHandle seekToEndOfFile]];
        [aFileHandle writeData:[data dataUsingEncoding:NSASCIIStringEncoding]];
        [aFileHandle closeFile];
        
}

- (void)beginGPXFile {
        NSString* start = @"<?xml version=\"1.0\" encoding=\"ASCII\" standalone=\"yes\"?>\n<gpx\n  version=\"1.1\"\n  creator=\"TrailRunner http://www.TrailRunnerx.com\"\n  xmlns=\"http://www.topografix.com/GPX/1/1\"\n  xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n  xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd\">\n  <trk>\n";
        [start writeToFile:filename atomically:NO encoding:NSASCIIStringEncoding error:nil];
}

- (void)beginGPXTrackSegment {
        NSString* start = @"    <trkseg>\n";
        [self appendToGPX: start];
}

- (void)endGPXTrackSegment {
        NSString* end = @"    </trkseg>\n";
        [self appendToGPX: end];
}

- (void)endGPXFile {
        NSString* end = @"  </trk>\n</gpx>\n";
        [self appendToGPX: end];
}

- (void)pointInGPX:(CLLocation*)loc {
        NSString* ts = [loc.timestamp descriptionWithCalendarFormat:@"%Y-%m-%dT%H:%M:%SZ" timeZone:nil locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
        
        NSString* data = [NSString stringWithFormat:@"      <trkpt lat=\"%f\" lon=\"%f\">\n        <ele>%f</ele>\n        <time>%@</time>\n      </trkpt>\n",
                          loc.coordinate.latitude, loc.coordinate.longitude, loc.altitude, ts];
        
        [self appendToGPX: data];
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
        
        NSString *path=[[NSBundle mainBundle] pathForResource:@"unitsets" ofType:@"plist"];
        unitSets = [NSArray arrayWithContentsOfFile:path];
        [unitSets retain];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);	
	NSString *documentsDirectory = [paths objectAtIndex:0];
	filename = [NSString stringWithFormat:@"%@/track-%@.gpx", documentsDirectory, [[NSDate date] description]];
        [filename retain];
        
        locations = [[NSMutableArray alloc] init];
        
        self.locationManager = [[[CLLocationManager alloc] init] autorelease];
        //self.locationManager.distanceFilter = FILTER_DISTANCE;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager startUpdatingLocation];
        
        if (DISABLE_IDLE)
                [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        if (ENABLE_PROXIMITY)
                [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
        
        positionLabel.text = @"-";
        accuracyLabel.text = @"-";
        elapsedTimeLabel.text = @"0:00:00";
        
        totalDistanceLabel.text = @"-";
        currentSpeedLabel.text = @"-";
        averageSpeedLabel.text = @"-";
        currentTimePerDistanceLabel.text = @"-";
        statusLabel.text = @"-";
        
        [self beginGPXFile];
        [self beginGPXTrackSegment];
        inTrackSegment = YES;
        
        NSTimer* displayUpdater = [NSTimer timerWithTimeInterval:UPDATE_INTERVAL target:self selector:@selector(updateDisplay:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:displayUpdater forMode:NSDefaultRunLoopMode];
        NSTimer* averagedMeasurementTaker = [NSTimer timerWithTimeInterval:MEASUREMENT_INTERVAL target:self selector:@selector(takeAveragedMeasurement:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:averagedMeasurementTaker forMode:NSDefaultRunLoopMode];
        NSTimer* directMeasurementTaker = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(takeDirectMeasurement:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:directMeasurementTaker forMode:NSDefaultRunLoopMode];
}

- (void) viewWillDisappear:(BOOL)animated
{
        [self endGPXFile];
        
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

- (double) speedFromLocation:(CLLocation*)locA toLocation:(CLLocation*)locB {
        double td = [locA.timestamp timeIntervalSinceDate:locB.timestamp] / 3600.0;
        if (td < 0.0)
                td = -td;
        if (td == 0.0)
                return 0.0;
        double dist = [self distanceBetweenLocation:locA andLocation:locB];
        return dist / td;
}

- (double) bearingFromLocation:(CLLocation*)loc1 toLocation:(CLLocation*)loc2 {
        double y1 = -loc1.coordinate.latitude / 180.0 * M_PI;
        double x1 = loc1.coordinate.longitude / 180.0 * M_PI;
        double y2 = -loc2.coordinate.latitude / 180.0 * M_PI;
        double x2 = loc2.coordinate.longitude / 180.0 * M_PI;
        double y = cos(x1) * sin(x2) - sin(x1) * cos(x2) * cos(y2-y1);
        double x = sin(y2-y1) * cos(x2);
        double t = atan2(y, x);
        double b = t / M_PI * 180.0 + 360.0;
        if (b >= 360.0)
                b -= 360.0;
        return b;
}


- (double) averageSpeedOverSeconds:(double)cutoff {
        if ([locations count] < 2)
                return 0.0;
        
        double totDist = 0.0;
        double totTime = 0.0;
        NSDate *now = [NSDate date];
        
        if (cutoff == 0) {
                CLLocation *locA, *locB;
                locA = [locations objectAtIndex:[locations count] - 2];
                locB = [locations objectAtIndex:[locations count] - 1];
                return [self speedFromLocation:locA toLocation:locB];
        } else {
                CLLocation *last = [locations lastObject];
                for (int i = [locations count] - 2; i >= 0; i--) {
                        CLLocation*  loc = [locations objectAtIndex:i];
                        double secs = [now timeIntervalSinceDate:loc.timestamp];
                        if (secs <= cutoff) {
                                double dist = [self distanceBetweenLocation:last andLocation:loc];
                                double timeinterval = [last.timestamp timeIntervalSinceDate:loc.timestamp];
                                
                                totDist += dist;
                                totTime += (timeinterval / 3600.0);
                                
                                last = loc;
                        }
                }
        }
        
        return totDist / totTime;
}

- (double) averageCourseOverSeconds:(double)cutoff {
        if ([locations count] < 2)
                return 0.0;
        
        NSDate *now = [NSDate date];
        CLLocation *locA = nil, *locB = nil;
        locB = [locations objectAtIndex:[locations count] - 1];
        if (cutoff == 0) {
                locA = [locations objectAtIndex:[locations count] - 2];
        } else {
                for (int i = [locations count] - 2; i >= 0; i--) {
                        locA = [locations objectAtIndex:i];
                        double secs = [now timeIntervalSinceDate:locA.timestamp];
                        if (secs > cutoff)
                                break;
                }
        }

        if (!locA)
                return 0.0;
        else
                return [self bearingFromLocation:locA toLocation:locB];
}

- (NSString*) formatCourse:(double)bearing {
        int quadrant = (int) ((bearing + 11.25) / 22.5);
        NSString *names[] = { @"N", @"NNE", @"NE", @"ENE", @"E", @"ESE", @"SE", @"SSE", @"S", @"SSW", @"SW", @"WSW", @"W", @"WNW", @"NW", @"NNW", @"N" };
        return [NSString stringWithFormat:@"%.0f° %@", bearing, names[quadrant]];
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

- (void)takeDirectMeasurement:(NSTimer*)timer
{
        // Nil locations are not good
        if (!locationManager.location)
                return;
        
#ifdef DEBUG
        static double offset = 0.0;
        CLLocation *newLocation = [[CLLocation alloc] initWithLatitude:locationManager.location.coordinate.latitude + offset longitude:locationManager.location.coordinate.longitude + offset];
        offset += 0.00001;
#else
        CLLocation *newLocation = locationManager.location;
#endif
        
        // Save it so it can be displayed etc.
        self.currentLocation = newLocation;
        
        // Update the state (good = we have enough precision).
        stateGood = (newLocation.horizontalAccuracy <= MINIMUM_PRECISION);
        
        // If we don't have the required accuracy, end things here.
        if (newLocation.horizontalAccuracy < 0 || newLocation.horizontalAccuracy > MINIMUM_PRECISION) {
                if ([directMeasurements count] > 0) {
                        [directMeasurements release];
                        directMeasurements = [[NSMutableArray alloc] init];                        
                }
                if (inTrackSegment) {
                        [self endGPXTrackSegment];
                        inTrackSegment = NO;
                }
                return;
        } else {
                // Set the start time if we haven't
                if (!startTime)
                        startTime = [[NSDate date] retain];
                
                // Save a "direct measurement"
                [directMeasurements addObject:newLocation];
        }
}

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
        distance += [self distanceBetweenLocation:[locations lastObject] andLocation:location];
        
        // Save the averaged reading
        [locations addObject:location];
        
        if (!inTrackSegment) {
                [self beginGPXTrackSegment];
                inTrackSegment = YES;
        }
        [self pointInGPX:location];
}

- (void)updateDisplay:(NSTimer*)timer
{
        static BOOL prevStateGood = NO;
        static double distFactor = 0.0;
        static double speedFactor = 0.0;
        static NSString *distFormat = nil;
        static NSString *speedFormat = nil;
        
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
        
        double progress = ((double) lastSampleSize / DESIRED_MULTIPLIER);
        if (progress > 1.0)
                progress = 1.0;
        
        if (currentLocation)
                positionLabel.text = [NSString stringWithFormat:@"%@\n%@\nelev %.0f m", [self formatLat: currentLocation.coordinate.latitude], [self formatLon: currentLocation.coordinate.longitude], currentLocation.altitude];
        if (currentLocation.verticalAccuracy < 0)
                accuracyLabel.text = [NSString stringWithFormat:@"±%.0f m h, ±inf v.", currentLocation.horizontalAccuracy];
        else
                accuracyLabel.text = [NSString stringWithFormat:@"±%.0f m h, ±%.0f m v.", currentLocation.horizontalAccuracy, currentLocation.verticalAccuracy];
        
        if (startTime != nil)
                elapsedTimeLabel.text =  [self formatTimestamp:[[NSDate date] timeIntervalSinceDate:startTime] maxTime:86400];
        
        double curSpeed = [self averageSpeedOverSeconds:USERPREF_CURRENT_SECONDS];
        totalDistanceLabel.text = [NSString stringWithFormat:distFormat, distance*distFactor];
        currentSpeedLabel.text = [NSString stringWithFormat:speedFormat, curSpeed*speedFactor];
        averageSpeedLabel.text = [NSString stringWithFormat:speedFormat, [self averageSpeedOverSeconds:USERPREF_AVERAGE_SECONDS]*speedFactor];
        currentTimePerDistanceLabel.text = [self formatTimestamp:USERPREF_ESTIMATE_DISTANCE * 3600.0 / curSpeed maxTime:86400];
        currentTimePerDistanceDescrLabel.text = [NSString stringWithFormat:@"per %.2f km", USERPREF_ESTIMATE_DISTANCE];
        statusLabel.text = [NSString stringWithFormat:@"%04d measurements", averagedMeasurements];
        compass.course = [self averageCourseOverSeconds:USERPREF_CURRENT_SECONDS];
        //bearingLabel.text = [NSString stringWithFormat:@"%.0f°", [self averageCourseOverSeconds:USERPREF_CURRENT_SECONDS]];
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
