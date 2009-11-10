//
//  JBGradientLabel.h
//  Glint
//
//  Created by Jakob Borg on 7/31/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GradientLabel : UILabel {
	CGGradientRef gradient;
	UIColor *oldColor;
}

- (void)setGradientWithParts:(int)numParts andColors:(float[])colors atPositions:(float[])positions;

@end
