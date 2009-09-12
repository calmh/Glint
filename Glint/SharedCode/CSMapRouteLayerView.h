//
// CSMapRouteLayerView.h
// mapLines
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface CSMapRouteLayerView : UIView <MKMapViewDelegate>
{
        MKMapView* _mapView;
        NSArray* _points;
        UIColor* _lineColor;
}

- (id)initWithRoute:(NSArray*)routePoints mapView:(MKMapView*)mapView;
- (void)stop;

@property (nonatomic, retain) NSArray* points;
@property (nonatomic, retain) MKMapView* mapView;
@property (nonatomic, retain) UIColor* lineColor;

@end
