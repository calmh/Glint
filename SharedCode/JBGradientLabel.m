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
        [self setTextColor:self.textColor];
}

- (void) setTextColor:(UIColor*)color {
        [super setTextColor:color];
        const float *c1 = CGColorGetComponents([color CGColor]);
        float divisor = 3.0f;
        float colors[] = { c1[0], c1[1], c1[2], 1.0f, c1[0]/divisor, c1[1]/divisor, c1[2]/divisor, 1.0f };
        float positions[] = { 0.4f, 1.0f };
        [self setGradientWithParts:2 andColors:colors atPositions:positions];
}

- (void)setGradientWithParts:(int)numParts andColors:(float[])colors atPositions:(float[])positions {
        if (gradient)
                CGGradientRelease(gradient);
        gradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), colors, positions, numParts);
}

- (void)drawRect:(CGRect)rect {
	CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        CGPoint textEnd;
        float pointSize = [[self font] pointSize];
        NSInteger length = [[self text] length];
        if (length <= 0)
                return;
        
        unichar chars[length];
        CGGlyph glyphs[length];
        do {
                // Get drawing font.
                
                CGFontRef font = CGFontCreateWithFontName((CFStringRef)[[self font] fontName]);
                CGContextSetFont(ctx, font);
                CGContextSetFontSize(ctx, pointSize);
                
                // Transform text characters to unicode glyphs.
                
                [[self text] getCharacters:chars range:NSMakeRange(0, length)];
                CGFontGetGlyphsForUnichars(font, chars, glyphs, length);
                
                // Measure text dimensions.
                
                CGContextSetTextDrawingMode(ctx, kCGTextInvisible); 
                CGContextSetTextPosition(ctx, 0, 0);
                CGContextShowGlyphs(ctx, glyphs, length);
                textEnd = CGContextGetTextPosition(ctx);
                pointSize *= 0.975;
        } while (textEnd.x > rect.size.width);
        
        // Calculate text drawing point.
        
        CGPoint alignment = CGPointMake(0, 0);
        CGPoint anchor = CGPointMake(textEnd.x * (-0.5), [[self font] pointSize] * (-0.33));  
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
