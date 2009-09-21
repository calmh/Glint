//
//  SlideView.m
//  Glint
//
//  Created by Jakob Borg on 8/9/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "SlideView.h"

@implementation SlideView

@synthesize slider, delegate;

- (id)initWithFrame:(CGRect)frame {
        if (self = [super initWithFrame:frame]) {
                // Initialization code
        }
        return self;
}


- (void)drawRect:(CGRect)rect {
        // Background
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSetGrayFillColor(ctx, 0.1, 1.0);
        float colors[] = {
                0x19/255.0f, 0x19/255.0f, 0x19/255.0f, 1.0f,
                0.25f, 0.25f, 0.25f, 1.0f
        };
        float positions[] = { 0.0f, 1.0f };
        CGGradientRef gradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), colors, positions, 2);
        CGPoint start = CGPointMake(rect.origin.x, rect.origin.y);
        CGPoint end = CGPointMake(rect.origin.x, rect.size.height);
        CGContextDrawLinearGradient(ctx, gradient, start, end, 0);
        CGGradientRelease(gradient);
}

- (void)dealloc {
        [super dealloc];
}

- (void)reset {
        CGRect rect = slider.frame;
        rect.origin.x = MARGIN;
        [slider setFrame:rect];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
        UITouch *touch = [touches anyObject];

        CGPoint inSliderCoordinate = [touch locationInView:slider];
        CGPoint inFrameCoordinate = [touch locationInView:self];
        if (inSliderCoordinate.x < 0.0f || inSliderCoordinate.x > (slider.frame.size.width * 2.0f))
                // Way outside the slider
                return;
        if (inFrameCoordinate.y < -slider.frame.size.height)
                // Way above the frame
                return;

        // Move the slider to the new position
        float newx = inFrameCoordinate.x - [slider frame].size.width / 2.0f;
        if (newx < MARGIN)
                newx = MARGIN;
        if (newx > [self frame].size.width - [slider frame].size.width - MARGIN)
                newx = [self frame].size.width - [slider frame].size.width - MARGIN;
        CGRect rect = slider.frame;
        rect.origin.x = newx;
        [slider setFrame:rect];

        // Redraw
        [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
        if (slider.frame.origin.x + slider.frame.size.width > self.frame.size.width - MARGIN - 10 /* sensitivity */) {
                [delegate slided:self];
        } else {
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration:0.2];
                CGRect rect = slider.frame;
                rect.origin.x = MARGIN;
                [slider setFrame:rect];
                [UIView commitAnimations];
        }
}

@end

