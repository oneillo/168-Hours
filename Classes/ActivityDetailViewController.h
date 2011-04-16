//
//  ActivityDetailViewController.h
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

#import <UIKit/UIKit.h>
#import "Activity.h"
@class RenameActivityView;
@class EntryDetailView;


@interface ActivityDetailViewController : UIViewController <UITableViewDelegate> 
{
	IBOutlet UIButton *activityTitle;
    IBOutlet UILabel *weekLabel;
    IBOutlet UILabel *weekOneHours;
    IBOutlet UILabel *weekOneMinutes;
	Activity *activity;
	NSMutableArray *entries;
	NSMutableArray *selectedEntries;
	NSInteger selectedWeek;
	UITableViewCell *entryCell;
	RenameActivityView *renameActivityView;
    EntryDetailView *entryDetailView;
    
    NSMutableArray *dailyActivityData;
}

@property (nonatomic, retain) Activity *activity;
@property (nonatomic, retain) NSMutableArray *entries;
@property (nonatomic, assign) IBOutlet UITableViewCell *entryCell;

- (IBAction)setWeekToShow:(id)sender;
- (void)setTimeButtons;
- (void)setEntriesToShow;
- (IBAction)renameActivity:(id)sender;

@end
