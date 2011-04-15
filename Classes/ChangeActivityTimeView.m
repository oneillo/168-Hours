//
//  ChangeActivityTimeView.m
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

#import "ChangeActivityTimeView.h"
#import "Activity.h"
#import "TimeTrackerAppDelegate.h"
//#import "Entry.h"


@implementation ChangeActivityTimeView

@synthesize selectedEntry, newEntryTime, newActivityForEntry;

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
	navButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(changeEntryTime:)];
	[[self navigationItem] setRightBarButtonItem:navButton];
	[navButton release];
	
	[self setTitle:@"Change Entry"];
	return self;
}

// Overwrite default init method
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self init];
}


#pragma mark -
#pragma mark App Lifecycle

- (void)viewWillAppear:(BOOL)animated
{
	// Set up the time options for UIPicker
	hourOptions = [[NSMutableArray alloc] init];
	minuteOptions = [[NSMutableArray alloc] init];
	[self setUpPickerOptions];
	
	// Set up the labels on the screen
	Activity *activity = [selectedEntry activity];
	[activityTitle setTitle:[activity name] forState:UIControlStateNormal];
	
	NSDateFormatter *date = [[[NSDateFormatter alloc] init] autorelease]; 
	[date setDateFormat:@"EEEE, MM/dd/YY"];
	NSString *stringDate = [date stringFromDate:[selectedEntry startDate]];
	[entryDate setText:stringDate];
	[date setTimeStyle:NSDateFormatterShortStyle];
    if ([selectedEntry endDate]) 
	{
		[entryStartTime setText:[NSString stringWithFormat:@"%@ - %@",[date stringFromDate:[selectedEntry startDate]],[date stringFromDate:[selectedEntry endDate]]]];
	}
	else 
	{
		[entryStartTime setText:[NSString stringWithFormat:@"%@...",[date stringFromDate:[selectedEntry startDate]]]];	
    }
	
	
	if ([selectedEntry endDate] == nil) 
	{
		[durationPickerView setHidden:1];
		UILabel *label;
		for (int i=0; i<3; i++) 
		{
			label = (UILabel *)[[self view] viewWithTag:1000+i];
			[label setHidden:1];
		}
	}
	else 
	{
		NSMutableArray *timeData = [self timeSpentDoingEntry:selectedEntry];
		NSNumber *hours = [timeData objectAtIndex:0];
		NSNumber *minutes = [timeData objectAtIndex:1];
		NSInteger selectedHours;
		NSInteger selectedMinutes;
	
		selectedHours = [hours intValue];
		selectedMinutes = [minutes intValue];
	
        UILabel *label = (UILabel *)[[self view] viewWithTag:1000];
        [label setHidden:0];
        label = (UILabel *)[[self view] viewWithTag:1001];
        [label setHidden:0]; 
        label = (UILabel *)[[self view] viewWithTag:1002];
        [label setHidden:0];
        
        // Find the activity to set it to
        NSUInteger activityIndex = [activityOptions indexOfObject:activity];
        
        [durationPickerView selectRow:activityIndex inComponent:0 animated:NO];
        [durationPickerView selectRow:selectedHours inComponent:1 animated:NO];
        [durationPickerView selectRow:selectedMinutes inComponent:2 animated:NO];
	}
}


#pragma mark -
#pragma mark Action Methods

- (void)cancel:(id)sender
{
	//[self setActivityName:nil];
	[self setNewEntryTime:(float)0];
	[[self navigationController] popViewControllerAnimated:YES];
}	


- (void)changeEntryTime:(id)sender
{
	NSInteger newHours;
	NSInteger newMinutes;
	NSMutableArray *timeData = [self timeSpentDoingEntry:selectedEntry];
	
    newActivityForEntry = [activityOptions objectAtIndex:[durationPickerView selectedRowInComponent:0]];
        
    newHours = [durationPickerView selectedRowInComponent:1];
    if (newHours == 168) 
    {
        newMinutes = 0;
    }
    newMinutes = [durationPickerView selectedRowInComponent:2];
    
	NSInteger currSeconds = ([[timeData objectAtIndex:0] intValue]*3600 + [[timeData objectAtIndex:1] intValue]*60);
	NSInteger newSeconds = newHours*3600 + newMinutes*60;
	
	NSTimeInterval entryTime;
	entryTime = [[selectedEntry endDate] timeIntervalSinceDate:[selectedEntry startDate]];
	
	if (newSeconds < currSeconds && newSeconds > 0) 
	{
		[self setNewEntryTime:entryTime - (float)(currSeconds - newSeconds)];
	}
	else 
	{
		[self setNewEntryTime:(float)0];
	}	
	[[self navigationController] popViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Time Methods

- (void)setUpPickerOptions
{
	NSMutableArray *timeData = [self timeSpentDoingEntry:selectedEntry];
	NSInteger hourLimit = [[timeData objectAtIndex:0] intValue];
	
	NSNumber *number = [[NSNumber alloc] init];
	for (int i=0; i <= hourLimit; i++)
	{
		number = [NSNumber numberWithInt:i];
		[hourOptions addObject:number];
	}
	
	for (int i=0; i<60; i++)
	{
		number = [NSNumber numberWithInt:i];
		[minuteOptions addObject:number];
	}
    
    // Get the available activities
    TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
    NSArray *fetchedActivities = [appDelegate allInstancesOf:@"Activity"];		
    activityOptions = [fetchedActivities mutableCopy];  
}

- (NSMutableArray *)timeSpentDoingEntry:(Entry *)entry
{
	NSTimeInterval entryTime;
	NSMutableArray *timedata = [[NSMutableArray alloc] init];
	
	entryTime = [[entry endDate] timeIntervalSinceDate:[entry startDate]];
	
	NSNumber *hours;
	NSNumber *minutes;
	
	hours = [NSNumber numberWithInt:(int)(entryTime/3600)];
	int min = (entryTime - ([hours intValue] * 3600))/60;
	//min %= 60;
	minutes = [NSNumber numberWithInt:min];
	
	//NSLog(@"Name = %@", [activity name]);
	//NSLog(@"Hours = %i", [hours intValue]);
	//NSLog(@"Minutes = %i", [minutes intValue]);
	//NSLog(@" ");
	[timedata addObject:hours];
	[timedata addObject:minutes];
	return timedata;
}


#pragma mark -
#pragma mark picker delegate

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    if (component == 0) 
    {
        return (CGFloat)134; 
    }
    else
    {
        if (component == 1) 
        {
            return (CGFloat)85;
        }
        return (CGFloat)75;
    }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 3;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (component == 0) 
    {
        return (NSInteger)[activityOptions count];
    }
    else
    {
        if (component == 1) 
        {
            return (NSInteger)[hourOptions count];
        }
        else 
        {
            return (NSInteger)[minuteOptions count];
        }
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component == 0) 
    {
        return [NSString stringWithFormat:@"%@",[[activityOptions objectAtIndex:row] name]];
    }
    else
    {
        if (component == 1) 
        {
            //return [[hourOptions objectAtIndex:row] stringValue];
            return [NSString stringWithFormat:@"%@",[[hourOptions objectAtIndex:row] stringValue]];
        }
        else 
        {
            //return [[minuteOptions objectAtIndex:row] stringValue];
            return [NSString stringWithFormat:@"%@",[[minuteOptions objectAtIndex:row] stringValue]];
        } 
    }
}


#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload 
{
	// View stuff
	[durationPickerView release];
	[activityTitle release];
	[entryDate release];
	[entryStartTime release];
	durationPickerView = nil;
	activityTitle = nil;
	entryDate = nil;
	entryStartTime = nil;
	
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	//[selectedEntry release];
	
	// View stuff
	[durationPickerView release];
	[activityTitle release];
	[entryDate release];
	[entryStartTime release];
	
    [super dealloc];
}


@end