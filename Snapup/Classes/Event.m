//
//  Event.m
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
#import "Event.h"

#import "NSDate+StringFunctions.h"

@implementation Event

// event basic details
@dynamic eventId;
@dynamic name;
@dynamic eventDesc;
@dynamic photoUrl;
@dynamic groupName;

@dynamic localDate;
@dynamic eventTime;
@dynamic eventShortDate;

@dynamic colloquialTime;

// rsvp counts
@dynamic yesRsvpCount;
@dynamic maybeRsvpCount;
@dynamic noRsvpCount;

@dynamic myRsvp;
@dynamic isMeetup;

+ (NSEntityDescription *)getEntityDescription:(NSManagedObjectContext *)moContext {
	return [NSEntityDescription entityForName:@"Event" inManagedObjectContext:moContext];
}

+ (Event *)insertIntoManagedObjectContext:(NSManagedObjectContext *)moContext withResponseObject:(NSDictionary *)response {
	NSError *error = nil;
	
	Event *event = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:moContext];
	NSAssert1(error == nil, @"error accessing context: %@", [error localizedDescription]);

	[Event updateEvent:event withResponseObject:response];
	
	return event;
}

+ (void)updateEvent:(Event *)event withResponseObject:(NSDictionary *)response {
	NSInteger eventId = [[response objectForKey:@"id"] integerValue];
	event.eventId = [NSNumber numberWithInteger:eventId];
	
	event.name = [response objectForKey:@"name"];
	event.eventDesc = [response objectForKey:@"description"];
	event.photoUrl = [response objectForKey:@"photo_url"];
	event.groupName = [response objectForKey:@"group_name"];
	
	event.yesRsvpCount = [NSNumber numberWithInteger:[[response objectForKey:@"rsvpcount"] integerValue]];
	event.maybeRsvpCount = [NSNumber numberWithInteger:[[response objectForKey:@"maybe_rsvpcount"] integerValue]];
	event.noRsvpCount = [NSNumber numberWithInteger:[[response objectForKey:@"no_rsvpcount"] integerValue]];
	
	event.isMeetup = [NSNumber numberWithBool:([[response objectForKey:@"ismeetup"] integerValue] == 1)];
	
	// date (XXX - make sure all dates can be parsed)
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:kDatabaseDate];
	
	NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
	[timeFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	NSDate *localDate = [dateFormatter dateFromString:[response objectForKey:@"time"]];
	event.localDate = localDate;
	event.eventTime = [timeFormatter stringFromDate:localDate];
	
	// add the short date to all events
	NSDateFormatter *superShortDateFormatter = [[NSDateFormatter alloc] init];
	[superShortDateFormatter setDateFormat:kSuperShortDate];
	
	event.eventShortDate = [superShortDateFormatter stringFromDate:event.localDate]; 
	
	[dateFormatter release];
	[timeFormatter release];
	[superShortDateFormatter release];
	
	// my rsvp
	NSString *myRsvp = [response objectForKey:@"myrsvp"];
	RsvpResponse rsvpResponse = RsvpResponseNone;
	
	if ([myRsvp isEqualToString:@"yes"]) {
		rsvpResponse = RsvpResponseYes;
	} else if ([myRsvp isEqualToString:@"maybe"]) {
		rsvpResponse = RsvpResponseMaybe;
	} else if ([myRsvp isEqualToString:@"no"]) {
		rsvpResponse = RsvpResponseNo;
	}
	
	event.myRsvp = [NSNumber numberWithInteger:rsvpResponse];
}

- (NSString *)colloquialTime {
    [self willAccessValueForKey:@"colloquialTime"];
    NSString *relativeToNowString = [[self localDate] relativeToNowString];
	
    [self didAccessValueForKey:@"colloquialTime"];
    return relativeToNowString;
}

- (void)awakeFromFetch {
	[super awakeFromFetch];
	
	//NSString *relativeToNowString = [self localDate];
	//[self setPrimitiveValue:[relativeToNowString] forKey:"@colloquialTime"];
}

@end
