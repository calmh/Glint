//
// RouteViewController.m
// Glint
//
// Created by Jakob Borg on 9/11/09.
// Copyright 2009 Jakob Borg. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
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
        [polyLine release];
        polyLine = nil;
        [super viewDidDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
        [super viewDidAppear:animated];

        // Extract the 2D locations for a polyline, and calculate the regions bound.
        CLLocationCoordinate2D *locations2d = malloc([locations count] * sizeof(CLLocationCoordinate2D));
        int i = 0;
        CLLocationCoordinate2D minCoord = {0};
        CLLocationCoordinate2D maxCoord = {0};
        for (CLLocation*loc in locations) {
                locations2d[i++] = loc.coordinate;
                if (minCoord.latitude == 0.0f || loc.coordinate.latitude < minCoord.latitude)
                        minCoord.latitude = loc.coordinate.latitude;
                if (minCoord.longitude == 0.0f || loc.coordinate.longitude < minCoord.longitude)
                        minCoord.longitude = loc.coordinate.longitude;
                if (maxCoord.latitude == 0.0f || loc.coordinate.latitude > maxCoord.latitude)
                        maxCoord.latitude = loc.coordinate.latitude;
                if (maxCoord.longitude == 0.0f || loc.coordinate.longitude > maxCoord.longitude)
                        maxCoord.longitude = loc.coordinate.longitude;
        }
        float latSpan = maxCoord.latitude - minCoord.latitude;
        float lonSpan = maxCoord.longitude - minCoord.longitude;

        // Center the map over the region containing the track.
        MKCoordinateRegion region;
        region.center = CLLocationCoordinate2DMake(minCoord.latitude + latSpan / 2.0, minCoord.longitude + lonSpan / 2.0);
        region.span = MKCoordinateSpanMake(latSpan * 1.25, lonSpan * 1.25);
        [(MKMapView*)self.view setRegion:region animated:YES];

        // Create and add a polyline overlay for the track.
        polyLine = [[MKPolyline polylineWithCoordinates:locations2d count:i] retain];
        [(MKMapView*)self.view addOverlay:polyLine];

        // Check that we have internet connectivity, or complain.
        [self verifyNetworkConnectivity];
}

- (MKOverlayView*)mapView:(MKMapView*)mapView viewForOverlay:(id<MKOverlay>)overlay
{
        static MKPolylineView *polyLineView = nil;

        if (overlay == polyLine) {
                if (nil == polyLineView) {
                        polyLineView = [[[MKPolylineView alloc] initWithPolyline:polyLine] autorelease];
                        polyLineView.strokeColor = [UIColor blueColor];
                        polyLineView.lineWidth = 3;
                }
                return polyLineView;
        }
        return nil;
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
