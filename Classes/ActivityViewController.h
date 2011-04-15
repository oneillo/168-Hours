//
//  ActivityViewController.h
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

#import <UIKit/UIKit.h>
#import	"Activity.h"
#import <MessageUI/MFMailComposeViewController.h>
@class AddActivityViewController;


@interface ActivityViewController : UIViewController <UITableViewDelegate, UIAlertViewDelegate,MFMailComposeViewControllerDelegate>
{
	// Array contains all activities that will be displayed in the table
    NSMutableArray *activities;
    
    // A dictionary of all of the activities' entries
    // This allows the entries to be accessed via their activity's name
	NSMutableDictionary *entries;
	
    AddActivityViewController *addActivityViewController;
    
    // This is returned to other classes so that they can update the time data in this screen
    // Mainly happens when an entry is deleted or reassigned
    UITableView *sharedTableView;
    
    // Holds a custom table cell view
	UITableViewCell *activityCell;
    
    // Array to hold all of the entries when they are pulled from the DB
	// The entries dictionary is populated from this array
    NSMutableArray *allEntries;
    
    // Can either be set to 1: day view or 2: week view
    // Toggled by the togglePeriod button in the bottom left of the main screen and changes the relevant period from today to this week
    NSInteger selectedDisplayPeriod;
    UIBarButtonItem *togglePeriod;
    
    // Gets set to 1 if this is the first time the app has been launched so that an 
    // alert message can be sent to the user with a welcome message
    NSInteger firstTimeRun;
    
    // Used to update the times on the screen automatically whenever an activity is running
    NSTimer *timer;
    
    // This variable is set to the name of the log file anytime the user taps the Save Log button
    NSString *logFileName;
    
    // Tracks if the log file is not sent in an email for whatever reason after the user chooses the email option
    // If it is set to 1, meaning the email was not sent, then the alert window with info on downloading the log from iTunes pops up
    bool logEmailNotSent;
}

// Other class uses this to update the data in the table for this view
+ (ActivityViewController *)sharedActivityViewController;

@property (nonatomic, retain) NSMutableArray *activities;
@property (nonatomic, retain) NSMutableDictionary *entries;
@property (nonatomic, retain) NSMutableArray *allEntries;
@property (nonatomic, retain) UITableView *sharedTableView;
@property (nonatomic, retain) NSString *logFileName;
@property (nonatomic, assign) IBOutlet UITableViewCell *activityCell;
@property (nonatomic, assign) IBOutlet UIBarButtonItem *togglePeriod;
@property (nonatomic, retain) NSTimer *timer;

// All of the class functions
// Their info is documented in the .m file
- (IBAction)setDisplayPeriod:(id)sender;
- (void)createActivityObject:(NSString *)name withCurrentHours:(NSNumber *)currHours withGoalHours:(NSNumber *)goalHours;
- (void)createActivityObject:(NSString *)name;
- (void)createSettingsObject:(NSNumber *)activityEnabled;
- (bool)checkIfActivityExists:(NSString *)name;
- (void)changeActivityState:(Activity *)selectedActivity;
- (IBAction)showActivityDetail:(id)sender event:(id)event;
- (void)createEntry:(Activity *)activity;
- (void)setEntryTime:(Activity *)activity;
- (void)setTitleTime;
- (void)updateEntries;
- (void)deleteOldEntries;
- (void)updateActivityOrder;
- (NSMutableArray *)timeSpentDoingActivity:(Activity *)activity;
- (NSMutableArray *)timeSpentDoingActivityForLog:(NSString *)ActivityName;
- (IBAction)exportLog:(id)sender;
- (void)sendLogViaEmail;
- (void)updateRunningScreen;

@end
