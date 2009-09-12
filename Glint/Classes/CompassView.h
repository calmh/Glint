//
//  CompassView.h
//  Glint
//
//  Created by Jakob Borg on 7/6/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CompassView : UIView {
        float course;
        float showingCourse;
        NSTimer *animationTimer;
        NSDictionary *markers;
}

@property (assign) float course;

@end
