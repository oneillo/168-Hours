//
//  Entry.h
//  TimeTracker
//
//  Created by Orlando O'Neill on 1/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Activity;

@interface Entry :  NSManagedObject  
{
}

@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) Activity * activity;

@end



