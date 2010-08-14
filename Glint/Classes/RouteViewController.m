//
// RouteViewController.m
// Glint
//
// Created by Jakob Borg on 9/11/09.
// Copyright 2009 Jakob Borg. All rights reserved.
//

#import "RouteViewController.h"

@interface RouteViewController (Private)
- (void)verifyNetworkConnectivity;
@end


@implementation RouteViewController

@synthesize locations;

- (void)dealloc
{
        [locations release];
        [super dealloc];
}

- (void)viewDidLoad
{
        self.title = NSLocalizedString(@"Map View", nil);
        MKMapView *map_view = (MKMapView*) self.view;
        if (USERPREF_MAP_TYPE == 0)
                [map_view setMapType:MKMapTypeStandard];
        else if (USERPREF_MAP_TYPE == 1)
                [map_view setMapType:MKMapTypeSatellite];
        else if (USERPREF_MAP_TYPE == 2)
                [map_view setMapType:MKMapTypeHybrid];
}

- (void)viewDidDisappear:(BOOL)animated
{
        [routeLayer stop];
        [routeLayer release];
        [super viewDidDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
        [super viewDidAppear:animated];
        routeLayer = [[CSMapRouteLayerView alloc] initWithRoute:locations mapView:(MKMapView*) self.view];

        [self verifyNetworkConnectivity];
}

/*
 * Private methods
 */

- (void)verifyNetworkConnectivity
{
        GlintAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        NetworkStatus netStatus = [[delegate reachManager] currentReachabilityStatus];
        if (netStatus == NotReachable) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet Connectivity Required", nil) message:NSLocalizedString(@"Without internet connectivity, the map cannot be displayed. A blank background will be used instead.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
                [alert show];
        }
}

@end
