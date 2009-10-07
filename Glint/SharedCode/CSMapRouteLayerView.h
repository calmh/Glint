//
// CSMapRouteLayerView.h
// mapLines
#import "JBLocationMath.h"
#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>

@interface CSMapRouteLayerView : UIView <MKMapViewDelegate>
{
	MKMapView *_mapView;
	NSArray *_points;
	UIColor *_lineColor;
}

- (id)initWithRoute:(NSArray*)routePoints mapView:(MKMapView*)mapView;
- (void)stop;

@property (nonatomic, retain) NSArray *points;
@property (nonatomic, retain) MKMapView *mapView;
@property (nonatomic, retain) UIColor *lineColor;

@end
