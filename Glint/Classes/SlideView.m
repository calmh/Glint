//
//  SlideView.m
//  Glint
//
//  Created by Jakob Borg on 8/9/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "SlideView.h"

@implementation SlideView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame {
        if (self = [super initWithFrame:frame]) {
                sliderPosition = MARGIN;
        }
        return self;
}

- (void)awakeFromNib {
        [super awakeFromNib];
        sliderPosition = MARGIN;
}

- (void)drawRect:(CGRect)rect {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSetGrayFillColor(ctx, 0x19/255.0f, 1.0);
        CGContextFillRect(ctx, rect);

        // Draw track
        CGContextSetGrayStrokeColor(ctx, 0.2f, 1.0f);
        CGContextSetLineWidth(ctx, 1.0f);
        float colors[] = {
                0x19/255.0f, 0x19/255.0f, 0x19/255.0f, 0.8f,
                0.25f, 0.25f, 0.25f, 0.8f
        };
        float positions[] = { 0.0f, 1.0f };
        CGGradientRef gradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), colors, positions, 2);
        CGRect outline = CGRectInset(rect, MARGIN - 3.5f, 1.5f);
        [SlideView drawRoundedRect:outline inContext:ctx withRadius:5.0f andGradient:gradient];
        CGGradientRelease(gradient);

        // Draw slider
        CGContextSetGrayStrokeColor(ctx, 0.8f, 1.0f);
        CGContextSetLineWidth(ctx, 2.0f);
        float sliderColors[] = {
                1.0f, 1.0f, 1.0f, 1.0f,
                0.8f, 0.8f, 0.8f, 0.8f,
                0.7f, 0.7f, 0.7f, 0.8f,
                0.5f, 0.5f, 0.5f, 0.5f
        };
        float sliderPositions[] = { 0.0f, 0.5f, 0.5f, 1.0f };
        gradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), sliderColors, sliderPositions, 4);
        outline = CGRectMake(sliderPosition, 5.5f, SLIDERWIDTH, rect.size.height - 11.0f);
        [SlideView drawRoundedRect:outline inContext:ctx withRadius:5.0f andGradient:gradient];
        CGGradientRelease(gradient);

        NSString *label = @">>";
        CGContextSelectFont (ctx, "Helvetica", 20, kCGEncodingMacRoman);
        CGContextSetTextMatrix (ctx, CGAffineTransformMake(1,0,0,-1,0,rect.size.height));
        CGContextSetShouldSmoothFonts(ctx, YES);
        CGContextSetShouldAntialias(ctx, YES);
        CGPoint before = CGContextGetTextPosition(ctx);
        CGContextSetTextDrawingMode(ctx, kCGTextInvisible);
        CGContextShowText(ctx, [label cStringUsingEncoding:NSUTF8StringEncoding], [label length]);
        CGPoint after = CGContextGetTextPosition(ctx);
        float width = after.x - before.x;
        CGContextSetTextDrawingMode (ctx, kCGTextFill);
        CGContextShowTextAtPoint(ctx, sliderPosition + SLIDERWIDTH / 2.0f - width / 2.0f, rect.size.height / 2.0f + 5, [label cStringUsingEncoding:NSUTF8StringEncoding], [label length]);
}

- (void)dealloc {
        [super dealloc];
}

- (void)reset {
        sliderPosition = MARGIN;
        [self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
        UITouch *touch = [touches anyObject];

        //CGPoint inSliderCoordinate = [touch locationInView:slider];
        CGPoint inFrameCoordinate = [touch locationInView:self];
        if (inFrameCoordinate.x < sliderPosition || inFrameCoordinate.x > sliderPosition + SLIDERWIDTH * 2.0f)
                // Way outside the slider
                return;
        if (inFrameCoordinate.y < -self.frame.size.height * 2.0f)
                // Way above the frame
                return;

        // Move the slider to the new position
        float newx = inFrameCoordinate.x - SLIDERWIDTH / 2.0f;
        if (newx < MARGIN)
                newx = MARGIN;
        if (newx > [self frame].size.width - SLIDERWIDTH - MARGIN)
                newx = [self frame].size.width - SLIDERWIDTH - MARGIN;
        //        CGRect rect = slider.frame;
        //rect.origin.x = newx;
        //[slider setFrame:rect];
        sliderPosition = newx;

        // Redraw
        [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
        if (sliderPosition + SLIDERWIDTH > self.frame.size.width - MARGIN - 10 /* sensitivity */) {
                [delegate slided:self];
        } else {
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration:0.2];
                sliderPosition = MARGIN;
                [UIView commitAnimations];
                [self setNeedsDisplay];
        }
}

+ (void)drawRoundedRect:(CGRect)rrect inContext:(CGContextRef)context withRadius:(CGFloat)radius andGradient:(CGGradientRef)gradient
{
	CGFloat minx = CGRectGetMinX(rrect);
	CGFloat midx = CGRectGetMidX(rrect);
	CGFloat maxx = CGRectGetMaxX(rrect);
	CGFloat miny = CGRectGetMinY(rrect);
	CGFloat midy = CGRectGetMidY(rrect);
	CGFloat maxy = CGRectGetMaxY(rrect);


        CGContextMoveToPoint(context, minx, midy);
        CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
        CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
        CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
        CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
        CGContextClosePath(context);
        CGContextDrawPath(context, kCGPathFillStroke);

        CGContextSaveGState(context);
	CGContextMoveToPoint(context, minx, midy);
	CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
	CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
	CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
	CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
	CGContextClosePath(context);
        CGContextClip(context);
        CGPoint start = CGPointMake(0, rrect.origin.y);
        CGPoint end = CGPointMake(0, rrect.origin.y + rrect.size.height);
        CGContextDrawLinearGradient(context, gradient, start, end, 0);
        CGContextRestoreGState(context);
}

@end

