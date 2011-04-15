//
//  Activity.h
//  TimeTracker
//
//  Created by Orlando O'Neill on 1/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Entry;

@interface Activity :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * currentHours;
@property (nonatomic, retain) NSDate * createDate;
@property (nonatomic, retain) NSNumber * goalHours;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * active;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSSet* entries;

@end


@interface Activity (CoreDataGeneratedAccessors)
- (void)addEntriesObject:(Entry *)value;
- (void)removeEntriesObject:(Entry *)value;
- (void)addEntries:(NSSet *)value;
- (void)removeEntries:(NSSet *)value;

@end

