//
//  SnapupViewController.m
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

#import "SnapupViewController.h"
#import "SnapupAppDelegate.h"
#import "MeetupAsyncRequest.h";
#import "EventTableCell.h"
#import "NowCell.h";
#import "BasicTextCell.h";
#import "Event.h";
#import "User.h";

#import "MPOAuthAuthenticationMethodOAuth.h"
#import "MeetupConnectionManager.h"
#import "PhotoUploadViewController.h"

#import "MPURLRequestParameter.h"
#import "MPOAuthAPI.h"

#define kNowCellId			-1
#define	kMoreEventsCellId	-2

#define kEventsPageSize		20

@interface SnapupViewController (Private)
- (void)showUploadActionSheet;
- (void)loadMoreEvents;

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath*)indexPath;

- (void)updateTableView;
- (void)addOrUpdateNowCell;
- (void)addOrUpdateLoadMoreCell;

- (NSUInteger)getTotalEventsInCoreDataCount;

- (void)setupEventsFetchRequest:(NSFetchRequest *)fetchRequest showYesMaybeOnly:(BOOL)showYesMaybeOnly;
@end

@implementation SnapupViewController

@synthesize eventsRequest;

@synthesize currEvent = _currEvent;
@synthesize nowEvent = _nowEvent;

@synthesize tableContainingView = _tableContainingView;
@synthesize tableView = _tableView;
@synthesize segmentedControl = _segmentedControl;
@synthesize imagePickerController = _imagePickerController;

@synthesize currOffset = _currOffset;
@synthesize afterDate = _afterDate;

@synthesize shownEvents = _shownEvents;
@synthesize totalEvents = _totalEvents;

@synthesize moContext = _moContext;

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize attendingFetchRequest= _attendingFetchRequest;
@synthesize showAllFetchRequest = _showAllFetchRequest;
@synthesize totalFetchRequest = _totalFetchRequest;
@synthesize error = _error;

@synthesize changeIsUserDriven;
@synthesize preventUpdating;

- (void)viewDidLoad {
    [super viewDidLoad];
	
	SnapupAppDelegate *delegate = (SnapupAppDelegate *)[[UIApplication sharedApplication] delegate];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	// switch to the default segmented control selection (attending/show all)
	if ([defaults valueForKey:@"selectedSegment"]) {
		self.preventUpdating = YES;
		self.segmentedControl.selectedSegmentIndex = [defaults integerForKey:@"selectedSegment"];
		self.preventUpdating = NO;
	}

	// if we got a new token or there are no events in coredata, force a refresh
	if (delegate.newTokenReceived || ([self getTotalEventsInCoreDataCount] == 0)) {
		[self refreshEventList];
	}
	else {
		// get the current offset
		if ([defaults valueForKey:@"currOffset"])
			self.currOffset = [defaults integerForKey:@"currOffset"];
		if ([defaults valueForKey:@"afterDate"])
			self.afterDate = [defaults stringForKey:@"afterDate"];
		
		[self updateTableView];
	}
}

// carry over values that don't need coredata or keychain storage
- (void)updatePersistingPrimitiveData {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:_currOffset forKey:@"currOffset"];	
	[defaults setInteger:_segmentedControl.selectedSegmentIndex forKey:@"selectedSegment"];
	[defaults setValue:_afterDate forKey:@"afterDate"];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	self.tableContainingView = nil;
	self.tableView = nil;
	self.segmentedControl = nil;
	
	[super viewDidUnload];
}

- (void)dealloc {
	[eventsRequest release];
	[_segmentedControl release];
	[_imagePickerController release];
	[_tableView release];
	[_tableContainingView release];

	[_fetchedResultsController release];
	[_error release];
	
	[_afterDate release];
	
	[_currEvent release];
	[_nowEvent release];
	
	[_moContext release];
	
	[_attendingFetchRequest release];
	[_showAllFetchRequest release];
	[_totalFetchRequest release];
	
	eventsRequest = nil;
	_segmentedControl = nil;
	_imagePickerController = nil;
	_tableView = nil;
	_tableContainingView = nil;
	_error = nil;
	
    [super dealloc];
}

#pragma mark -
#pragma mark UIActionSheetDelegate Methods

- (void)showUploadActionSheet {
	// bring up photo taking actionsheet
	NSString *actionSheetTitle = [[NSString alloc] initWithFormat:@"Add Photo to %@", _currEvent.name];
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] 
								  initWithTitle:actionSheetTitle delegate:self
								  cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take a Picture", @"Choose Existing Photo", nil];
	[actionSheet showInView:self.view];
	
	[actionSheet release];
	[actionSheetTitle release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if ( buttonIndex != [actionSheet cancelButtonIndex] ) {
		// if can't take photo using camera, just display error message
		if ( ( buttonIndex == 0 ) && ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ) {
			UIAlertView *noCameraAlert = [[UIAlertView alloc]
									   initWithTitle:@"Error!" 
									   message:@"Sorry, you need a device with a camera."
									   delegate:nil
									   cancelButtonTitle:@"Bummer"
									   otherButtonTitles:nil];
			
			[noCameraAlert show];
			[noCameraAlert release];
			
			return;
		}
		
		if (!self.imagePickerController) {
			UIImagePickerController *picker = [[UIImagePickerController alloc] init];
			
			self.imagePickerController = picker;
			self.imagePickerController.delegate = self;
			
			[picker release];
		}
		
		// take a picture
		if ( buttonIndex == 0 ) {
			self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
			//_imagePickerController.allowsImageEditing = YES;
		}
		// choose existing photo
		else if ( buttonIndex == 1 ) {
			self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
		}
		
		[self presentModalViewController:self.imagePickerController animated:YES];
	}
}

#pragma mark -
#pragma mark UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
	
	if ([buttonTitle isEqualToString:@"Add Another"]) {
		[self showUploadActionSheet];
	}
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
	// save the original photo if the image came from camera?
	if ( picker.sourceType == UIImagePickerControllerSourceTypeCamera ) {
		UIImageWriteToSavedPhotosAlbum( image, nil, nil, nil );
	}
	
	PhotoUploadViewController *uploadViewController = [[PhotoUploadViewController alloc] initWithNibName:@"PhotoUploadViewController" bundle:nil];
	uploadViewController.event = _currEvent;
	//uploadViewController.image = image;
	
	// XXX - is this leaking?
	UIImage *rotatedImage = [uploadViewController scaleAndRotateImage:image];
	uploadViewController.image = rotatedImage;
	uploadViewController.delegate = self;
	
	[self.navigationController pushViewController:uploadViewController animated:NO];
	[uploadViewController release];
	
	//self.currEvent = nil;
	
	[picker dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[picker dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Network Calls

- (IBAction)refreshEventList {
	// if there's already a request going, then jump out
	if (eventsRequest)
		return;
	
	self.changeIsUserDriven = YES;
	
	self.eventsRequest = nil;
	self.error = nil;
	
	MeetupAsyncRequest *eventsRequestTemp = [[MeetupAsyncRequest alloc] init];
	eventsRequestTemp.delegate = self;
	eventsRequestTemp.callback = @selector( didReceiveEvents: );
	eventsRequestTemp.errorCallback = @selector( failedReceivingEvents: );
	
	User *member = [[MeetupConnectionManager sharedManager] getAuthenticatedMember];
	
	self.currOffset = 0;
	self.tableView.scrollEnabled = NO;
	
	static NSTimeInterval intervalOneDay = 60 * 60 * 24;
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:kAPIDate];	
	self.afterDate = [dateFormatter stringFromDate:[[NSDate date] addTimeInterval:(intervalOneDay * -3.0)]];
	[dateFormatter release];
	
	NSString *params = [NSString stringWithFormat:@"member_id=%d&order=time&after=%@&before=12m&page=%d&offset=%d", member.userId, _afterDate, kEventsPageSize, _currOffset];
	[eventsRequestTemp doMethod:@"events" withParams:params withLoadingViewIn:self.tableContainingView andLoadingText:@"Loading Meetups..."];
	
	self.eventsRequest = eventsRequestTemp;
	[eventsRequestTemp release];
}

- (void)loadMoreEvents {
	// if there's already a request going, then jump out
	if (eventsRequest)
		return;
	
	self.changeIsUserDriven = YES;
	
	self.eventsRequest = nil;	
	self.error = nil;
	
	//[self.tableView reloadData];
	
	MeetupAsyncRequest *eventsRequestTemp = [[MeetupAsyncRequest alloc] init];
	eventsRequestTemp.delegate = self;
	eventsRequestTemp.callback = @selector( didReceiveMoreEvents: );
	eventsRequestTemp.errorCallback = @selector( failedReceivingMoreEvents: );
	
	User *member = [[MeetupConnectionManager sharedManager] getAuthenticatedMember];
	
	self.currOffset++;
	self.tableView.scrollEnabled = NO;
	
	NSString *params = [NSString stringWithFormat:@"member_id=%d&order=time&after=%@&before=12m&page=%d&offset=%d", member.userId, _afterDate, kEventsPageSize, _currOffset];
	[eventsRequestTemp doMethod:@"events" withParams:params withLoadingViewIn:self.tableContainingView andLoadingText:@"Loading More Meetups..."];
	
	self.eventsRequest = eventsRequestTemp;
	[eventsRequestTemp release];
}

- (void)didReceiveEvents:(NSDictionary *)response {
	// reset the context to remove event data
	[self clearEventsInCoreData];
	
	self.eventsRequest = nil;
	
	// need a fetched results controller
	self.fetchedResultsController = nil;
	[self fetchedResultsController];
	
	self.tableView.scrollEnabled = YES;
	
	//[[NSNotificationCenter defaultCenter] removeObserver:self name:@"AppDelegateDidReceiveUserData" object:nil];
	NSDictionary *eventsResultsJSON = [response objectForKey:@"results"];
	
	// if there aren't any more results, set the offset to -1!
	if ([eventsResultsJSON count] < kEventsPageSize)
		self.currOffset = -1;
	
	_totalEvents = 0;
	for (NSDictionary *eventResult in eventsResultsJSON) {
		Event *event = [Event insertIntoManagedObjectContext:_moContext withResponseObject:eventResult];
		NSLog(@"new event, id = %d", [event.eventId intValue]);
		
		self.totalEvents++;
	}
	
	// add the now cell and load more cells
	[self addOrUpdateNowCell];
	[self addOrUpdateLoadMoreCell];
	
	NSError *error = nil;
	[_moContext save:&error];
	NSAssert1(error == nil, @"error saving context: %@", [error localizedDescription]);		

	// now perform the fetch
	[[self fetchedResultsController] performFetch:&error];
	NSAssert1(error == nil, @"failed to retrieve results: %@", [error localizedDescription]);
	
	[self updatePersistingPrimitiveData];
	
	[_tableView reloadData];
	self.changeIsUserDriven = NO;
}

- (void)failedReceivingEvents:(NSError *)error {
	self.error = error;
	
	self.tableView.scrollEnabled = YES;
	
	self.eventsRequest = nil;
			
	[_tableView reloadData];
	self.changeIsUserDriven = NO;
}

- (void)didReceiveMoreEvents:(NSDictionary *)response {
	self.eventsRequest = nil;
	
	self.tableView.scrollEnabled = YES;
	
	//[[NSNotificationCenter defaultCenter] removeObserver:self name:@"AppDelegateDidReceiveUserData" object:nil];
	NSDictionary *eventsResultsJSON = [response objectForKey:@"results"];
	
	// if there aren't any more results, set the offset to -1!
	if (([eventsResultsJSON count] == 0) || ([eventsResultsJSON count] < 20))
		self.currOffset = -1;

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[Event getEntityDescription:_moContext]];
	
	NSError *error = nil;
	for (NSDictionary *eventResult in eventsResultsJSON) {
		// just make sure that we're not repeating any events on the table
		NSInteger eventId = [[eventResult objectForKey:@"id"] integerValue];
		[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"eventId == %d", eventId]];

		Event *event = [[_moContext executeFetchRequest:fetchRequest error:&error] lastObject];
		NSAssert1(error == nil, @"error accessing context: %@", [error localizedDescription]);	
		
		if (!event) {
			event = [Event insertIntoManagedObjectContext:_moContext withResponseObject:eventResult];
			NSLog(@"new event, id = %d", [event.eventId intValue]);
			
			self.totalEvents++;
		}
		else {
			[Event updateEvent:event withResponseObject:eventResult];
			NSLog(@"overwriting old event, id = %d", [event.eventId intValue]);
		}
	}

	[fetchRequest release];
	
	// update the now cell and load more cells
	[self addOrUpdateNowCell];
	[self addOrUpdateLoadMoreCell];
	
	[_moContext save:&error];
	NSAssert1(error == nil, @"error saving context: %@", [error localizedDescription]);		
	
	[self updatePersistingPrimitiveData];
	
	[_tableView reloadData];
	self.changeIsUserDriven = NO;
}

- (void)failedReceivingMoreEvents:(NSError *)error {
	self.eventsRequest = nil;
	
	self.tableView.scrollEnabled = YES;
	
	self.error = error;
	
	[_tableView reloadData];
	self.changeIsUserDriven = NO;
}

#pragma mark -
#pragma mark UI Methods

- (IBAction)updateTableViewAndJump {
	if (preventUpdating)
		return;
	
	// block the buttons if a request is happening
	if (eventsRequest)
		return;
	
	[self updateTableView];
	
	// scroll up to the top
	//[_tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
	
	[self jumpToNow];
}
	
- (void)updateTableView {
	self.changeIsUserDriven = YES;
	
	// reset numerical values
	self.shownEvents = 0;
	self.totalEvents = 0;
	
	// clear the old fetchresultscontroller
	self.fetchedResultsController = nil;
	[self fetchedResultsController];

	// XXX - these have to be added before the fetch
	[self addOrUpdateNowCell];
	[self addOrUpdateLoadMoreCell];
	
	NSError *error = nil;
	[[self fetchedResultsController] performFetch:&error];
	NSAssert1(error == nil, @"Failed to retrieve results: %@", [error localizedDescription]);
	
	[self updatePersistingPrimitiveData];
	
	[_tableView reloadData];
	self.changeIsUserDriven = NO;
}

- (void)addOrUpdateNowCell {
	// first check if there's a now cell and if so delete it
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	
	NSPredicate *isNowCellPredicate = [NSPredicate predicateWithFormat:@"eventId == %d", kNowCellId];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Event" inManagedObjectContext:_moContext]];
	[fetchRequest setPredicate:isNowCellPredicate];
	
	NSError *error = nil;
	NSArray *nowCellsArray = [_moContext executeFetchRequest:fetchRequest error:&error];

	self.nowEvent = nil;
	
	if (!error) {
		for (NSManagedObject *nowCell in nowCellsArray) {
			self.nowEvent = (Event *)nowCell;
			self.nowEvent.localDate = [NSDate date];
		}
	}

	[fetchRequest release];
	
	// add the now cell if it doesn't exist
	if (!_nowEvent) {
		self.nowEvent = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:_moContext];
		NSAssert1(error == nil, @"error accessing context: %@", [error localizedDescription]);
	
		// add values that will force this to show up all the time
		self.nowEvent.eventId = [NSNumber numberWithInteger:kNowCellId];
		self.nowEvent.localDate = [NSDate date];
	}
}

- (void)addOrUpdateLoadMoreCell {
	//NSArray *fetchedObjects = [_fetchedResultsController fetchedObjects];
	
	// get the displayed and total number of events in the list
	NSError *error = nil;
	
	// grab the last fetched object and use its local date to put it in the right sort location
	Event *loadMoreEvent = nil;
	Event *lastEvent = nil;
	
	NSFetchRequest *fetchRequest = nil;
	if (_segmentedControl.selectedSegmentIndex == 0)
		fetchRequest = [self attendingFetchRequest];
	else
		fetchRequest = [self showAllFetchRequest];
	
	NSArray *shownEventsArray = [_moContext executeFetchRequest:fetchRequest error:&error];
	self.shownEvents = 0;
	for (Event *event in shownEventsArray) {
		if ([event.eventId intValue] == kMoreEventsCellId)
			loadMoreEvent = (Event *)event;
		else if ([event.eventId intValue] > 0) {
			lastEvent = (Event *)event;
			self.shownEvents++;
		}
	}
	
	self.totalEvents = [self getTotalEventsInCoreDataCount];
	
	// if there's no last event date, then use the nowevent
	if (!lastEvent || (_nowEvent && [lastEvent.localDate compare:_nowEvent.localDate] == NSOrderedAscending)) {
		lastEvent = _nowEvent;
	}

	if (lastEvent != nil) {
		if (loadMoreEvent == nil) {
			NSError *error = nil;
			loadMoreEvent = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:_moContext];
			NSAssert1(error == nil, @"error accessing context: %@", [error localizedDescription]);
			
			loadMoreEvent.eventId = [NSNumber numberWithInteger:kMoreEventsCellId];
		}
	
		loadMoreEvent.localDate = lastEvent.localDate;
		loadMoreEvent.yesRsvpCount = [NSNumber numberWithInteger:_currOffset];
	}
}

- (IBAction)jumpToNow {	
	if (_nowEvent) {
		NSIndexPath *nowIndexPath = [_fetchedResultsController indexPathForObject:_nowEvent];
		
		if (nowIndexPath)
			[_tableView scrollToRowAtIndexPath:nowIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
	}
}

#pragma mark -
#pragma mark Table Data Source Methods

// http://developer.apple.com/iphone/library/documentation/CoreData/Reference/NSFetchedResultsController_Class/Reference/Reference.html
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NSUInteger count = [[_fetchedResultsController sections] count];

    /* XXX - agh don't do this, despite apple recommending you to do so (= real pain)
	if (count == 0) {
        count = 1;
    }
	*/
	
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSArray *sections = [_fetchedResultsController sections];
    NSUInteger count = 0;
	
    if ([sections count]) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
        count = [sectionInfo numberOfObjects];
    }
	
    return count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	int count = [[_fetchedResultsController sections] count];
	
	if (count > section) {
		id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
		return [sectionInfo name];
	}
	
	return nil;
	
	//id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    //return [sectionInfo name];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [_fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
} 

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *EventTableCellIdentifier = @"EventTableCellIdentifier";
	static NSString *NowCellIdentifier        = @"NowCellIdentifier";
	static NSString *BasicTextCellIdentifier  = @"BasicTextCellIdentifier";
	
	Event *event = (Event *)[_fetchedResultsController objectAtIndexPath:indexPath];
	
	// if no event, then this is the now cell or more events cell
	UITableViewCell *cell = nil;
	if ([event.eventId intValue] == kNowCellId) {	
		cell = [tableView dequeueReusableCellWithIdentifier:NowCellIdentifier];
			
		if (cell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"NowCell" owner:self options:nil];
				
			for (id oneObject in nib) {
				if ([oneObject isKindOfClass:[NowCell class]]) {
					cell = oneObject;
					break;
				}
			}
		}
	}
	else if ([event.eventId intValue] == kMoreEventsCellId) {
		cell = [tableView dequeueReusableCellWithIdentifier:BasicTextCellIdentifier];
		
		if (cell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"BasicTextCell" owner:self options:nil];
			
			for (id oneObject in nib) {
				if ([oneObject isKindOfClass:[BasicTextCell class]]) {
					cell = oneObject;
					break;
				}
			}
		}	
	}
	else {
		cell = [tableView dequeueReusableCellWithIdentifier:EventTableCellIdentifier];
		
		if (cell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"EventTableCell" owner:self options:nil];
			
			for (id oneObject in nib) {
				if ([oneObject isKindOfClass:[EventTableCell class]]) {
					cell = oneObject;
					break;
				}
			}
		}
	}
	
	if (cell)
		[self configureCell:cell atIndexPath:indexPath];
	
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath*)indexPath
{
	Event *event = (Event *)[_fetchedResultsController objectAtIndexPath:indexPath];
	
	if ([cell isKindOfClass:[NowCell class]]) {
		NowCell *nowCell = (NowCell *)cell;
		
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:kShortTimeDate];
		
		nowCell.currentTimeLabel.text = [NSString stringWithFormat:@"Current Time: %@", [dateFormatter stringFromDate:event.localDate]];
		nowCell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		[dateFormatter release];
	}
	else if ([cell isKindOfClass:[BasicTextCell class]]) {
		BasicTextCell *moreEventsCell = (BasicTextCell *)cell;
		
		if (_currOffset == -1) {
			moreEventsCell.textLabel.text = @"No More Upcoming Meetups (Hit Refresh for Latest)";
			moreEventsCell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		else {
			moreEventsCell.textLabel.text = [NSString stringWithFormat:@"Load %d More Meetups...", kEventsPageSize];
			//moreEventsCell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		 
		BOOL showYesMaybeOnly = NO;
		if (_segmentedControl.selectedSegmentIndex == 0)
			showYesMaybeOnly = YES;	
		 
		if (_shownEvents == 0 && _totalEvents > 0) {
			moreEventsCell.subtextLabel.text = [NSString stringWithFormat:@"Select \"Show All\" to See All %d", _totalEvents];
		}
		else if (_shownEvents != _totalEvents) {
			if (showYesMaybeOnly)
				moreEventsCell.subtextLabel.text = [NSString stringWithFormat:@"Showing %d Attending of %d Total", _shownEvents, _totalEvents];
			else
				moreEventsCell.subtextLabel.text = [NSString stringWithFormat:@"Showing %d of %d Total (Notes Are Hidden)", _shownEvents, _totalEvents];
		}
		else {
			moreEventsCell.subtextLabel.text = [NSString stringWithFormat:@"Showing %d Total", _totalEvents];
		}
	}
	else if ([cell isKindOfClass:[EventTableCell class]]) {
		EventTableCell *eventCell = (EventTableCell *)cell;
		
		[eventCell.eventImage unsetImage];
		eventCell.eventImage.urlPath = event.photoUrl;
		eventCell.eventNameLabel.text = event.name;
		eventCell.groupNameLabel.text = event.groupName;
		eventCell.eventTimeLabel.text = event.eventTime;
		
		eventCell.eventDateLabel.text = event.eventShortDate;
		
		if ([event.myRsvp intValue] == RsvpResponseYes) {
			eventCell.rsvpLabel.text = @"Yes";
			eventCell.rsvpLabel.textColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:1.0];
		}
		else if ([event.myRsvp intValue] == RsvpResponseMaybe) {
			eventCell.rsvpLabel.text = @"Maybe";
			eventCell.rsvpLabel.textColor = [UIColor brownColor];
		}
		else if ([event.myRsvp intValue] == RsvpResponseNo) {
			eventCell.rsvpLabel.text = @"No";
			eventCell.rsvpLabel.textColor = [UIColor grayColor];
		}
		else {
			eventCell.rsvpLabel.text = @"None";
			eventCell.rsvpLabel.textColor = [UIColor lightGrayColor];
		}
	}
	else {
		NSLog(@"unable to configure cell at %@", indexPath);
	}
}

#pragma mark -
#pragma mark Table View Delegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// first deselect the row
	[tableView deselectRowAtIndexPath:indexPath animated:NO];

	Event *event = (Event *)[_fetchedResultsController objectAtIndexPath:indexPath];

	if ([event.eventId intValue] == kMoreEventsCellId) {
		if (_currOffset >= 0)
			[self loadMoreEvents];
	}
	else if ([event.eventId intValue] != kNowCellId) {
		_currEvent = event;
		[self showUploadActionSheet];
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	Event *event = (Event *)[_fetchedResultsController objectAtIndexPath:indexPath];
	
	if ([event.eventId intValue] == kNowCellId)
		return kNowCellHeight;
	//else if (event.eventId == kMoreEventsCellId)
	//	return kBasicTextCellHeight;
	
	return kEventTableCellHeight;
}

#pragma mark -
#pragma mark Core Data Methods

- (NSUInteger)getTotalEventsInCoreDataCount {
	NSError *error = nil;
	NSArray *allEventsArray = [_moContext executeFetchRequest:[self totalFetchRequest] error:&error];	
	
	NSUInteger totalEvents = 0;
	if (!error) {
		for (Event *event in allEventsArray) {
			if ([event.eventId intValue] > 0) {
				totalEvents++;
			}
		}
	}
	
	return totalEvents;
}

- (void)clearEventsInCoreData {
	NSError *error = nil;
	NSArray *eventsArray = [_moContext executeFetchRequest:[self totalFetchRequest] error:&error];
	
	if (!error) {
		for (NSManagedObject *event in eventsArray) {
			[_moContext deleteObject:event];
		}

		// save deletions
		[_moContext save:&error];
		NSAssert1(error == nil, @"error saving context: %@", [error localizedDescription]);	
	}	
}

#pragma mark -
#pragma mark Fetched Results Controller Delegate Methods

- (NSFetchRequest *)attendingFetchRequest {
	if (_attendingFetchRequest)
		return _attendingFetchRequest;
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[self setupEventsFetchRequest:fetchRequest showYesMaybeOnly:YES];
	self.attendingFetchRequest = fetchRequest;
	[fetchRequest release];
	
	return _attendingFetchRequest;
}

- (NSFetchRequest *)showAllFetchRequest {
	if (_showAllFetchRequest)
		return _showAllFetchRequest;
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[self setupEventsFetchRequest:fetchRequest showYesMaybeOnly:NO];
	self.showAllFetchRequest = fetchRequest;
	[fetchRequest release];
	
	return _showAllFetchRequest;
}

- (NSFetchRequest *)totalFetchRequest {
	if (_totalFetchRequest)
		return _totalFetchRequest;
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[Event getEntityDescription:_moContext]];
	self.totalFetchRequest = fetchRequest;
	[fetchRequest release];
	
	return _totalFetchRequest;
}
	
- (void)setupEventsFetchRequest:(NSFetchRequest *)fetchRequest showYesMaybeOnly:(BOOL)showYesMaybeOnly {
	NSEntityDescription *eventEntity = [Event getEntityDescription:_moContext];
	
	NSSortDescriptor *dateSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"localDate" ascending:YES];
	
	// this is somewhat lame
	NSSortDescriptor *idSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"eventId" ascending:NO];
	//NSSortDescriptor *nameSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:dateSortDescriptor, idSortDescriptor, nil];
	
	// skip events that are just notes
	NSPredicate *specialEventsPredicate = [NSPredicate predicateWithFormat:@"eventId IN %@", 
										   [NSArray arrayWithObjects:[NSNumber numberWithInt:kNowCellId], [NSNumber numberWithInt:kMoreEventsCellId], nil]];
	
	NSPredicate *isMeetupPredicate = [NSPredicate predicateWithFormat:@"isMeetup == YES"];
	NSPredicate *eventDateStringNilPredicate = [NSPredicate predicateWithFormat:@"localDate != $DATE"];
	eventDateStringNilPredicate = [eventDateStringNilPredicate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:[NSNull null] forKey:@"DATE"]];
	
	NSPredicate *compoundPredicate = nil;
	if (showYesMaybeOnly) {
		NSPredicate *showYesMaybePredicate = [NSPredicate predicateWithFormat:@"myRsvp IN %@", 
											  [NSArray arrayWithObjects:[NSNumber numberWithInt:RsvpResponseYes], [NSNumber numberWithInt:RsvpResponseMaybe], nil]];
		compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:isMeetupPredicate, eventDateStringNilPredicate, showYesMaybePredicate, nil]];
	}
	else {
		compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:isMeetupPredicate, eventDateStringNilPredicate, nil]];
	}
	
	[fetchRequest setEntity:eventEntity];
	[fetchRequest setFetchBatchSize:0];
	[fetchRequest setSortDescriptors:sortDescriptors];
	[fetchRequest setPredicate:[NSCompoundPredicate orPredicateWithSubpredicates:[NSArray arrayWithObjects:specialEventsPredicate, compoundPredicate, nil]]];
	
	[dateSortDescriptor release];
	//[nameSortDescriptor release];
	[idSortDescriptor release];
	[sortDescriptors release];
}

- (NSFetchedResultsController *)fetchedResultsController {
	if (_fetchedResultsController)
		return _fetchedResultsController;
	
	// figure out if we're only showing events you rsvp'd yes/maybe to
	NSFetchRequest *fetchRequest = nil;
	if (_segmentedControl.selectedSegmentIndex == 0)
		fetchRequest = [self attendingFetchRequest];
	else
		fetchRequest = [self showAllFetchRequest];
	
	NSFetchedResultsController *tempFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																								   managedObjectContext:_moContext
																									 sectionNameKeyPath:@"colloquialTime"
																							//		 sectionNameKeyPath:nil
																											  cacheName:nil];
	[tempFetchedResultsController setDelegate:self];
	self.fetchedResultsController = tempFetchedResultsController;
	[tempFetchedResultsController release];
	
	// executeFetchRequest:error:
	// countForFetchRequest:error:
	
	return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller {
    if (changeIsUserDriven)
		return;
	
	[_tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller {
    if (changeIsUserDriven)
		return;
	
	[_tableView endUpdates];
} 

- (void)controller:(NSFetchedResultsController*)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    if (changeIsUserDriven)
		return;
	
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[_tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
			break;
		case NSFetchedResultsChangeDelete:
			[_tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
			break;
	}
}

- (void)controller:(NSFetchedResultsController*)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath*)indexPath forChangeType:(NSFetchedResultsChangeType)type  newIndexPath:(NSIndexPath*)newIndexPath {	
    if (changeIsUserDriven)
		return;
	
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
			break;
		case NSFetchedResultsChangeDelete:
			[_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];			
			break;
		case NSFetchedResultsChangeUpdate:
			[self configureCell:[_tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			break;
		case NSFetchedResultsChangeMove:
			[_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
			[_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
			
			// Delete the section if it's now empty
			// http://iphonedevelopment.posterous.com/nsfetchedresultscontroller-didchangesection-d
			//if ([[_fetchedResultsController sections] count] == 1){
			//	[_tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
			//}
			
			break;
	}  
}

// "making nsfetchedresultscontroller my bitch"
// http://www.appleiphonetech.com/i-know-youre-tired-of-hearing-about-nsfetchedresultscontroller-but%E2%80%A6.html

@end
