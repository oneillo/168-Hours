//
//  Activity.h
//  TimeTracker
//
//  Created by Orlando O'Neill on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface Activity :  NSManagedObject  
{
}

@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSNumber * currentHours;
@property (nonatomic, retain) NSDate * endTime;
@property (nonatomic, retain) NSNumber * goalHours;
@property (nonatomic, retain) NSString * name;

@end



