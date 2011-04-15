//
//  TimeTrackerAppDelegate.m
//  168 Hours
//
//  Created by Orlando O'Neill on 1/6/11.
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

#import "TimeTrackerAppDelegate.h"
#import "ActivityViewController.h"
#import "Activity.h"

static TimeTrackerAppDelegate *sharedInstance;


@implementation TimeTrackerAppDelegate

@synthesize window;

#pragma mark -
#pragma mark Initialization

- (id)init
{
	if (sharedInstance) 
	{
		NSLog(@"Error: You are creating a second TimeTrackerAppDelegate");
	}
	
	[super init];
	sharedInstance = self;
	
	// For Debug Purposes
    // If enabled,the lines below will cause the SQL database code to be displayed for any core data calls
	//Class privateClass = NSClassFromString(@"NSSQLCore");
	//[privateClass setDebugDefault:YES];
	
	return self;
}

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
{    
    ActivityViewController *mainViewController = [[ActivityViewController alloc] init];
	
	// Create the navController and set mainViewController as its root
	navigationController = [[UINavigationController alloc] initWithRootViewController:mainViewController];
		
	[window setRootViewController:navigationController];
    [window makeKeyAndVisible];
	
	[mainViewController release];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
    
    // Save core data changes to the database when the app is closed
    [self saveContext];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of the transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
    //ActivityViewController *activityView = [ActivityViewController sharedActivityViewController];
    
    // Start the activity indicator
    //UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[[activityView view] viewWithTag:667];
    //[activityIndicator setHidden:0];
    //[activityIndicator startAnimating];
        
    // Update the table data
    //[[activityView sharedTableView] reloadData];
    //[activityView setTitleTime];

    
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
    // This updates the time data in the main view when the app comes out of running in the background
    // Otherwise, the user would see stale data from when the app was closed
    ActivityViewController *activityView = [ActivityViewController sharedActivityViewController];
    [[activityView sharedTableView] reloadData];
    [activityView setTitleTime];
}


/**
 applicationWillTerminate: saves changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
	[self saveContext];
}


- (void)saveContext {
    
    NSError *error = nil;
    if (managedObjectContext_ != nil) {
        if ([managedObjectContext_ hasChanges] && ![managedObjectContext_ save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}    


#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
    
    if (managedObjectContext_ != nil) {
        return managedObjectContext_;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext_ = [[NSManagedObjectContext alloc] init];
        [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext_;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel_ != nil) {
        return managedObjectModel_;
    }
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"TimeTracker" ofType:@"momd"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return managedObjectModel_;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (persistentStoreCoordinator_ != nil) {
        return persistentStoreCoordinator_;
    }
    
    NSURL *storeURL = [NSURL fileURLWithPath: [[self applicationLibraryDirectory] stringByAppendingPathComponent: @"168Hours.sqlite"]];
    
    NSError *error = nil;
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
	// Enabling automatic lightweight migration
	// From the CoreDataVersion pdf, p18
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    	
	if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }  
    
    // This is code to migrate the store (aka database file) to a new location if necessary
    // Won't neeed this on the official app, because it will start with the right store location
    /*NSURL *newURL = [NSURL fileURLWithPath: [[self applicationLibraryDirectory] stringByAppendingPathComponent: @"168Hours.sqlite"]]; 
    NSPersistentStore *xmlStore = [persistentStoreCoordinator_ persistentStoreForURL:storeURL]; 
    NSPersistentStore *sqLiteStore = [persistentStoreCoordinator_ migratePersistentStore:xmlStore toURL:newURL options:nil withType:NSSQLiteStoreType error:&error];
     */
    
    return persistentStoreCoordinator_;
}


#pragma mark -
#pragma mark Convenience Methods

// Returns a reference to the main instance of this class so that other classes can call the shared methods
+ (TimeTrackerAppDelegate *)sharedAppDelegate
{
	return sharedInstance;
}

// Returns an array with either all of the Activities or all of the Entries out of the database 
- (NSArray *)allInstancesOf:(NSString *)entityName
{
	// Get the context
	NSManagedObjectContext *context = [[TimeTrackerAppDelegate sharedAppDelegate] managedObjectContext];
	
	// Fetch whatever is in the Core Data persistant store to show in the table
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	
	// Sort if pulling the list of activities
	if (entityName == @"Activity") 		
	{
		// Sort the activities by their order DB field
        // Initially, the order is based on when they were created, but the user can rearrange them 
        // The array will be in ascending order, such that the first object corresponds to the first row in the table
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
		[request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
		[sortDescriptor release];
	}
	
	// Sort if pulling the list of entries
	if (entityName == @"Entry") 		
	{
		// Sort the entries by when each one was created
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:NO];
		[request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
		[sortDescriptor release];
	}
	
	NSError *error;
	NSArray *fetchedItems = [context executeFetchRequest:request error:&error];
	[request release];
	
    // This is to handle if an error occurs when fetching the data from the database
    // It doesn't really handle the error very well at all
    // It just puts up a message notifying the user of the error
	if (!fetchedItems) 
	{
		// Show an alert view
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Fetch failed" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alertView autorelease];
		[alertView show];
		return nil;
	}
	
	// return the result
	return fetchedItems;
}

// This function can be used to delete all activities or entries
// Useful for when you are testing changes to the app
// But it isn't used ever outside of development
- (void)deleteAllObjects:(NSString *)entityDescription
{
	// Get the managedObjectContext
	NSManagedObjectContext *context = [[TimeTrackerAppDelegate sharedAppDelegate] managedObjectContext];
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityDescription inManagedObjectContext:context];
	[fetchRequest setEntity:entity];
	
    // Pull all of the objects from the database
	NSError *error;
	NSArray *items = [context executeFetchRequest:fetchRequest error:&error];
	[fetchRequest release];
	
    // Go through each object and delete it
	for (Activity *activs in items) 
	{
		[context deleteObject:activs];
		NSLog(@"%@ object deleted", entityDescription);
	}
	
	if(![context save:&error])
	{
		NSLog(@"Error deleting %@ - error:%@", entityDescription, [error localizedDescription]);
	}
}


#pragma mark -
#pragma mark Application's Documents directory

/**
 Returns the path to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

/**
 Returns the path to the application's Library directory.
 */
- (NSString *)applicationLibraryDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
    
    [managedObjectContext_ release];
    [managedObjectModel_ release];
    [persistentStoreCoordinator_ release];
    
    [window release];
    [super dealloc];
}


@end

