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
- (void)positiveIndicator:(UILabel*)indicator;
- (void)negativeIndicator:(UILabel*)indicator;
- (void)disabledIndicator:(UILabel*)indicator;
- (void)resetPage;
- (void)switchPage;
- (void)switchPageWithSpeed:(float)secs;
- (void)switchPageWithoutAnimation;
- (void)shiftViewsTo:(float)position;
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

	delegate = [[UIApplication sharedApplication] delegate];
	gpsManager = [delegate gpsManager];

	[containerView addSubview:primaryView];
	[containerView addSubview:secondaryView];
	[containerView addSubview:tertiaryView];
	[self shiftViewsTo:0.0f];
	int numPages = [containerView.subviews count];
	[pager setNumberOfPages:numPages];

	badSound = [[SoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Basso" ofType:@"aiff"]];
	goodSound = [[SoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Purr" ofType:@"aiff"]];
	lapSound = [[SoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Ping" ofType:@"aiff"]];
	firstMeasurementDate  = nil;
	lastMeasurementDate = nil;
	lockTimer = nil;
	touchStartTime = nil;

	[self disabledIndicator:signalIndicator];
	[self disabledIndicator:recordingIndicator];
	[self disabledIndicator:racingIndicator];

	UIBarButtonItem *playPauseButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Pause",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(playPause:)] autorelease];
	UIBarButtonItem *filesButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Files",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(sendFiles:)] autorelease];
	UIBarButtonItem *recordButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Record",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(startStopRecording:)] autorelease];
	UIBarButtonItem *stopRaceButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"End Race",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(endRace:)] autorelease];
	toolbarItems = [[NSArray arrayWithObjects:playPauseButton, filesButton, recordButton, stopRaceButton, nil] retain];
	[toolbar setItems:toolbarItems animated:YES];

	CGRect pageDescriptionRect = CGRectMake(-145.0f, 344.0f / 2.0f, 314.0f, 24.0f);

	// Primary page

	self.primaryScreenDescription.text = NSLocalizedString(@"Speed & Distance",nil);
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

	// Secondary page

	self.secondaryScreenDescription.text = NSLocalizedString(@"Position & Course",nil);
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

	// Tertiary page

	self.tertiaryScreenDescription.text = NSLocalizedString(@"Lap Times",nil);
	self.tertiaryScreenDescription.frame = pageDescriptionRect;
	self.tertiaryScreenDescription.transform = CGAffineTransformMakeRotation(-M_PI / 2.0f);

	self.measurementsLabel.text = [NSString stringWithFormat:@"0 %@", NSLocalizedString(@"measurements",nil)];

	NSTimer *displayUpdater = [NSTimer timerWithTimeInterval:DISPLAY_THREAD_INTERVAL target:self selector:@selector(updateDisplay:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:displayUpdater forMode:NSDefaultRunLoopMode];

	NSTimer *statusUpdater = [NSTimer timerWithTimeInterval:STATUS_THREAD_INTERVAL target:self selector:@selector(updateStatus:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:statusUpdater forMode:NSDefaultRunLoopMode];

	[pager setCurrentPage:USERPREF_CURRENTPAGE];
	[self switchPageWithoutAnimation];
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
	if (touch.view == containerView) {
		touchStartPoint = [touch locationInView:containerView];
		[touchStartTime release];
		touchStartTime = [[NSDate date] retain];
	}
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:containerView];
	float xdiff = point.x - touchStartPoint.x;
	if (xdiff > 0.0f && pager.currentPage == 0 || // Moving too far to the left
	    xdiff < 0.0f && pager.currentPage == pager.numberOfPages - 1) // Moving too far to the right
		xdiff /= 2.0f;  // Increase "resistance"
	[self shiftViewsTo:xdiff - pager.currentPage * containerView.frame.size.width];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
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
		debug_NSLog(@"Finishing animation with speed %f s",animationSecs);
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
	static BOOL prevStateGood = NO;

	// Update color of signal indicator, play sound on change

	if (!gpsManager.isGPSEnabled)
		[self disabledIndicator:signalIndicator];
	else {
		if (gpsManager.isPrecisionAcceptable)
			[self positiveIndicator:signalIndicator];
		else
			[self negativeIndicator:signalIndicator];

		if (USERPREF_SOUNDS && prevStateGood != gpsManager.isPrecisionAcceptable) {
			if (gpsManager.isPrecisionAcceptable)
				[goodSound play];
			else
				[badSound play];
		}
		prevStateGood = gpsManager.isPrecisionAcceptable;
	}

	LocationMath *tmath = [gpsManager math];
	NSArray *tloc = [tmath raceLocations];

	if (tloc != nil)
		[self positiveIndicator:racingIndicator];
	else
		[self disabledIndicator:racingIndicator];

	// Update lap times

	NSArray *newLaptimes = [gpsManager queuedLapTimes];
	if ([newLaptimes count] > 0) {
		[lapSound play];
		for (LapTime*l in newLaptimes) {
			debug_NSLog(@"Lap time: %f seconds at distance %f meters", l.elapsedTime, l.distance);
			[lapTimeController addLapTime:l.elapsedTime forDistance:l.distance];
		}
	}
}

- (void)updateDisplay:(NSTimer*)timer
{
	// Don't update the display if it's turned off by the proximity sensor.
	// Saves CPU cycles and battery time, I hope.

	if ([[UIDevice currentDevice] proximityState])
		return;

	CLLocation *current = gpsManager.location;
	[current retain];

	// Position and accuracy

	if (current) {
		//self.positionLabel.text = [NSString stringWithFormat:@"%@\n%@\nelev %.0f m", [delegate formatLat: current.coordinate.latitude], [delegate formatLon: current.coordinate.longitude], current.altitude];
		self.latitudeLabel.text = [delegate formatLat:current.coordinate.latitude];
		self.longitudeLabel.text = [delegate formatLon:current.coordinate.longitude];
		self.elevationLabel.text = [delegate formatShortDistance:current.altitude];
		//self.positionLabel.textColor = [UIColor whiteColor];
		if (current.horizontalAccuracy >= 0)
			self.horAccuracyLabel.text = [delegate formatShortDistance:current.horizontalAccuracy];
		else
			self.horAccuracyLabel.text = @"±inf";

		if (current.verticalAccuracy >= 0)
			self.verAccuracyLabel.text = [delegate formatShortDistance:current.verticalAccuracy];
		else
			self.verAccuracyLabel.text = @"±inf";
	}

	// Timer

	self.elapsedTimeLabel.text =  [delegate formatTimestamp:[[gpsManager math] estimatedElapsedTime] maxTime:86400 allowNegatives:NO];

	// Total distance

	self.totalDistanceLabel.text = [delegate formatDistance:[[gpsManager math] totalDistance]];

	// Current speed

	if ([[gpsManager math] currentSpeed] >= 0.0)
		self.currentSpeedLabel.text = [delegate formatSpeed:[[gpsManager math] currentSpeed]];
	else
		self.currentSpeedLabel.text = @"?";

	//if (currentDataSource == kGlintDataSourceMovement)
	//        self.currentSpeedLabel.textColor = [UIColor colorWithRed:0xCC/255.0 green:0xFF/255.0 blue:0x66/255.0 alpha:1.0];
	//else if (currentDataSource == kGlintDataSourceTimer)
	//        self.currentSpeedLabel.textColor = [UIColor colorWithRed:0xA0/255.0 green:0xB5/255.0 blue:0x66/255.0 alpha:1.0];

	if (!gpsManager.isPaused) {
		if (![[gpsManager math] raceLocations]) {
			self.averageSpeedLabel.textColor = [UIColor colorWithRed:0xFF / 255.0f green:0x80 / 255.0f blue:0x00 / 255.0f alpha:1.0f];
			self.currentTimePerDistanceLabel.textColor = [UIColor colorWithRed:0x66 / 255.0f green:0xFF / 255.0f blue:0x66 / 255.0f alpha:1.0f];

			// Average speed and time per configured distance

			self.averageSpeedLabel.text = [delegate formatSpeed:[[gpsManager math] averageSpeed]];
			self.averageSpeedDescrLabel.text = NSLocalizedString(@"avg speed", nil);

			float secsPerEstDist = USERPREF_ESTIMATE_DISTANCE * 1000.0 / [[gpsManager math] currentSpeed];
			self.currentTimePerDistanceLabel.text = [delegate formatTimestamp:secsPerEstDist maxTime:86400 allowNegatives:NO];
			NSString *distStr = [delegate formatDistance:USERPREF_ESTIMATE_DISTANCE * 1000.0];
			self.currentTimePerDistanceDescrLabel.text = [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"per", @"... per (distance)"), distStr];
		} else {
			// Difference in time and distance against raceAgainstLocations.

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
	}

	// Number of saved measurements

	if (gpsManager.isRecording)
		self.measurementsLabel.text = [NSString stringWithFormat:@"%d %@", [gpsManager numSavedMeasurements], NSLocalizedString(@"measurements", nil)];

	// Current course

	self.compass.course = [[gpsManager math] currentCourse];
	self.courseLabel.text = [NSString stringWithFormat:@"%.0f°", [[gpsManager math] currentCourse]];

	[current release];
}

/*
 * Private methods
 */

// Color the specified UILabel green
- (void)positiveIndicator:(UILabel*)indicator
{
	indicator.backgroundColor = [UIColor colorWithRed:0.4 green:1.0 blue:0.4 alpha:1.0];
	indicator.textColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:1.0];
}

// Color the specified UILabel red
- (void)negativeIndicator:(UILabel*)indicator
{
	indicator.backgroundColor = [UIColor colorWithRed:1.0 green:0.4 blue:0.4 alpha:1.0];
	indicator.textColor = [UIColor colorWithRed:0.5 green:0.0 blue:0.0 alpha:1.0];
}

// Color the specified UILabel gray
- (void)disabledIndicator:(UILabel*)indicator
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

- (void)playPause:(id)sender
{
	static UIColor *elapsedTimeColor, *totalDistanceColor, *currentSpeedColor, *averageSpeedColor, *timePerDistColor;

	if (gpsManager.isPaused) {
		[[toolbarItems objectAtIndex:0] setTitle:NSLocalizedString(@"Pause",nil)];
		elapsedTimeLabel.textColor = [elapsedTimeColor autorelease];
		totalDistanceLabel.textColor = [totalDistanceColor autorelease];
		currentSpeedLabel.textColor = [currentSpeedColor autorelease];
		averageSpeedLabel.textColor = [averageSpeedColor autorelease];
		currentTimePerDistanceLabel.textColor = [timePerDistColor autorelease];
		[gpsManager resumeUpdates];
	} else {
		[gpsManager pauseUpdates];
		[[toolbarItems objectAtIndex:0] setTitle:NSLocalizedString(@"Go",nil)];
		elapsedTimeColor = [elapsedTimeLabel.textColor retain];
		elapsedTimeLabel.textColor = [UIColor colorWithRed:0.8f green:0.8f blue:0.8f alpha:1.0f];
		totalDistanceColor = [totalDistanceLabel.textColor retain];
		totalDistanceLabel.textColor = [UIColor colorWithRed:0.8f green:0.8f blue:0.8f alpha:1.0f];
		currentSpeedColor = [currentSpeedLabel.textColor retain];
		currentSpeedLabel.textColor = [UIColor colorWithRed:0.8f green:0.8f blue:0.8f alpha:1.0f];
		averageSpeedColor = [averageSpeedLabel.textColor retain];
		averageSpeedLabel.textColor = [UIColor colorWithRed:0.8f green:0.8f blue:0.8f alpha:1.0f];
		timePerDistColor = [currentTimePerDistanceLabel.textColor retain];
		currentTimePerDistanceLabel.textColor = [UIColor colorWithRed:0.8f green:0.8f blue:0.8f alpha:1.0f];
	}
}

- (void)slided:(id)sender
{
	@synchronized (self) {
		debug_NSLog(@"unlock: start");
		if ([gpsManager isRecording])
			[(UIBarButtonItem*) [toolbarItems objectAtIndex:2] setTitle:NSLocalizedString(@"End Recording", nil)];
		else
			[(UIBarButtonItem*) [toolbarItems objectAtIndex:2] setTitle:NSLocalizedString(@"Record", nil)];

		if ([[gpsManager math] raceLocations])
			[(UIBarButtonItem*) [toolbarItems objectAtIndex:3] setEnabled:YES];
		else
			[(UIBarButtonItem*) [toolbarItems objectAtIndex:3] setEnabled:NO];

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
		lockTimer = [NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(lock:) userInfo:nil repeats:NO];
		[lockTimer retain];
		[[NSRunLoop currentRunLoop] addTimer:lockTimer forMode:NSDefaultRunLoopMode];
		debug_NSLog(@"unlock: done");
	}
}

- (void)lock:(id)sender
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
		[self positiveIndicator:recordingIndicator];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		NSString *filename = [NSString stringWithFormat:@"%@/track-%@.gpx", documentsDirectory, [formatter stringFromDate:[NSDate date]]];
		[[NSUserDefaults standardUserDefaults] setObject:filename forKey:@"recording_filename"];
		[gpsManager startRecordingOnFile:filename];
	} else {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"recording_filename"];
		[self disabledIndicator:recordingIndicator];
		[gpsManager stopRecording];
	}
	[self lock:sender];
}

- (void)resumeRecordingOnFile:(NSString*)filename
{
	[gpsManager resumeRecordingOnFile:filename];
	[self performSelectorOnMainThread:@selector(positiveIndicator:) withObject:recordingIndicator waitUntilDone:NO];
}

- (void)endRace:(id)sender
{
	[[gpsManager math] setRaceLocations:nil];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"raceAgainstFile"];
	[self lock:sender];
}

@end
