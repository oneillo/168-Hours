//
//  ActivityViewController.m
//  168 Hours
//
//  Created by Orlando O'Neill on 1/5/11.
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

#import "TimeTrackerAppDelegate.h"
#import "ActivityViewController.h"
#import "AddActivityViewController.h"
#import "ActivityDetailViewController.h"
#import "Activity.h"
#import "General.h"
#import	"Entry.h"
#import <MessageUI/MFMailComposeViewController.h>


static ActivityViewController *sharedInstance;

@implementation ActivityViewController

// Create the getter/setter methods for these variables
@synthesize activities, activityCell, entries, allEntries, sharedTableView, togglePeriod, timer, logFileName;


#pragma mark -
#pragma mark Initializtion Methods

- (id)init
{
	[super initWithNibName:nil bundle:nil];
    
    if (sharedInstance) 
	{
		NSLog(@"Error: You are creating a second ActivityViewController");
	}
	
	// Initialize some of the variables
    sharedInstance = self;
    [self setSharedTableView:(UITableView *)[[self view] viewWithTag:1982]];
    
    // Initially set the period to this week and the button to say it is set to this
    selectedDisplayPeriod = 2;
    [togglePeriod setTitle:@"This Week"];
    firstTimeRun = 0;
    logEmailNotSent = 0;
    logFileName = [[NSString alloc] init];
    
	TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
	
    // Uncomment next line to clear all items from persistent store
    // Only used in development/testing
	//[appDelegate deleteAllObjects:@"Activity"];
	
    // Delete the General DB object
    // This object holds just 1 value: activityRunning, which is 1 if there is an activity running
    //[appDelegate deleteAllObjects:@"General"];
	
    // Get the activities from the persistent store and populate activities
    NSArray *fetchedActivities = [appDelegate allInstancesOf:@"Activity"];		
	activities = [fetchedActivities mutableCopy];
    
    // Check if there are no activities, meaning this is the first time the app has been launched
	if([activities count] == 0)
	{
		// NSLog(@"activities is empty. First time this has been run");
		// Create the 2 base activities: Sleep and Misc
		[self createActivityObject:@"Misc"];
		[self createActivityObject:@"Sleep" withCurrentHours:[NSNumber numberWithInt:0] withGoalHours:[NSNumber numberWithInt:49]];
        
        // Set the variable so the Welcome message pops up
        firstTimeRun = 1;
	}
	
	// Check if the General settings entity exists...if not, then create it
	NSArray	*settings = [appDelegate allInstancesOf:@"General"];
	NSMutableArray *genSettings = [settings mutableCopy];
	
	if ([genSettings count] == 0) 
	{
		//NSLog(@"Creating object to hold general app settings and info");
		// Create the object
        // This core data object only stores 1 variable right now related to if an activity is running or not
        // It could be expanded with other general variables
		[self createSettingsObject:[NSNumber numberWithInt:0]];
	}
		
	// Pull all of the entries from core data
	entries = [[NSMutableDictionary alloc] init];
	
    // Update the entries dictionary with the latest. Complete refresh from core data
    [self updateEntries];
    
    // Delete any entries that are more than 4 weeks old
    // This uses an the array of entries populated by the last call
	[self deleteOldEntries];
    
    // Update the entries dictionary with the latest. Complete refresh from core data
    // From a performance standpoint, this could be improved by only calling this if any entries are deleted by the last line
	[self updateEntries];
	
	// Set the navigation items in the top NavBar
	UIBarButtonItem *addActivityButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addActivity:)];
	[[self navigationItem] setLeftBarButtonItem:addActivityButton];
	[addActivityButton release];
	
    // Set the timer to autoupdate the screen every minute if an activity is running
    timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(updateRunningScreen) userInfo:nil repeats:YES];
	
	return self;
}

// Overwrite default init method
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self init];
}

#pragma mark -
#pragma mark Settings Actions

// Creates and initializes the General Settings database object
- (void)createSettingsObject:(NSNumber *)activityEnabled
{
	// Add the settings into the persistent store
	TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
	NSManagedObjectContext *context = [appDelegate managedObjectContext];
	
	General *settings = [NSEntityDescription insertNewObjectForEntityForName:@"General" inManagedObjectContext:context];
	[settings setActivityEnabled:activityEnabled];
	[appDelegate saveContext];
}


#pragma mark -
#pragma mark Activity Actions

// This method is called whenever the user taps the Add activity button in the top navigation bar
- (void)addActivity:(id)sender
{
	// Initialized the controller and push it onto the screen
    addActivityViewController = [[AddActivityViewController alloc] init];
	[[self navigationController] pushViewController:addActivityViewController animated:YES];
}

// This method is called to create a new activity with initialized values
// Originally, I was going to let the user set a goal for the # of hours to spend on each activity
// but abandoned the idea
- (void)createActivityObject:(NSString *)name withCurrentHours:(NSNumber *)currHours withGoalHours:(NSNumber *)goalHours 
{
	// Don't wan't to duplicate an activity of course, so check if there is already one by this name
    if(![self checkIfActivityExists:name])
	{
		// Add an activity into the persistent store
		TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
		NSManagedObjectContext *context = [appDelegate managedObjectContext];
	
		Activity *newActivity = [NSEntityDescription insertNewObjectForEntityForName:@"Activity" inManagedObjectContext:context];
		[newActivity setName:name];
		[newActivity setCreateDate:[NSDate date]];
		[newActivity setCurrentHours:currHours];
		[newActivity setGoalHours:goalHours];
        // Save everything to core data database
        [appDelegate saveContext];
	
		// Now add the new activity into the activities array to show in the table view
		[activities insertObject:newActivity atIndex:0];
        
        // Now update the Order value for all of the activities
        [self updateActivityOrder];
        
        // Scroll to the new activity at the top of the table
        NSIndexPath *newItemIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [[self sharedTableView] scrollToRowAtIndexPath:newItemIndexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        [[self sharedTableView] reloadData];
	}
}

// A shorter version of the method in case you don't want to set any initial values
- (void)createActivityObject:(NSString *)name
{
	[self createActivityObject:name withCurrentHours:[NSNumber numberWithInt:0] withGoalHours:[NSNumber numberWithInt:0]];
}

// Called whenever the order of the activities changes to update the activities' order variable with the new positions
- (void)updateActivityOrder
{
    // Get a reference to the main app instance
    // Need this to call the saveContext funcction
    TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
    
    // Go through each Activity in the activities array and update it
    for(int i = 0; i < [activities count]; i++)
    {
        Activity *curAct = [activities objectAtIndex:i];
        [curAct setOrder:[NSNumber numberWithInt:i]];
        [appDelegate saveContext];
    }
}

// Self explanatory
- (bool)checkIfActivityExists:(NSString *)name
{
	for (Activity *activ in activities) 
	{
		// Convert the 2 strings into lowercase to ignore case during the comparison
		// e.g. Run = rUn = RUN
		if ([[[activ name] lowercaseString] isEqualToString:[name lowercaseString]]) 
		{
			return 1;
		}
	}
	return 0;
};

// This is called whenever an activity is tapped in the main screen to either
// start or stop it
- (void)changeActivityState:(Activity *)selectedActivity
{
	// Will need appDelegate to save the context
	TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
	
	// Check if an activity is currently running. If so, then we'll stop it
	// Otherwise we'll start it
	NSArray	*settings = [appDelegate allInstancesOf:@"General"];
	General *genSettings = [settings objectAtIndex:0];
	
    // Goes into this first block if there is a running activity
	if ([[genSettings activityEnabled] intValue]) 
	{
		// First we'll check if the activity that was selected is the one that is currently active
        // If so, then we'll just stop it
        if ([[selectedActivity active] intValue]) 
        {
            [genSettings setActivityEnabled:[NSNumber numberWithInt:0]];
            [selectedActivity setActive:[NSNumber numberWithInt:0]];
            [self setEntryTime:selectedActivity];
            
            // Disable the timer when there are no active activities
            // The main window only updates in real time for running stuff
            [timer invalidate];
            timer = nil;
        }
        else
        {
            // If the activity that is being started is not the active one
            // Then we need to find the active one, stop it, and then start the new one
            for (Activity *act in activities) 
            {
                if ([[act active] intValue]) 
                {
                    // This is the active activity...so let's stop it
                    [act setActive:[NSNumber numberWithInt:0]];
                    [self setEntryTime:act]; 
                }
                //else
                //{
                //    NSLog(@"Hey! We were expecting to find an active activity, but didn't. What gives?");
                //}
            }
            
            // Now we need to start the new activity
            [selectedActivity setActive:[NSNumber numberWithInt:1]];
            [self createEntry:selectedActivity];
            [self setEntryTime:selectedActivity];
            
            // And reset the timer to coincide with this activity's start time
            [timer invalidate];
            timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(updateRunningScreen) userInfo:nil repeats:YES];
        }
	}
	else 
	{
		// There is no running activity, so just start this one
        [genSettings setActivityEnabled:[NSNumber numberWithInt:1]];
		[selectedActivity setActive:[NSNumber numberWithInt:1]];
		[self createEntry:selectedActivity];
		[self setEntryTime:selectedActivity];
		//NSLog(@"Time to start the activity");
		//NSLog(@"Sender Row = %d", [indexPath row]);
		//NSLog(@"Activity Name = %@", [selectedActivity name]);
        
        // Set the timer to begin autoupdating the screen if necessary
        if (timer != nil)
            [timer invalidate];
        timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(updateRunningScreen) userInfo:nil repeats:YES];
	}
	
    // Save the core data changes
	[appDelegate saveContext];
    
    // Reload the table to update the cell/row for the running activity
	[[self sharedTableView] reloadData];
}

- (IBAction)showActivityDetail:(id)sender event:(id)event
{
    ActivityDetailViewController *activityDetailView = [[ActivityDetailViewController alloc] init];
    
    // Get the information from the sender to identify the activity
	NSSet *touches = [event allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPos = [touch locationInView:[self sharedTableView]];
	NSIndexPath *indexPath = [[self sharedTableView] indexPathForRowAtPoint:currentTouchPos];
	Activity *selectedActivity = [activities objectAtIndex:[indexPath row]];
    NSMutableArray *entryList = [entries objectForKey:[selectedActivity name]];
	
	if ([[selectedActivity name] isEqualToString:@"Misc"]) 
	{
        [activityDetailView setEntries:allEntries];
	}
	else 
	{
		[activityDetailView setEntries:entryList];
	}
	[activityDetailView setActivity:selectedActivity];
	[[self navigationController] pushViewController:activityDetailView animated:YES];
	[activityDetailView release];
}

// This function is called every minute when an activity is running
// to update the screen with the latest time
- (void)updateRunningScreen
{
    // Check if there is a running activity
    // If not, then we'll disable this
    TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
    NSArray	*settings = [appDelegate allInstancesOf:@"General"];
    General *genSettings = [settings objectAtIndex:0];
    if ([[genSettings activityEnabled] intValue] == 1) 
    {
        //NSLog(@"Updating running screen");
        [[self sharedTableView] reloadData];
    }
    else
    {
        [timer invalidate];
        timer = nil;
    }
}

#pragma mark -
#pragma mark Logfile Actions

- (IBAction)exportLog:(id)sender
{
    // Grab the path to the app's Documents folder 
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; 
    
    // Create the full path to the log file
    // Will use the current date in the file name
    NSDate *today = [[NSDate alloc] init];
    NSDateFormatter *date = [[[NSDateFormatter alloc] init] autorelease]; 
	[date setDateFormat:@"YYYYMMdd"];
	NSString *stringDate = [date stringFromDate:today];
    [self setLogFileName:[NSString stringWithFormat:@"%@_168Hours_log.csv", stringDate]];
    NSString *pathToLogFile = [documentsDirectory stringByAppendingPathComponent:logFileName];
    
    //NSLog(@"Path to file = %@", pathToFile);
    // String to write
    NSString *stringToWrite = @"Summary - Hours spent on activities \n";
    int firsttime = 1;
    
    for (Activity *selectedActivity in activities) 
    {
        NSMutableArray *timeData = [self timeSpentDoingActivityForLog:[selectedActivity name]];
        // If this is the first time we've run this
        // Then pull the date ranges to put into the log file
        if (firsttime) 
        {
            stringToWrite = [stringToWrite stringByAppendingString:[NSString stringWithFormat:@"Activity,%@,%@,%@,%@\n",[timeData objectAtIndex:7],[timeData objectAtIndex:6],[timeData objectAtIndex:5],[timeData objectAtIndex:4]]];
            firsttime=0;
        }
        
        stringToWrite = [stringToWrite stringByAppendingString:[NSString stringWithFormat:@"%@,%@,%@,%@,%@\n",[selectedActivity name],[timeData objectAtIndex:3],[timeData objectAtIndex:2],[timeData objectAtIndex:1],[timeData objectAtIndex:0]]];
    }
    
    // String to write
    stringToWrite = [stringToWrite stringByAppendingString:@"\n\nIndividual Entries\n"];
    stringToWrite = [stringToWrite stringByAppendingString:@"Activity,Date,Start,End,Time(Hours)\n"];
    
    // Cycle through the entries and append their contents to the string
    for(Entry *currentEntry in allEntries) 
    {
        NSString *activityName = [[currentEntry activity] name];
        
        [date setDateFormat:@"MM/dd/YY"];
        NSString *entryDate = [date stringFromDate:[currentEntry startDate]];
         
        [date setTimeStyle:NSDateFormatterShortStyle];
        NSString *startTime = [date stringFromDate:[currentEntry startDate]];
        
        NSString *endTime;
        if ([currentEntry endDate]) 
        {
            endTime=[date stringFromDate:[currentEntry endDate]];
        }
        else
        {
            endTime=[date stringFromDate:today];
        }
        
        // Now calculate the entry time
        NSTimeInterval entryTime;        
        if ([currentEntry endDate]) 
        {
            entryTime = [[currentEntry endDate] timeIntervalSinceDate:[currentEntry startDate]];
        }
        else
        {
            entryTime = [today timeIntervalSinceDate:[currentEntry startDate]];
        }
        
        //int hours = (int)((entryTime+30)/3600);
        float hours = (entryTime/3600);
        NSString *time = [NSString stringWithFormat:@"%f",hours];
        
        stringToWrite = [stringToWrite stringByAppendingString:[NSString stringWithFormat:@"%@,%@,%@,%@,%@\n",activityName, entryDate, startTime, endTime, time]];
    }
    //NSLog(@"String to write = %@", stringToWrite);
    
    // Start writing the data to the log file
    NSError *error;
    BOOL ok = [stringToWrite writeToFile:pathToLogFile atomically:YES encoding:NSUnicodeStringEncoding error:&error];
    
    // Check if the log file was successfully written
    if (!ok) 
    {
        // An error occurred while trying to save the log file, so ask the user to try again
        // Ideally, should probably have a counter to track errors and eventually just have the user
        // contact me or something
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" 
														message:@"Bummer! The log was not saved. \n\nPlease try to save it again."
													   delegate:nil 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles: nil];
		[alert show];
		[alert release];
    }
    else
    {
        Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
        if ([MFMailComposeViewController canSendMail] && mailClass != nil) 
        {            
            
            UIAlertView *alert = [[UIAlertView alloc] init];
            [alert setTitle:@"Log saved!"];
            [alert setDelegate:self];
            [alert setMessage:@"Send it in an email?"];
            [alert addButtonWithTitle:@"YES"];
            [alert addButtonWithTitle:@"NO"];
            [alert show];
            [alert release];
        }
        else
        {    
            // If the device can't send mail then tell the user how to download the log file via iTunes
            // This could happen if they haven't set up their default email address yet for example
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log saved!" 
                                                            message:@"Connect to iTunes to get the log via the device's Apps window."
                                                           delegate:nil 
                                                  cancelButtonTitle:@"OK" 
                                                  otherButtonTitles: nil];
            [alert show];
            [alert release];
        }
    }
}

// This will configure an email message with the log file attached
- (void)sendLogViaEmail
{
    // First get the path to the file attachment
    // Grab the path to the app's Documents folder 
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; 
    
    // Create the full path to the log file
    NSString *pathToLogFile = [documentsDirectory stringByAppendingPathComponent:logFileName];
    
    // Now start configuring the email message
    MFMailComposeViewController *mailComposeView = [[MFMailComposeViewController alloc] init];
    [mailComposeView setMailComposeDelegate:self];
    [mailComposeView setSubject:@"168 Hours Log"];
    NSData *logFile = [NSData dataWithContentsOfFile:pathToLogFile];
    [mailComposeView addAttachmentData:logFile mimeType:@"text/csv" fileName:logFileName];
    
    // Present the email composer view to the user
    [self presentModalViewController:mailComposeView animated:YES];
    [mailComposeView release];
}


#pragma mark -
#pragma mark Entry Actions

// Update the entries dictionary with the latest. Complete refresh from core data
- (void)updateEntries
{
	TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
	NSArray *allTheEntries = [appDelegate allInstancesOf:@"Entry"];
	allEntries = [allTheEntries mutableCopy];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    // Go through and delete any Misc entries that are present
    for (Entry *entryToDelete in allTheEntries) 
    {
        if ([[[entryToDelete activity] name] isEqualToString:@"Misc"]) 
        {
            [allEntries removeObject:entryToDelete];
            // Remove the object from the persistent store
            [context deleteObject:entryToDelete];
        }
    }
    [appDelegate saveContext];
	
	for (Activity *activ in activities)
	{
		// Pull all entries for each activity into an array
		NSMutableArray *entryList = [[NSMutableArray alloc] init];
		for (Entry *ent in allEntries) 
		{
			if ([ent activity] == activ) 
			{
				[entryList addObject:ent];
			}
		}
		
		// Then save the array of activity entries into the dictionary
		[entries setObject:entryList forKey:[activ name]];
		[entryList release];
	}
}

- (void)createEntry:(Activity *)activity 
{
	// Add an entry into the persistent store
	TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
	NSManagedObjectContext *context = [appDelegate managedObjectContext];
	
	Entry *newEntry = [NSEntityDescription insertNewObjectForEntityForName:@"Entry" inManagedObjectContext:context];
	[newEntry setActivity:activity];
	[appDelegate saveContext];
	
	// Add the new entry into the entries dictionary
	NSMutableArray *entryList = [entries objectForKey:[activity name]];
	if (entryList == nil) 
	{
		entryList = [[NSMutableArray alloc] init];
	}
	[entryList insertObject:newEntry atIndex:0];
	//[entries removeObjectForKey:[activity name]];
	[entries setObject:entryList forKey:[activity name]];
}

- (void)setEntryTime:(Activity *)activity
{
	TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
	NSMutableArray *activityEntries = [entries objectForKey:[activity name]];
	
    //Entry *targetEntry = [activityEntries objectAtIndex:0];
    Entry *targetEntry;
    
    for (Entry *thisEntry in activityEntries) 
    {
        if (![thisEntry endDate]) 
        {
            targetEntry = thisEntry;
            break;
        }
    }
    
	NSDate *currentDate = [NSDate date];
	if ([targetEntry startDate]) 
	{
		[targetEntry setEndDate:currentDate];
	}
	else 
	{
		[targetEntry setStartDate:currentDate];
	}
	[appDelegate saveContext]; 
}

- (void)deleteOldEntries
{
	TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
	NSCalendar *curCalendar = [NSCalendar currentCalendar];
	NSDate *today = [[NSDate alloc] init]; 
	NSDate *beginningOfWeekOne = nil; 
	BOOL ok = [curCalendar rangeOfUnit:NSWeekCalendarUnit startDate:&beginningOfWeekOne interval:NULL forDate:today];
	if (!ok) 
	{
		NSLog(@"Some kind of error in deleteOldEntries");
	}
	
	// Now calculate the beginning of the past weeks 
	NSTimeInterval secondsPerWeek = 7 * 24 * 60 * 60;
	NSDate *beginningOfWeekFour = [beginningOfWeekOne dateByAddingTimeInterval:-3*secondsPerWeek];	
	
	for (Entry *ent in allEntries) 
	{
		//NSLog(@"Checking entry");
		if ([beginningOfWeekFour compare:[ent endDate]] == NSOrderedDescending)
		{
			//NSLog(@"Deleting entry");
			// Delete the object from the main store if it finished more than 4 weeks ago
			NSManagedObjectContext *context = [appDelegate managedObjectContext];
			[context deleteObject:ent];
			[appDelegate saveContext];
		}
	}
}


#pragma mark -
#pragma mark Date Actions

- (NSInteger)hoursLeftInWeek
{
	//Listing 3	Getting the beginning of the week - From Date and Time books
	NSCalendar *curCalendar = [NSCalendar currentCalendar];
	NSDate *today = [[NSDate alloc] init]; 
    NSInteger hoursLeft;
	
    if (selectedDisplayPeriod == 1) 
    {
        unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSWeekdayCalendarUnit;
        NSDateComponents *dateComps = [curCalendar components:unitFlags fromDate:today];
        [dateComps setHour:0];
        [dateComps setMinute:0];
        [dateComps setSecond:0];
        NSDate *startOfToday = [curCalendar dateFromComponents:dateComps];
        
        NSTimeInterval timeInterval = [today timeIntervalSinceDate:startOfToday];
        timeInterval = timeInterval/(3600);
        hoursLeft = 24 - round(timeInterval);
    }
    else
    {
        NSDate *beginningOfWeek = nil; 
        BOOL ok = [curCalendar rangeOfUnit:NSWeekCalendarUnit startDate:&beginningOfWeek interval:NULL forDate:today];
        if (!ok) 
        {
            NSLog(@"Some kine of error in hoursLeftInWeek");
        }
        
        //NSLog(@"Beginning of week = %@", [beginningOfWeek description]);
        //NSLog(@"Today = %@", [today description]);
        
        NSTimeInterval timeInterval = [today timeIntervalSinceDate:beginningOfWeek];
        timeInterval = timeInterval/(3600);
        hoursLeft = 168 - round(timeInterval);
        //NSLog(@"Time interval since beg week = %i", hoursLeft);
    }
    
	return hoursLeft;
}

- (NSMutableArray *)timeSpentDoingActivity:(Activity *)activity
{
	NSMutableArray *entryList;
	NSTimeInterval timeThatPassed;
	NSTimeInterval cumulativeTime = 0;
	NSTimeInterval entryTime;
	NSMutableArray *timedata = [[NSMutableArray alloc] init];
	NSCalendar *curCalendar = [NSCalendar currentCalendar];
	NSDate *today = [[NSDate alloc] init]; 
	
    // Set the beginning date that we use to calculate the cumulative time
    // If selectedDisplayPeriod=1, then we use the start of today
    // Otherwise, we use the start of the week
    NSDate *beginningOfPeriod = nil; 
	if (selectedDisplayPeriod == 1) 
    {
        unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSWeekdayCalendarUnit;
        NSDateComponents *dateComps = [curCalendar components:unitFlags fromDate:today];
        [dateComps setHour:0];
        [dateComps setMinute:0];
        [dateComps setSecond:0];
        beginningOfPeriod = [curCalendar dateFromComponents:dateComps];
    }
    else
    {    
        BOOL ok = [curCalendar rangeOfUnit:NSWeekCalendarUnit startDate:&beginningOfPeriod interval:NULL forDate:today];
        if (!ok) 
        {
            NSLog(@"Some kine of error in timeSpentDoingActivity");
        }
    }
    		
	if ([[activity name] isEqualToString:@"Misc"]) 
	{
		// Need to update allEntries to reflect that one might
		// have been deleted in the ActivityDetailViewController
		TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
		NSArray *allTheEntries = [appDelegate allInstancesOf:@"Entry"];
		allEntries = [allTheEntries mutableCopy];
		entryList = [allEntries mutableCopy];
		timeThatPassed = [today timeIntervalSinceDate:beginningOfPeriod];
		//NSLog(@"In here for Misc");
	}
	else 
	{
		// If the activity is currently running, 
		// then show the elapsed time of the current entry
		if ([[activity active] intValue])
		{
			entryList = [NSMutableArray arrayWithObject:[[entries objectForKey:[activity name]] objectAtIndex:0]];
		}
		else 
		{
			entryList = [entries objectForKey:[activity name]];
		}
	}
		
		
	for (Entry *ent in entryList) 
	{
		// Check against selected week
		// orlando - 02/06 changed for inter-week bug seen
		if ([today compare:[ent startDate]] == NSOrderedDescending && ([[ent startDate] compare:beginningOfPeriod] == NSOrderedDescending || [[ent endDate] compare:beginningOfPeriod] == NSOrderedDescending) || ![ent endDate])
		{
			if ([ent endDate]) 
			{
				if ([[ent startDate] compare:beginningOfPeriod] == NSOrderedDescending) 
				{
					entryTime = [[ent endDate] timeIntervalSinceDate:[ent startDate]];
				}
				else 
				{
					entryTime = [[ent endDate] timeIntervalSinceDate:beginningOfPeriod];
					//entryTime = [beginningOfWeekOne timeIntervalSinceDate:[entry startDate]];
					//timeIntervalWeekTwo += entryTime;
				}
			}
			else 
			{
				if ([[ent startDate] compare:beginningOfPeriod] == NSOrderedDescending)
				{	
					entryTime = [today timeIntervalSinceDate:[ent startDate]];
				}
				else 
				{
					entryTime = [today timeIntervalSinceDate:beginningOfPeriod];
				}

			}
			cumulativeTime += entryTime;
		}
	}
	
	
	NSNumber *hours;
	NSNumber *minutes;
    
    //NSLog(@"Activity: %@", [activity name]);
    //NSLog(@"Cum Time: %f", cumulativeTime);
    
	
	if ([[activity name] isEqualToString:@"Misc"]) 
	{
		//NSLog(@"Time that passed: %f", timeThatPassed);
        timeThatPassed -= cumulativeTime;
        //hours = [NSNumber numberWithInt:(int)(timeThatPassed/3600 - cumulativeTime/3600)];
        hours = [NSNumber numberWithInt:(int)timeThatPassed/3600];
		//int min = round(timeThatPassed/60)-round(cumulativeTime/60);
        //int min = round(timeThatPassed/60);
		//min %= 60;
		int min = (timeThatPassed - ([hours intValue] * 3600))/60;
        minutes = [NSNumber numberWithInt:min];
	}
	else 
	{
		hours = [NSNumber numberWithInt:(int)(cumulativeTime/3600)];
		int min = (cumulativeTime - ([hours intValue] * 3600))/60;
		//min %= 60;
		minutes = [NSNumber numberWithInt:min];
	}
    
    //NSLog(@"Hours  : %i", [hours intValue]);
    //NSLog(@"Minutes: %i", [minutes intValue]);
    //NSLog(@" ");
	
	//NSLog(@"Name = %@", [activity name]);
	//NSLog(@"Hours = %i", [hours intValue]);
	//NSLog(@"Minutes = %i", [minutes intValue]);
	//NSLog(@" ");
	[timedata addObject:hours];
	[timedata addObject:minutes];
	return timedata;
}

- (IBAction)setDisplayPeriod:(id)sender
{
	// Pull the tab from the sender button 
    // Then divide by 10 to see if they selected option 1=Day or 2=Week
	//int senderTag = (int)[sender tag];
	//senderTag = senderTag/10;
	//selectedDisplayPeriod = senderTag;
    //UIToolbar *bottomBar = (UIToolbar *)[[self view] viewWithTag:27];
    //UIBarButtonItem *periodToggle = (UIBarButtonItem *)[bottomBar viewWithTag:10];
    
    if (selectedDisplayPeriod == 1) 
    {
        selectedDisplayPeriod = 2;
        [togglePeriod setTitle:@"This Week"]; 
    }
    else
    {
        selectedDisplayPeriod = 1;
        [togglePeriod setTitle:@"Today"];
    }
    
    // Reload the time left in the title bar
    [self setTitleTime];
    
    // Now reload the table data to call the time methods again with the new period
	[[self sharedTableView] reloadData];		
}

- (void)setTitleTime
{
    NSInteger hoursLeft = [self hoursLeftInWeek];
	if (hoursLeft > 99) 
	{
		[self setTitle:[NSString stringWithFormat:@"%i Hours Left",hoursLeft]];
	}
	else 
	{
		if (hoursLeft > 9) 
		{
			[self setTitle:[NSString stringWithFormat:@"%i Hours Left",hoursLeft]];
		}
		else 
		{
			if (hoursLeft == 0) 
            {
                [self setTitle:[NSString stringWithFormat:@"<1 Hour Left"]];
            }
            else
            {
                if (hoursLeft == 1) 
                    [self setTitle:[NSString stringWithFormat:@"%i Hour Left",hoursLeft]];
                else
                    [self setTitle:[NSString stringWithFormat:@"%i Hours Left",hoursLeft]];
            }
		}
        
	}	
}

- (NSMutableArray *)timeSpentDoingActivityForLog:(NSString *)activityName
{
	NSMutableArray *entryList;
    NSTimeInterval timeIntervalWeekOne = 0;
	NSTimeInterval timeIntervalWeekTwo = 0;
	NSTimeInterval timeIntervalWeekThree = 0;
	NSTimeInterval timeIntervalWeekFour = 0;
	NSMutableArray *timedata = [[NSMutableArray alloc] init];
	NSCalendar *curCalendar = [NSCalendar currentCalendar];
	NSDate *today = [[NSDate alloc] init]; 
	NSDate *beginningOfWeekOne = nil; 
	BOOL ok = [curCalendar rangeOfUnit:NSWeekCalendarUnit startDate:&beginningOfWeekOne interval:NULL forDate:today];
	if (!ok) 
	{
		NSLog(@"Some kind of error in timeSpentDoingActivity");
	}
	NSTimeInterval timeThatPassed = [today timeIntervalSinceDate:beginningOfWeekOne];
	
	// Now calculate the beginning of the past weeks 
	NSTimeInterval secondsPerWeek = 7 * 24 * 60 * 60;
	NSDate *beginningOfWeekTwo = [beginningOfWeekOne dateByAddingTimeInterval:-secondsPerWeek];
	NSDate *beginningOfWeekThree = [beginningOfWeekTwo dateByAddingTimeInterval:-secondsPerWeek];
	NSDate *beginningOfWeekFour = [beginningOfWeekThree dateByAddingTimeInterval:-secondsPerWeek];
	
    if ([activityName isEqualToString:@"Misc"]) 
    {
        entryList = allEntries;
    }
    else
    {
        entryList = [entries objectForKey:activityName];
    }
    
	// Now go through every entry and figure out where it goes
	for (Entry *entry in entryList) 
	{
		NSTimeInterval entryTime;
		// Check week 1
		if ([[entry startDate] compare:beginningOfWeekOne] == NSOrderedDescending || [[entry endDate] compare:beginningOfWeekOne] == NSOrderedDescending || ![entry endDate]) 
		{
			if ([entry endDate]) 
			{
				if ([[entry startDate] compare:beginningOfWeekOne] == NSOrderedDescending) 
				{
					entryTime = [[entry endDate] timeIntervalSinceDate:[entry startDate]];
				}
				else 
				{
					entryTime = [[entry endDate] timeIntervalSinceDate:beginningOfWeekOne];
					//entryTime = [beginningOfWeekOne timeIntervalSinceDate:[entry startDate]];
					//timeIntervalWeekTwo += entryTime;
				}
			}
			else 
			{
				if ([[entry startDate] compare:beginningOfWeekOne] == NSOrderedDescending)
				{
					entryTime = [today timeIntervalSinceDate:[entry startDate]];
				}
				else 
				{
					entryTime = [today timeIntervalSinceDate:beginningOfWeekOne];
				}
			}
			timeIntervalWeekOne += entryTime;
		}
        
        
		// Check week 2
		if ([beginningOfWeekOne compare:[entry startDate]] == NSOrderedDescending && ([[entry startDate] compare:beginningOfWeekTwo] == NSOrderedDescending || [[entry endDate] compare:beginningOfWeekTwo] == NSOrderedDescending))
		{
			if ([entry endDate]) 
			{
				if ([[entry startDate] compare:beginningOfWeekTwo] == NSOrderedDescending) 
				{
					if ([[entry endDate] compare:beginningOfWeekOne] == NSOrderedDescending) 
					{
						entryTime = [beginningOfWeekOne timeIntervalSinceDate:[entry startDate]];
					}
					else 
					{
						entryTime = [[entry endDate] timeIntervalSinceDate:[entry startDate]];
					}
				}
				else 
				{
					entryTime = [[entry endDate] timeIntervalSinceDate:beginningOfWeekTwo];
					//entryTime = [beginningOfWeekOne timeIntervalSinceDate:[entry startDate]];
					//timeIntervalWeekTwo += entryTime;
				}
			}
			else 
			{
				entryTime = [beginningOfWeekOne timeIntervalSinceDate:[entry startDate]];
			}
			timeIntervalWeekTwo += entryTime;
		}
		
		// Check week 3
		if ([beginningOfWeekTwo compare:[entry startDate]] == NSOrderedDescending && ([[entry startDate] compare:beginningOfWeekThree] == NSOrderedDescending || [[entry endDate] compare:beginningOfWeekThree] == NSOrderedDescending))
		{
			if ([entry endDate]) 
			{
				if ([[entry startDate] compare:beginningOfWeekThree] == NSOrderedDescending) 
				{
					entryTime = [[entry endDate] timeIntervalSinceDate:[entry startDate]];
				}
				else 
				{
					entryTime = [[entry endDate] timeIntervalSinceDate:beginningOfWeekThree];
					//entryTime = [beginningOfWeekOne timeIntervalSinceDate:[entry startDate]];
					//timeIntervalWeekTwo += entryTime;
				}
			}
			else 
			{
				entryTime = [beginningOfWeekTwo timeIntervalSinceDate:[entry startDate]];
			}
			timeIntervalWeekThree += entryTime;
		}
        
		// Check week 4
		if ([beginningOfWeekThree compare:[entry startDate]] == NSOrderedDescending && ([[entry startDate] compare:beginningOfWeekFour] == NSOrderedDescending || [[entry endDate] compare:beginningOfWeekFour] == NSOrderedDescending))
		{
			if ([entry endDate]) 
			{
				if ([[entry startDate] compare:beginningOfWeekFour] == NSOrderedDescending) 
				{
					entryTime = [[entry endDate] timeIntervalSinceDate:[entry startDate]];
				}
				else 
				{
					entryTime = [[entry endDate] timeIntervalSinceDate:beginningOfWeekFour];
					//entryTime = [beginningOfWeekOne timeIntervalSinceDate:[entry startDate]];
					//timeIntervalWeekTwo += entryTime;
				}
			}
			else 
			{
				entryTime = [beginningOfWeekThree timeIntervalSinceDate:[entry startDate]];
			}
			timeIntervalWeekFour += entryTime;
		}
        
	}
	
	// Now calculate the hours to put into the return array as strings
	float hours;
	NSString *time;
    int timeBump=0;
	
    // Week 1
    /*if (timeIntervalWeekOne != 0) 
    {
        timeBump = 30;
    }
    else
    {
        timeBump = 0;
    }*/
	
    if ([activityName isEqualToString:@"Misc"]) 
    {
        timeThatPassed -= timeIntervalWeekOne;
        hours = ((timeThatPassed+timeBump)/3600);
    }
    else 
    {
        hours = ((timeIntervalWeekOne+timeBump)/3600);
    }
    time = [NSString stringWithFormat:@"%f",hours];
    [timedata addObject:time];
	
    // Week 2
    /*if (timeIntervalWeekTwo != 0) 
    {
        timeBump = 30;
    }
    else
    {
        timeBump = 0;
    }*/
    
    if ([activityName isEqualToString:@"Misc"]) 
    {
        hours = 168 - ((timeIntervalWeekTwo+timeBump)/3600);
    }
    else 
    {
        hours = ((timeIntervalWeekTwo+timeBump)/3600);
    }
    time = [NSString stringWithFormat:@"%f",hours];
    [timedata addObject:time];
    
    // Week 3
    /*if (timeIntervalWeekThree != 0) 
    {
        timeBump = 30;
    }
    else
    {
        timeBump = 0;
    }*/
    
	if ([activityName isEqualToString:@"Misc"]) 
	{
		hours = 168 - ((timeIntervalWeekThree+timeBump)/3600);
	}
	else 
	{
		hours = ((timeIntervalWeekThree+timeBump)/3600);
	}
	time = [NSString stringWithFormat:@"%f",hours];
	[timedata addObject:time];
	
    // Week 4
    /*if (timeIntervalWeekFour != 0) 
    {
        timeBump = 30;
    }
    else
    {
        timeBump = 0;
    }*/
    
	if ([activityName isEqualToString:@"Misc"]) 
	{
		hours = 168 - ((timeIntervalWeekFour+timeBump)/3600);
	}
	else 
	{
		hours = ((timeIntervalWeekFour+timeBump)/3600);
	}
	time = [NSString stringWithFormat:@"%f",hours];
	[timedata addObject:time];
   
    
    // Now calculate the beginning of the past weeks 
    NSTimeInterval secondsInADay = 24 * 60 * 60;
    NSString *weekRange;
    NSDate *topDate, *bottomDate;
    NSDateFormatter *date = [[[NSDateFormatter alloc] init] autorelease]; 
	[date setDateFormat:@"MM/dd/yy"];
	
    // Week 1 Range
    topDate = [beginningOfWeekOne dateByAddingTimeInterval:secondsPerWeek];
    bottomDate = beginningOfWeekOne;
    topDate = [topDate dateByAddingTimeInterval:-secondsInADay];
    NSString *stringDateTop = [date stringFromDate:topDate];
    NSString *stringDateBottom = [date stringFromDate:bottomDate];
    weekRange = [NSString stringWithFormat:@"%@ - %@",stringDateBottom,stringDateTop];
    [timedata addObject:weekRange];
    
	// Weeks 2-4 Range
    for (int i = 2; i < 5; i++) 
    {
        topDate = [beginningOfWeekOne dateByAddingTimeInterval:-(i - 2)*secondsPerWeek];
		bottomDate = [beginningOfWeekOne dateByAddingTimeInterval:-(i - 1)*secondsPerWeek];
        topDate = [topDate dateByAddingTimeInterval:-secondsInADay];
        stringDateTop = [date stringFromDate:topDate];
        stringDateBottom = [date stringFromDate:bottomDate];
        weekRange = [NSString stringWithFormat:@"%@ - %@",stringDateBottom,stringDateTop];
        [timedata addObject:weekRange];
    }

	return timedata;
}



#pragma mark -
#pragma mark View lifecycle


 - (void)viewDidLoad 
{
    [super viewDidLoad];
	//self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

 - (void)viewWillAppear:(BOOL)animated
{	
    /*
    // Hate to do this...crud
    // Call this to delete any misc entries that may be left over
    [self updateEntries];
    
    // Make sure to deselect the selected row anytime the view comes up
	// Need this when coming back from ActivityDetailViewController
	[[self sharedTableView] deselectRowAtIndexPath:[[self sharedTableView] indexPathForSelectedRow] animated:NO];
	[[self sharedTableView] reloadData];
    
    // Hide the edit button if we have less than 3 items
    // Because you can't edit the base ones
    if ([activities count] < 3) 
    {
        //NSLog(@"In here. Count: %i", [activities count]);
        [[self navigationItem] setRightBarButtonItem:Nil];
    }
    else
    {
        [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
    }
	
	if (addActivityViewController)
	{
		// Take the table out of editing mode if the user left it there
		[self setEditing:NO animated:NO];
        
        if ([addActivityViewController activityName] && ([[addActivityViewController activityName] length] > 0) ) 
		{
            [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
        }
	}
    */
    	
    // Set the time left in the TitleBar
	[self setTitleTime];
    
    // Start the activity indicator
    UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[[self view] viewWithTag:667];
    [activityIndicator setHidden:0];
    [activityIndicator startAnimating];
}

 - (void)viewDidAppear:(BOOL)animated 
{
    [super viewDidAppear:animated];
	    
    // Hate to do this...crud
    // Call this to delete any misc entries that may be left over
    [self updateEntries];
    
    // Make sure to deselect the selected row anytime the view comes up
	// Need this when coming back from ActivityDetailViewController
	[[self sharedTableView] deselectRowAtIndexPath:[[self sharedTableView] indexPathForSelectedRow] animated:NO];
	[[self sharedTableView] reloadData];
    
    // Hide the edit button if we have less than 3 items
    // Because you can't edit the base ones
    if ([activities count] < 3) 
    {
        //NSLog(@"In here. Count: %i", [activities count]);
        [[self navigationItem] setRightBarButtonItem:Nil];
    }
    else
    {
        [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
    }
	
    /*
	if (addActivityViewController)
	{
		// Take the table out of editing mode if the user left it there
		[self setEditing:NO animated:NO];
        
        if ([addActivityViewController activityName] && ([[addActivityViewController activityName] length] > 0) ) 
		{
            [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
        }
	}
    */
	
    // If this is the first time the app has been run,
    // then give the user a quick hello message
    // with one tidbit of usage info
    if (firstTimeRun) 
    {
        // an error occurred
        firstTimeRun = 0;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Howdy!" 
                                                        message:@"Quick heads up. Tap an activity to start or stop tracking the time spent on it.\n\nSo add stuff and have fun!"
                                                        delegate:nil 
                                                        cancelButtonTitle:@"OK" 
                                                        otherButtonTitles: nil];
        [alert show];
        [alert release];
    }
    
	// Check if addActivityViewController exists
	// cuz if so, then we entered the addActivity method
	// and are now returning from it
	if (addActivityViewController) 
	{
		if ([addActivityViewController activityName] && ([[addActivityViewController activityName] length] > 0) ) 
		{
			//[self createActivityObject:[addActivityViewController activityName] withCurrentHours:[NSNumber numberWithInt:0] withGoalHours:[addActivityViewController goalHours]];
			[self createActivityObject:[addActivityViewController activityName]];
		}
        
        // Take the table out of editing mode if the user left it there
		[self setEditing:NO animated:NO];
        
        if ([addActivityViewController activityName] && ([[addActivityViewController activityName] length] > 0) ) 
		{
            [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
        }
	}
	
	// Now release the addActivityViewController to reset the above test
	[addActivityViewController release];
	addActivityViewController = nil;
    
    // Stop and hide the activity indicator
    UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[[self view] viewWithTag:667];
    [activityIndicator setHidden:1];
    [activityIndicator stopAnimating];
    
    // Check if a log email did not get sent or saved just now
    // If so, then tell the user how to download it via Itunes
    if (logEmailNotSent) 
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil 
                                                        message:@"Connect to iTunes to get the log via the device's Apps window."
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles: nil];
        [alert show];
        [alert release];
        logEmailNotSent = 0;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
	TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
	[appDelegate saveContext];
}


#pragma mark -
#pragma mark Convenience Methods

+ (ActivityViewController *)sharedActivityViewController
{
	return sharedInstance;
}


#pragma mark -
#pragma mark Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	//NSLog(@"ACTIVITIES COUNT = %d", [activities count]);
    return [activities count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	Activity *activity = [activities objectAtIndex:[indexPath row]];
	
    //static NSString *CellIdentifier = @"Cell";
	static NSString *CellIdentifier = @"ActivityCell";
	
	if ([[activity name] isEqualToString:@"Misc"]) 
	{
		CellIdentifier = @"MiscCell";
	}
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        //cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		[[NSBundle mainBundle] loadNibNamed:@"ActivityCell" owner:self options:nil];
		cell = activityCell;
    }
    
    // Configure the cell...
	UILabel *activityName;
	activityName = (UILabel *)[cell viewWithTag:900];
	[activityName setTextColor:[UIColor blackColor]];
	[activityName setText:[activity name]];
	
	// Get the amount of time spent doing the activity this week to display
	NSMutableArray *timeData = [self timeSpentDoingActivity:activity];
	NSNumber *hours = [timeData objectAtIndex:0];
	NSNumber *minutes = [timeData objectAtIndex:1];
	UILabel *hoursLabel;
	hoursLabel = (UILabel *)[cell viewWithTag:901];
	[hoursLabel setTextColor:[UIColor blackColor]];
	if ([hours intValue] == 0) 
	{
		[hoursLabel setText:@""];
	}
	else 
	{
		[hoursLabel setText:[NSString stringWithFormat:@"%ih",[hours intValue]]];
	}
	
	UILabel *minutesLabel;
	minutesLabel = (UILabel *)[cell viewWithTag:902];
	[minutesLabel setTextColor:[UIColor blackColor]];
	if ([minutes intValue] == 0) 
	{
		[minutesLabel setText:@""];
	}
	else 
	{
		[minutesLabel setText:[NSString stringWithFormat:@"%im",[minutes intValue]]];
	}
	
	// Pull the general settings to see if an activity is currently active or not
	TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
	NSArray	*settings = [appDelegate allInstancesOf:@"General"];
	
	NSMutableArray *genSettings = [settings mutableCopy];
	General *genAppSettings = [genSettings objectAtIndex:0];
	NSNumber *activEnabled = [genAppSettings activityEnabled];
	
	// Configuring the button in the cell
	UIButton *button = (UIButton *)[cell viewWithTag:1];
	//[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[button setBackgroundColor:[UIColor	colorWithRed:0 green:0 blue:0 alpha:0]];
	//[button setEnabled:YES];
	
	
	//NSLog(@"Activity name = %@",[activity name]);
	//NSLog(@"State of activEnabled: %d",[activEnabled intValue]);
	//NSLog(@"State of activity Active: %d",[[activity active] intValue]);
	//NSLog(@" ");


	if ([activEnabled intValue])
	{
		if (![[activity active] intValue]) 
		{
			[activityName setTextColor:[UIColor grayColor]];
			[hoursLabel setTextColor:[UIColor grayColor]];
			[minutesLabel setTextColor:[UIColor grayColor]];
			//[button setBackgroundColor:[UIColor	colorWithRed:0 green:.6 blue:.1 alpha:0.3]];
			//[button setEnabled:NO];
		}
		else 
		{
			[hoursLabel setTextColor:[UIColor colorWithRed:0 green:.6 blue:.1 alpha:1]];
			[minutesLabel setTextColor:[UIColor colorWithRed:0 green:.6 blue:.1 alpha:1]];
			[button setBackgroundColor:[UIColor	colorWithRed:0 green:.6 blue:.1 alpha:1]];
			if ([minutes intValue] == 0) 
			{
				[minutesLabel setText:@"0m"];
			}
		}
	}
	
	if ([[activity name] isEqualToString:@"Misc"]) 
	{
		[button setEnabled:NO];
		[button setBackgroundColor:[UIColor	colorWithRed:0 green:.6 blue:.1 alpha:0]];
	}
    
    // When editing mode is enabled, hide the hoursLabel, minutesLabel, and detail disclosure button
    if ([tableView isEditing] && [indexPath row] < [activities count]-2) 
    {
        [minutesLabel setHidden:1];
        [hoursLabel setHidden:1];
        [[cell viewWithTag:1982] setHidden:1];
    }
    else
    {
        [minutesLabel setHidden:0];
        [hoursLabel setHidden:0];
        [[cell viewWithTag:1982] setHidden:0];
    }
	
	// Allow table rows to be reordered by the user
	[cell setShowsReorderControl:YES];
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];

    return cell;
}


// Prevent Sleep and Misc from being deleted
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath row] == ([activities count] - 1) || [indexPath row] == ([activities count] - 2)) 
	{
		return NO;
	}
	return YES;
}

// Handle the deletion of a row
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) 
	{
		TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
		Activity *activity = [activities objectAtIndex:[indexPath row]];
		
		// If this activity was ACTIVE, then need to change general setting
		// to show that there is no longer an active activity
		if ([[activity active] intValue]) 
		{
			NSArray	*settings = [appDelegate allInstancesOf:@"General"];
			General *genSettings = [settings objectAtIndex:0];
			[genSettings setActivityEnabled:[NSNumber numberWithInt:0]];
            
            // Disable the timer that autoupdates the screen
            [timer invalidate];
            timer = nil;
		}
			
		// Remove the entries NSDictionary object for this activity
		[entries removeObjectForKey:[activity name]];
		
		[activities removeObjectAtIndex:[indexPath row]];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		
		// Remove the object from the persistent store
		NSManagedObjectContext *context = [appDelegate managedObjectContext];
		[context deleteObject:activity];
		[appDelegate saveContext];
        
        // Update the activity order
        [self updateActivityOrder];
        
        // If deleting the activity reduced the number of total activities to 2
        // then remove the Edit button, because you can't edit the default 2
        if ([activities count] < 3) 
        {
            [[self navigationItem] setRightBarButtonItem:Nil];
            
            [super setEditing:0 animated:YES];  
            [[self sharedTableView] setEditing:0 animated:YES];
        }
	
	}
	[[self sharedTableView] reloadData];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated 
{ 
    [super setEditing:editing animated:animated];  
    [[self sharedTableView] setEditing:editing animated:YES]; 
    
    if(!editing)
    { 
        for (int i=0; i < [activities count]; i++) 
        {
            NSIndexPath *myIndexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [[[sharedTableView cellForRowAtIndexPath:myIndexPath] viewWithTag:1982] setHidden:0];
            [[[sharedTableView cellForRowAtIndexPath:myIndexPath] viewWithTag:901] setHidden:0];
            [[[sharedTableView cellForRowAtIndexPath:myIndexPath] viewWithTag:902] setHidden:0];
        }
    }
}


#pragma mark -
#pragma mark AlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0) 
    {
        // The user opted to send the log in an email
        // so call the method to bring up the email screen
        [self sendLogViaEmail];
    }
    else 
    {
        // The user opted to not send out the log via an email
        // so give them the instructions for downloading the file via iTunes
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil 
                                                        message:@"Connect to iTunes to get the log via the device's Apps window."
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles: nil];
        [alert show];
        [alert release];
    }
}


#pragma mark - 
#pragma mark MailController Delegate
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    // Get the mail compose view off the screen
    [self dismissModalViewControllerAnimated:YES];
    
    // Now check the result
    if (result == MFMailComposeResultSaved || result == MFMailComposeResultSent) 
    {
        // If the email was sent or saved, then delete the log file because it isn't needed anymore
        // First get the path to the file attachment
        // Grab the path to the app's Documents folder 
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0]; 
        
        // Create the full path to the log file
        NSString *pathToLogFile = [documentsDirectory stringByAppendingPathComponent:logFileName];
        
        // Now delete the file
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:pathToLogFile error:NULL];
    }
    else
        // Otherwise leave the file in place and display the instructions for downloading it via iTunes
        // when the main activity view reappears
        logEmailNotSent = 1;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
	Activity *selectedActivity = [activities objectAtIndex:[indexPath row]];
    if (![[selectedActivity name] isEqualToString:@"Misc"]) 
    {
         [self changeActivityState:selectedActivity];
    }
   
    // ORIGINAL Actions
    /* 
	ActivityDetailViewController *activityDetailView = [[ActivityDetailViewController alloc] init];
	Activity *selectedActivity = [activities objectAtIndex:[indexPath row]];
	NSMutableArray *entryList = [entries objectForKey:[selectedActivity name]];
	
	if ([[selectedActivity name] isEqualToString:@"Misc"]) 
	{
		[activityDetailView setEntries:allEntries];
	}
	else 
	{
		[activityDetailView setEntries:entryList];
	}
	[activityDetailView setActivity:selectedActivity];
	[[self navigationController] pushViewController:activityDetailView animated:YES];
	[activityDetailView release];
     */ 
}


// These next few methods are all for the sake of row relocation
- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	if ([proposedDestinationIndexPath row] < [activities count]-2)
	{
		// Let it move the row to anywhere above the sleep and Misc rows
		return proposedDestinationIndexPath;
	}
	// If user tries to move the row below one of the defaults, then we move it on top of sleep
	NSIndexPath *betterIndexPath = [NSIndexPath indexPathForRow:[activities count] - 3 inSection:0];	
	return betterIndexPath;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath 
{
    // Don't let the user move the default rows
    if (indexPath.row < [activities count] - 2)
        return YES;
    return NO;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
	// Get pointer to object being moved
	Activity *selectedActivity = [activities objectAtIndex:[fromIndexPath row]];
	
	// Retain selectedActivity so that it is not deallocated when it is removed from the array
	[selectedActivity retain];
    // Retain count of selectedActivity is now 2
	
	// Remove the selectedActivity from the activities array, it is automatically sent release
	[activities removeObjectAtIndex:[fromIndexPath row]];
    // Retain count of selectedActivity is now 1
	
	// Re-insert the selectedActivity into the array at new location, it is automatically retained
	[activities insertObject:selectedActivity atIndex:[toIndexPath row]];
    // Retain count of selectedActivity is now 2
	
	// Release selectedActivity
	[selectedActivity release];
    // Retain count of selectedActivity is now 1
    
    // Now update the order info in coredata
    [self updateActivityOrder];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    if ([indexPath row] < [activities count]-2) 
    {
        if ([tableView isEditing]) 
        {
            [[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:1982] setHidden:1];
            [[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:901] setHidden:1];
            [[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:902] setHidden:1];  
        }
        return UITableViewCellEditingStyleDelete;
    }
    else
    {
        return UITableViewCellEditingStyleNone;
    }
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.navigationItem.rightBarButtonItem = Nil;
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:1982] setHidden:0];
    [[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:901] setHidden:0];
    [[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:902] setHidden:0];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
	[activities release];
	[entries release];
	[allEntries release];
    [logFileName release];
    [timer invalidate];
    [super dealloc];
}


@end

