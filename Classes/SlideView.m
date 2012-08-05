//
// SlideView.m
// Glint
//
// Created by Jakob Borg on 8/9/09.
// Copyright 2009 Jakob Borg. All rights reserved.
//

#import "CMGlyphDrawing.h"
#import "SlideView.h"

@implementation SlideMarkerView

- (id)initWithFrame:(CGRect)frame
{
        if (self = [super initWithFrame:frame])
                self.backgroundColor = [UIColor clearColor];
        return self;
}

- (void)drawRect:(CGRect)rect
{
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSetGrayStrokeColor(ctx, 0.8f, 1.0f);
        CGContextSetLineWidth(ctx, 2.0f);
        float sliderColors[] = {
                1.0f, 1.0f, 1.0f, 1.0f,
                0.8f, 0.8f, 0.8f, 0.8f,
                0.7f, 0.7f, 0.7f, 0.8f,
                0.5f, 0.5f, 0.5f, 0.5f
        };
        float sliderPositions[] = { 0.0f, 0.5f, 0.5f, 1.0f };
        CGGradientRef gradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), sliderColors, sliderPositions, 4);
        CGRect outline = CGRectInset(rect, 1.0f, 1.0f);
        [SlideView drawRoundedRect:outline inContext:ctx withRadius:5.0f andGradient:gradient];
        CGGradientRelease(gradient);

        NSString *label = @"\u2192"; // →
        CGContextSetTextMatrix(ctx, CGAffineTransformMake(1, 0, 0, -1.4, 0, rect.size.height));
        int length = [label length];
        unichar chars[length];
        CGGlyph glyphs[length];
        [label getCharacters:chars range:NSMakeRange(0, length)];
        CGFontRef font = CGFontCreateWithFontName((CFStringRef) @"Arial");
        CGContextSetFont(ctx, font);
        CGContextSetFontSize(ctx, 40.0f);
        CGContextSetGrayFillColor(ctx, 1.0f, 1.0f);
        CMFontGetGlyphsForUnichars(font, chars, glyphs, length);
        CGContextShowGlyphsAtPoint(ctx, rect.size.width / 2.0f - 19.0f, rect.size.height / 2.0f + 14.0f, glyphs, length);
}

@end

@implementation SlideView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
        if (self = [super initWithFrame:frame]) {
                marker = [[SlideMarkerView alloc] initWithFrame:CGRectMake(MARGIN, 5.0f, SLIDERWIDTH, self.frame.size.height - 10.0f)];
                [self addSubview:marker];
        }
        return self;
}

- (void)awakeFromNib
{
        [super awakeFromNib];
        marker = [[SlideMarkerView alloc] initWithFrame:CGRectMake(MARGIN, 5.0f, SLIDERWIDTH, self.frame.size.height - 10.0f)];
        [self addSubview:marker];
}

- (void)drawRect:(CGRect)rect
{
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSetGrayFillColor(ctx, 0x19 / 255.0f, 1.0);
        CGContextFillRect(ctx, rect);

        // Draw track
        CGContextSetGrayStrokeColor(ctx, 0.2f, 1.0f);
        CGContextSetLineWidth(ctx, 1.0f);
        float colors[] = {
                0x19 / 255.0f, 0x19 / 255.0f, 0x19 / 255.0f, 0.8f,
                0.25f, 0.25f, 0.25f, 0.8f
        };
        float positions[] = { 0.0f, 1.0f };
        CGGradientRef gradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), colors, positions, 2);
        CGRect outline = CGRectInset(rect, MARGIN - 3.5f, 1.5f);
        [SlideView drawRoundedRect:outline inContext:ctx withRadius:5.0f andGradient:gradient];
        CGGradientRelease(gradient);
}

- (void)dealloc
{
        [super dealloc];
}

- (void)reset
{
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.2f];
        CGRect rect = marker.frame;
        rect.origin.x = MARGIN;
        marker.frame = rect;
        [UIView commitAnimations];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
        UITouch *touch = [touches anyObject];

        CGPoint inFrameCoordinate = [touch locationInView:self];
        if (inFrameCoordinate.x < marker.frame.origin.x || inFrameCoordinate.x > marker.frame.origin.x + SLIDERWIDTH * 2.5f)
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

        CGRect rect = marker.frame;
        rect.origin.x = newx;
        marker.frame = rect;
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
        if (marker.frame.origin.x + SLIDERWIDTH > self.frame.size.width - MARGIN - 10 /* sensitivity */)
                [delegate slided:self];
        else
                [self reset];
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
