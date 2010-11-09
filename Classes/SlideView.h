//
// SlideView.h
// Glint
//
// Created by Jakob Borg on 8/9/09.
// Copyright 2009 Jakob Borg. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SlideViewDelegate
- (void)slided:(id)sender;
@end

@interface SlideMarkerView : UIView { }

@end

@interface SlideView : UIView {
        id <SlideViewDelegate> delegate;
        SlideMarkerView *marker;
}

@property (retain, nonatomic) IBOutlet id <SlideViewDelegate> delegate;

- (void)reset;
+ (void)drawRoundedRect:(CGRect)rrect inContext:(CGContextRef)context withRadius:(CGFloat)radius andGradient:(CGGradientRef)gradient;

@end

#define MARGIN 35.0f
#define SLIDERWIDTH 65.0f
