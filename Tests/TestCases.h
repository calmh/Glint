//
//  TestCases.h
//  Glint
//
//  Created by Jakob Borg on 7/27/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//
//  See Also: http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/135-Unit_Testing_Applications/unit_testing_applications.html

#import <SenTestingKit/SenTestingKit.h>
#import <UIKit/UIKit.h>
#import "JBLocationMath.h"
#import "JBGPXReader.h"

@interface TestCases : SenTestCase {

}

- (void)testLocationMath;
- (void)testGPXReader;
- (void)testInterpolation;

@end
