//
//  ChangeActivityTimeView.h
//  168 Hours
//
//  Created by Orlando O'Neill on 2/3/11.
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
