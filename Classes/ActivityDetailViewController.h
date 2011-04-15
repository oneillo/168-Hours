//
//  ActivityDetailViewController.h
//  168 Hours
//
//  Created by Orlando O'Neill on 1/29/11.
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
