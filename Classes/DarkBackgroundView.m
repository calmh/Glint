//
//  DarkBackgroundView.m
//  Glint
//
//  Created by Jakob Borg on 7/19/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "DarkBackgroundView.h"

@implementation DarkBackgroundView

CGGradientRef CreateGradient(CGColorRef inColor1, CGFloat inColor1Start,
                             CGColorRef inColor2, CGFloat inColor2Start,
                             CGColorRef inColor3, CGFloat inColor3Start,
                             CGColorRef inColor4, CGFloat inColor4Start)
{
        // Setup a CFArray with our CGColorRefs
        const void *colorRefs[4] = {inColor1, inColor2, inColor3, inColor4};
        CFArrayRef colorArray = CFArrayCreate(kCFAllocatorDefault, colorRefs, 4, &kCFTypeArrayCallBacks);
        // Setup a parallel array that contains the start locations of those colors
        CGFloat locations[4] = {inColor1Start, inColor2Start, inColor3Start, inColor4Start};
        // Create the gradient
        CGGradientRef gradient = CGGradientCreateWithColors(NULL, colorArray, locations);
        // clean up the color array (the gradient will retain it if necessary)
        CFRelease(colorArray);
        return gradient;
}

- (void)drawRect:(CGRect)rect {
        /*
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSetTextMatrix (ctx, CGAffineTransformMake(1,0,0,-1,0,rect.size.height)); 

        CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
        CGFloat comps1[] = {0.05, 0.05, 0.05, 1.0};
        CGColorRef color1 = CGColorCreate(rgb, comps1);
        CGFloat comps2[] = {0.15, 0.15, 0.15, 1.0};
        CGColorRef color2 = CGColorCreate(rgb, comps2);
        CGFloat comps3[] = {0.15, 0.15, 0.15, 1.0};
        CGColorRef color3 = CGColorCreate(rgb, comps3);
        CGFloat comps4[] = {0.05, 0.05, 0.05, 1.0};
        CGColorRef color4 = CGColorCreate(rgb, comps4);
        CGColorSpaceRelease(rgb);
        
        CGGradientRef gradient = CreateGradient(color1, 0.0, color2, 0.25, color3, 0.66, color4, 1.0);
        CGContextDrawLinearGradient(ctx, gradient, CGPointMake(rect.origin.x, rect.origin.y), CGPointMake(rect.origin.x, rect.origin.y + rect.size.height), 0);
         */
}

@end
