//
//  CompassView.m
//  Glint
//
//  Created by Jakob Borg on 7/6/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "CompassView.h"

@interface CompassView ()
-(void)startTimer;
-(void)stopTimer;
-(void)updateCourse:(NSTimer*)timer;
- (void) drawCenteredText:(NSString *)label inContext:(CGContextRef)ctx atPosition:(CGPoint)point;
@end

@implementation CompassView

@synthesize course;

- (void)dealloc {
        [markers release];
        [super dealloc];
}

-(void)setCourse:(float)newCourse {
        if (newCourse < 0)
                newCourse += 360.0;
        else if (newCourse > 360.0)
                newCourse -= 360.0;
        
        if (newCourse != course) {
                course = newCourse;
                [self startTimer];
        }
}

-(void)awakeFromNib 
{
	[super awakeFromNib];        
        float randOrig = -10.0 + 20.0 * (random() / (float) RAND_MAX);
        if (randOrig < 0.0)
                randOrig += 360.0;
        course = randOrig;
        showingCourse = randOrig;
        animationTimer = nil;
        markers = [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"N", @"N"), [NSNumber numberWithFloat:0.0],
                   NSLocalizedString(@"NNE", @"NNE"), [NSNumber numberWithFloat:22.5],
                   NSLocalizedString(@"NE", @"NE"), [NSNumber numberWithFloat:2*22.5],
                   NSLocalizedString(@"ENE", @"ENE"), [NSNumber numberWithFloat:3*22.5],
                   NSLocalizedString(@"E", @"E"), [NSNumber numberWithFloat:4*22.5],
                   NSLocalizedString(@"ESE", @"ESE"), [NSNumber numberWithFloat:5*22.5],
                   NSLocalizedString(@"SE", @"SE"), [NSNumber numberWithFloat:6*22.5],
                   NSLocalizedString(@"SSE", @"SSE"), [NSNumber numberWithFloat:7*22.5],
                   NSLocalizedString(@"S", @"S"), [NSNumber numberWithFloat:8*22.5],
                   NSLocalizedString(@"SSW", @"SSW"), [NSNumber numberWithFloat:9*22.5],
                   NSLocalizedString(@"SW", @"SW"), [NSNumber numberWithFloat:10*22.5],
                   NSLocalizedString(@"WSW", @"WSW"), [NSNumber numberWithFloat:11*22.5],
                   NSLocalizedString(@"W", @"W"), [NSNumber numberWithFloat:12*22.5],
                   NSLocalizedString(@"WNW", @"WNW"), [NSNumber numberWithFloat:13*22.5],
                   NSLocalizedString(@"NW", @"NW"), [NSNumber numberWithFloat:14*22.5],
                   NSLocalizedString(@"NNW", @"NNW"), [NSNumber numberWithFloat:15*22.5],
                   nil];
        [markers retain];
        //[self setCourse:0];
}

- (void)drawRect:(CGRect)rect
{        
        int drawDegrees = 40;
        
        CGContextRef ctx = UIGraphicsGetCurrentContext();        
        CGContextSetGrayFillColor(ctx, 0.1, 1.0);
        CGContextFillRect(ctx, rect);
        
        // Border
        CGContextBeginPath(ctx);
        CGContextSetLineWidth(ctx, 2.0);
        CGContextSetRGBStrokeColor(ctx, 0.2, 0.2, 0.2, 1.0);
        CGContextAddRect(ctx, rect);
        CGContextStrokePath(ctx);
        
        // Red marker
        CGContextBeginPath(ctx);
        CGContextSetLineWidth(ctx, 1.0);
        CGContextSetRGBStrokeColor(ctx, 1.0, 0.2, 0.2, 0.8);
        CGContextAddRect(ctx, CGRectMake(rect.size.width / 2 - 3, 2, 6, rect.size.height - 4));
        CGContextStrokePath(ctx);
        
        CGContextSetRGBStrokeColor(ctx, 0.9, 0.9, 0.9, 1.0);
        CGContextSetGrayFillColor(ctx, 0.9, 1.0);
        CGContextSelectFont (ctx, "Helvetica-Bold", 12, kCGEncodingMacRoman);
        CGContextSetTextMatrix (ctx, CGAffineTransformMake(1,0,0,-1,0,rect.size.height)); 
        CGContextSetShouldSmoothFonts(ctx, YES);
        CGContextSetShouldAntialias(ctx, YES);
        CGContextTranslateCTM(ctx, rect.size.width / 2.0, COMPASS_RADIUS + rect.size.height / 2.0);
        CGContextRotateCTM(ctx, -showingCourse / 180.0 * M_PI);
        
        // Find the boundaries of the visible
        int imin = (showingCourse - drawDegrees) * 2;
        if (imin < 0)
                imin += 720;
        else if (imin >= 720)
                imin -= 720;
        int imax = (showingCourse + drawDegrees) * 2;
        if (imax < 0)
                imax += 720;
        else if (imax >= 720)
                imax -= 720;
        
        float len;
        NSString *marker;
        for (int i = 0; i < 720; i++) {
                if (imin < imax && i >= imin && i <= imax ||
                    (imin > imax && (i >= imin || i <= imax))) { 
                        // This is the visible part of the rose
                        if (i % 90 == 0) {
                                CGContextSetLineWidth(ctx, 3.0);
                                len = 8;
                        }
                        else if (i % 10 == 0) {
                                CGContextSetLineWidth(ctx, 1.0);
                                len = 6;
                        }
                        else {
                                CGContextSetLineWidth(ctx, 1.0);
                                len = 4;
                        }
                        
                        float startY = -COMPASS_RADIUS;
                        float stopY = -(COMPASS_RADIUS + len);
                        
                        if (i % 20 == 0)
                                [self drawCenteredText:[NSString stringWithFormat:@"%d", i/2] inContext:ctx atPosition:CGPointMake(0, startY + 10)];
                        
                        if (i % 5 == 0 && (marker = [markers objectForKey:[NSNumber numberWithFloat:(float)i/2.0]]))
                                [self drawCenteredText:marker inContext:ctx atPosition:CGPointMake(0, startY - 10)];
                        
                        if (i % 2 == 0) {
                                CGContextBeginPath(ctx);
                                CGContextMoveToPoint(ctx, 0, startY);
                                CGContextAddLineToPoint(ctx, 0, stopY);
                                CGContextStrokePath(ctx);
                        }
                }
                CGContextRotateCTM(ctx, 0.5 / 180.0 * M_PI);
        }        
} 

/*
 * Private methods
 */

-(void)startTimer {
        @synchronized (self) {
                if (animationTimer)
                        return;
                animationTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(updateCourse:) userInfo:nil repeats:YES];
                [[NSRunLoop currentRunLoop] addTimer:animationTimer forMode:NSDefaultRunLoopMode];
        }
}

-(void)stopTimer {
        @synchronized (self) {
                if (!animationTimer)
                        return;
                [animationTimer invalidate];
                [animationTimer release];
                animationTimer = nil;
        }
}

-(void)updateCourse:(NSTimer*)timer {
        if (course == showingCourse) {
                [timer invalidate];
                animationTimer = nil;
        } else {
                float diff = course - showingCourse;
                if (diff > 180.0)
                        diff -= 360;
                else if (diff < -180.0)
                        diff += 360;
                if (fabs(diff) < 0.15)
                        showingCourse = course;
                else
                        showingCourse += diff / 15.0;                        
                [self setNeedsDisplay];
        }
}

- (void) drawCenteredText:(NSString *)label inContext:(CGContextRef)ctx atPosition:(CGPoint)point  {
        CGPoint before = CGContextGetTextPosition(ctx);
        CGContextSetTextDrawingMode(ctx, kCGTextInvisible);
        CGContextShowText(ctx, [label cStringUsingEncoding:NSUTF8StringEncoding], [label length]);
        CGPoint after = CGContextGetTextPosition(ctx);
        float width = after.x - before.x;
        CGContextSetTextDrawingMode (ctx, kCGTextFill);
        CGContextShowTextAtPoint(ctx, point.x - width / 2.0, point.y, [label cStringUsingEncoding:NSUTF8StringEncoding], [label length]);
}

@end
