//
//  SnapupViewController.h
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
#import "MPOAuthAPI.h"

@class MeetupAsyncRequest, Event;

@interface SnapupViewController : UIViewController <UIActionSheetDelegate, 
		UITableViewDelegate, UITableViewDataSource, 
		UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate,
		NSFetchedResultsControllerDelegate> {
			
	MeetupAsyncRequest *eventsRequest;

	Event		*_currEvent;
	Event		*_nowEvent;
			
	UIView *_tableContainingView;
	UITableView *_tableView;
	UISegmentedControl *_segmentedControl;
	UIImagePickerController *_imagePickerController;
			
	NSInteger _currOffset;
	NSString *_afterDate;
			
	NSUInteger _shownEvents;
	NSUInteger _totalEvents;
			
	NSManagedObjectContext *_moContext;
			
	NSFetchedResultsController *_fetchedResultsController;
	NSFetchRequest *_attendingFetchRequest;
	NSFetchRequest *_showAllFetchRequest;
	NSFetchRequest *_totalFetchRequest;
	NSError *_error;			
			
	BOOL changeIsUserDriven;
	BOOL preventUpdating;
}

@property (nonatomic, retain) MeetupAsyncRequest *eventsRequest;

@property (nonatomic, retain) Event   *currEvent;
@property (nonatomic, retain) Event	  *nowEvent;

@property (nonatomic, retain) IBOutlet UIView *tableContainingView;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, retain) UIImagePickerController *imagePickerController;

@property (nonatomic, assign) NSInteger currOffset;
@property (nonatomic, retain) NSString *afterDate;

@property (nonatomic, assign) NSUInteger shownEvents;
@property (nonatomic, assign) NSUInteger totalEvents;

@property (nonatomic, retain) NSManagedObjectContext *moContext;

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSFetchRequest *attendingFetchRequest;
@property (nonatomic, retain) NSFetchRequest *showAllFetchRequest;
@property (nonatomic, retain) NSFetchRequest *totalFetchRequest;
@property (nonatomic, retain) NSError *error;

@property BOOL changeIsUserDriven;
@property BOOL preventUpdating;

- (IBAction)refreshEventList;
- (IBAction)updateTableViewAndJump;
- (IBAction)jumpToNow;

- (void)clearEventsInCoreData;

@end

