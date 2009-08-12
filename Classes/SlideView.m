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
        CGContextFillRect(ctx, rect);
        
/*        CGContextBeginPath(ctx);
        CGContextSetLineWidth(ctx, 2.0);
        CGContextSetRGBStrokeColor(ctx, 0.2, 0.2, 0.2, 1.0);
        CGContextMoveToPoint(ctx, touchPoint1.x, touchPoint1.y);
        CGContextAddLineToPoint(ctx, touchPoint2.x, touchPoint2.y);
        CGContextStrokePath(ctx);*/
}


- (void)dealloc {
    [super dealloc];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
        
        UITouch *touch = [touches anyObject];
        touchPoint2 = [touch locationInView:self];
        float buttonX = touchPoint2.x - [slider frame].size.width / 2.0f;
        if (buttonX < 2.0f)
                buttonX = 2.0f;
        if (buttonX > [self frame].size.width - [slider frame].size.width - 2.0f)
                buttonX = [self frame].size.width - [slider frame].size.width - 2.0f;
        CGRect rect = CGRectMake(buttonX, 2.0f, [slider frame].size.width, [slider frame].size.height);
        [slider setFrame:rect];
        [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
        if (slider.frame.origin.x + slider.frame.size.width > self.frame.size.width - 10)
                [delegate slided:self];
        CGRect rect = slider.frame;
        rect.origin.x = 0.0f;
        [slider setFrame:rect];
}

@end
