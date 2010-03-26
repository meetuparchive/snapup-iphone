//
//  Event.h
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

#import <Foundation/Foundation.h>

typedef enum {
	RsvpResponseNone,
    RsvpResponseYes,
	RsvpResponseMaybe,
    RsvpResponseNo
} RsvpResponse;

@interface Event : NSManagedObject {
	NSNumber	*eventId;
	NSString	*name;
	NSString	*eventDesc;
	NSString	*photoUrl;
	NSString	*groupName;
	
	NSDate		*localDate;
	NSString	*eventTime;
	NSString	*eventShortDate;
	
	NSString	*colloquialTime;
	
	NSNumber	*yesRsvpCount;
	NSNumber	*maybeRsvpCount;
	NSNumber	*noRsvpCount;
	
	NSNumber	*myRsvp;
	NSNumber	*isMeetup;
}

@property (nonatomic, retain)	NSNumber	*eventId;
@property (nonatomic, retain)	NSString	*name;
@property (nonatomic, retain)	NSString	*eventDesc;
@property (nonatomic, retain)	NSString	*photoUrl;
@property (nonatomic, retain)	NSString	*groupName;

@property (nonatomic, retain)	NSDate		*localDate;
@property (nonatomic, retain)	NSString	*eventTime;
@property (nonatomic, retain)	NSString	*eventShortDate;

@property (nonatomic, retain)	NSString	*colloquialTime;

@property (nonatomic, retain)	NSNumber	*yesRsvpCount;
@property (nonatomic, retain)	NSNumber	*maybeRsvpCount;
@property (nonatomic, retain)	NSNumber	*noRsvpCount;

@property (nonatomic, retain)	NSNumber	*myRsvp;
@property (nonatomic, retain)	NSNumber	*isMeetup;

+ (NSEntityDescription *)getEntityDescription:(NSManagedObjectContext *)moContext;
+ (Event *)insertIntoManagedObjectContext:(NSManagedObjectContext *)moContext withResponseObject:(NSDictionary *)response;
+ (void)updateEvent:(Event *)event withResponseObject:(NSDictionary *)response;

@end
