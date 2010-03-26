//
//  PhotoUploadViewController.m
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

#import "PhotoUploadViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "MPOAuthAPIRequestLoader.h"
#import "MPURLRequestParameter.h"
#import "MeetupConnectionManager.h"
#import "Event.h"

#import "LoadingView.h"
#import "JSON.h"

#define kMaxCaptionLength 250

@implementation PhotoUploadViewController

@synthesize event = _event;
@synthesize image = _image;

@synthesize loader = _loader;
@synthesize oauthError = _oauthError;

@synthesize loadingView = _loadingView;

@synthesize imageView = _imageView;
@synthesize caption = _caption;

@synthesize delegate = _delegate;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		self.oauthError = nil;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(errorOccurred:) name:MPOAuthNotificationErrorHasOccurred object:nil];
	}
    
	return self;
}

- (void)loadView {
	[super loadView];
	
	UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:nil action:nil] autorelease];
	cancelButton.enabled = YES;
	cancelButton.target = self;
	cancelButton.action = @selector(cancelUpload:);
	
	self.navigationItem.backBarButtonItem = nil;
	self.navigationItem.hidesBackButton = YES;
	self.navigationItem.rightBarButtonItem = cancelButton;
}

- (void)cancelUpload:(id)sender {
	// otherwise just cancel the upload
	[_loader.oauthConnection cancel];

	// indicate that the transfer is finished in the loading view
	if (_loadingView) {
		[_loadingView cancelProgressBar];

		[self.navigationController performSelector:@selector(popViewControllerAnimated:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.6];
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		
	}
	else {
		// if upload isn't in progress, can just pop view back in
		[self.navigationController popViewControllerAnimated:YES];
	}
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	self.title = @"Photo to Upload";
	self.navigationItem.prompt = self.event.name;
	
	self.imageView.image = self.image;
	//_imageView.layer.borderWidth = 1.0;
	//_imageView.layer.borderColor = [UIColor blackColor].CGColor; 
	
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
		
	self.imageView = nil;
	self.caption = nil;
}

- (IBAction)upload {
	NSString *caption = [_caption text];
	NSString *eventId = [NSString stringWithFormat:@"%d", [_event.eventId intValue]];
	
	// XXX - check for memory issues here
	NSMutableArray *params = [[NSMutableArray alloc] initWithCapacity:3];
	
	// just do a quick ping to make sure we have a member object, otherwise bounce out because it'll error
	MeetupConnectionManager *manager = [MeetupConnectionManager sharedManager];
	[manager getAuthenticatedMember];
	
	MPURLRequestParameter *eventParam = [[MPURLRequestParameter alloc] initWithName:@"event_id" andValue:eventId];
	MPURLRequestParameter *captionParam = [[MPURLRequestParameter alloc] initWithName:@"caption" andValue:caption];
	[params addObject:eventParam];
	[params addObject:captionParam];
	[eventParam release];
	[captionParam release];
	
	self.loadingView = [LoadingView loadingViewInView:self.view withLabel:@"Uploading Photo" useProgressBar:YES];
	[self.loadingView updateProgressBar:0 totalBytesExpectedToWrite:-1];
	
	// XXX - rotation is weird. let's see if this works
	//UIImage *photoToUpload = [self scaleAndRotateImage:_image];
	UIImage *photoToUpload = _image;
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	// keep a reference of the loader so we can cancel the upload when needed
	self.loader = [manager.oauthAPI performPOSTImageMethod:@"photo" withParameters:params withImageParamName:@"photo" andImage:photoToUpload withTarget:self andAction:@selector(receivedPhotoResponse:withResponseString:)];
	
	[params release];
}

- (void)receivedPhotoResponse:(NSURL *)inURL withResponseString:(NSString *)inString {
	if (_loadingView)
		[_loadingView removeView];

	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
	self.navigationItem.rightBarButtonItem.enabled = YES;
	
	NSLog(@"%@", inString);

	if (_oauthError) {
		UIAlertView *errorAlert = [[UIAlertView alloc]
								   initWithTitle:@"Authentication Error" 
								   message:@"Cannot authenticate your account. Try logging in again."
								   delegate:nil
								   cancelButtonTitle:@"OK"
								   otherButtonTitles:nil];
		[errorAlert show];
		[errorAlert release];
	}
	else {
		// if we receive a response, just make sure we don't have a problem message
		NSDictionary *jsonResponse = [inString JSONValue];	
		
		//NSString *description = @"";
		NSString *problem = @"";
		NSString *details = @"";
		if (jsonResponse) {
			//description = [jsonResponse objectForKey:@"description"];
			problem = [jsonResponse objectForKey:@"problem"];
			details = [jsonResponse objectForKey:@"details"];
		}
					
		if ([problem length] > 0) {
			NSLog(@"problem with upload, got problem: %@, details: %@", problem, details);
			
			// this shouldn't happen if this is working right but just in case
			UIAlertView *errorAlert = [[UIAlertView alloc]
									   initWithTitle:@"API Error"
									   message:[NSString stringWithFormat:@"%@ %@", problem, details]
									   delegate:nil
									   cancelButtonTitle:@"OK"
									   otherButtonTitles:nil];
			[errorAlert show];
			[errorAlert release];				
		}
		else {
			NSLog(@"finished upload, got description: %@, details: %@", problem, details);
				
			UIAlertView *successAlert = [[UIAlertView alloc]
										 initWithTitle:@"Success!"
										 message:[NSString stringWithFormat:@"Your photo has been uploaded to the %@ album.", _event.name]
										 delegate:_delegate
										 cancelButtonTitle:@"OK"
										 otherButtonTitles:@"Add Another", nil];
			[successAlert show];
			[successAlert release];	
				
			[self.navigationController popViewControllerAnimated:YES];
			
			self.image = nil;
		}
	}
}

- (void)loader:(MPOAuthAPIRequestLoader *)loader didFailWithError:(NSError *)error {
	if (_loadingView)
		[_loadingView removeView];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
	self.navigationItem.rightBarButtonItem.enabled = YES;
	
	//NSString *errorString = [error description];
	
	UIAlertView *errorAlert = [[UIAlertView alloc]
							   initWithTitle:@"Connection Error" 
	//						   message:errorString
							   message:@"Unable to connect to Meetup.com. Please try again later."
							   delegate:nil
							   cancelButtonTitle:@"OK"
							   otherButtonTitles:nil];
	[errorAlert show];
	[errorAlert release];
}

- (void)loader:(MPOAuthAPIRequestLoader *)loader didSendBodyData:(NSArray *)bodyData {
	if (_loadingView) {
		//NSInteger bytesWritten = [(NSNumber *)[bodyData objectAtIndex:0] integerValue];
		NSInteger totalBytesWritten = [(NSNumber *)[bodyData objectAtIndex:1] integerValue];
		NSInteger totalBytesExpectedToWrite = [(NSNumber *)[bodyData objectAtIndex:2] integerValue];
	
		// looks like we're done, so disable that cancel button since it'd be pointless to cancel at this point
		// XXX - can't disable (http://stackoverflow.com/questions/536399/how-to-change-image-and-disable-uibarbuttonitem), so just hide it
		if (totalBytesWritten == totalBytesExpectedToWrite)
			self.navigationItem.rightBarButtonItem.enabled = NO;
		
		[_loadingView updateProgressBar:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
	}
}

- (void)errorOccurred:(NSNotification *)inNotification {
	static int OAUTH_ERROR_CODE = kOAuthErrorCode;
	
	NSDictionary *userInfo = [inNotification userInfo];
	NSError *tempError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:OAUTH_ERROR_CODE userInfo:userInfo];
	self.oauthError = tempError;
	
	[tempError release];
}

- (IBAction)textFieldDoneEditing:(id)sender {	
	[_caption resignFirstResponder];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	if (textField.text.length >= kMaxCaptionLength && range.length == 0 && ![string isEqual:@"\n"])
		return NO;
	
	return YES;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:MPOAuthNotificationErrorHasOccurred object:nil];
	[_loader release];
	[_oauthError release];
	[_loadingView release];
	[_delegate release];
	
	[_event release];
	[_image release];
	[_imageView release];
	[_caption release];
	
    [super dealloc];
}

#pragma mark Convenience Functions for Image Picking

// borrowed from http://praveenmatanam.wordpress.com/2008/07/22/how-to-rotate-the-image-to-its-proper-state/

- (UIImage *)scaleAndRotateImage:(UIImage *)image
{
	int kMaxResolution = 1024; // Or whatever
	
	CGImageRef imgRef = image.CGImage;
	
	CGFloat width = CGImageGetWidth(imgRef);
	CGFloat height = CGImageGetHeight(imgRef);
	
	CGAffineTransform transform = CGAffineTransformIdentity;
	CGRect bounds = CGRectMake(0, 0, width, height);
	if (width > kMaxResolution || height > kMaxResolution) {
		CGFloat ratio = width/height;
		if (ratio > 1) {
			bounds.size.width = kMaxResolution;
			bounds.size.height = bounds.size.width / ratio;
		}
		else {
			bounds.size.height = kMaxResolution;
			bounds.size.width = bounds.size.height * ratio;
		}
	}
	
	CGFloat scaleRatio = bounds.size.width / width;
	CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
	CGFloat boundHeight;
	UIImageOrientation orient = image.imageOrientation;
	switch(orient) {
			
		case UIImageOrientationUp: //EXIF = 1
			transform = CGAffineTransformIdentity;
			break;
			
		case UIImageOrientationUpMirrored: //EXIF = 2
			transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			break;
			
		case UIImageOrientationDown: //EXIF = 3
			transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
			transform = CGAffineTransformRotate(transform, M_PI);
			break;
			
		case UIImageOrientationDownMirrored: //EXIF = 4
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
			transform = CGAffineTransformScale(transform, 1.0, -1.0);
			break;
			
		case UIImageOrientationLeftMirrored: //EXIF = 5
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
			
		case UIImageOrientationLeft: //EXIF = 6
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
			
		case UIImageOrientationRightMirrored: //EXIF = 7
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeScale(-1.0, 1.0);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);
			break;
			
		case UIImageOrientationRight: //EXIF = 8
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);
			break;
			
		default:
			[NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
			
	}
	
	UIGraphicsBeginImageContext(bounds.size);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
		CGContextScaleCTM(context, -scaleRatio, scaleRatio);
		CGContextTranslateCTM(context, -height, 0);
	}
	else {
		CGContextScaleCTM(context, scaleRatio, -scaleRatio);
		CGContextTranslateCTM(context, 0, -height);
	}
	
	CGContextConcatCTM(context, transform);
	
	CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
	UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return imageCopy;
}


@end
