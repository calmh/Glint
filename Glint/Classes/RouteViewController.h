//
// RouteViewController.h
// Glint
//
// Created by Jakob Borg on 9/11/09.
// Copyright 2009 Jakob Borg. All rights reserved.
//

#import "CSMapRouteLayerView.h"
#import "GlintAppDelegate.h"
#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>

@interface RouteViewController : UIViewController {
        NSArray *locations;
        CSMapRouteLayerView *routeLayer;
}

@property (retain, nonatomic) NSArray *locations;

@end
