//
//  SnapupAppDelegate.m
//  Snapup
//
//  Copyright (c) 2010, Meetup, Inc.
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are
//  met:
//  
//  * Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//  * Neither the name of the Meetup, Inc. nor the names of its contributors
//    may be used to endorse or promote products derived from this software
//    without specific prior written permission. 
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
//  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "SnapupAppDelegate.h"
#import "SnapupViewController.h"
#import "LoginViewController.h"
#import "MeetupConnectionManager.h"
#import "MPURLRequestParameter.h"
#import "LoadingView.h"

@implementation SnapupAppDelegate

@synthesize window;
@synthesize splashScreenView;
@synthesize loginViewController;

@synthesize snapupViewController;
@synthesize eventsListViewController;

@synthesize launchDefault;
@synthesize newTokenReceived;

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	NSLog(@"handleOpenURL");
	self.launchDefault = NO;
	
	if (!url)
		return NO;
	
	// the url is the callback url with the query string including oauth_token and oauth_verifier in 1.0a
	if ([[url host] isEqualToString:@"success"] && [url query].length > 0) {
		NSDictionary *oauthParameters = [MPURLRequestParameter parameterDictionaryFromString:[url query]];
		NSString *oauthVerifier = [oauthParameters objectForKey:@"oauth_verifier"];

		if (oauthVerifier) {
			[self showLoadingScreen];
			[[MeetupConnectionManager sharedManager] authenticateMemberWithOAuthVerifier:oauthVerifier 
																			  withTarget:self 
																			 andSelector:@selector(forcePostLaunch)
																		andErrorSelector:@selector(errorAuthenticating)];
		}
	}
	
	return YES;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	self.launchDefault = YES;
	
	[self showLoadingScreen];
	[self performSelector:@selector(postLaunch) withObject:nil afterDelay:0.0];
}

/**
 applicationWillTerminate: saves changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
	
    NSError *error = nil;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
			/*
			 Replace this implementation with code to handle the error appropriately.
			 
			 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
			 */
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			
			UIAlertView *errorAlert = [[UIAlertView alloc]
									   initWithTitle:@"Unexpected Error" 
									   message:@"Please press the Home button and reopen the application."
									   delegate:nil
									   cancelButtonTitle:@"OK"
									   otherButtonTitles:nil];
			[errorAlert show];
			[errorAlert release];
        } 
    }
}

- (void)forcePostLaunch {
	self.launchDefault = YES;
	self.newTokenReceived = YES;
	
	[self postLaunch];
}

- (void)errorAuthenticating {
	NSLog(@"errorAuthenticating");
	
	UIAlertView *errorAlert = [[UIAlertView alloc]
							   initWithTitle:@"Authentication Error" 
							   message:@"Unable to authenticate your Meetup.com account. Please try to log in again."
							   delegate:nil
							   cancelButtonTitle:@"OK"
							   otherButtonTitles:nil];
	[errorAlert show];
	[errorAlert release];
	
	self.launchDefault = YES;
	self.newTokenReceived = NO;
	
	[self postLaunch];
}

- (void)postLaunch {
	snapupViewController.moContext = [self managedObjectContext];
		
	// properly deal with handleOpenURL (http://blog.rightsprite.com/2008/11/iphone-applicationdidfinishlaunching.html)
	if (self.launchDefault) {
		// check if member is logged in
		BOOL isLoggedIn = [[MeetupConnectionManager sharedManager] isLoggedIn];
		
		// push login page or default page
		if (!isLoggedIn) {
			[self showLoginScreen];
		}
		else {
			[self showEventsList];
		}
		
		[window makeKeyAndVisible];
	}	
}

- (void)removeSubviews
{
	for (UIView * aSubview in [window subviews])
		[aSubview removeFromSuperview];
}

- (void)showLoadingScreen {
	[self removeSubviews];
	
	NSLog(@"Showing loading...");
	self.splashScreenView.frame = CGRectInset(window.frame, 0, 0);
	[window addSubview:self.splashScreenView];
}

- (void)showLoginScreen {
	[self removeSubviews];
	
	// push login page back into view
	NSLog(@"Showing login...");
	[window addSubview:loginViewController.view];
}

- (void)showEventsList {
	[self removeSubviews];
	
	// push events page back into view
	NSLog(@"Showing events...");
	
	[window addSubview:eventsListViewController.view];
}

- (void)logout {
	// clear out all the coredata info
	[snapupViewController clearEventsInCoreData];
	
	[self showLoginScreen];	
	[[MeetupConnectionManager sharedManager] logout];
}

- (void)dealloc {
    [managedObjectContext release];
    [managedObjectModel release];
    [persistentStoreCoordinator release];
	
	[splashScreenView release];
    [loginViewController release];
    [eventsListViewController release];
	
    [window release];
	
    [super dealloc];
}

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
	NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"SnapUpLive.sqlite"]];
	
	NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
		/*
		 Replace this implementation with code to handle the error appropriately.
		 
		 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
		 
		 Typical reasons for an error here include:
		 * The persistent store is not accessible
		 * The schema for the persistent store is incompatible with current managed object model
		 Check the error message to determine what the actual problem was.
		 */
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		
		UIAlertView *errorAlert = [[UIAlertView alloc]
								   initWithTitle:@"Unexpected Error" 
								   message:@"Please press the Home button and reopen the application."
								   delegate:nil
								   cancelButtonTitle:@"OK"
								   otherButtonTitles:nil];
		[errorAlert show];
		[errorAlert release];
    }    
	
    return persistentStoreCoordinator;
}

#pragma mark -
#pragma mark Application's Documents directory

/**
 Returns the path to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

@end
