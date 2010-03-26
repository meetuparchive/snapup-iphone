//
//  SnapupAppDelegate.h
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

#import <UIKit/UIKit.h>

@class LoginViewController;
@class SnapupViewController;

@interface SnapupAppDelegate : NSObject <UIApplicationDelegate> {
    NSManagedObjectModel			*managedObjectModel;
    NSManagedObjectContext			*managedObjectContext;	    
    NSPersistentStoreCoordinator	*persistentStoreCoordinator;
    
	UIWindow				*window;
	UIView					*splashScreenView;
	
	LoginViewController     *loginViewController;
	
	SnapupViewController	*snapupViewController;
    UINavigationController	*eventsListViewController;
	
	BOOL launchDefault;
	BOOL newTokenReceived;
}

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIView *splashScreenView;
@property (nonatomic, retain) IBOutlet LoginViewController *loginViewController;

@property (nonatomic, retain) IBOutlet SnapupViewController *snapupViewController;
@property (nonatomic, retain) IBOutlet UINavigationController *eventsListViewController;

@property BOOL launchDefault;
@property BOOL newTokenReceived;

- (void)forcePostLaunch;
- (void)postLaunch;	

- (void)removeSubviews;
- (void)showLoadingScreen;
- (void)showLoginScreen;
- (void)showEventsList;

- (IBAction)logout;

- (NSString *)applicationDocumentsDirectory;

void myUncaughtExceptionHandler(NSException *theException);

@end

