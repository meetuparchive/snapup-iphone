//
//  MeetupAsyncRequest.m
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

#import "MeetupConnectionManager.h"
#import "MeetupAsyncRequest.h"
#import "LoadingView.h"

#import "MPURLRequestParameter.h"
#import "MPOAuthAPIRequestLoader.h"
#import "JSON.h"

@interface MeetupAsyncRequest (Private)
- (void)didFinishLoading:(NSString *)responseString;
- (void)didFailWithError:(NSError *)error;
- (void)didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;
@end

@implementation MeetupAsyncRequest

@synthesize delegate = _delegate;
@synthesize callback = _callback;
@synthesize errorCallback = _errorCallback;

@synthesize oauthError = _oauthError;

@synthesize loadingView = _loadingView;

@synthesize receivedData = _receivedData;
@synthesize urlRequest = _urlRequest;
@synthesize urlConnection = _urlConnection;

-(id)init {
	if (self = [super init]) {
		self.oauthError = nil;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(errorOccurred:) name:MPOAuthNotificationErrorHasOccurred object:nil];
    }
	
    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:MPOAuthNotificationErrorHasOccurred object:nil];
	[_oauthError release];
	[_loadingView release];
	
	[_urlConnection release];
	[_receivedData release];
	[_urlRequest release];	
	
	[super dealloc];
}

- (void)doMethod:(NSString *)method withParams:(NSString *)paramsString {
	[self doMethod:method withParams:paramsString withLoadingViewIn:nil andLoadingText:nil];
}

- (void)doMethod:(NSString *)method withParams:(NSString *)paramsString withLoadingViewIn:(UIView *)view andLoadingText:(NSString *)loadingText {
	NSArray *params = nil;
	if (paramsString.length > 0) {
		params = [MPURLRequestParameter parametersFromString:paramsString];
	}
	
	MeetupConnectionManager *manager = [MeetupConnectionManager sharedManager];
	MPOAuthAPI *oauthAPI = manager.oauthAPI;
	
	if (view && loadingText)
		self.loadingView = [LoadingView loadingViewInView:view withLabel:loadingText useProgressBar:NO];
	
	[oauthAPI performMethod:method atURL:oauthAPI.baseURL withParameters:params withTarget:self andAction:@selector(methodLoadedFromURL:withResponseString:)];
}

- (void)doNonOAuthRequest:(NSString *)urlString withLoadingViewIn:(UIView *)view andLoadingText:(NSString *)loadingText {
	NSURL *url = [NSURL URLWithString:urlString];
	NSLog(@"requesting %@", url);
	
	if (view && loadingText)
		self.loadingView = [LoadingView loadingViewInView:view withLabel:loadingText];
	
	NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url];
	NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
	
	if (urlConnection)
		self.receivedData = [NSMutableData data];
	
	self.urlRequest = urlRequest;
	self.urlConnection = urlConnection;
	
	[urlRequest release];
	[urlConnection release];
}

#pragma mark -
#pragma mark Asynchronous Request Methods

- (void)didFinishLoading:(NSString *)responseString {
	if (_loadingView)
		[_loadingView removeView];
	
	// if we had an oauth error, call the errorCallback instead
	if (_oauthError) {
		if (self.delegate && self.errorCallback && [self.delegate respondsToSelector:self.errorCallback]) {
			[self.delegate performSelectorOnMainThread:self.errorCallback withObject:_oauthError waitUntilDone:NO];
			
			UIAlertView *errorAlert = [[UIAlertView alloc]
									   initWithTitle:@"Authentication Error" 
									   message:@"Cannot authenticate your account. Try logging in again."
									   delegate:nil
									   cancelButtonTitle:@"OK"
									   otherButtonTitles:nil];
			[errorAlert show];
			[errorAlert release];
		}
	}
	else if (self.delegate && self.callback && [self.delegate respondsToSelector:self.callback]) {
		NSDictionary *jsonResponse = [responseString JSONValue];
		
		if (jsonResponse) {
			[self.delegate performSelectorOnMainThread:self.callback withObject:jsonResponse waitUntilDone:NO];
		}
	}
}

- (void)didFailWithError:(NSError *)error {
	if (_loadingView)
		[_loadingView removeView];
	
	if (self.delegate && self.errorCallback && [self.delegate respondsToSelector:self.errorCallback]) {
		[self.delegate performSelectorOnMainThread:self.errorCallback withObject:error waitUntilDone:NO];
	}
	
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

- (void)didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
	if (_loadingView)
		[_loadingView updateProgressBar:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
}

#pragma mark -
#pragma mark MPOAuthRequest Delegate Methods

- (void)methodLoadedFromURL:(NSURL *)inURL withResponseString:(NSString *)inString {
	[self didFinishLoading:inString];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:MPOAuthNotificationErrorHasOccurred object:nil];
}

- (void)loader:(MPOAuthAPIRequestLoader *)loader didFailWithError:(NSError *)error {
	[self didFailWithError:error];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:MPOAuthNotificationErrorHasOccurred object:nil];
}

- (void)loader:(MPOAuthAPIRequestLoader *)loader didSendBodyData:(NSArray *)bodyData {
	NSInteger bytesWritten = [(NSNumber *)[bodyData objectAtIndex:0] integerValue];
	NSInteger totalBytesWritten = [(NSNumber *)[bodyData objectAtIndex:1] integerValue];
	NSInteger totalBytesExpectedToWrite = [(NSNumber *)[bodyData objectAtIndex:2] integerValue];
	
	[self didSendBodyData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
}

- (void)errorOccurred:(NSNotification *)inNotification {
	static int OAUTH_ERROR_CODE = kOAuthErrorCode;
	
	NSDictionary *userInfo = [inNotification userInfo];
	NSError *tempError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:OAUTH_ERROR_CODE userInfo:userInfo];
	self.oauthError = tempError;
	
	[tempError release];
}
	
#pragma mark -
#pragma mark URL Connection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[self.receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self.receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[_urlConnection release];
	[_receivedData release];
	[_urlRequest release];
	
	_urlConnection = nil;
	_receivedData = nil;
	_urlRequest = nil;
	
	[self didFailWithError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {	
	NSString *strResponse = [[NSString alloc] initWithData:self.receivedData encoding:NSASCIIStringEncoding];

	[self didFinishLoading:strResponse];
	
	// getting leaks on NSURLConnection, and not really changing responses, so this is the suggested solution
	// http://forums.macrumors.com/showthread.php?t=573253
	[[NSURLCache sharedURLCache] setMemoryCapacity:0];
	[[NSURLCache sharedURLCache] setDiskCapacity:0];
	NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
	[NSURLCache setSharedURLCache:sharedCache];
	[sharedCache release];
	
	[_urlConnection release];
	[_receivedData release];
	[_urlRequest release];
	
	_urlConnection = nil;
	_receivedData = nil;
	_urlRequest = nil;
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
	[self didSendBodyData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
}

@end
