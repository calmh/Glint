//
// RouteViewController.h
// Glint
//
// Created by Jakob Borg on 9/11/09.
// Copyright 2009 Jakob Borg. All rights reserved.
//

#import "GlintAppDelegate.h"
#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>

@interface RouteViewController : UIViewController <MKMapViewDelegate> {
        NSArray *locations;
        MKPolyline *polyLine;
}

@property (retain, nonatomic) NSArray *locations;

@end
