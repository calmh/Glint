//
//  GlintCompassView.m
//  Glint
//
//  Created by Jakob Borg on 7/6/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "GlintCompassView.h"

@implementation GlintCompassView

@synthesize course;

- (void)dealloc {
        [markers release];
        [super dealloc];
}

-(void)setCourse:(double)newCourse {
        course = newCourse;
        [self setNeedsDisplay];
}

-(void)awakeFromNib 
{
	[super awakeFromNib];        
        
        course = 0.0;
        markers = [NSDictionary dictionaryWithObjectsAndKeys:
                   NSLocalizedString(@"N", @"N"), [NSNumber numberWithDouble:0.0],
                   NSLocalizedString(@"NNE", @"NNE"), [NSNumber numberWithDouble:22.5],
                   NSLocalizedString(@"NE", @"NE"), [NSNumber numberWithDouble:2*22.5],
                   NSLocalizedString(@"ENE", @"ENE"), [NSNumber numberWithDouble:3*22.5],
                   NSLocalizedString(@"E", @"E"), [NSNumber numberWithDouble:4*22.5],
                   NSLocalizedString(@"ESE", @"ESE"), [NSNumber numberWithDouble:5*22.5],
                   NSLocalizedString(@"SE", @"SE"), [NSNumber numberWithDouble:6*22.5],
                   NSLocalizedString(@"SSE", @"SSE"), [NSNumber numberWithDouble:7*22.5],
                   NSLocalizedString(@"S", @"S"), [NSNumber numberWithDouble:8*22.5],
                   NSLocalizedString(@"SSW", @"SSW"), [NSNumber numberWithDouble:9*22.5],
                   NSLocalizedString(@"SW", @"SW"), [NSNumber numberWithDouble:10*22.5],
                   NSLocalizedString(@"WSW", @"WSW"), [NSNumber numberWithDouble:11*22.5],
                   NSLocalizedString(@"W", @"W"), [NSNumber numberWithDouble:12*22.5],
                   NSLocalizedString(@"WNW", @"WNW"), [NSNumber numberWithDouble:13*22.5],
                   NSLocalizedString(@"NW", @"NW"), [NSNumber numberWithDouble:14*22.5],
                   NSLocalizedString(@"NNW", @"NNW"), [NSNumber numberWithDouble:15*22.5],
                   nil];
        [markers retain];
}

- (void) drawCenteredText:(NSString *)label inContext:(CGContextRef)ctx atPosition:(CGPoint)point  {
        CGPoint before = CGContextGetTextPosition(ctx);
        CGContextSetTextDrawingMode(ctx, kCGTextInvisible);
        CGContextShowText(ctx, [label cStringUsingEncoding:NSUTF8StringEncoding], [label length]);
        CGPoint after = CGContextGetTextPosition(ctx);
        double width = after.x - before.x;
        CGContextSetTextDrawingMode (ctx, kCGTextFill);
        CGContextShowTextAtPoint(ctx, point.x - width / 2.0, point.y, [label cStringUsingEncoding:NSUTF8StringEncoding], [label length]);
}

- (void)drawRect:(CGRect)rect
{        
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSetTextMatrix (ctx, CGAffineTransformMake(1,0,0,-1,0,rect.size.height)); 
        
        CGContextSetGrayFillColor(ctx, 0.1, 1.0);
        CGContextFillRect(ctx, rect);
        
        CGContextBeginPath(ctx);
        CGContextSetRGBStrokeColor(ctx, 0.9, 0.9, 0.9, 1.0);
        CGContextSetLineWidth(ctx, 2.5);
        CGContextMoveToPoint(ctx, 0.0, rect.size.height / 2.0);
        CGContextAddLineToPoint(ctx, rect.size.width, rect.size.height / 2.0);
        CGContextStrokePath(ctx);
        
        CGContextSetGrayFillColor(ctx, 0.9, 1.0);
        CGContextSelectFont (ctx, "Helvetica-Bold", 15, kCGEncodingMacRoman);
        for (NSNumber* nsposition in [markers allKeys]) {
                NSString* label = [markers objectForKey:nsposition];
                double position = [nsposition doubleValue];
                position -= course;
                if (position >= 180.0)
                        position -= 360.0;
                else if (position <= -180.0)
                        position += 360.0;
                position /= -COMPASS_WIDTH;
                position *= rect.size.width;
                position += rect.size.width / 2.0;
                
                [self drawCenteredText:label inContext:ctx atPosition:CGPointMake(position, 15.0)];
        }
        
        
        CGContextSelectFont (ctx, "Helvetica-Bold", 12, kCGEncodingMacRoman);
        for (int i = 0; i < 360; i++) {
                double position = i;
                position -= course;
                if (position >= 180.0)
                        position -= 360.0;
                else if (position <= -180.0)
                        position += 360.0;
                position /= -COMPASS_WIDTH;
                position *= rect.size.width;
                position += rect.size.width / 2.0;
                double start = 20;
                double stop = 30;
                if (i % 45 == 0) {
                        CGContextSetLineWidth(ctx, 3.0);
                        start = 18;
                        stop = 35;
                }
                else if (i % 5 == 0) {
                        CGContextSetLineWidth(ctx, 1.0);
                        stop = 33;
                }
                else
                        CGContextSetLineWidth(ctx, 1.0);
                
                if (i % 10 == 0)
                        [self drawCenteredText:[NSString stringWithFormat:@"%d", i] inContext:ctx atPosition:CGPointMake(position, 45.0)];
                
                CGContextBeginPath(ctx);
                CGContextMoveToPoint(ctx, position, start);
                CGContextAddLineToPoint(ctx, position, stop);
                CGContextStrokePath(ctx);
        }
        
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
} 

@end
