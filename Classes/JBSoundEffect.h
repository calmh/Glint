//
//  JBSoundEffect.h
//  GPS Logger
//
//  Created by Jakob Borg on 5/24/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>

@interface JBSoundEffect : NSObject {
	SystemSoundID soundID;
}

- (id)initWithContentsOfFile:(NSString *)path;
- (void)play;
@end