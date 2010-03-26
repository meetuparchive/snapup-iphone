//
//  MeetupAsyncRequest.h
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

@class LoadingView;

/**
 Allows you to execute an asynchronous request against the Meetup API. The response,
 if successful, is delivered to the delegate's callback.
 */
@interface MeetupAsyncRequest : NSObject {
	id _delegate;
	SEL _callback;
	SEL _errorCallback;
	
	NSError *_oauthError;
	
	LoadingView *_loadingView;
	
	NSMutableData *_receivedData;
	NSURLRequest *_urlRequest;
	NSURLConnection *_urlConnection;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) SEL callback;
@property (nonatomic, assign) SEL errorCallback;

@property (nonatomic, retain) NSError *oauthError;

@property (nonatomic, retain) LoadingView *loadingView;

@property (nonatomic, retain) NSMutableData *receivedData;
@property (nonatomic, retain) NSURLRequest *urlRequest;
@property (nonatomic, retain) NSURLConnection *urlConnection;

- (void)doMethod:(NSString *)method withParams:(NSString *)params;
- (void)doMethod:(NSString *)method withParams:(NSString *)params withLoadingViewIn:(UIView *)view andLoadingText:(NSString *)loadingText;

// for non-oauth requests
- (void)doNonOAuthRequest:(NSString *)url withLoadingViewIn:(UIView *)view andLoadingText:(NSString *)loadingText;

@end
