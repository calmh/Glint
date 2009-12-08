//
//  StringEditorController.h
//  Glint
//
//  Created by Jakob Borg on 11/15/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol StringEditorControllerDelegate
- (void)stringEditorController:(id)controller producedValue:(NSString*)value;
@end


@interface StringEditorController : UIViewController {
	UITextField *textField;
	UILabel *label;
	NSObject<StringEditorControllerDelegate> *delegate;
}

@property (nonatomic, retain) IBOutlet UITextField *textField;
@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, assign) IBOutlet NSObject<StringEditorControllerDelegate> *delegate;

@end
