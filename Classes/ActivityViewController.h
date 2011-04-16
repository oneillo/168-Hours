//
//  ActivityViewController.h
//  168 Hours
//
//  Created by Orlando O'Neill on 1/5/11.
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
