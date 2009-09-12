//
//  RouteViewController.m
//  Glint
//
//  Created by Jakob Borg on 9/11/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "RouteViewController.h"

@implementation RouteViewController

@synthesize locations;

- (void)dealloc {
        [locations release];
        [super dealloc];
}

/*
- (void)setLocations:(NSArray *)newLocations {
        if (locations != newLocations) {
                [locations release];
                locations = [newLocations retain];
        }
}
*/

- (void)viewDidLoad {
        self.title = NSLocalizedString(@"Map View",nil);
}

- (void)viewDidDisappear:(BOOL)animated {
        [routeLayer stop];
        [routeLayer release];
        [super viewDidDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
        routeLayer = [[CSMapRouteLayerView alloc] initWithRoute:locations mapView:(MKMapView*)self.view];
        [super viewDidAppear:animated];
}

@end
