//
//  NSDate+StringFunctions.m
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

#import "NSDate+StringFunctions.h"

#import <Three20/NSDateAdditions.h>

@implementation NSDate (StringFunctions)

// modified from: http://github.com/billymeltdown/nsdate-helper/blob/b74ce1c0b8b46340adaa9dda7004d71bfe96b64e/NSDate+Helper.m
+ (NSDate *)beginningOfWeek:(NSDate *)aDate {
	// largely borrowed from "Date and Time Programming Guide for Cocoa"
	// we'll use the default calendar and hope for the best
	
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDate *beginningOfWeek = nil;
	BOOL ok = [calendar rangeOfUnit:NSWeekCalendarUnit startDate:&beginningOfWeek
						   interval:NULL forDate:aDate];
	if (ok) {
		return beginningOfWeek;
	}
	
	// couldn't calc via range, so try to grab Sunday, assuming gregorian style
	// Get the weekday component of the current date
	NSDateComponents *weekdayComponents = [calendar components:NSWeekdayCalendarUnit fromDate:aDate];
	
	/*
	 Create a date components to represent the number of days to subtract from the current date.
	 The weekday value for Sunday in the Gregorian calendar is 1, so subtract 1 from the number of days to subtract from the date in question. (If today's Sunday, subtract 0 days.)
	 */
	NSDateComponents *componentsToSubtract = [[NSDateComponents alloc] init];
	[componentsToSubtract setDay: 0 - ([weekdayComponents weekday] - 1)];
	beginningOfWeek = nil;
	beginningOfWeek = [calendar dateByAddingComponents:componentsToSubtract toDate:aDate options:0];
	[componentsToSubtract release];
	
	//normalize to midnight, extract the year, month, and day components and create a new date from those components.
	NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
											   fromDate:beginningOfWeek];
	return [calendar dateFromComponents:components];
}

- (NSString *)relativeToNowString {
	static NSTimeInterval intervalOneDay = 60 * 60 * 24;
	
	NSDate *nowDate = [NSDate date];
	
	// time intervals
	NSTimeInterval eventTimeInterval = [self timeIntervalSinceDate:nowDate];
	NSTimeInterval sinceMidnightInterval = [[nowDate dateAtMidnight] timeIntervalSinceDate:nowDate];
	
	// put events in their correct intervals
	if ( eventTimeInterval < (sinceMidnightInterval - intervalOneDay * 4.0) ) {
		return @"Older";
	}
	else if ( eventTimeInterval < (sinceMidnightInterval - intervalOneDay) ) {
		return @"Past Three Days";
	}
	else if ( eventTimeInterval < sinceMidnightInterval ) {
		return @"Yesterday";
	}
	else if ( eventTimeInterval < (sinceMidnightInterval + intervalOneDay) ) {
		return @"Today";
	}
	else if ( eventTimeInterval < (sinceMidnightInterval + 2 * intervalOneDay) ) {
		return @"Tomorrow";
	}
	
	// this week and next week ends
	NSDate *beginningOfNextWeek = [[NSDate beginningOfWeek:nowDate] addTimeInterval:(intervalOneDay * 7.0)];
	NSDate *beginningOfTwoWeeks = [beginningOfNextWeek addTimeInterval:(intervalOneDay * 7.0)];
	NSDate *beginningOfThreeWeeks = [beginningOfTwoWeeks addTimeInterval:(intervalOneDay * 7.0)];
	
	NSTimeInterval beforeNextWeekInterval = [beginningOfNextWeek timeIntervalSinceDate:nowDate];
	NSTimeInterval beforeTwoWeeksInterval = [beginningOfTwoWeeks timeIntervalSinceDate:nowDate];
	NSTimeInterval beforeThreeWeeksInterval = [beginningOfThreeWeeks timeIntervalSinceDate:nowDate];
	
	if ( eventTimeInterval < beforeNextWeekInterval ) {
		return @"This Week";
	}
	else if ( eventTimeInterval < beforeTwoWeeksInterval ) {
		return @"Next Week";
	}
	else if ( eventTimeInterval < beforeThreeWeeksInterval ) {
		return @"In Two Weeks";
	}
	
	return @"Upcoming Later";
}

@end
