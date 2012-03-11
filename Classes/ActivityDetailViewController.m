//
//  ActivityDetailViewController.m
//  168 Hours
//
//  Created by Orlando O'Neill on 1/29/11.
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

#import "TimeTrackerAppDelegate.h"
#import "ActivityDetailViewController.h"
#import "RenameActivityView.h"
#import "Activity.h"
#import	"Entry.h"
#import "General.h"
#import "ActivityViewController.h"
#import "EntryDetailView.h"

@implementation ActivityDetailViewController

@synthesize activity, entries, entryCell;

#pragma mark -
#pragma mark Init Methods

// Declare custom init method
- (id)init
{
	[super initWithNibName:nil bundle:nil];
	//[self setButtonDisplay:[NSNumber numberWithInt:1]];
	selectedWeek = 1;
    return self;
}


// Overwrite default init method
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self init];
}

#pragma mark -
#pragma mark View Lifecycle

//- (void)viewWillAppear:(BOOL)animated

- (void)viewWillAppear:(BOOL)animated
{
    [self setTitle:@"Activity Info"];
    UITableView *tableView = (UITableView *)[[self view] viewWithTag:90];
	[tableView setHidden:1];
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
    
    UIButton *renameButton = (UIButton *)[[self view] viewWithTag:1774];
    [renameButton setHidden:1];
    
    // Check if user renamed the activity
	if (renameActivityView) 
	{
		if ([renameActivityView activityName] && ([[renameActivityView activityName] length] > 0) && (![[renameActivityView activityName] isEqualToString:[activity name]])) 
		{
			[activity setName:[renameActivityView activityName]]; 
			TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
			[appDelegate saveContext];
			
			ActivityViewController *activityView = [ActivityViewController sharedActivityViewController];
			[activityView updateEntries];
			[[activityView sharedTableView] reloadData];
		}		
	}
	// Now release the addActivityViewController to reset the above test
	[renameActivityView release];
	renameActivityView = nil;
    
    [activityTitle setTitle:[activity name] forState:UIControlStateNormal];
    UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[[self view] viewWithTag:667];
    [activityIndicator setHidden:0];
    [activityIndicator startAnimating];
    
    // Hide the cumulative hour and minute labels at the top until they've
    // been recalculated in viewDidAppear via setTimeButtons:
    UIButton *hourText = (UIButton *)[[self view] viewWithTag:12];
    UIButton *minuteText = (UIButton *)[[self view] viewWithTag:13];
    [hourText setHidden:1];
    [minuteText setHidden:1];
}


- (void)viewDidAppear:(BOOL)animated
{
    UIButton *renameButton = (UIButton *)[[self view] viewWithTag:1774];
    [renameButton setHidden:0];
    
	UITableView *tableView = (UITableView *)[[self view] viewWithTag:90];
    
    // Do set up stuff if the activity is Misc
    if ([[activity name] isEqualToString:@"Misc"]) 
    {
        [renameButton setHidden:1];
    }
    else
    {
        UIButton *renameButton = (UIButton *)[[self view] viewWithTag:1774];
        [renameButton setHidden:0];
    }
    
    if (entryDetailView) 
    {
        // If the # of entries coming out of this view are different
        // then the user deleted one
        // So update the entries array with the latest
        if ([[entryDetailView deletedAnEntry] intValue]) 
        {
            // Update the entries dictionary with the latest. Complete refresh from core data
            TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
            NSArray *allTheEntries = [appDelegate allInstancesOf:@"Entry"];
            NSMutableArray *allEntries = [allTheEntries mutableCopy];
            
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
            
            // Pull all entries for each activity into an array
            NSMutableArray *entryList = [[NSMutableArray alloc] init];
            for (Entry *ent in allEntries) 
            {
                if ([[activity name] isEqualToString:@"Misc"]) 
                {
                    [entryList addObject:ent];
                }
                else
                {     
                    if ([ent activity] == activity) 
                    {
                        [entryList addObject:ent];
                    }
                }
            }
            
            // Update the entries for this activity
            entries = entryList;   
        }
    }
    // Now release the addActivityViewController to reset the above test
    [entryDetailView release];
	entryDetailView = nil;
    
    [self setTimeButtons];
    // selectedEntries is set in this next function 
    [self setEntriesToShow];
    
    // Remove the tableview if there is no content to show    
	if ([dailyActivityData count] == 0) 
	{
        UITableView *tableView = (UITableView *)[[self view] viewWithTag:90];
		[tableView setHidden:1];
	}
	else 
	{
        // Remove the tableview if there is no content to show
        [tableView setHidden:0];
		
		// If it is the Misc activity, then still want to remove the table
		// because otherwise, it will display all of the entires across all activities
		[self setEntriesToShow];
    }
        
    tableView = (UITableView *)[[self view] viewWithTag:90];
    [tableView reloadData];
    
    UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[[self view] viewWithTag:667];
    [activityIndicator setHidden:1];
    [activityIndicator stopAnimating];
}

- (void)viewDidLoad 
{
	[super viewDidLoad];
}


#pragma mark -
#pragma mark Date Actions

- (NSMutableArray *)timeSpentDoingActivity
{
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
	
    // Orlando
    // Fixed
    NSTimeInterval timeThatPassed = [today timeIntervalSinceDate:beginningOfWeekOne];
    NSInteger startDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:beginningOfWeekOne];
    NSInteger endDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:today];
    NSTimeInterval offsetForDaylightSavings = endDateTimeZoneOffset - startDateTimeZoneOffset;
    timeThatPassed = timeThatPassed + offsetForDaylightSavings;
    
	// Now calculate the beginning of the past weeks 
	NSTimeInterval secondsPerWeek = 7 * 24 * 60 * 60;
	//NSDate *beginningOfWeekTwo = [beginningOfWeekOne dateByAddingTimeInterval:-secondsPerWeek];
	//NSDate *beginningOfWeekThree = [beginningOfWeekTwo dateByAddingTimeInterval:-secondsPerWeek];
	//NSDate *beginningOfWeekFour = [beginningOfWeekThree dateByAddingTimeInterval:-secondsPerWeek];
    NSDateComponents *dateOffset = [[[NSDateComponents alloc] init] autorelease];
    [dateOffset setDay:-7];
    NSDate *beginningOfWeekTwo = [curCalendar dateByAddingComponents:dateOffset toDate:beginningOfWeekOne options:0];
    NSDate *beginningOfWeekThree = [curCalendar dateByAddingComponents:dateOffset toDate:beginningOfWeekTwo options:0];
    NSDate *beginningOfWeekFour = [curCalendar dateByAddingComponents:dateOffset toDate:beginningOfWeekThree options:0]; 
	
    NSDate *startTime, *endTime;
	// Now go through every entry and figure out where it goes
	for (Entry *entry in entries) 
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
                    endTime = [entry endDate];
                    startTime = [entry startDate];
				}
				else 
				{
					entryTime = [[entry endDate] timeIntervalSinceDate:beginningOfWeekOne];
                    endTime = [entry endDate];
                    startTime = beginningOfWeekOne;
				}
			}
			else 
			{
				if ([[entry startDate] compare:beginningOfWeekOne] == NSOrderedDescending)
				{
					entryTime = [today timeIntervalSinceDate:[entry startDate]];
                    endTime = today;
                    startTime = [entry startDate];
				}
				else 
				{
					entryTime = [today timeIntervalSinceDate:beginningOfWeekOne];
                    endTime = today;
                    startTime = beginningOfWeekOne;
				}
			}
            
            // Fix any offset issues from daylight savings time
            // on the time spent doing an activity
            NSInteger startDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:startTime];
            NSInteger endDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:endTime];
            NSTimeInterval offsetForDaylightSavings = endDateTimeZoneOffset - startDateTimeZoneOffset;
            
			timeIntervalWeekOne += entryTime;
            timeIntervalWeekOne += offsetForDaylightSavings;
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
                        endTime = beginningOfWeekOne;
                        startTime = [entry startDate];
					}
					else 
					{
						entryTime = [[entry endDate] timeIntervalSinceDate:[entry startDate]];
                        endTime = [entry endDate];
                        startTime = [entry startDate];
					}
				}
				else 
				{
					entryTime = [[entry endDate] timeIntervalSinceDate:beginningOfWeekTwo];
                    endTime = [entry endDate];
                    startTime = beginningOfWeekTwo;
				}
			}
			else 
			{
				entryTime = [beginningOfWeekOne timeIntervalSinceDate:[entry startDate]];
                endTime = beginningOfWeekOne;
                startTime = [entry startDate];
			}
			timeIntervalWeekTwo += entryTime;
            
            // Fix any offset issues from daylight savings time
            // on the time spent doing an activity
            NSInteger startDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:startTime];
            NSInteger endDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:endTime];
            NSTimeInterval offsetForDaylightSavings = endDateTimeZoneOffset - startDateTimeZoneOffset;
            
            timeIntervalWeekTwo += offsetForDaylightSavings;

		}
		
		// Check week 3
		if ([beginningOfWeekTwo compare:[entry startDate]] == NSOrderedDescending && ([[entry startDate] compare:beginningOfWeekThree] == NSOrderedDescending || [[entry endDate] compare:beginningOfWeekThree] == NSOrderedDescending))
		{
			if ([entry endDate]) 
			{
				if ([[entry startDate] compare:beginningOfWeekThree] == NSOrderedDescending) 
				{
					entryTime = [[entry endDate] timeIntervalSinceDate:[entry startDate]];
                    endTime = [entry endDate];
                    startTime = [entry startDate];
				}
				else 
				{
					entryTime = [[entry endDate] timeIntervalSinceDate:beginningOfWeekThree];
					//entryTime = [beginningOfWeekOne timeIntervalSinceDate:[entry startDate]];
					//timeIntervalWeekTwo += entryTime;
                    endTime = [entry endDate];
                    startTime = beginningOfWeekThree;
				}
			}
			else 
			{
				entryTime = [beginningOfWeekTwo timeIntervalSinceDate:[entry startDate]];
                endTime = beginningOfWeekTwo;
                startTime = [entry startDate];
			}
			timeIntervalWeekThree += entryTime;
            
            // Fix any offset issues from daylight savings time
            // on the time spent doing an activity
            NSInteger startDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:startTime];
            NSInteger endDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:endTime];
            NSTimeInterval offsetForDaylightSavings = endDateTimeZoneOffset - startDateTimeZoneOffset;
            
            timeIntervalWeekThree += offsetForDaylightSavings;
		}
	
		// Check week 4
		if ([beginningOfWeekThree compare:[entry startDate]] == NSOrderedDescending && ([[entry startDate] compare:beginningOfWeekFour] == NSOrderedDescending || [[entry endDate] compare:beginningOfWeekFour] == NSOrderedDescending))
		{
			if ([entry endDate]) 
			{
				if ([[entry startDate] compare:beginningOfWeekFour] == NSOrderedDescending) 
				{
					entryTime = [[entry endDate] timeIntervalSinceDate:[entry startDate]];
                    endTime = [entry endDate];
                    startTime = [entry startDate];
				}
				else 
				{
					entryTime = [[entry endDate] timeIntervalSinceDate:beginningOfWeekFour];
					//entryTime = [beginningOfWeekOne timeIntervalSinceDate:[entry startDate]];
					//timeIntervalWeekTwo += entryTime;
                    endTime = [entry endDate];
                    startTime = beginningOfWeekFour;
				}
			}
			else 
			{
				entryTime = [beginningOfWeekThree timeIntervalSinceDate:[entry startDate]];
                endTime = beginningOfWeekThree;
                startTime = [entry startDate];
			}
			timeIntervalWeekFour += entryTime;
            
            // Fix any offset issues from daylight savings time
            // on the time spent doing an activity
            NSInteger startDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:startTime];
            NSInteger endDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:endTime];
            NSTimeInterval offsetForDaylightSavings = endDateTimeZoneOffset - startDateTimeZoneOffset;
            
            timeIntervalWeekFour += offsetForDaylightSavings;
		}

	}
	
	// Now calculate the hours and minutes to put into an array to return
	NSMutableArray *weekTimeData = [[NSMutableArray alloc] init];
	NSNumber *hours;
	int min;
	NSNumber *minutes;
	
	if ([[activity name] isEqualToString:@"Misc"]) 
	{
        timeThatPassed -= timeIntervalWeekOne;
        hours = [NSNumber numberWithInt:(int)(timeThatPassed/3600)];
        min = (timeThatPassed - ([hours intValue] * 3600))/60;
		//min %= 60;
		minutes = [NSNumber numberWithInt:min];
	}
	else 
	{
		hours = [NSNumber numberWithInt:(int)(timeIntervalWeekOne/3600)];
        min = (timeIntervalWeekOne - ([hours intValue] * 3600))/60;
		minutes = [NSNumber numberWithInt:min];
	}
	[weekTimeData addObject:hours];
	[weekTimeData addObject:minutes];
	[timedata addObject:weekTimeData];
	[weekTimeData release];
	[hours release];
	[minutes release];
	
	weekTimeData = [[NSMutableArray alloc] init];
	
	if ([[activity name] isEqualToString:@"Misc"]) 
	{
        //NSTimeInterval timeForWeekTwo = secondsPerWeek - timeIntervalWeekTwo;
        //hours = [NSNumber numberWithInt:168 - (int)((timeIntervalWeekTwo+30)/3600)];
		timeIntervalWeekTwo = secondsPerWeek - timeIntervalWeekTwo;
        hours = [NSNumber numberWithInt:(int)(timeIntervalWeekTwo/3600)];
        min = (timeIntervalWeekTwo - ([hours intValue] * 3600))/60;
		/*if (min != 0) 
		{
			min = 60 - min;
		}*/
		minutes = [NSNumber numberWithInt:min];
	}
	else 
	{
		hours = [NSNumber numberWithInt:(int)(timeIntervalWeekTwo/3600)];
        min = (timeIntervalWeekTwo - ([hours intValue] * 3600))/60;
		minutes = [NSNumber numberWithInt:min];
	}
	[weekTimeData addObject:hours];
	[weekTimeData addObject:minutes];
	[timedata addObject:weekTimeData];
	[weekTimeData release];
	
	weekTimeData = [[NSMutableArray alloc] init];
	if ([[activity name] isEqualToString:@"Misc"]) 
	{
		timeIntervalWeekThree = secondsPerWeek - timeIntervalWeekThree;
        hours = [NSNumber numberWithInt:(int)(timeIntervalWeekThree/3600)];
		min = (timeIntervalWeekThree - ([hours intValue] * 3600))/60;
        //min = round(timeIntervalWeekThree/60);
		//min %= 60;
		/*if (min != 0) 
		{
			min = 60 - min;
		}*/	
		minutes = [NSNumber numberWithInt:min];
	}
	else 
	{
		hours = [NSNumber numberWithInt:(int)(timeIntervalWeekThree/3600)];
        min = (timeIntervalWeekThree - ([hours intValue] * 3600))/60;
		minutes = [NSNumber numberWithInt:min];
	}
	[weekTimeData addObject:hours];
	[weekTimeData addObject:minutes];
	[timedata addObject:weekTimeData];
	[weekTimeData release];
	
	weekTimeData = [[NSMutableArray alloc] init];
	if ([[activity name] isEqualToString:@"Misc"]) 
	{
		timeIntervalWeekFour = secondsPerWeek - timeIntervalWeekFour;
        hours = [NSNumber numberWithInt:(int)(timeIntervalWeekFour/3600)];
		min = (timeIntervalWeekFour - ([hours intValue] * 3600))/60;
        //min = round(timeIntervalWeekFour/60);
		//min %= 60;
		/*if (min != 0) 
		{
			min = 60 - min;
		}*/	
		minutes = [NSNumber numberWithInt:min];
	}
	else 
	{
		hours = [NSNumber numberWithInt:(int)(timeIntervalWeekFour/3600)];
        min = (timeIntervalWeekFour - ([hours intValue] * 3600))/60;
		minutes = [NSNumber numberWithInt:min];
	}
	[weekTimeData addObject:hours];
	[weekTimeData addObject:minutes];
	[timedata addObject:weekTimeData];
	[weekTimeData release];

	return timedata;
}


#pragma mark -
#pragma mark Action Methods

- (IBAction)setWeekToShow:(id)sender
{
	int senderTag = (int)[sender tag];
	senderTag = senderTag/10;
	selectedWeek = senderTag;
    [self setTimeButtons];
	
	// Update the selectedEntries list and redraw the table
	[self setEntriesToShow];
    
    if ([dailyActivityData count] == 0) 
    {
        UITableView *tableView = (UITableView *)[[self view] viewWithTag:90];
        [tableView setHidden:1];
    }
    else
    {
        UITableView *tableView = (UITableView *)[[self view] viewWithTag:90];
        [tableView setHidden:0];

        tableView = (UITableView *)[[self view] viewWithTag:90];
        [tableView reloadData];
	}	
}

- (void)setEntriesToShow
{
	NSMutableArray *tempEntryList = [[NSMutableArray alloc] init];
	NSCalendar *curCalendar = [NSCalendar currentCalendar];
	NSDate *topDate, *bottomDate;
	NSDate *today = [[NSDate alloc] init]; 
    
	NSDate *beginningOfWeekOne = nil; 
	BOOL ok = [curCalendar rangeOfUnit:NSWeekCalendarUnit startDate:&beginningOfWeekOne interval:NULL forDate:today];
	if (!ok) 
	{
		NSLog(@"Some kind of error in setEntriesToShow");
	}
    
    
	// Now calculate the beginning of the past weeks 
	//NSTimeInterval secondsPerWeek = 7 * 24 * 60 * 60;
    NSTimeInterval secondsInADay  = 24 * 60 * 60;
    
    // Orlando
    NSDateComponents *dateOffset = [[[NSDateComponents alloc] init] autorelease];
    int daysInWeek = 7;
	
	if (selectedWeek == 1) 
	{
		//topDate = today;
        // Orlando
        [dateOffset setDay:daysInWeek];
        topDate = [curCalendar dateByAddingComponents:dateOffset toDate:beginningOfWeekOne options:0];
        unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSWeekdayCalendarUnit;
        NSDateComponents *dateComps = [curCalendar components:unitFlags fromDate:topDate];
        [dateComps setHour:0];
        [dateComps setMinute:0];
        [dateComps setSecond:0];
        topDate = [curCalendar dateFromComponents:dateComps];
        
		//bottomDate = beginningOfWeekOne;
        
        //Orlando
        dateComps = [curCalendar components:unitFlags fromDate:beginningOfWeekOne];
        [dateComps setHour:0];
        [dateComps setMinute:0];
        [dateComps setSecond:0];
        bottomDate = [curCalendar dateFromComponents:dateComps];
        
	}
	else 
	{
		//topDate = [beginningOfWeekOne dateByAddingTimeInterval:-(selectedWeek - 2)*secondsPerWeek];
		//bottomDate = [beginningOfWeekOne dateByAddingTimeInterval:-(selectedWeek - 1)*secondsPerWeek];
        
        // Orlando
        [dateOffset setDay:-daysInWeek*(selectedWeek - 2)];
        topDate = [curCalendar dateByAddingComponents:dateOffset toDate:beginningOfWeekOne options:0];
        unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSWeekdayCalendarUnit;
        NSDateComponents *dateComps = [curCalendar components:unitFlags fromDate:topDate];
        [dateComps setHour:0];
        [dateComps setMinute:0];
        [dateComps setSecond:0];
        topDate = [curCalendar dateFromComponents:dateComps];
        
        [dateOffset setDay:-daysInWeek*(selectedWeek - 1)];
        bottomDate = [curCalendar dateByAddingComponents:dateOffset toDate:beginningOfWeekOne options:0];
        dateComps = [curCalendar components:unitFlags fromDate:bottomDate];
        [dateComps setHour:0];
        [dateComps setMinute:0];
        [dateComps setSecond:0];
        bottomDate = [curCalendar dateFromComponents:dateComps];
        
	}
	
    // First we get just the activities in this week
    for (Entry *entry in entries)
    {
		// Check against selected week
        if (([topDate compare:[entry startDate]] == NSOrderedDescending && ([[entry startDate] compare:bottomDate] == NSOrderedDescending || [[entry endDate] compare:bottomDate] == NSOrderedDescending)) || (![entry endDate] && selectedWeek == 1))
        {
            [tempEntryList addObject:entry];
        }
    }
    
    selectedEntries = tempEntryList;
    
    // Set up the array to hold how much time was spent doing it each day
    NSTimeInterval sundayTime=0;
    NSTimeInterval mondayTime=0;
    NSTimeInterval tuesdayTime=0;
    NSTimeInterval wednesdayTime=0;
    NSTimeInterval thursdayTime=0;
    NSTimeInterval fridayTime=0;
    NSTimeInterval saturdayTime=0;
    NSDate *bottomDay, *topDay, *startTime, *endTime;
    
    for (Entry *entry in selectedEntries) 
    {        
        NSDate *entryEnds;
        // This is to account for entries that are still running
        if (![entry endDate]) 
        {
            entryEnds = today;
        }
        else
            entryEnds = [entry endDate];
        
        bottomDay = bottomDate;
        
        for(int i=1; i < 8; i++)
        {
            [dateOffset setDay:1];
            topDay = [curCalendar dateByAddingComponents:dateOffset toDate:bottomDay options:0];
            unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSWeekdayCalendarUnit;
            NSDateComponents *dateComps = [curCalendar components:unitFlags fromDate:topDay];
            [dateComps setHour:0];
            [dateComps setMinute:0];
            [dateComps setSecond:0];
            topDay = [curCalendar dateFromComponents:dateComps];
            
            
            if ([topDay compare:[entry startDate] ] == NSOrderedDescending && [bottomDay compare:entryEnds] != NSOrderedDescending) 
            {
                if ([bottomDay compare:[entry startDate]] == NSOrderedDescending ) 
                    startTime = bottomDay;
                else
                    startTime = [entry startDate];
                
                if ([entryEnds compare:topDay] == NSOrderedDescending) 
                    endTime = topDay;
                else
                    endTime = entryEnds;
            
            // Have some insane nested if statements...I'm sure there is a better way to do this
            // figure out what day to add the entry time to
            //NSTimeInterval tempTime = [endTime timeIntervalSinceDate:startTime];
            if (i == 1) 
            {
                sundayTime += [endTime timeIntervalSinceDate:startTime];
                // Fix any offset issues from daylight savings time
                // on the time spent doing an activity
                NSInteger startDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:startTime];
                NSInteger endDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:endTime];
                NSTimeInterval offsetForDaylightSavings = endDateTimeZoneOffset - startDateTimeZoneOffset;
                sundayTime += offsetForDaylightSavings;
                // Orlando - do this for all of the other ones below as well

            }
            else
            {
                if (i == 2) 
                {
                    mondayTime += [endTime timeIntervalSinceDate:startTime];
                    // Fix any offset issues from daylight savings time
                    // on the time spent doing an activity
                    NSInteger startDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:startTime];
                    NSInteger endDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:endTime];
                    NSTimeInterval offsetForDaylightSavings = endDateTimeZoneOffset - startDateTimeZoneOffset;
                    mondayTime += offsetForDaylightSavings;
                }
                else
                {
                    if (i == 3) 
                    {
                        tuesdayTime += [endTime timeIntervalSinceDate:startTime];
                        // Fix any offset issues from daylight savings time
                        // on the time spent doing an activity
                        NSInteger startDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:startTime];
                        NSInteger endDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:endTime];
                        NSTimeInterval offsetForDaylightSavings = endDateTimeZoneOffset - startDateTimeZoneOffset;
                        tuesdayTime += offsetForDaylightSavings;
                    }
                    else
                    {
                        if (i == 4) 
                        {
                            wednesdayTime += [endTime timeIntervalSinceDate:startTime];
                            // Fix any offset issues from daylight savings time
                            // on the time spent doing an activity
                            NSInteger startDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:startTime];
                            NSInteger endDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:endTime];
                            NSTimeInterval offsetForDaylightSavings = endDateTimeZoneOffset - startDateTimeZoneOffset;
                            wednesdayTime += offsetForDaylightSavings;
                        }
                        else
                        {
                            if (i == 5) 
                            {
                                thursdayTime += [endTime timeIntervalSinceDate:startTime];
                                // Fix any offset issues from daylight savings time
                                // on the time spent doing an activity
                                NSInteger startDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:startTime];
                                NSInteger endDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:endTime];
                                NSTimeInterval offsetForDaylightSavings = endDateTimeZoneOffset - startDateTimeZoneOffset;
                                thursdayTime += offsetForDaylightSavings;
                            }
                            else
                            {
                                if (i == 6) 
                                {
                                    fridayTime += [endTime timeIntervalSinceDate:startTime];
                                    // Fix any offset issues from daylight savings time
                                    // on the time spent doing an activity
                                    NSInteger startDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:startTime];
                                    NSInteger endDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:endTime];
                                    NSTimeInterval offsetForDaylightSavings = endDateTimeZoneOffset - startDateTimeZoneOffset;
                                    fridayTime += offsetForDaylightSavings;
                                }
                                else
                                {
                                    saturdayTime += [endTime timeIntervalSinceDate:startTime];
                                    // Fix any offset issues from daylight savings time
                                    // on the time spent doing an activity
                                    NSInteger startDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:startTime];
                                    NSInteger endDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:endTime];
                                    NSTimeInterval offsetForDaylightSavings = endDateTimeZoneOffset - startDateTimeZoneOffset;
                                    saturdayTime += offsetForDaylightSavings;
                                }
                            }
                        }
                    }
                }
            }
                
            }
            bottomDay = [curCalendar dateByAddingComponents:dateOffset toDate:bottomDay options:0];
            dateComps = [curCalendar components:unitFlags fromDate:bottomDay];
            [dateComps setHour:0];
            [dateComps setMinute:0];
            [dateComps setSecond:0];
            bottomDay = [curCalendar dateFromComponents:dateComps];
            
        }
    }
    
    // Now go through and come up with the strings for time spent each day
    // and fill in the weeksEntries array
    //NSDateFormatter *date = [[[NSDateFormatter alloc] init] autorelease]; 
	//[date setDateFormat:@"EE, MM/dd"];
	//NSString *stringDate;
    
    NSMutableArray *dayEntry = [[NSMutableArray alloc] init];
    NSMutableArray *weeksEntries = [[NSMutableArray alloc] init];
    NSNumber *hours;
	int min;
	NSNumber *minutes;
	
	// Sunday
    // This block puts the day names in the array
    // adds the name of the day to the day entry
    //stringDate = [date stringFromDate:bottomDate];    
    //NSTimeInterval timeThatPassed = [today timeIntervalSinceDate:beginningOfWeekOne];

    // Orlando
    if ([[activity name] isEqualToString:@"Misc"]) 
	{
        if (([today compare:bottomDate] == NSOrderedDescending && [today compare:[bottomDate dateByAddingTimeInterval:secondsInADay]] == NSOrderedDescending) || ([today compare:bottomDate] == NSOrderedDescending && [today compare:[bottomDate dateByAddingTimeInterval:secondsInADay]] == NSOrderedAscending)) 
        {
            if ([today compare:bottomDate] == NSOrderedDescending && [today compare:[bottomDate dateByAddingTimeInterval:secondsInADay]] == NSOrderedAscending) 
            {
                NSTimeInterval timeThatPassedToday = [today timeIntervalSinceDate:bottomDate];
                // Check if there is a GMT offset delta from daylight savings time
                // And correct it if necessary
                
                NSInteger startDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:bottomDate];
                NSInteger endDateTimeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:today];
                NSTimeInterval offsetForDaylightSavings = endDateTimeZoneOffset - startDateTimeZoneOffset;
                timeThatPassedToday = timeThatPassedToday + offsetForDaylightSavings;
                
                sundayTime = timeThatPassedToday - sundayTime;
            }
            else
            {
                sundayTime = secondsInADay - sundayTime;
            }
            // Orlando
            //NSLog(@"This entry: %@ - %@", [entry startDate],[entry endDate]);
            //NSLog(@" ");
            
            hours = [NSNumber numberWithInt:(int)(sundayTime/3600)];
            min = (sundayTime - ([hours intValue] * 3600))/60;
            
            //min %= 60;
            minutes = [NSNumber numberWithInt:min];
        }
        else
        {   
            hours = [NSNumber numberWithInt:0];
            minutes = [NSNumber numberWithInt:0];
        }
	}
	else 
	{
		hours = [NSNumber numberWithInt:(int)(sundayTime/3600)];
        min = (sundayTime - ([hours intValue] * 3600))/60;
		minutes = [NSNumber numberWithInt:min];
	}
    
    if (sundayTime !=0) 
    {
        [dayEntry addObject:bottomDate];
        [dayEntry addObject:hours];
        [dayEntry addObject:minutes];
        [weeksEntries addObject:dayEntry];
        
        [dayEntry release];
        dayEntry = [[NSMutableArray alloc] init];
        //[hours release];
        hours = [[NSNumber alloc] init];
        //[minutes release];
        minutes = [[NSNumber alloc] init]; 
    }
    
    
    // Monday
    // This block puts the day names in the array
    // adds the name of the day to the day entry
    //bottomDate = [bottomDate dateByAddingTimeInterval:secondsInADay];
    
    // Orlando
    [dateOffset setDay:1];
    bottomDate = [curCalendar dateByAddingComponents:dateOffset toDate:bottomDate options:0];
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSWeekdayCalendarUnit;
    NSDateComponents *dateComps = [curCalendar components:unitFlags fromDate:bottomDate];
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0];
    bottomDate = [curCalendar dateFromComponents:dateComps];
    
    
    if ([[activity name] isEqualToString:@"Misc"]) 
	{
        if (([today compare:bottomDate] == NSOrderedDescending && [today compare:[bottomDate dateByAddingTimeInterval:secondsInADay]] == NSOrderedDescending) || ([today compare:bottomDate] == NSOrderedDescending && [today compare:[bottomDate dateByAddingTimeInterval:secondsInADay]] == NSOrderedAscending))  
        {
            if ([today compare:bottomDate] == NSOrderedDescending && [today compare:[bottomDate dateByAddingTimeInterval:secondsInADay]] == NSOrderedAscending) 
            {
                NSTimeInterval timeThatPassedToday = [today timeIntervalSinceDate:bottomDate];
                mondayTime = timeThatPassedToday - mondayTime;
            }
            else
            {
                mondayTime = secondsInADay - mondayTime;
            }
            hours = [NSNumber numberWithInt:(int)(mondayTime/3600)];
            min = (mondayTime - ([hours intValue] * 3600))/60;
            //min %= 60;
            minutes = [NSNumber numberWithInt:min];
        }
        else
        {   
            hours = [NSNumber numberWithInt:0];
            minutes = [NSNumber numberWithInt:0];
        }
	}
	else 
	{
		hours = [NSNumber numberWithInt:(int)(mondayTime/3600)];
        min = (mondayTime - ([hours intValue] * 3600))/60;
		minutes = [NSNumber numberWithInt:min];
	}
    
    if (mondayTime !=0) 
    {        
        [dayEntry addObject:bottomDate];
        [dayEntry addObject:hours];
        [dayEntry addObject:minutes];
        [weeksEntries addObject:dayEntry];
        
        [dayEntry release];
        dayEntry = [[NSMutableArray alloc] init];
        //[hours release];
        hours = [[NSNumber alloc] init];
        //[minutes release];
        minutes = [[NSNumber alloc] init]; 
    }
    
    // Tuesday
    // This block puts the day names in the array
    // adds the name of the day to the day entry
    //bottomDate = [bottomDate dateByAddingTimeInterval:secondsInADay];
    
    // Orlando
    [dateOffset setDay:1];
    bottomDate = [curCalendar dateByAddingComponents:dateOffset toDate:bottomDate options:0];
    dateComps = [curCalendar components:unitFlags fromDate:bottomDate];
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0];
    bottomDate = [curCalendar dateFromComponents:dateComps];
    
    if ([[activity name] isEqualToString:@"Misc"]) 
	{
        if (([today compare:bottomDate] == NSOrderedDescending && [today compare:[bottomDate dateByAddingTimeInterval:secondsInADay]] == NSOrderedDescending) || ([today compare:bottomDate] == NSOrderedDescending && [today compare:[bottomDate dateByAddingTimeInterval:secondsInADay]] == NSOrderedAscending))  
        {
            if ([today compare:bottomDate] == NSOrderedDescending && [today compare:[bottomDate dateByAddingTimeInterval:secondsInADay]] == NSOrderedAscending) 
            {
                NSTimeInterval timeThatPassedToday = [today timeIntervalSinceDate:bottomDate];
                tuesdayTime = timeThatPassedToday - tuesdayTime;
            }
            else
            {
                tuesdayTime = secondsInADay - tuesdayTime;
            }
            hours = [NSNumber numberWithInt:(int)(tuesdayTime/3600)];
            min = (tuesdayTime - ([hours intValue] * 3600))/60;
            //min %= 60;
            minutes = [NSNumber numberWithInt:min];
        }
        else
        {   
            hours = [NSNumber numberWithInt:0];
            minutes = [NSNumber numberWithInt:0];
        }
	}
	else 
	{
		hours = [NSNumber numberWithInt:(int)(tuesdayTime/3600)];
        min = (tuesdayTime - ([hours intValue] * 3600))/60;
		minutes = [NSNumber numberWithInt:min];
	}
	
    if (tuesdayTime !=0) 
    {
        [dayEntry addObject:bottomDate];
        [dayEntry addObject:hours];
        [dayEntry addObject:minutes];
        [weeksEntries addObject:dayEntry];
        
        [dayEntry release];
        dayEntry = [[NSMutableArray alloc] init];
        //[hours release];
        hours = [[NSNumber alloc] init];
        //[minutes release];
        minutes = [[NSNumber alloc] init]; 
    }
    
    // Wednesday
    // This block puts the day names in the array
    // adds the name of the day to the day entry
    //bottomDate = [bottomDate dateByAddingTimeInterval:secondsInADay];
    
    // Orlando
    [dateOffset setDay:1];
    bottomDate = [curCalendar dateByAddingComponents:dateOffset toDate:bottomDate options:0];
    dateComps = [curCalendar components:unitFlags fromDate:bottomDate];
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0];
    bottomDate = [curCalendar dateFromComponents:dateComps];
    
    if ([[activity name] isEqualToString:@"Misc"]) 
	{
        if (([today compare:bottomDate] == NSOrderedDescending && [today compare:[bottomDate dateByAddingTimeInterval:secondsInADay]] == NSOrderedDescending) || ([today compare:bottomDate] == NSOrderedDescending && [today compare:[bottomDate dateByAddingTimeInterval:secondsInADay]] == NSOrderedAscending))  
        {
            if ([today compare:bottomDate] == NSOrderedDescending && [today compare:[bottomDate dateByAddingTimeInterval:secondsInADay]] == NSOrderedAscending) 
            {
                NSTimeInterval timeThatPassedToday = [today timeIntervalSinceDate:bottomDate];
                wednesdayTime = timeThatPassedToday - wednesdayTime;
            }
            else
            {
                wednesdayTime = secondsInADay - wednesdayTime;
            }
            hours = [NSNumber numberWithInt:(int)(wednesdayTime/3600)];
            min = (wednesdayTime - ([hours intValue] * 3600))/60;
            //min %= 60;
            minutes = [NSNumber numberWithInt:min];
        }
        else
        {   
            hours = [NSNumber numberWithInt:0];
            minutes = [NSNumber numberWithInt:0];
        }
	}
	else 
	{
		hours = [NSNumber numberWithInt:(int)(wednesdayTime/3600)];
        min = (wednesdayTime - ([hours intValue] * 3600))/60;
		minutes = [NSNumber numberWithInt:min];
	}
	
    if (wednesdayTime !=0) 
    {
        [dayEntry addObject:bottomDate];
        [dayEntry addObject:hours];
        [dayEntry addObject:minutes];
        [weeksEntries addObject:dayEntry];
        
        [dayEntry release];
        dayEntry = [[NSMutableArray alloc] init];
        //[hours release];
        hours = [[NSNumber alloc] init];
        //[minutes release];
        minutes = [[NSNumber alloc] init]; 
    }
    
    // Thursday
    // This block puts the day names in the array
    // adds the name of the day to the day entry
    // bottomDate = [bottomDate dateByAddingTimeInterval:secondsInADay];
    
    // Orlando
    [dateOffset setDay:1];
    bottomDate = [curCalendar dateByAddingComponents:dateOffset toDate:bottomDate options:0];
    dateComps = [curCalendar components:unitFlags fromDate:bottomDate];
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0];
    bottomDate = [curCalendar dateFromComponents:dateComps];

    
    if ([[activity name] isEqualToString:@"Misc"]) 
	{
        if (([today compare:bottomDate] == NSOrderedDescending && [today compare:[bottomDate dateByAddingTimeInterval:secondsInADay]] == NSOrderedDescending) || ([today compare:bottomDate] == NSOrderedDescending && [today compare:[bottomDate dateByAddingTimeInterval:secondsInADay]] == NSOrderedAscending))  
        {
            if ([today compare:bottomDate] == NSOrderedDescending && [today compare:[bottomDate dateByAddingTimeInterval:secondsInADay]] == NSOrderedAscending) 
            {
                NSTimeInterval timeThatPassedToday = [today timeIntervalSinceDate:bottomDate];
                thursdayTime = timeThatPassedToday - thursdayTime;
            }
            else
            {
                thursdayTime = secondsInADay - thursdayTime;
            }
            hours = [NSNumber numberWithInt:(int)(thursdayTime/3600)];
            min = (thursdayTime - ([hours intValue] * 3600))/60;
            //min %= 60;
            minutes = [NSNumber numberWithInt:min];
        }
        else
        {   
            hours = [NSNumber numberWithInt:0];
            minutes = [NSNumber numberWithInt:0];
        }
	}
	else 
	{
		hours = [NSNumber numberWithInt:(int)(thursdayTime/3600)];
        min = (thursdayTime - ([hours intValue] * 3600))/60;
		minutes = [NSNumber numberWithInt:min];
	}
	
    if (thursdayTime !=0) 
    {
        [dayEntry addObject:bottomDate];
        [dayEntry addObject:hours];
        [dayEntry addObject:minutes];
        [weeksEntries addObject:dayEntry];
        
        [dayEntry release];
        dayEntry = [[NSMutableArray alloc] init];
        //[hours release];
        hours = [[NSNumber alloc] init];
        //[minutes release];
        minutes = [[NSNumber alloc] init]; 
    }
    
    // Friday
    // This block puts the day names in the array
    // adds the name of the day to the day entry
    // bottomDate = [bottomDate dateByAddingTimeInterval:secondsInADay];
    
    // Orlando
    [dateOffset setDay:1];
    bottomDate = [curCalendar dateByAddingComponents:dateOffset toDate:bottomDate options:0];
    dateComps = [curCalendar components:unitFlags fromDate:bottomDate];
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0];
    bottomDate = [curCalendar dateFromComponents:dateComps];
    
    if ([[activity name] isEqualToString:@"Misc"]) 
	{
        if (([today compare:bottomDate] == NSOrderedDescending && [today compare:[bottomDate dateByAddingTimeInterval:secondsInADay]] == NSOrderedDescending) || ([today compare:bottomDate] == NSOrderedDescending && [today compare:[bottomDate dateByAddingTimeInterval:secondsInADay]] == NSOrderedAscending))  
        {
            if ([today compare:bottomDate] == NSOrderedDescending && [today compare:[bottomDate dateByAddingTimeInterval:secondsInADay]] == NSOrderedAscending) 
            {
                NSTimeInterval timeThatPassedToday = [today timeIntervalSinceDate:bottomDate];
                fridayTime = timeThatPassedToday - fridayTime;
            }
            else
            {
                fridayTime = secondsInADay - fridayTime;
            }
            hours = [NSNumber numberWithInt:(int)(fridayTime/3600)];
            min = (fridayTime - ([hours intValue] * 3600))/60;
            //min %= 60;
            minutes = [NSNumber numberWithInt:min];
        }
        else
        {   
            hours = [NSNumber numberWithInt:0];
            minutes = [NSNumber numberWithInt:0];
        }
	}
	else 
	{
		hours = [NSNumber numberWithInt:(int)(fridayTime/3600)];
        min = (fridayTime - ([hours intValue] * 3600))/60;
		minutes = [NSNumber numberWithInt:min];
	}
	
    if (fridayTime !=0) 
    {
        [dayEntry addObject:bottomDate];
        [dayEntry addObject:hours];
        [dayEntry addObject:minutes];
        [weeksEntries addObject:dayEntry];
        
        [dayEntry release];
        dayEntry = [[NSMutableArray alloc] init];
        //[hours release];
        hours = [[NSNumber alloc] init];
        //[minutes release];
        minutes = [[NSNumber alloc] init]; 
    }
    
    // Saturday
    // This block puts the day names in the array
    // adds the name of the day to the day entry
    //bottomDate = [bottomDate dateByAddingTimeInterval:secondsInADay];
    
    // Orlando
    [dateOffset setDay:1];
    bottomDate = [curCalendar dateByAddingComponents:dateOffset toDate:bottomDate options:0];
    dateComps = [curCalendar components:unitFlags fromDate:bottomDate];
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0];
    bottomDate = [curCalendar dateFromComponents:dateComps];

    
    if ([[activity name] isEqualToString:@"Misc"]) 
	{
        if (([today compare:bottomDate] == NSOrderedDescending && [today compare:[bottomDate dateByAddingTimeInterval:secondsInADay]] == NSOrderedDescending) || ([today compare:bottomDate] == NSOrderedDescending && [today compare:[bottomDate dateByAddingTimeInterval:secondsInADay]] == NSOrderedAscending))  
        {
            if ([today compare:bottomDate] == NSOrderedDescending && [today compare:[bottomDate dateByAddingTimeInterval:secondsInADay]] == NSOrderedAscending) 
            {
                NSTimeInterval timeThatPassedToday = [today timeIntervalSinceDate:bottomDate];
                saturdayTime = timeThatPassedToday - saturdayTime;
            }
            else
            {
                saturdayTime = secondsInADay - saturdayTime;
            }
            hours = [NSNumber numberWithInt:(int)(saturdayTime/3600)];
            min = (saturdayTime - ([hours intValue] * 3600))/60;
            //min %= 60;
            minutes = [NSNumber numberWithInt:min];
        }
        else
        {   
            hours = [NSNumber numberWithInt:0];
            minutes = [NSNumber numberWithInt:0];
        }
	}
	else 
	{
		hours = [NSNumber numberWithInt:(int)(saturdayTime/3600)];
        min = (saturdayTime - ([hours intValue] * 3600))/60;
		minutes = [NSNumber numberWithInt:min];
	}
    
    if (saturdayTime !=0) 
    {
        [dayEntry addObject:bottomDate];
        [dayEntry addObject:hours];
        [dayEntry addObject:minutes];
        [weeksEntries addObject:dayEntry];
        
        [dayEntry release];
        dayEntry = [[NSMutableArray alloc] init];
        //[hours release];
        hours = [[NSNumber alloc] init];
        //[minutes release];
        minutes = [[NSNumber alloc] init]; 
    }
	    
	dailyActivityData = weeksEntries;
}

- (void)setTimeButtons
{
	NSMutableArray *timeData = [self timeSpentDoingActivity];
    int i = selectedWeek; 
	//for (int i=1; i<5; i++)
	//{
    NSMutableArray *weekTimeData = [timeData objectAtIndex:i-1];
    NSNumber *hours = [weekTimeData objectAtIndex:0];
    NSNumber *minutes = [weekTimeData objectAtIndex:1];
    //UIButton *hourText = (UIButton *)[[self view] viewWithTag:i*10+2];
    //UIButton *minuteText = (UIButton *)[[self view] viewWithTag:i*10+3];
    UIButton *hourText = (UIButton *)[[self view] viewWithTag:12];
    UIButton *minuteText = (UIButton *)[[self view] viewWithTag:13];
    [hourText setHidden:0];
    [minuteText setHidden:0];
    
    if ([hours intValue]) 
    {
        [hourText setTitle:[NSString stringWithFormat:@"%ih",[hours intValue]] forState:UIControlStateNormal];
        //NSLog(@"Hours = %i", [hours intValue]);
    }
    else 
    {
        [hourText setTitle:@"" forState:UIControlStateNormal];
    }

    if ([minutes intValue]) 
    {			
        [minuteText setTitle:[NSString stringWithFormat:@"%im",[minutes intValue]] forState:UIControlStateNormal];
        //NSLog(@"Minutes = %i", [minutes intValue]);
    }
    else 
    {
        [minuteText setTitle:@"" forState:UIControlStateNormal];
    }
		
	//}
    
    // ********************* This part sets the week label at the top *****
    NSCalendar *curCalendar = [NSCalendar currentCalendar];
	NSDate *topDate, *bottomDate;
	NSDate *today = [[NSDate alloc] init]; 
	NSDate *beginningOfWeekOne = nil; 
	BOOL ok = [curCalendar rangeOfUnit:NSWeekCalendarUnit startDate:&beginningOfWeekOne interval:NULL forDate:today];
	if (!ok) 
	{
		NSLog(@"Some kind of error in setTimeButtons");
	}
	
	// Now calculate the beginning of the past weeks 
	//NSTimeInterval secondsPerWeek = 7 * 24 * 60 * 60;
    //NSTimeInterval secondsInADay = 24 * 60 * 60;
    NSDateComponents *dateOffset = [[[NSDateComponents alloc] init] autorelease];
    int daysInWeek = 7;
	
	if (selectedWeek == 1) 
	{
		//topDate = [beginningOfWeekOne dateByAddingTimeInterval:secondsPerWeek];
        [dateOffset setDay:daysInWeek];
        topDate = [curCalendar dateByAddingComponents:dateOffset toDate:beginningOfWeekOne options:0];
        NSCalendar *curCalendar = [NSCalendar currentCalendar];
        unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSWeekdayCalendarUnit;
        NSDateComponents *dateComps = [curCalendar components:unitFlags fromDate:topDate];
        [dateComps setHour:0];
        [dateComps setMinute:0];
        [dateComps setSecond:0];
        topDate = [curCalendar dateFromComponents:dateComps];
        
		bottomDate = beginningOfWeekOne;
	}
	else 
	{
		//topDate = [beginningOfWeekOne dateByAddingTimeInterval:-(selectedWeek - 2)*secondsPerWeek];
        [dateOffset setDay:-daysInWeek*(selectedWeek - 2)];
        topDate = [curCalendar dateByAddingComponents:dateOffset toDate:beginningOfWeekOne options:0];
        
        
		//bottomDate = [beginningOfWeekOne dateByAddingTimeInterval:-(selectedWeek - 1)*secondsPerWeek];
        [dateOffset setDay:-daysInWeek*(selectedWeek - 1)];
        bottomDate = [curCalendar dateByAddingComponents:dateOffset toDate:beginningOfWeekOne options:0];
	}
    
    //topDate = [topDate dateByAddingTimeInterval:-secondsInADay];
    [dateOffset setDay:-1];
    topDate = [curCalendar dateByAddingComponents:dateOffset toDate:topDate options:0];
    NSDateFormatter *date = [[[NSDateFormatter alloc] init] autorelease]; 
	[date setDateFormat:@"MM/dd/yy"];
	NSString *stringDateTop = [date stringFromDate:topDate];
    NSString *stringDateBottom = [date stringFromDate:bottomDate];
    
    [weekLabel setText:[NSString stringWithFormat:@"%@ - %@",stringDateBottom,stringDateTop]];

}

#pragma mark -
#pragma mark Activity Rename Methods

- (IBAction)renameActivity:(id)sender;
{
	if (![[activity name] isEqualToString:@"Misc"]) 
    {
        renameActivityView = [[RenameActivityView alloc] init];
        [renameActivityView setActivityName:[activity name]];
        [[self navigationController] pushViewController:renameActivityView animated:YES];
    }
}

#pragma mark -
#pragma mark Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [dailyActivityData count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //static NSString *CellIdentifier = @"Cell";
	static NSString *CellIdentifier = @"EntryCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
	{
        //cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		[[NSBundle mainBundle] loadNibNamed:@"ActivityDetailViewCell" owner:self options:nil];
		cell = entryCell;
	}
    
    // Configure the cell...
	
	NSMutableArray *entry = [dailyActivityData objectAtIndex:[indexPath row]];

	UILabel *entryDate;
	entryDate = (UILabel *)[cell viewWithTag:1];
	UILabel *entryHours;
	entryHours = (UILabel *)[cell viewWithTag:3];
	
	UILabel *entryMinutes;
	entryMinutes = (UILabel *)[cell viewWithTag:4];
	[entryHours setTextColor:[UIColor blackColor]];
	[entryMinutes setTextColor:[UIColor blackColor]];
	
    // Figure out what the beginning of today is
    NSDate *today = [[NSDate alloc] init];
    NSCalendar *curCalendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSWeekdayCalendarUnit;
    NSDateComponents *dateComps = [curCalendar components:unitFlags fromDate:today];
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0];
    NSDate *startOfToday = [curCalendar dateFromComponents:dateComps];

    
    NSDateFormatter *date = [[[NSDateFormatter alloc] init] autorelease]; 
	[date setDateFormat:@"EE, MM/dd"];
    NSDate *rowDay = [entry objectAtIndex:0];
    if ([rowDay compare:startOfToday] == NSOrderedSame) 
        [entryDate setTextColor:[UIColor orangeColor]];
    [entryDate setText:[date stringFromDate:rowDay]];
	    
	// Set the time spent doing the activity each day
	NSNumber *hours = [entry objectAtIndex:1];
	NSNumber *minutes = [entry objectAtIndex:2];
	
	if ([hours intValue]) 
	{
		[entryHours setText:[NSString stringWithFormat:@"%ih",[hours intValue]]];
	}
	else 
	{
		[entryHours setText:@""];
	}
	
	
	if ([minutes intValue]) 
	{
		[entryMinutes setText:[NSString stringWithFormat:@"%im",[minutes intValue]]];
	}
	else 
	{
        if ([hours intValue] == 0) 
            [entryMinutes setText:@"<1m"];
        else
            [entryMinutes setText:@""];
	}
		
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
	
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath 
{
	// Return NO if you do not want the specified item to be editable.
    return NO;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{	
    entryDetailView = [[EntryDetailView alloc] init];
    [entryDetailView setActivity:activity];
    
    // Pass a reversed copy of selectedEntries
    // To put the latest entry at the bottom of the table
    // Reverse the order of the array
    NSMutableArray *selectedEntriesCopy = selectedEntries;
    int i=0;
    int j=[selectedEntriesCopy count] - 1;
    while (i < j) 
    {
        [selectedEntriesCopy exchangeObjectAtIndex:i withObjectAtIndex:j];
        i++;
        j--;
    }
    
    [entryDetailView setEntries:selectedEntriesCopy];
    
    // Pass the selected day
    [entryDetailView setSelectedDay:[[dailyActivityData objectAtIndex:[indexPath row]] objectAtIndex:0]];
	[[self navigationController] pushViewController:entryDetailView animated:YES];
	//[entryDetailView release];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Days";
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:3] setHidden:1];
    [[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:4] setHidden:1];
    self.navigationItem.rightBarButtonItem = Nil;
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
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	[activityTitle release];
    [weekLabel release];
    [weekOneHours release];
    [weekOneMinutes release];
	
	activityTitle = nil;
    weekLabel = nil;
    weekOneHours = nil;
    weekOneMinutes = nil;
	
	[super viewDidUnload];
}


- (void)dealloc 
{
	// View stuff
	[activityTitle release];
    [weekLabel release];
    [weekOneHours release];
    [weekOneMinutes release];
	
	// Other variables
	[activity release];
	[entries release];
	
	[super dealloc];
}


@end
