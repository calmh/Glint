//
//  GlintApplicationTests.h
//  Glint
//
//  Created by Jakob Borg on 9/23/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//
//  See Also: http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/135-Unit_Testing_Applications/unit_testing_applications.html

#import <SenTestingKit/SenTestingKit.h>
#import <UIKit/UIKit.h>

@interface GlintApplicationTests : SenTestCase {

}

- (void)setUp;
- (void)test_a_WalkAndPause;
- (void)test_b_Race;
- (void)test_x1_StartStopRecording;

@end
