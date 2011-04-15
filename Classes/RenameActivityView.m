//
//  RenameActivityView.m
//  168 Hours
//
//  Created by Orlando O'Neill on 2/3/11.
//  Copyright 2011 Orlando O'Neill
//
//  This file is part of 168 Hours.
//
//  168 Hours is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  168 Hours is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with 168 Hours.  If not, see <http://www.gnu.org/licenses/>.
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
