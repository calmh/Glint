//
//  JBGradientLabel.m
//  Glint
//
//  Created by Jakob Borg on 7/31/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "JBGradientLabel.h"

// Missing in standard headers.
extern void CGFontGetGlyphsForUnichars(CGFontRef, const UniChar[], const CGGlyph[], size_t);

@implementation JBGradientLabel

-(void)awakeFromNib 
{
	[super awakeFromNib];
        gradient = nil;
        float colors[] = { 0.75f, 0.9f, 1.0f, 1.0f, 0.35f, 0.45f, 0.65f, 1.0f };
        float positions[] = { 0.2f, 1.0f };
        [self setGradientWithParts:2 andColors:colors atPositions:positions];
}

- (void)setGradientWithParts:(int)numParts andColors:(float[])colors atPositions:(float[])positions {
        if (gradient)
                CGGradientRelease(gradient);
        gradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), colors, positions, numParts);
}

- (void)drawRect:(CGRect)rect {
	CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        // Get drawing font.
        
        CGFontRef font = CGFontCreateWithFontName((CFStringRef)[[self font] fontName]);
        CGContextSetFont(ctx, font);
        CGContextSetFontSize(ctx, [[self font] pointSize]);
        
        // Transform text characters to unicode glyphs.
        
        NSInteger length = [[self text] length];
        unichar chars[length];
        CGGlyph glyphs[length];
        [[self text] getCharacters:chars range:NSMakeRange(0, length)];
        CGFontGetGlyphsForUnichars(font, chars, glyphs, length);
        
        // Measure text dimensions.
        
        CGContextSetTextDrawingMode(ctx, kCGTextInvisible); 
        CGContextSetTextPosition(ctx, 0, 0);
        CGContextShowGlyphs(ctx, glyphs, length);
        CGPoint textEnd = CGContextGetTextPosition(ctx);
        
        // Calculate text drawing point.
        
        CGPoint alignment = CGPointMake(0, 0);
        CGPoint anchor = CGPointMake(textEnd.x * (-0.5), [[self font] pointSize] * (-0.25));  
        CGPoint p = CGPointApplyAffineTransform(anchor, CGAffineTransformMake(1, 0, 0, -1, 0, 1));
        
        if ([self textAlignment] == UITextAlignmentCenter) {
                alignment.x = [self bounds].size.width * 0.5 + p.x;
        }
        else if ([self textAlignment] == UITextAlignmentLeft) {
                alignment.x = 0;
        }
        else {
                alignment.x = [self bounds].size.width - textEnd.x;
        }
        
        alignment.y = [self bounds].size.height * 0.5 + p.y;
        
        // Flip back mirrored text.
        
        CGContextSetTextMatrix(ctx, CGAffineTransformMakeScale(1, -1));
        
        // Draw shadow.
        
        /*
        CGContextSaveGState(ctx);
        CGContextSetTextDrawingMode(ctx, kCGTextFill);
        CGContextSetFillColorWithColor(ctx, [[self shadowColor] CGColor]);
        CGContextSetShadowWithColor(ctx, [self shadowOffset], 0, [[self shadowColor] CGColor]);
        CGContextShowGlyphsAtPoint(ctx, alignment.x, alignment.y, glyphs, length);
        CGContextRestoreGState(ctx);
        */
        
        // Draw text clipping path.
        
        CGContextSetTextDrawingMode(ctx, kCGTextClip);
        CGContextShowGlyphsAtPoint(ctx, alignment.x, alignment.y, glyphs, length);
        
        // Restore text mirroring.
        
        CGContextSetTextMatrix(ctx, CGAffineTransformIdentity);
        
        // Fill text clipping path with gradient.
        
        CGPoint start = CGPointMake(rect.origin.x, rect.origin.y);
        CGPoint end = CGPointMake(rect.origin.x, rect.size.height);
        CGContextDrawLinearGradient(ctx, gradient, start, end, 0);
        
        // Cut outside clipping path.
        
        CGContextClip(ctx);
}

@end
