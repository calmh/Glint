//
//  JBSoundEffect.m
//  GPS Logger
//
//  Created by Jakob Borg on 5/24/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "JBSoundEffect.h"

@implementation JBSoundEffect

- (id) initWithContentsOfFile:(NSString *)path
{
	self = [super init];
	if (self != nil) {
		NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
		AudioServicesCreateSystemSoundID((CFURLRef)filePath, &soundID);
	}
	return self;
}

- (void)play{
	AudioServicesPlaySystemSound(soundID);
}

@end