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
        
        // Border
        /*
         CGContextBeginPath(ctx);
         CGContextSetLineWidth(ctx, 2.0);
         CGContextSetRGBStrokeColor(ctx, 0.25, 0.25, 0.25, 2.0);
         CGContextAddRect(ctx, rect);
         CGContextStrokePath(ctx);        
         */
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
        
        // Verify that the touch is actually on the slider
        CGPoint inSliderButton = [touch locationInView:slider];
        if (inSliderButton.x < 0.0f || inSliderButton.x > (slider.frame.size.width * 2.0f))
                return;
        
        // Move the slider to the new position
        CGPoint touchPoint = [touch locationInView:self];
        if (touchPoint.y < 0.0f) // Above the frame
                return;
        float newx = touchPoint.x - [slider frame].size.width / 2.0f;
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
                rect.origin.x = 15.0f;
                [slider setFrame:rect];
                [UIView commitAnimations];
        }
}

@end
