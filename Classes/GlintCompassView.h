//
//  GlintCompassView.h
//  Glint
//
//  Created by Jakob Borg on 7/6/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface GlintCompassView : UIView {
        double course;
        NSDictionary *markers;
}

@property (assign) double course;

@end
