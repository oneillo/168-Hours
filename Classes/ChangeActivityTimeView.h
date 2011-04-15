//
//  ChangeActivityTimeView.h
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

#import <UIKit/UIKit.h>
#import "Entry.h"
#import "Activity.h"


@interface ChangeActivityTimeView : UIViewController <UIPickerViewDelegate>
{
	IBOutlet UIPickerView *durationPickerView;
	IBOutlet UIButton *activityTitle;
	IBOutlet UILabel *entryDate;
	IBOutlet UILabel *entryStartTime;
	NSMutableArray *hourOptions;
	NSMutableArray *minuteOptions;
    NSMutableArray *activityOptions;
	Entry *selectedEntry;
    Activity *newActivityForEntry;
	NSTimeInterval newEntryTime;
	
}
@property (nonatomic, retain) Entry *selectedEntry;
@property (nonatomic, copy) Activity *newActivityForEntry;
@property (nonatomic) NSTimeInterval newEntryTime;


- (void)setUpPickerOptions;
- (NSMutableArray *)timeSpentDoingEntry:(Entry *)entry;

@end
