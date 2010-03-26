//
//  Location.m
//  Meetup
//
//  Created by Vernon Thommeret on 7/22/09.
//  Copyright 2009 Vernon Thommeret. All rights reserved.
//

#import "Location.h"

@implementation Location

@synthesize title		= _title;
@synthesize address1	= _address1;
@synthesize address2	= _address2;
@synthesize address3	= _address3;
@synthesize city		= _city;
@synthesize state		= _state;
@synthesize country		= _country;
@synthesize zip			= _zip;
@synthesize lat			= _lat;
@synthesize lon			= _lon;
@synthesize phone		= _phone;

- (void)dealloc {
	[_title release];
	[_address1 release];
	[_address2 release];
	[_address3 release];
	[_city release];
	[_state release];
	[_country release];
	[_zip release];
	[_phone release];
	
	[super dealloc];
}

- (NSString *)mapDescription {
	NSString *region = @"";
	NSString *cityState = @"";
	
	// prepare the city, state substring using what we have available
	if ([self.city length] != 0 && [self.state length] != 0) {
		cityState = [NSString stringWithFormat:@"%@, %@", self.city, self.state];
	} else if ([self.city length] != 0) {
		cityState = self.city;
	} else if (self.state) {
		cityState = self.state;
	}
	
	// tack on the zip code if the city state was available, or just use the zipcode otherwise
	if ([cityState length] != 0 && [self.zip length] != 0) {
		region = [NSString stringWithFormat:@"%@ %@", cityState, self.zip];
	} else if ([self.zip length] != 0) {
		region = self.zip;
	}
	
	NSMutableArray *locationComponents = [NSMutableArray arrayWithCapacity:2];
	
	// add the first line of the address, if it's available
	if ([self.address1 length] != 0) {
		[locationComponents addObject:self.address1];
	}
	
	// add the region, if it's available
	if ([region length] != 0) {
		[locationComponents addObject:region];
	}
	
	// if neither the title nor the region were available, then just add the lat, lon if we have it
	if (self.lat && self.lon && [self.title length] == 0 && [region length] == 0) {
		[locationComponents addObject:[NSString stringWithFormat:@"%f,%f", self.lat, self.lon]];
	}
	
	return [locationComponents componentsJoinedByString:@", "];
}

- (NSString *)shortDescription {
	NSString *shortDescription = @"";
	
	if ([self.title length] != 0) {
		shortDescription = self.title;
	} else if ([self.city length] != 0 && [self.state length] != 0) {
		shortDescription = [NSString stringWithFormat:@"%@, %@", self.city, self.state];
	} else if ([self.city length] != 0) {
		shortDescription = self.city;
	} else if ([self.state length] != 0) {
		shortDescription = self.state;
	}
	
	// tack on the zip code if the city state was available, or just use the zipcode otherwise
	if ([shortDescription length] != 0 && [self.zip length] != 0) {
		shortDescription = [NSString stringWithFormat:@"%@ %@", shortDescription, self.zip];
	} else if ([self.zip length] != 0) {
		shortDescription = self.zip;
	}
	
	// if neither the title nor the region were available, then just add the lat, lon if we have it
	if (self.lat && self.lon && [self.title length] == 0 && [shortDescription length] == 0) {
		shortDescription = [NSString stringWithFormat:@"%f,%f", self.lat, self.lon];
	}
	
	return shortDescription;
}

- (NSString *)description {
	NSString *region = @"";
	NSString *cityState = @"";
	
	// prepare the city, state substring using what we have available
	if ([self.city length] != 0 && [self.state length] != 0) {
		cityState = [NSString stringWithFormat:@"%@, %@", self.city, self.state];
	} else if ([self.city length] != 0) {
		cityState = self.city;
	} else if (self.state) {
		cityState = self.state;
	}
	
	// tack on the zip code if the city state was available, or just use the zipcode otherwise
	if ([cityState length] != 0 && [self.zip length] != 0) {
		region = [NSString stringWithFormat:@"%@ %@", cityState, self.zip];
	} else if ([self.zip length] != 0) {
		region = self.zip;
	}
	
	NSMutableArray *locationComponents = [NSMutableArray arrayWithCapacity:3];
	
	// add the title, if it's available
	if ([self.title length] != 0) {
		[locationComponents addObject:self.title];
	}
	
	// add the address, if it's available
	if ([self.address1 length] != 0) {
		[locationComponents addObject:self.address1];
	}
	if ([self.address2 length] != 0) {
		[locationComponents addObject:self.address2];
	}
	if ([self.address3 length] != 0) {
		[locationComponents addObject:self.address3];
	}
	
	// add the region, if it's available
	if ([region length] != 0) {
		[locationComponents addObject:region];
	}
	
	// if neither the title nor the region were available, then just add the lat, lon if we have it
	if (self.lat && self.lon && [self.title length] == 0 && [region length] == 0) {
		[locationComponents addObject:[NSString stringWithFormat:@"%f,%f", self.lat, self.lon]];
	}
	
	return [locationComponents componentsJoinedByString:@"\n"];
}

@end
