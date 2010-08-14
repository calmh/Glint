//
// CSMapRouteLayerView.m
// mapLines
#import "CSMapRouteLayerView.h"

@implementation CSMapRouteLayerView
@synthesize mapView = _mapView;
@synthesize points = _points;
@synthesize lineColor = _lineColor;

- (id)initWithRoute:(NSArray*)routePoints mapView:(MKMapView*)mapView
{
        self = [super initWithFrame:CGRectMake(0, 0, mapView.frame.size.width, mapView.frame.size.height)];
        [self setBackgroundColor:[UIColor clearColor]];

        [self setMapView:mapView];
        [self setPoints:routePoints];

        CLLocationDegrees maxLat = -90;
        CLLocationDegrees maxLon = -180;
        CLLocationDegrees minLat = 90;
        CLLocationDegrees minLon = 180;

        if (self.points.count > 1)
                // determine the extents of the trip points that were passed in, and zoom in to that area.
                for (int idx = 0; idx < self.points.count; idx++) {
                        CLLocation *currentLocation = [self.points objectAtIndex:idx];

                        // Skip points that are break markers
                        if ([LocationMath isBreakMarker:currentLocation])
                                continue;

                        if (currentLocation.coordinate.latitude > maxLat)
                                maxLat = currentLocation.coordinate.latitude;
                        if (currentLocation.coordinate.latitude < minLat)
                                minLat = currentLocation.coordinate.latitude;
                        if (currentLocation.coordinate.longitude > maxLon)
                                maxLon = currentLocation.coordinate.longitude;
                        if (currentLocation.coordinate.longitude < minLon)
                                minLon = currentLocation.coordinate.longitude;
                }
        else if (self.points.count == 1) {
                CLLocation *loc = [self.points objectAtIndex:0];
                maxLat = loc.coordinate.latitude + 100.0f / 1852.0f / 60.0f;
                minLat = loc.coordinate.latitude - 100.0f / 1852.0f / 60.0f;
                maxLon = loc.coordinate.longitude + 100.0f / 1852.0f / 60.0f;
                minLon = loc.coordinate.longitude - 100.0f / 1852.0f / 60.0f;
        }

        MKCoordinateRegion region;
        region.center.latitude = (maxLat + minLat) / 2;
        region.center.longitude = (maxLon + minLon) / 2;
        region.span.latitudeDelta = maxLat - minLat;
        region.span.longitudeDelta = maxLon - minLon;

        [self.mapView setRegion:region];
        [self.mapView setDelegate:self];
        [self.mapView addSubview:self];

        return self;
}

- (void)drawRect:(CGRect)rect
{
        // only draw our lines if we're not int he moddie of a transition and we
        // acutally have some points to draw.
        if (!self.hidden && nil != self.points && self.points.count > 0) {
                CGContextRef context = UIGraphicsGetCurrentContext();

                if (nil == self.lineColor)
                        self.lineColor = [UIColor blueColor];

                CGContextSetStrokeColorWithColor(context, self.lineColor.CGColor);
                CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 1.0);

                // Draw them with a 2.0 stroke width so they are a bit more visible.
                CGContextSetLineWidth(context, 2.0);

                if (self.points.count > 1) {
                        BOOL shouldSkip = NO;
                        for (int idx = 0; idx < self.points.count; idx++) {
                                CLLocation *location = [self.points objectAtIndex:idx];
                                // Skip points that are break markers
                                if ([LocationMath isBreakMarker:location]) {
                                        shouldSkip = YES;
                                        continue;
                                }

                                CGPoint point = [_mapView convertCoordinate:location.coordinate toPointToView:self];
                                if (idx == 0 || shouldSkip)
                                        CGContextMoveToPoint(context, point.x, point.y);
                                else
                                        CGContextAddLineToPoint(context, point.x, point.y);
                                shouldSkip = NO;
                        }
                } else if (self.points.count == 1) {
                        CGPoint point = [_mapView convertCoordinate:((CLLocation*) [self.points objectAtIndex:0]).coordinate toPointToView:self];
                        int diamond_size = 4;
                        CGContextMoveToPoint(context, point.x, point.y - diamond_size);
                        CGContextAddLineToPoint(context, point.x + diamond_size, point.y);
                        CGContextAddLineToPoint(context, point.x, point.y + diamond_size);
                        CGContextAddLineToPoint(context, point.x - diamond_size, point.y);
                        CGContextAddLineToPoint(context, point.x, point.y - diamond_size);
                }

                CGContextStrokePath(context);
        }
}

#pragma mark mapView delegate functions
- (void)mapView:(MKMapView*)mapView regionWillChangeAnimated:(BOOL)animated
{
        // turn off the view of the route as the map is chaning regions. This prevents
        // the line from being displayed at an incorrect positoin on the map during the
        // transition.
        self.hidden = YES;
}

- (void)mapView:(MKMapView*)mapView regionDidChangeAnimated:(BOOL)animated
{
        // re-enable and re-poosition the route display.
        self.hidden = NO;
        [self setNeedsDisplay];
}

- (void)stop
{
        if (self.mapView.delegate == self)
                self.mapView.delegate = nil;
        [self removeFromSuperview];
}

- (void)dealloc
{
        [_points release];
        [_mapView release];
        [super dealloc];
}

@end
