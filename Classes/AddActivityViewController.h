//
//  AddActivityViewController.h
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


@interface AddActivityViewController : UIViewController {
	IBOutlet UITextField *textField;
	//IBOutlet UITextField *hoursField;
	NSString *activityName;
	//NSNumber *goalHours;
}
@property (nonatomic, retain) NSString *activityName;
//@property (nonatomic, copy) NSNumber *goalHours;

@end
