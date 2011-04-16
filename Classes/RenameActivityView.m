//
//  RenameActivityView.m
//  168 Hours
//
//  Created by Orlando O'Neill on 2/3/11.
//  Copyright 2011 Orlando O'Neill
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RenameActivityView.h"


@implementation RenameActivityView

// Create the getter/setter method for this variable
// This will allow ActivityViewController to read the value entered
@synthesize activityName;

#pragma mark -
#pragma mark Init Methods

// Declare custom init method
- (id)init
{
	[super initWithNibName:nil bundle:nil];
	
	// Set the navbar's left item to be the cancel button
	UIBarButtonItem *navButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
	[[self navigationItem] setLeftBarButtonItem:navButton];
	[navButton release];
	
	// Set the navbar's right item to be the done button
	navButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(renameActivity:)];
	[[self navigationItem] setRightBarButtonItem:navButton];
	[navButton release];
	
	[self setTitle:@"Rename Activity"];
	
	return self;
}


// Overwrite default init method
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self init];
}


#pragma mark -
#pragma mark Action Methods

- (void)cancel:(id)sender
{
	[self setActivityName:nil];
	//[self setGoalHours:nil];
	[[self navigationController] popViewControllerAnimated:YES];
}	


- (void)renameActivity:(id)sender
{
	// Trim the whitespace from both ends of the input
	[self setActivityName:[[textField text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
	
	//[self setGoalHours:[NSNumber numberWithInt:[[hoursField text] intValue]]];
	[[self navigationController] popViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Manage App Life Cycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	//[textField setClearsOnBeginEditing:YES];
	// Make the keyboard come up anytime the view appears on screen
	[textField becomeFirstResponder];
}

- (void)viewDidUnload 
{
	[textField release];
	textField = nil;
	
    [super viewDidUnload];
	// Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	// Set the text field's default text to be the current activity name
	[textField setText:activityName];
}


#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)dealloc {
    
	[textField release];
	//[activityName release];
	[super dealloc];
}


@end
