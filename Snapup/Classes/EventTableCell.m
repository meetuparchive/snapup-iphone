//
//  EventTableCell.m
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

#import "EventTableCell.h"
#import "Three20/Three20.h"

@implementation EventTableCell

@synthesize eventImage;
@synthesize eventNameLabel;
@synthesize groupNameLabel;
@synthesize rsvpLabel;
@synthesize eventTimeLabel;
@synthesize eventDateLabel;


- (void)layoutSubviews {
	[super layoutSubviews];
	
	// scale the image down to table cell size
	self.eventImage.opaque = YES;
	self.eventImage.contentMode = UIViewContentModeScaleAspectFill;
	self.eventImage.clipsToBounds = YES;
	self.eventImage.userInteractionEnabled = NO;
	
	// round the edges of the image
	self.eventImage.style = [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithTopLeft:10 topRight:10 bottomRight:10 bottomLeft:10] 
													next:[TTContentStyle styleWithNext:nil]]; 
}


- (void)dealloc {
	TT_RELEASE_SAFELY( eventImage );
	[eventNameLabel release];
	[groupNameLabel release];
	
	[rsvpLabel release];
	[eventTimeLabel release];
	[eventDateLabel release];
    [super dealloc];
}

/*
- (void)setPhotoUrl:(NSString *)newEventImageUrl {
	if (newEventImageUrl != eventImageUrl) {
		[eventImageUrl release];
		eventImageUrl = [newEventImageUrl copy];
	}
	
	// need to use some photo image cache
	if ([photoUrl length] != 0) {
		UIImage *photo = [[TTURLCache sharedCache] imageForURL:photoUrl];
		
		if (photo != nil) {
			UIImage *thumb = [[PhotoTableViewCellView class] thumbWithImage:photo url:_photoUrl];		
			[self.eventImage setImage:thumb];
		} else {
			TTURLRequest *photoRequest = [TTURLRequest requestWithURL:self.photoUrl delegate:self];
			
			TTURLImageResponse *response = [[TTURLImageResponse alloc] init];
			photoRequest.response = response;
			[response release];
			
			if ([photoRequest send]) { // if the image can be returned synchronously
				UIImage *thumb = [[PhotoTableViewCellView class] thumbWithImage:((TTURLImageResponse *) photoRequest.response).image url:_photoUrl];	
				[self.eventImage setImage:thumb];
				//[self.eventImage reload];
			} else {
				self.photoRequest = photoRequest;
			}
		}
	}
}
*/

/*
#pragma mark -
#pragma mark TTURLRequestDelegate Methods

- (void)requestDidFinishLoad:(TTURLRequest *)request {
	[self.eventImage setImage:((TTURLImageResponse *) request.response).image];
	
	[_photoRequest release];
	_photoRequest = nil;
	
	//[self.eventImage reload];
}
*/

@end
