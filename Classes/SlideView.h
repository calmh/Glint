//
//  SlideView.h
//  Glint
//
//  Created by Jakob Borg on 8/9/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SlideView : UIView {
        CGPoint touchPoint2;
        UIButton *slider;
}

@property (retain, nonatomic) IBOutlet UIButton *slider;

@end
