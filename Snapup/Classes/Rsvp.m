//
//  Rsvp.m
//  Meetup
//
//  Created by Vernon Thommeret on 8/18/09.
//  Copyright 2009 Vernon Thommeret. All rights reserved.
//

#import "Rsvp.h"
#import "User.h"

@implementation Rsvp

@synthesize user	 = _user;
@synthesize event	 = _event;
@synthesize response = _response;

- (void)dealloc {
	[_user release];
	[_event release];
	
	[super dealloc];
}

- (id)initWithResponseObject:(NSDictionary *)response {
	if (self = [super init]) {
		// rsvp response and http response are different things...
		NSString *rsvpResponse = [response objectForKey:@"response"];
		
		if ([rsvpResponse isEqualToString:@"yes"]) {
			self.response = RsvpResponseYes;
		} else if ([rsvpResponse isEqualToString:@"maybe"]) {
			self.response = RsvpResponseMaybe;
		} else if ([rsvpResponse isEqualToString:@"no"]) {
			self.response = RsvpResponseNo;
		} else { // [rsvpResponse isEqualToString:@"none"]
			self.response = RsvpResponseNone;
		}
		
		User *user = [[User alloc] init];
		user.userId   = [[response objectForKey:@"id"] intValue];
		user.name     = [response objectForKey:@"name"];
		user.photoUrl = [response objectForKey:@"photo_url"];
		
		self.user = user;
		[user release];
	}
	return self;
}

@end
