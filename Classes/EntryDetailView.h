//
//  EntryDetailView.h
//  168 Hours
//
//  Created by Orlando O'Neill on 3/3/11.
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
#import "Activity.h"
@class RenameActivityView;
@class ChangeActivityTimeView;


@interface EntryDetailView : UIViewController <UITableViewDelegate> 
{
	IBOutlet UIButton *weekOneHours;
	IBOutlet UIButton *weekOneMinutes;
	IBOutlet UIButton *activityTitle;
    IBOutlet UILabel *weekLabel;
    NSNumber *deletedAnEntry;
	Activity *activity;
	NSMutableArray *entries;
	NSMutableArray *selectedEntries;
    NSDate *selectedDay;
    NSMutableArray *miscEntries;
	UITableViewCell *entryCell;
	RenameActivityView *renameActivityView;
	ChangeActivityTimeView *changeActivityTimeView;
}

@property (nonatomic, retain) Activity *activity;
@property (nonatomic, retain) NSMutableArray *entries;
@property (nonatomic, retain) NSDate *selectedDay;
@property (nonatomic, retain) NSNumber *deletedAnEntry;
@property (nonatomic, assign) IBOutlet UITableViewCell *entryCell;

//- (void)setButtonDisplay:(NSNumber *)week;
- (void)setTimeButtons;
- (NSMutableArray *)timeSpentDoingEntry:(Entry *)entry;
- (void)setEntriesToShow;
- (IBAction)renameActivity:(id)sender;
- (void)createMiscEntries:(NSMutableArray *)entries;

@end
