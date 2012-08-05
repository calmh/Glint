//
// MainScreenViewController.m
// Glint
//
// Created by Jakob Borg on 6/26/09.
// Copyright Jakob Borg 2009. All rights reserved.
//

#import "MainScreenViewController.h"

/*
 * Private methods
 */
@interface MainScreenViewController ()
- (void)indicatePositiveState:(UILabel*)indicator;
- (void)indicateNegativeState:(UILabel*)indicator;
- (void)indicateDisabledState:(UILabel*)indicator;
- (void)resetPage;
- (void)switchPage;
- (void)switchPageWithSpeed:(float)secs;
- (void)switchPageWithoutAnimation;
- (void)shiftViewsTo:(float)position;
- (void)updateLapTimes;
- (void)updateRacingIndicator;
- (void)updateSignalIndicator;
- (void)initializePrimaryPageWithDescriptionRect:(CGRect)pageDescriptionRect;
- (void)initializeSecondaryPageWithDescriptionRect:(CGRect)pageDescriptionRect;
- (void)initializeTertiaryPageWithDescriptionRect:(CGRect)pageDescriptionRect;
- (void)loadSoundEffects;
- (void)initializePages;
- (void)initializeIndicators;
- (void)initializeLocalizedElements;
- (void)updateLapTimes;
- (void)updateRacingIndicator;
- (void)updateSignalIndicator;
- (void)updateLocationLabels:(CLLocation*)current;
- (void)updateMeasurementsLabel;
- (void)updateSpeedAndDistanceLabels;
- (void)updateRacingLabels;
- (void)updateSpeedLabels;
- (void)updateTimeAndDistanceLabels;
- (void)updateCourse;
- (void)displayGPSInstructions;
@end

@implementation MainScreenViewController

@synthesize containerView, primaryView, secondaryView, tertiaryView;
@synthesize pager;
@synthesize signalIndicator, recordingIndicator, racingIndicator;
@synthesize toolbar;
@synthesize measurementsLabel;
@synthesize slider;

@synthesize primaryScreenDescription;
@synthesize elapsedTimeLabel, elapsedTimeDescrLabel;
@synthesize totalDistanceLabel, totalDistanceDescrLabel;
@synthesize currentSpeedLabel, currentSpeedDescrLabel;
@synthesize averageSpeedLabel, averageSpeedDescrLabel;
@synthesize currentTimePerDistanceLabel, currentTimePerDistanceDescrLabel;
@synthesize compass;

@synthesize secondaryScreenDescription;
@synthesize latitudeLabel, latitudeDescrLabel;
@synthesize longitudeLabel, longitudeDescrLabel;
@synthesize elevationLabel, elevationDescrLabel;
@synthesize horAccuracyLabel, horAccuracyDescrLabel;
@synthesize verAccuracyLabel, verAccuracyDescrLabel;
@synthesize courseLabel, courseDescrLabel;

@synthesize tertiaryScreenDescription;
@synthesize lapTimeController;

- (void)dealloc
{
        [goodSound release];
        [badSound release];
        [firstMeasurementDate release];
        [lastMeasurementDate release];
        [super dealloc];
}

- (void)viewDidLoad
{
        [super viewDidLoad];

        firstMeasurementDate  = nil;
        lastMeasurementDate = nil;
        lockTimer = nil;
        touchStartTime = nil;

        delegate = [[UIApplication sharedApplication] delegate];
        gpsManager = [delegate gpsManager];

        [self loadSoundEffects];
        [self initializePages];
        [self initializeIndicators];
        [self initializeLocalizedElements];
        [self startTimers];

#ifdef DEBUG
        self.measurementsLabel.textColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:1.0];
#endif

        [self displayGPSInstructions];
}

- (void)viewWillDisappear:(BOOL)animated
{
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
        [gpsManager commit];

        [super viewWillDisappear:animated];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
        UITouch *touch = [touches anyObject];
        [touchStartTime release];
        if (touch.view == containerView) {
                touchStartPoint = [touch locationInView:containerView];
                touchStartTime = [[NSDate date] retain];
        } else
                touchStartTime = nil;
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
        if (!touchStartTime) return;

        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:containerView];
        float xdiff = point.x - touchStartPoint.x;
        if ((xdiff > 0.0f && pager.currentPage == 0) || // Moving too far to the left
            (xdiff < 0.0f && pager.currentPage == pager.numberOfPages - 1)) // Moving too far to the right
                xdiff /= 2.0f;  // Increase "resistance"
        [self shiftViewsTo:xdiff - pager.currentPage * containerView.frame.size.width];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
        if (!touchStartTime) return;

        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:containerView];
        float xdiff = point.x - touchStartPoint.x;
        float tdiff = [[NSDate date] timeIntervalSinceDate:touchStartTime];
        int minPage = 0;
        int maxPage = [containerView.subviews count] - 1;
        bool pageChanged = NO;

        if (pager.currentPage < maxPage && (xdiff <= -containerView.frame.size.width / 2.0 || xdiff / tdiff <= -250.0f)) {
                // Moving right
                pager.currentPage = pager.currentPage + 1;
                pageChanged = YES;
        } else if (pager.currentPage > minPage && (xdiff >= containerView.frame.size.width / 2.0 || xdiff / tdiff >= 250.0f)) {
                // Moving left
                pager.currentPage = pager.currentPage - 1;
                pageChanged = YES;
        }

        if (pageChanged) {
                float leftToMove = containerView.frame.size.width - fabs(xdiff);
                float speed = fabs(xdiff / tdiff);
                float animationSecs = leftToMove / speed;
                debug_NSLog(@"Finishing animation with speed %f s", animationSecs);
                [self switchPageWithSpeed:animationSecs];
        } else
                [self resetPage];
}

/*
 * IBActions
 */

- (IBAction)pageChanged:(id)sender
{
        [self switchPage];
}

- (void)updateStatus:(NSTimer*)timer
{
        if (!statusTimerRunning) {
                [timer invalidate];
                return;
        }

        [self updateSignalIndicator];
        [self updateRacingIndicator];
        [self updateLapTimes];
}

- (void)updateDisplay:(NSTimer*)timer
{
        if (!displayTimerRunning) {
                [timer invalidate];
                return;
        }

        if ([[UIDevice currentDevice] proximityState])
                // Don't update the display if it's turned off by the proximity sensor.
                // Saves CPU cycles and battery time, I hope.
                return;

        [self updateLocationLabels:gpsManager.location];
        [self updateTimeAndDistanceLabels];
        [self updateSpeedLabels];
        [self updateMeasurementsLabel];
        [self updateCourse];

        if ([[gpsManager math] raceLocations] != nil)
                [self updateRacingLabels];
        else
                [self updateSpeedAndDistanceLabels];
}

- (void)startTimers
{
        displayTimerRunning = YES;
        NSTimer *displayUpdater = [NSTimer timerWithTimeInterval:DISPLAY_THREAD_INTERVAL target:self selector:@selector(updateDisplay:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:displayUpdater forMode:NSDefaultRunLoopMode];

        statusTimerRunning = YES;
        NSTimer *statusUpdater = [NSTimer timerWithTimeInterval:STATUS_THREAD_INTERVAL target:self selector:@selector(updateStatus:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:statusUpdater forMode:NSDefaultRunLoopMode];
}

- (void)stopTimers
{
        displayTimerRunning = NO;
        statusTimerRunning = NO;
}

/*
 * Private methods
 */

- (void)initializePrimaryPageWithDescriptionRect:(CGRect)pageDescriptionRect
{
        self.primaryScreenDescription.text = NSLocalizedString(@"Speed & Distance", nil);
        self.primaryScreenDescription.frame = pageDescriptionRect;
        self.primaryScreenDescription.transform = CGAffineTransformMakeRotation(-M_PI / 2.0f);
        self.elapsedTimeLabel.text = [delegate formatTimestamp:0.0f maxTime:86400.0f allowNegatives:NO];
        self.totalDistanceLabel.text = [delegate formatDistance:0.0f];
        self.currentSpeedLabel.text = [delegate formatSpeed:0.0f];
        self.averageSpeedLabel.text = [delegate formatSpeed:0.0f];
        self.currentTimePerDistanceLabel.text = @"?";
        self.elapsedTimeDescrLabel.text = NSLocalizedString(@"elapsed", nil);
        self.totalDistanceDescrLabel.text = NSLocalizedString(@"total distance", nil);
        self.currentSpeedDescrLabel.text = NSLocalizedString(@"cur speed", nil);
}

- (void)initializeSecondaryPageWithDescriptionRect:(CGRect)pageDescriptionRect
{
        self.secondaryScreenDescription.text = NSLocalizedString(@"Position & Course", nil);
        self.secondaryScreenDescription.frame = pageDescriptionRect;
        self.secondaryScreenDescription.transform = CGAffineTransformMakeRotation(-M_PI / 2.0f);
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
}

- (void)initializeTertiaryPageWithDescriptionRect:(CGRect)pageDescriptionRect
{
        self.tertiaryScreenDescription.text = NSLocalizedString(@"Lap Times", nil);
        self.tertiaryScreenDescription.frame = pageDescriptionRect;
        self.tertiaryScreenDescription.transform = CGAffineTransformMakeRotation(-M_PI / 2.0f);
}

- (void)loadSoundEffects
{
        badSound = [[SoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Basso" ofType:@"aiff"]];
        goodSound = [[SoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Purr" ofType:@"aiff"]];
        lapSound = [[SoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Ping" ofType:@"aiff"]];
}

- (void)initializePages
{
        [containerView addSubview:primaryView];
        [containerView addSubview:secondaryView];
        [containerView addSubview:tertiaryView];
        [self shiftViewsTo:0.0f];
        int numPages = [containerView.subviews count];
        [pager setNumberOfPages:numPages];

        CGRect pageDescriptionRect = CGRectMake(-145.0f, 344.0f / 2.0f, 314.0f, 24.0f);
        [self initializePrimaryPageWithDescriptionRect:pageDescriptionRect];
        [self initializeSecondaryPageWithDescriptionRect:pageDescriptionRect];
        [self initializeTertiaryPageWithDescriptionRect:pageDescriptionRect];

        [pager setCurrentPage:USERPREF_CURRENTPAGE];
        [self switchPageWithoutAnimation];
}

- (void)initializeIndicators
{
        [self indicateDisabledState:signalIndicator];
        [self indicateDisabledState:recordingIndicator];
        [self indicateDisabledState:racingIndicator];
}

- (void)initializeLocalizedElements
{
        self.measurementsLabel.text = [NSString stringWithFormat:@"0 %@", NSLocalizedString(@"measurements", nil)];

        UIBarButtonItem *filesButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Files", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(sendFiles:)] autorelease];
        UIBarButtonItem *recordButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Record", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(startStopRecording:)] autorelease];
        UIBarButtonItem *stopRaceButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"End Race", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(endRace:)] autorelease];
        toolbarItems = [[NSArray arrayWithObjects:filesButton, recordButton, stopRaceButton, nil] retain];
        [toolbar setItems:toolbarItems animated:YES];
}

- (void)updateLapTimes
{
        NSArray *newLaptimes = [gpsManager queuedLapTimes];
        if ([newLaptimes count] > 0) {
                [lapSound play];
                for (LapTime*l in newLaptimes) {
                        debug_NSLog(@"Lap time: %f seconds at distance %f meters", l.elapsedTime, l.distance);
                        [lapTimeController addLapTime:l.elapsedTime forDistance:l.distance];
                }
        }
}

- (void)updateRacingIndicator
{
        LocationMath *tmath = [gpsManager math];
        NSArray *tloc = [tmath raceLocations];

        if (tloc != nil)
                [self indicatePositiveState:racingIndicator];
        else
                [self indicateDisabledState:racingIndicator];
}

- (void)updateSignalIndicator
{
        static BOOL prevStateGood = NO;

        if (!gpsManager.isGPSEnabled)
                [self indicateDisabledState:signalIndicator];
        else {
                if (gpsManager.isPrecisionAcceptable)
                        [self indicatePositiveState:signalIndicator];
                else
                        [self indicateNegativeState:signalIndicator];

                if (USERPREF_SOUNDS && prevStateGood != gpsManager.isPrecisionAcceptable) {
                        if (gpsManager.isPrecisionAcceptable)
                                [goodSound play];
                        else
                                [badSound play];
                }
                prevStateGood = gpsManager.isPrecisionAcceptable;
        }
}

- (void)updateLocationLabels:(CLLocation*)current
{
        if (!current)
                return;

        self.latitudeLabel.text = [delegate formatLat:current.coordinate.latitude];
        self.longitudeLabel.text = [delegate formatLon:current.coordinate.longitude];
        self.elevationLabel.text = [delegate formatShortDistance:current.altitude];

        if (current.horizontalAccuracy >= 0)
                self.horAccuracyLabel.text = [delegate formatShortDistance:current.horizontalAccuracy];
        else
                self.horAccuracyLabel.text = @"±inf";

        if (current.verticalAccuracy >= 0)
                self.verAccuracyLabel.text = [delegate formatShortDistance:current.verticalAccuracy];
        else
                self.verAccuracyLabel.text = @"±inf";
}

- (void)updateMeasurementsLabel
{
        if (gpsManager.isRecording)
                self.measurementsLabel.text = [NSString stringWithFormat:@"%d %@", [gpsManager numSavedMeasurements], NSLocalizedString(@"measurements", nil)];
}

- (void)updateSpeedAndDistanceLabels
{
        self.averageSpeedLabel.textColor = [UIColor colorWithRed:0xFF / 255.0f green:0x80 / 255.0f blue:0x00 / 255.0f alpha:1.0f];
        self.currentTimePerDistanceLabel.textColor = [UIColor colorWithRed:0x66 / 255.0f green:0xFF / 255.0f blue:0x66 / 255.0f alpha:1.0f];

        self.averageSpeedLabel.text = [delegate formatSpeed:[[gpsManager math] averageSpeed]];
        self.averageSpeedDescrLabel.text = NSLocalizedString(@"avg speed", nil);

        float secsPerEstDist = USERPREF_ESTIMATE_DISTANCE * 1000.0 / [[gpsManager math] currentSpeed];
        self.currentTimePerDistanceLabel.text = [delegate formatTimestamp:secsPerEstDist maxTime:86400 allowNegatives:NO];
        NSString *distStr = [delegate formatDistance:USERPREF_ESTIMATE_DISTANCE * 1000.0];
        self.currentTimePerDistanceDescrLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"per", @"... per (distance)"), distStr];
}

- (void)updateRacingLabels
{
        // TODO: Needs refactoring to clear up what's going on

        float distDiff = [[gpsManager math] distDifferenceInRace];
        if (!isnan(distDiff)) {
                NSString *distString = [delegate formatDistance:distDiff];
                self.averageSpeedLabel.text = [distDiff < 0.0 ? @"":@"+" stringByAppendingString:distString];
        } else
                self.averageSpeedLabel.text = @"?";
        self.averageSpeedDescrLabel.text = NSLocalizedString(@"dist diff", nil);
        if (distDiff < 0.0)
                self.averageSpeedLabel.textColor = [UIColor colorWithRed:0xFF / 255.0 green:0x40 / 255.0 blue:0x40 / 255.0 alpha:1.0];
        else
                self.averageSpeedLabel.textColor = [UIColor colorWithRed:0x40 / 255.0 green:0xFF / 255.0 blue:0x40 / 255.0 alpha:1.0];

        float timeDiff = [[gpsManager math] timeDifferenceInRace];
        self.currentTimePerDistanceLabel.text = [delegate formatTimestamp:timeDiff maxTime:86400 allowNegatives:YES];
        self.currentTimePerDistanceDescrLabel.text = NSLocalizedString(@"time diff", nil);
        if (timeDiff > 0.0)
                self.currentTimePerDistanceLabel.textColor = [UIColor colorWithRed:0xFF / 255.0 green:0x40 / 255.0 blue:0x40 / 255.0 alpha:1.0];
        else
                self.currentTimePerDistanceLabel.textColor = [UIColor colorWithRed:0x40 / 255.0 green:0xFF / 255.0 blue:0x40 / 255.0 alpha:1.0];
}

- (void)updateSpeedLabels
{
        if ([[gpsManager math] currentSpeed] >= 0.0)
                self.currentSpeedLabel.text = [delegate formatSpeed:[[gpsManager math] currentSpeed]];
        else
                self.currentSpeedLabel.text = @"?";
}

- (void)updateTimeAndDistanceLabels
{
        self.elapsedTimeLabel.text =  [delegate formatTimestamp:[[gpsManager math] estimatedElapsedTime] maxTime:86400 allowNegatives:NO];
        self.totalDistanceLabel.text = [delegate formatDistance:[[gpsManager math] totalDistance]];
}

- (void)updateCourse
{
        self.compass.course = [[gpsManager math] currentCourse];
        self.courseLabel.text = [NSString stringWithFormat:@"%.0f°", [[gpsManager math] currentCourse]];
}

- (void)indicatePositiveState:(UILabel*)indicator
{
        indicator.backgroundColor = [UIColor colorWithRed:0.4 green:1.0 blue:0.4 alpha:1.0];
        indicator.textColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:1.0];
}

- (void)indicateNegativeState:(UILabel*)indicator
{
        indicator.backgroundColor = [UIColor colorWithRed:1.0 green:0.4 blue:0.4 alpha:1.0];
        indicator.textColor = [UIColor colorWithRed:0.5 green:0.0 blue:0.0 alpha:1.0];
}

- (void)indicateDisabledState:(UILabel*)indicator
{
        indicator.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
        indicator.textColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0];
}

// Switch the main screen to the other page

- (void)switchPage
{
        [self switchPageWithSpeed:0.5];
}

- (void)switchPageWithSpeed:(float)secs
{
        // Save page number as future default
        [[NSUserDefaults standardUserDefaults] setInteger:pager.currentPage forKey:@"current_page"];

        // Animate to the new page
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:secs];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [self shiftViewsTo:-pager.currentPage * containerView.frame.size.width];
        [UIView commitAnimations];
}

- (void)switchPageWithoutAnimation
{
        // Save page number as future default
        [[NSUserDefaults standardUserDefaults] setInteger:pager.currentPage forKey:@"current_page"];

        // Shift instantly to the new page
        [self shiftViewsTo:-pager.currentPage * containerView.frame.size.width];
}

// Reset the main screen to the same page we are on

- (void)resetPage
{
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.5];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [self shiftViewsTo:-pager.currentPage * containerView.frame.size.width];
        [UIView commitAnimations];
}

- (void)shiftViewsTo:(float)position
{
        CGRect r = containerView.frame;
        r.origin.x += position;
        for (UIView*view in containerView.subviews) {
                // Set the page position
                view.frame = r;

                // Fade away pages that are not in the center of the view.
                float visibleAmount = 1.0 - fabs(r.origin.x) / containerView.frame.size.width;
                if (visibleAmount < 0.0f)
                        visibleAmount = 0.0f;
                view.alpha = visibleAmount;

                // Update coordinate for next page
                r.origin.x += r.size.width;
        }
}

- (void)slided:(id)sender
{
        @synchronized(self) {
                debug_NSLog(@"unlock: start");
                if ([gpsManager isRecording])
                        [(UIBarButtonItem*) [toolbarItems objectAtIndex:1] setTitle:NSLocalizedString(@"End Recording", nil)];
                else
                        [(UIBarButtonItem*) [toolbarItems objectAtIndex:1] setTitle:NSLocalizedString(@"Record", nil)];

                if ([[gpsManager math] raceLocations])
                        [(UIBarButtonItem*) [toolbarItems objectAtIndex:2] setEnabled:YES];
                else
                        [(UIBarButtonItem*) [toolbarItems objectAtIndex:2] setEnabled:NO];

                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration:0.3];
                CGRect rect = slider.frame;
                rect.origin.y = self.view.frame.size.height + 1;
                [slider setFrame:rect];
                [UIView commitAnimations];

                if (lockTimer) {
                        [lockTimer invalidate];
                        [lockTimer release];
                }
                lockTimer = [NSTimer timerWithTimeInterval:SLIDER_DELAY_INTERVAL target:self selector:@selector(lock:) userInfo:nil repeats:NO];
                [lockTimer retain];
                [[NSRunLoop currentRunLoop] addTimer:lockTimer forMode:NSDefaultRunLoopMode];
                debug_NSLog(@"unlock: done");
        }
}

- (void)lock:(id)sender
{
        @synchronized(self) {
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
                // [slider setHidden:NO];
                // [toolbar setItems:lockedToolbarItems animated:NO];
                debug_NSLog(@"lock: done");
        }
}

- (void)sendFiles:(id)sender
{
        [(GlintAppDelegate*)[[UIApplication sharedApplication] delegate] switchToSendFilesView:sender];
        [self lock:sender];
}

- (void)startStopRecording:(id)sender
{
        if (![gpsManager isRecording]) {
                NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
                [formatter setDateFormat:@"yyyyMMdd-HHmmss"];
                [self indicatePositiveState:recordingIndicator];
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString *filename = [NSString stringWithFormat:@"%@/track-%@.gpx", documentsDirectory, [formatter stringFromDate:[NSDate date]]];
                [[NSUserDefaults standardUserDefaults] setObject:filename forKey:@"recording_filename"];
                [gpsManager startRecordingOnFile:filename];
        } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"recording_filename"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [self indicateDisabledState:recordingIndicator];
                [gpsManager stopRecording];
        }
        [self lock:sender];
}

- (void)resumeRecordingOnFile:(NSString*)filename
{
        [gpsManager resumeRecordingOnFile:filename];
        [self performSelectorOnMainThread:@selector(indicatePositiveState:) withObject:recordingIndicator waitUntilDone:NO];
}

- (void)endRace:(id)sender
{
        [[gpsManager math] setRaceLocations:nil];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"raceAgainstFile"];
        [self lock:sender];
}

- (void)displayGPSInstructions
{
        bool instructions_shown = [[NSUserDefaults standardUserDefaults] boolForKey:@"have_shown_gps_instructions"];
        if (!instructions_shown) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"GPS Signal Required", nil) message:NSLocalizedString(@"Glint needs a GPS signal. For best results, please make sure that you are outdoors and have a clear view of the sky.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"I understand", nil) otherButtonTitles:nil];
                [alert show];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"have_shown_gps_instructions"];
        }
}

@end
