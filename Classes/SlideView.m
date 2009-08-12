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
                0.05f, 0.05f, 0.05f, 1.0f,
                0.15f, 0.15f, 0.15f, 1.0f
        };
        float positions[] = { 0.0f, 1.0f };
        CGGradientRef gradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), colors, positions, 2);
        CGPoint start = CGPointMake(rect.origin.x, rect.origin.y);
        CGPoint end = CGPointMake(rect.origin.x, rect.size.height);
        CGContextDrawLinearGradient(ctx, gradient, start, end, 0);
        CGGradientRelease(gradient);

        // Border
        CGContextBeginPath(ctx);
        CGContextSetLineWidth(ctx, 2.0);
        CGContextSetRGBStrokeColor(ctx, 0.3, 0.3, 0.3, 2.0);
        CGContextAddRect(ctx, rect);
        CGContextStrokePath(ctx);        
}


- (void)dealloc {
    [super dealloc];
}

- (void)reset {
        CGRect rect = slider.frame;
        rect.origin.x = 5.0f;
        [slider setFrame:rect];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
        UITouch *touch = [touches anyObject];
        touchPoint2 = [touch locationInView:self];
        float buttonX = touchPoint2.x - [slider frame].size.width / 2.0f;
        if (buttonX < 5.0f)
                buttonX = 5.0f;
        if (buttonX > [self frame].size.width - [slider frame].size.width - 5.0f)
                buttonX = [self frame].size.width - [slider frame].size.width - 5.0f;
        CGRect rect = CGRectMake(buttonX, slider.frame.origin.y, slider.frame.size.width, slider.frame.size.height);
        [slider setFrame:rect];
        [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
        if (slider.frame.origin.x + slider.frame.size.width > self.frame.size.width - 10) {
                [delegate slided:self];
        } else {
        [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.2];
        CGRect rect = slider.frame;
        rect.origin.x = 5.0f;
        [slider setFrame:rect];
        [UIView commitAnimations];
        }
}

@end
