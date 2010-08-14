//
// JBSoundEffect.h
// Glint
//
// Created by Jakob Borg on 5/24/09.
// Copyright 2009 Jakob Borg. All rights reserved.
//

#import <AudioToolbox/AudioServices.h>
#import <UIKit/UIKit.h>

@interface SoundEffect : NSObject {
        SystemSoundID soundID;
}

- (id)initWithContentsOfFile:(NSString*)path;
- (void)play;
@end
