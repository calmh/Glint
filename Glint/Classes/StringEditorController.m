//
//  StringEditorController.m
//  Glint
//
//  Created by Jakob Borg on 11/15/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "StringEditorController.h"


@implementation StringEditorController

@synthesize textField, label, delegate;

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
	self.label.textColor = [UIColor colorWithRed:0x4c / 255.0f green:0x56 / 255.0f blue:0x6c / 255.0f alpha:1.0f];
	self.label.shadowColor = [UIColor whiteColor];
	[self.textField becomeFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField*)evTextField
{
	if (delegate != nil && [delegate respondsToSelector:@selector(stringEditorController:producedValue:)])
		[delegate stringEditorController:self producedValue:textField.text];
	return YES;
}

- (void)dealloc
{
	[super dealloc];
}

@end
