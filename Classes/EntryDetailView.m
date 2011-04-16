//
//  EntryDetailView.m
//  168 Hours
//
//  Created by Orlando O'Neill on 3/3/11.
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

#import "EntryDetailView.h"
#import "TimeTrackerAppDelegate.h"
#import "ActivityDetailViewController.h"
#import "RenameActivityView.h"
#import "ChangeActivityTimeView.h"
#import "Activity.h"
#import	"Entry.h"
#import "General.h"
#import "ActivityViewController.h"

@implementation EntryDetailView

@synthesize activity, entries, entryCell, selectedDay, deletedAnEntry;

#pragma mark -
#pragma mark Init Methods

// Declare custom init method
- (id)init
{
	[super initWithNibName:nil bundle:nil];
	//[self setButtonDisplay:[NSNumber numberWithInt:1]];
    miscEntries = [[NSMutableArray alloc] init];
    deletedAnEntry = [NSNumber numberWithInt:0];
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
    [self setTitle:@"Entry Info"];
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
    
    // Hide the cumulative time at the top until it has been recalculated
    UIButton *hourText = (UIButton *)[[self view] viewWithTag:12];
    UIButton *minuteText = (UIButton *)[[self view] viewWithTag:13];
    [hourText setHidden:1];
    [minuteText setHidden:1];
}


- (void)viewDidAppear:(BOOL)animated
{
	UIButton *renameButton = (UIButton *)[[self view] viewWithTag:1774];
    [renameButton setHidden:0];
    int returnedFromChangeActViewWithNoChanges = 0;
    
    //[self setTitle:@"Activity Info"];
	UITableView *tableView = (UITableView *)[[self view] viewWithTag:90];
	//[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
	
	// Check if user changed time of an entry
	if (changeActivityTimeView)
	{
		NSTimeInterval newEntryTime = [changeActivityTimeView newEntryTime];
		TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
        ActivityViewController *activityView = [ActivityViewController sharedActivityViewController];
        Entry *selectedEntry = [changeActivityTimeView selectedEntry];
        Entry *originalEntry = [changeActivityTimeView selectedEntry];
        
        // If the user changed the entry time and it isn't a MISC entry, then make it so
        //if (newEntryTime != (float)0 && ![changeActivityTimeView newActivityForEntry]) 
        if (newEntryTime != (float)0 && ![[activity name] isEqualToString:@"Misc"] && [[[changeActivityTimeView newActivityForEntry] name] isEqualToString:[activity name]])
		{
            NSDate *newEndDate = [NSDate dateWithTimeInterval:newEntryTime sinceDate:[selectedEntry startDate]];
			[selectedEntry setEndDate:newEndDate];
            
			//NSLog(@"New end date = %@",newEndDate);
			// Save the change to the persistent store
			[appDelegate saveContext];
			
			// Update the list of entries in main view so that TimeSpentDoingActivity will work
			[activityView updateEntries];
			[[activityView sharedTableView] reloadData];
			
			//UITableView *tableView = (UITableView *)[[self view] viewWithTag:90];
			//[tableView reloadData];
		}
        
        // If there is a value for newActivityForEntry
        // And it isn't equal to Misc, so it has been changed,
        // Then recategorize this slice of time under the new activity
        if ([changeActivityTimeView newActivityForEntry] && ![[[changeActivityTimeView newActivityForEntry] name] isEqualToString:[activity name]]) 
        {
            if (newEntryTime != (float)0) 
            {
                NSDate *newEndDate = [NSDate dateWithTimeInterval:newEntryTime sinceDate:[selectedEntry startDate]];
                [selectedEntry setEndDate:newEndDate];
            }
            [selectedEntry setActivity:[changeActivityTimeView newActivityForEntry]];
            
            [appDelegate saveContext];
			
			// Update the list of entries in main view so that TimeSpentDoingActivity will work
			[activityView updateEntries];
			[[activityView sharedTableView] reloadData];
            
            // Remove the entry from miscEntries array if this is a Misc item
            if (![[activity name] isEqualToString:@"Misc"])
            {
                [selectedEntries removeObject:originalEntry];
                [entries removeObject:originalEntry];
                
                if (![deletedAnEntry intValue]) 
                    deletedAnEntry = [NSNumber numberWithInt:1];
            }
            else
            {
                [miscEntries removeObject:originalEntry];
                [selectedEntries removeObject:originalEntry];
            
                // And now update entries so that it includes the newly recategorized one
                NSArray *allTheEntries = [appDelegate allInstancesOf:@"Entry"];
                        
                // Pass a reversed copy of selectedEntries
                // To put the latest entry at the bottom of the table
                // Reverse the order of the array
                NSMutableArray *allTheEntriesCopy = [allTheEntries mutableCopy];
                int i=0;
                int j=[allTheEntriesCopy count] - 1;
                while (i < j) 
                {
                    [allTheEntriesCopy exchangeObjectAtIndex:i withObjectAtIndex:j];
                    i++;
                    j--;
                }
            
                entries = [allTheEntriesCopy mutableCopy];
                [allTheEntriesCopy release];
            
                if (![deletedAnEntry intValue]) 
                    deletedAnEntry = [NSNumber numberWithInt:1];
                //UITableView *tableView = (UITableView *)[[self view] viewWithTag:90];
                //[tableView reloadData];
            }
        }
        else
        {
            returnedFromChangeActViewWithNoChanges = 1;
        }
	}
	// Now release the addActivityViewController to reset the above test
    [changeActivityTimeView release];
	changeActivityTimeView = nil;
	
    
    // Do set up stuff if the activity is Misc
    if ([[activity name] isEqualToString:@"Misc"]) 
    {
        //UIButton *renameButton = (UIButton *)[[self view] viewWithTag:1774];
        [renameButton setHidden:1];
        if (!returnedFromChangeActViewWithNoChanges) 
        {
            [self createMiscEntries:entries];
        }
    }
    else
    {
        UIButton *renameButton = (UIButton *)[[self view] viewWithTag:1774];
        [renameButton setHidden:0];
    }
    
    
	//[activityTitle setTitle:[activity name] forState:UIControlStateNormal];
    [self setTimeButtons];
    // selectedEntries is set in this next function 
    [self setEntriesToShow];
    
    // Remove the tableview if there is no content to show
	if ([selectedEntries count] == 0) 
	{
        UITableView *tableView = (UITableView *)[[self view] viewWithTag:90];
		[tableView setHidden:1];
	}
	else 
	{
		[tableView setHidden:0];
        
        //[self setTimeButtons];
		
		// If it is the Misc activity, then still want to remove the table
		// because otherwise, it will display all of the entires across all activities
		if ([[activity name] isEqualToString:@"Misc"]) 
		{
			// Won't need this if showing misc entries
            //UITableView *tableView = (UITableView *)[[self view] viewWithTag:90];
			//[tableView removeFromSuperview];
            UITableView *tableView = (UITableView *)[[self view] viewWithTag:90];
			[tableView reloadData];
		}
		else 
		{
			self.navigationItem.rightBarButtonItem = self.editButtonItem;
		}
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
 	// Only show the Edit button if you have more than the base 2 items
	// Since you can't delete those
	//if ([activities count] > 2) 
	//{
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
	//}	
}


#pragma mark -
#pragma mark Date Actions

- (NSMutableArray *)timeSpentDoingEntry:(Entry *)entry
{
	NSTimeInterval entryTime = 0;
	NSMutableArray *timedata = [[NSMutableArray alloc] init];

	NSDate *today = [[NSDate alloc] init]; 
	// Figure out what the beginning of today is
    NSCalendar *curCalendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSWeekdayCalendarUnit;
    NSDateComponents *dateComps = [curCalendar components:unitFlags fromDate:today];
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0];
    NSDate *startOfToday = [curCalendar dateFromComponents:dateComps];
	
	// Now calculate the beginning of the past weeks 
	NSTimeInterval secondsPerDay = 24 * 60 * 60;
    NSDate *topDay = [selectedDay dateByAddingTimeInterval:secondsPerDay];
	
	// Orlando
    // Change this to use the day as the top and bottom day
    //topDate = [beginningOfWeekOne dateByAddingTimeInterval:-(selectedWeek - 2)*secondsPerWeek];
    //bottomDate = [beginningOfWeekOne dateByAddingTimeInterval:-(selectedWeek - 1)*secondsPerWeek];
    
	// Check against selected week
	//if ([topDate compare:[entry startDate]] == NSOrderedDescending && ([[entry startDate] compare:bottomDate] == NSOrderedDescending || [[entry endDate] compare:bottomDate] == NSOrderedDescending) || (![entry endDate] && selectedWeek == 1))
    if ([topDay compare:[entry startDate]] == NSOrderedDescending && ([[entry startDate] compare:selectedDay] == NSOrderedDescending || [[entry endDate] compare:selectedDay] == NSOrderedDescending) || (![entry endDate] && [selectedDay compare:startOfToday] == NSOrderedSame))
	{
		if ([entry endDate]) 
		{
			if ([[entry startDate] compare:selectedDay] == NSOrderedDescending) 
			{
				//entryTime = [[entry endDate] timeIntervalSinceDate:[entry startDate]];
				if ([[entry endDate] compare:topDay] == NSOrderedDescending) 
				{
					entryTime = [topDay timeIntervalSinceDate:[entry startDate]];
				}
				else 
				{
					entryTime = [[entry endDate] timeIntervalSinceDate:[entry startDate]];
				}
			}
			else 
			{
				entryTime = [[entry endDate] timeIntervalSinceDate:selectedDay];
			}
		}
		else 
		{
			if ([[entry startDate] compare:selectedDay] == NSOrderedDescending)
			{
				entryTime = [today timeIntervalSinceDate:[entry startDate]];
			}
			else 
			{
				entryTime = [today timeIntervalSinceDate:selectedDay];
			}
            
		}
	}
	
	NSNumber *hours = [NSNumber numberWithInt:(int)(entryTime/(3600))];
	int min = (entryTime - ([hours intValue] * 3600))/60;
	NSNumber *minutes = [NSNumber numberWithInt:min];
	[timedata addObject:hours];
	[timedata addObject:minutes];
	return timedata;
}

- (NSMutableArray *)timeSpentDoingActivity
{
	NSTimeInterval timeIntervalToday = 0;
	NSDate *today = [[NSDate alloc] init]; 
    // Figure out what the beginning of today is
    NSCalendar *curCalendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSWeekdayCalendarUnit;
    NSDateComponents *dateComps = [curCalendar components:unitFlags fromDate:today];
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0];
    NSDate *startOfToday = [curCalendar dateFromComponents:dateComps];
    
	NSTimeInterval timeThatPassed = [today timeIntervalSinceDate:selectedDay];
    NSTimeInterval secondsInADay = 24*60*60;
	
	// Now go through every entry and figure out if it goes in this day
    NSDate *topDay, *startTime, *endTime;
    
	for (Entry *entry in entries) 
	{
        NSDate *entryEnds;
        // This is to account for entries that are still running
        if (![entry endDate]) 
        {
            entryEnds = today;
        }
        else
            entryEnds = [entry endDate];
        
		// Check if today
        topDay = [selectedDay dateByAddingTimeInterval:secondsInADay];
        
        if ([topDay compare:[entry startDate] ] == NSOrderedDescending && [selectedDay compare:entryEnds] != NSOrderedDescending) 
        {
            if ([selectedDay compare:[entry startDate]] == NSOrderedDescending ) 
                startTime = selectedDay;
            else
                startTime = [entry startDate];
            
            if ([entryEnds compare:topDay] == NSOrderedDescending) 
                endTime = topDay;
            else
                endTime = entryEnds;
            
            // Add the time for this entry to the running total for today
            timeIntervalToday += [endTime timeIntervalSinceDate:startTime];
        }
    }
	
	// Now calculate the hours and minutes to put into an array to return
	NSMutableArray *dayTimeData = [[NSMutableArray alloc] init];
	NSNumber *hours;
	int min;
	NSNumber *minutes;
	
	if ([[activity name] isEqualToString:@"Misc"]) 
	{
        // Figure out if we are looking at today's Misc time
        // If so, then use the time up today as total time
        // Otherwise use 24 hrs as total time
        if ([selectedDay compare:startOfToday] == NSOrderedSame) 
        {
            timeThatPassed -= timeIntervalToday;
        }
        else
        {
            timeThatPassed = secondsInADay - timeIntervalToday;
        }
        hours = [NSNumber numberWithInt:(int)(timeThatPassed/3600)];
        min = (timeThatPassed - ([hours intValue] * 3600))/60;   
		//min %= 60;
		minutes = [NSNumber numberWithInt:min];
	}
	else 
	{
		hours = [NSNumber numberWithInt:(int)(timeIntervalToday/3600)];
        min = (timeIntervalToday - ([hours intValue] * 3600))/60;
		minutes = [NSNumber numberWithInt:min];
	}
	[dayTimeData addObject:hours];
	[dayTimeData addObject:minutes];
	[hours release];
	[minutes release];

	return dayTimeData;
}


#pragma mark -
#pragma mark Action Methods

- (void)setEntriesToShow
{
	NSMutableArray *tempEntryList = [[NSMutableArray alloc] init];
	NSDate *today = [[NSDate alloc] init]; 
	
	// Now calculate the beginning of the past weeks 
	NSTimeInterval secondsPerDay = 24 * 60 * 60;
    NSDate *topDay = [selectedDay dateByAddingTimeInterval:secondsPerDay];
	
	// Figure out what the beginning of today is
    NSCalendar *curCalendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSWeekdayCalendarUnit;
    NSDateComponents *dateComps = [curCalendar components:unitFlags fromDate:today];
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0];
    NSDate *startOfToday = [curCalendar dateFromComponents:dateComps];
	
    if ([[activity name] isEqualToString:@"Misc"]) 
    {
        // If Misc, then we use the miscEntries array
        for (Entry *entry in miscEntries)
        {
            // Check against selected day
            //if ([topDate compare:[entry startDate]] == NSOrderedDescending && ([[entry startDate] compare:bottomDate] == NSOrderedDescending || [[entry endDate] compare:bottomDate] == NSOrderedDescending) || (![entry endDate] && selectedWeek == 1))
            if ([topDay compare:[entry startDate]] == NSOrderedDescending && ([[entry startDate] compare:selectedDay] == NSOrderedDescending || [[entry endDate] compare:selectedDay] == NSOrderedDescending) || (![entry endDate] && [selectedDay compare:startOfToday] == NSOrderedSame))
            {
                [tempEntryList addObject:entry];
            }
        }
    }
    else
	{
        for (Entry *entry in entries)
        {
            // Check against selected week
            //if ([topDate compare:[entry startDate]] == NSOrderedDescending && ([[entry startDate] compare:bottomDate] == NSOrderedDescending || [[entry endDate] compare:bottomDate] == NSOrderedDescending) || (![entry endDate] && selectedWeek == 1))
            if ([topDay compare:[entry startDate]] == NSOrderedDescending && ([[entry startDate] compare:selectedDay] == NSOrderedDescending || [[entry endDate] compare:selectedDay] == NSOrderedDescending) || (![entry endDate] && [selectedDay compare:startOfToday] == NSOrderedSame))
            {
                [tempEntryList addObject:entry];
            }
        }
    }
	selectedEntries = tempEntryList;
}

- (void)setTimeButtons
{
	NSMutableArray *timeData = [self timeSpentDoingActivity];
    NSNumber *hours = [timeData objectAtIndex:0];
    NSNumber *minutes = [timeData objectAtIndex:1];
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
    NSDateFormatter *date = [[[NSDateFormatter alloc] init] autorelease]; 
	[date setDateFormat:@"EEEE, MM/dd/yy"];
    
    [weekLabel setText:[NSString stringWithFormat:@"%@",[date stringFromDate:selectedDay]]];
    
}


- (void)createMiscEntries:(NSMutableArray *)passedEntries
{
    // First delete any miscEntries that already exist
    // Always create them from scratch when coming in here
    if ([miscEntries count] > 0) 
	{
        //TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
		NSMutableArray *miscEntryCopy = [miscEntries mutableCopy];
        for(Entry *entryToDelete in miscEntryCopy)
        {
            [miscEntries removeObject:entryToDelete];
            // Remove the object from the persistent store
            //NSManagedObjectContext *context = [appDelegate managedObjectContext];
            //[context deleteObject:entryToDelete];
            //[appDelegate saveContext];
        }
	}
    
    // Set up the key dates
	NSDate *today = [[NSDate alloc] init]; 
    // Get the start of today
	NSCalendar *curCalendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSWeekdayCalendarUnit;
    NSDateComponents *dateComps = [curCalendar components:unitFlags fromDate:today];
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0];
    NSDate *startOfToday = [curCalendar dateFromComponents:dateComps];
	
	// Now calculate the beginning of the past weeks 
	NSTimeInterval secondsPerDay = 24 * 60 * 60;
    NSMutableArray *passedEntriesCopy = [passedEntries mutableCopy];
    NSDate *lastEntryFinish = [[NSDate alloc] init];
      
    if ([passedEntriesCopy count]) 
    {
        //NSLog(@"A pass of this function");
        lastEntryFinish = selectedDay;
        for (Entry *selectedEntry in passedEntriesCopy)
        //for (int i = [passedEntriesCopy count]-1; i>=0; i--)
        {
            //Entry *selectedEntry = [passedEntriesCopy objectAtIndex:i];
            /*
            NSLog(@"Entry activity = %@", [[selectedEntry activity] name]);
            NSLog(@" ");
             */
            //NSLog(@"This entry: %@ - %@", [selectedEntry startDate], [selectedEntry endDate]);
            if ([[selectedEntry startDate] timeIntervalSinceDate:lastEntryFinish] > 60) 
            {
                /*
                NSLog(@"Select entry start: %@", [selectedEntry startDate]);
                NSLog(@"Last entry finish: %@", lastEntryFinish);
                NSLog(@" ");
                 */
                // Code to create the entries
                // Add an entry into the persistent store
                TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
                NSManagedObjectContext *context = [appDelegate managedObjectContext];
                Entry *newEntry;
            
                // Fill in the time for the entry
                newEntry = [NSEntityDescription insertNewObjectForEntityForName:@"Entry" inManagedObjectContext:context];
                [newEntry setActivity:activity];
                
                if ([selectedDay compare:lastEntryFinish] == NSOrderedDescending)
                    [newEntry setStartDate:selectedDay];
                else
                    [newEntry setStartDate:lastEntryFinish];
            
                if ([[selectedEntry startDate] compare:[selectedDay dateByAddingTimeInterval:secondsPerDay]] == NSOrderedDescending) 
                    [newEntry setEndDate:[selectedDay dateByAddingTimeInterval:secondsPerDay]];
                else
                    [newEntry setEndDate:[selectedEntry startDate]];
                //[miscEntries insertObject:newEntry atIndex:0];
                [miscEntries addObject:newEntry];
            } 
        
            // Now set the new lastActivityFinish date for the comparison with the next entry
            if ([selectedEntry endDate]) 
            {
                if ([[selectedEntry endDate] compare:selectedDay] == NSOrderedAscending)
                    lastEntryFinish = selectedDay;
                else
                    lastEntryFinish = [selectedEntry endDate]; 
            }
            else
            {
                lastEntryFinish = today;
            }
        }
        // Now do this last test to check if we need a Misc entry between right now and the
        // last completed activity
        
        // Depending on if this is today or another day when we hit the last object
        // Compare it's finish time to either today or the end of the current day
        NSDate *lastComparison = [[NSDate alloc] init];
        if ([selectedDay compare:startOfToday] == NSOrderedSame) 
            lastComparison = today;
        else
            lastComparison = [selectedDay dateByAddingTimeInterval:secondsPerDay];
        
        /*
        NSLog(@"Last entry finish = %@", lastEntryFinish);
        NSLog(@"Last comparison   = %@", lastComparison);
        NSLog(@" ");
        */
         
        if ([lastComparison timeIntervalSinceDate:lastEntryFinish] > 60) 
        {
            // Code to create the entries
            // Add an entry into the persistent store
            TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
            NSManagedObjectContext *context = [appDelegate managedObjectContext];
        
            Entry *newEntry = [NSEntityDescription insertNewObjectForEntityForName:@"Entry" inManagedObjectContext:context];
            [newEntry setActivity:activity];        
        
            [newEntry setStartDate:lastEntryFinish];
            [newEntry setEndDate:lastComparison];
        
            // Add the new entry miscEntries array
            //[miscEntries insertObject:newEntry atIndex:0];
            [miscEntries addObject:newEntry];
        } 
    }
    else
    {
        // If there are no entries for the selected day
        // then either the entire thing is a Misc entry
        // or if the selected day is today, then
        // the time up to now is a Misc entry
        TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
        NSManagedObjectContext *context = [appDelegate managedObjectContext];
        
        Entry *newEntry = [NSEntityDescription insertNewObjectForEntityForName:@"Entry" inManagedObjectContext:context];
        [newEntry setActivity:activity];        
        
        [newEntry setStartDate:selectedDay];
        if ([selectedDay compare:startOfToday] == NSOrderedSame) 
            [newEntry setEndDate:today];
        else
            [newEntry setEndDate:[selectedDay dateByAddingTimeInterval:secondsPerDay]];
        
        // Add the new entry miscEntries array
        //[miscEntries insertObject:newEntry atIndex:0];
        [miscEntries addObject:newEntry]; 
    }
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
	//NSLog(@"ENTRIES COUNT = %d", [entries count]);
    return [selectedEntries count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //static NSString *CellIdentifier = @"Cell";
	static NSString *CellIdentifier = @"EntryCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
	{
        //cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		[[NSBundle mainBundle] loadNibNamed:@"EntryDetailViewCell" owner:self options:nil];
		cell = entryCell;
	}
    
    // Configure the cell...
	
	Entry *entry = [selectedEntries objectAtIndex:[indexPath row]];
    
	UILabel *entryDate;
	entryDate = (UILabel *)[cell viewWithTag:1];
	//[activityName setTextColor:[UIColor blackColor]];
	//[activityName setText:[activity name]];
	UILabel *entryHours;
	entryHours = (UILabel *)[cell viewWithTag:3];
	
	UILabel *entryMinutes;
	entryMinutes = (UILabel *)[cell viewWithTag:4];
	[entryHours setTextColor:[UIColor blackColor]];
	[entryMinutes setTextColor:[UIColor blackColor]];
	
	NSDateFormatter *date = [[[NSDateFormatter alloc] init] autorelease]; 
	[date setDateFormat:@"EE, MM/dd"];
	NSString *stringDate = [date stringFromDate:[entry startDate]];
	[entryDate setText:stringDate];
	[date setTimeStyle:NSDateFormatterShortStyle];
	if ([entry endDate]) 
	{
		stringDate = [NSString stringWithFormat:@"%@ - %@",[date stringFromDate:[entry startDate]],[date stringFromDate:[entry endDate]]];
	}
	else 
	{
		stringDate = [NSString stringWithFormat:@"%@...",[date stringFromDate:[entry startDate]]];
		[entryHours setTextColor:[UIColor colorWithRed:0 green:.6 blue:.1 alpha:1]];
		[entryMinutes setTextColor:[UIColor colorWithRed:0 green:.6 blue:.1 alpha:1]];
	}
    
	UILabel *entryTime;
	entryTime = (UILabel *)[cell viewWithTag:2];
	//[activityName setTextColor:[UIColor blackColor]];
	//[activityName setText:[activity name]];
	[entryTime setText:stringDate];
	
	// Get the amount of time spent doing the activity this week to display
	NSMutableArray *timeData = [self timeSpentDoingEntry:entry];
	NSNumber *hours = [timeData objectAtIndex:0];
	NSNumber *minutes = [timeData objectAtIndex:1];
	
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
		if (![entry endDate]) 
		{
			[entryMinutes setText:@"0m"];
		}
		else 
		{
			if ([hours intValue] == 0) 
                [entryMinutes setText:@"<1m"];
            else
                [entryMinutes setText:@""];
		}
	}
    
	// Allow table rows to be reordered by the user
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	[cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
	
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath 
{
	// Return NO if you do not want the specified item to be editable.
	if ([[activity name] isEqualToString:@"Misc"]) 
    {
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{
 	if (editingStyle == UITableViewCellEditingStyleDelete) 
	{
		TimeTrackerAppDelegate *appDelegate = [TimeTrackerAppDelegate sharedAppDelegate];
		ActivityViewController *activityView = [ActivityViewController sharedActivityViewController];
		Entry *entry = [selectedEntries objectAtIndex:[indexPath row]];
		
		// If this activity was ACTIVE, then need to change general setting
		// to show that there is no longer an active activity
		if ([[activity active] intValue]  && ![entry endDate]) 
		{
			NSArray	*settings = [appDelegate allInstancesOf:@"General"];
			General *genSettings = [settings objectAtIndex:0];
			[genSettings setActivityEnabled:[NSNumber numberWithInt:0]];
			[activity setActive:[NSNumber numberWithInt:0]];
			
			// Reload the table data in the main view to go back to nonActive state
			[[activityView sharedTableView] reloadData];
		}
		
		[entries removeObject:entry];
		[selectedEntries removeObjectAtIndex:[indexPath row]];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		
		// Remove the object from the persistent store
		NSManagedObjectContext *context = [appDelegate managedObjectContext];
		[context deleteObject:entry];
		[appDelegate saveContext];
		
		// Update the list of entries in main view so that TimeSpentDoingActivity will work
		[activityView updateEntries];
        
        // If deleting this item left nothing else to be displayed,
        // then hide the table view
        if ([selectedEntries count] == 0) 
        {
            [[self navigationItem] setRightBarButtonItem:Nil];
            
            [super setEditing:0 animated:YES];  
            [tableView setEditing:0 animated:YES];
            [tableView setHidden:1];
        }
	}
    
    if (![deletedAnEntry intValue]) 
        deletedAnEntry = [NSNumber numberWithInt:1];
    
	[tableView reloadData];
	[self setTimeButtons];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated 
{ 
	[super setEditing:editing animated:animated]; 
	UITableView *tableView = (UITableView *)[[self view] viewWithTag:90];
	[tableView setEditing:editing animated:YES]; 
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{	
	changeActivityTimeView = [[ChangeActivityTimeView alloc] init];
	Entry *selectedEntry = [selectedEntries	objectAtIndex:[indexPath row]];
    [changeActivityTimeView setSelectedEntry:selectedEntry];
    [[self navigationController] pushViewController:changeActivityTimeView animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Entries";
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:3] setHidden:1];
    [[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:4] setHidden:1];
    self.navigationItem.rightBarButtonItem = Nil;
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([selectedEntries count] == 0) 
	{
        UITableView *tableView = (UITableView *)[[self view] viewWithTag:90];
		[tableView setHidden:1];
	}
    else
    {
        [[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:3] setHidden:0];
        [[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:4] setHidden:0];
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	[weekOneHours release];
	[weekOneMinutes release];
	[activityTitle release];
    [weekLabel release];
	
	weekOneHours = nil;
	weekOneMinutes = nil;
	activityTitle = nil;
    weekLabel = nil;
	
	[super viewDidUnload];
}


- (void)dealloc 
{
	// View stuff
	[weekOneHours release];
	[weekOneMinutes release];
	[activityTitle release];
    [weekLabel release];
	
	// Other variables
	[activity release];
	[entries release];
	[selectedDay release];
    [deletedAnEntry release];
	
	[super dealloc];
}


@end

