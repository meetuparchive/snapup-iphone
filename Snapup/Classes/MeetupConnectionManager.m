//
//  MeetupConnectionManager.m
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
//
//  Singleton code is borrowed from:
//  http://iphone.galloway.me.uk/iphone-sdktutorials/singleton-classes/

#import "MeetupConnectionManager.h"
#import "MPURLRequestParameter.h"
#import "SnapupAppDelegate.h"
#import "LoadingView.h"
#import "JSON.h"
#import "User.h"

#define kConsumerKey		@"key"
#define kConsumerSecret		@"secret"
#define kAuthenticationURL	@"http://www.meetup.com/authorize/"
#define kBaseURL			@"http://api.meetup.com/"

static MeetupConnectionManager *sharedMeetupConnectionManager = nil;

@implementation MeetupConnectionManager

@synthesize oauthAPI            = _oauthAPI;
@synthesize oauthVerifier       = _oauthVerifier;
@synthesize authenticatedMember = _authenticatedMember;

@synthesize oauthErrorOccurred = _oauthErrorOccurred;
@synthesize oauthFailDelegate  = _oauthFailDelegate;

- (id)initDefault {
	if (self = [super init]) {
		if (!_oauthAPI) {
			NSDictionary *credentials = [NSDictionary dictionaryWithObjectsAndKeys:	kConsumerKey, kMPOAuthCredentialConsumerKey,
										 kConsumerSecret, kMPOAuthCredentialConsumerSecret,
										 nil];
			
			self.oauthAPI = [[MPOAuthAPI alloc] initWithCredentials:credentials
												  authenticationURL:[NSURL URLWithString:kAuthenticationURL]
														 andBaseURL:[NSURL URLWithString:kBaseURL]
														  autoStart:NO];
			
			// XXX - if using MPOAuthAuthenticationMethodAuthExchange (4sq), no need for this delegate
			((MPOAuthAuthenticationMethodOAuth *)_oauthAPI.authenticationMethod).delegate = self;
		}
	
		self.oauthErrorOccurred = NO;
		self.authenticatedMember = nil;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(errorOccurred:) name:MPOAuthNotificationAccessTokenRejected object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(errorOccurred:) name:MPOAuthNotificationRequestTokenRejected object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(errorOccurred:) name:MPOAuthNotificationErrorHasOccurred object:nil];
	}
		
	return self;
}

- (BOOL)isLoggedIn {
	// don't need to do this if member was just authenticated
	if ([_oauthAPI isAuthenticated] && _authenticatedMember) {
		return YES;
	}
	else if ([_oauthAPI credentials].accessToken) {
		self.oauthErrorOccurred = NO;
		
		// ping! make an api call to make sure that we're connected (don't care what we get back)
		[self getAuthenticatedMember];
		
		// well we have an access token and there wasn't an oauth error, so could be just a connection error
		if (!_oauthErrorOccurred)
			return YES;
	}
	
	return NO;
}

- (User *)getAuthenticatedMember {
	// already got an authenticated member
	if (_authenticatedMember) {
		return _authenticatedMember;
	}
	
	NSData *data = nil;
	if ([_oauthAPI credentials].accessToken) {		
		NSArray *params = [MPURLRequestParameter parametersFromString:@"relation=self"];
		data = [_oauthAPI dataForMethod:@"members" withParameters:params];
	}
	
	// there was an oauth error, so just reauthenticate (XXX - shouldn't have to check data is nil)
	if (!_oauthErrorOccurred && data) {
		NSString *dataString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding: NSUTF8StringEncoding];
		
		for (NSDictionary *userResult in [[dataString JSONValue] objectForKey:@"results"]) {
			self.authenticatedMember = [[User alloc] initWithResponseObject:userResult];
			break;
		}
		
		[dataString release];
	}
	
	return _authenticatedMember;
}

- (void)logout {
	[self deauthenticateMember];
	
	SnapupAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate showLoginScreen];
}


- (void)authenticateMember {
	[_oauthAPI discardCredentials];
	[_oauthAPI authenticate];
}

- (void)authenticateMemberWithOAuthVerifier:(NSString *)oauthVerifier withTarget:(id)target andSelector:(SEL)selector andErrorSelector:(SEL)errorSelector {
	[[NSNotificationCenter defaultCenter] addObserver:target selector:selector name:MPOAuthNotificationAccessTokenReceived object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:target selector:errorSelector name:MPOAuthNotificationAccessTokenRejected object:nil];
	
	self.oauthVerifier = oauthVerifier;
	[_oauthAPI authenticate];
}

- (void)deauthenticateMember {
	[_oauthAPI discardCredentials];
}

- (void)errorOccurred:(NSNotification *)inNotification {
	self.oauthErrorOccurred = YES;
	
	// error occurred so clear the authenticated member and discard credentials
	[_authenticatedMember release];
	self.authenticatedMember = nil;
	
	// something messed up so just wipe out credentials
	[_oauthAPI discardCredentials];
}

#pragma mark - URL Request Calls -

#pragma mark - Singleton Methods -

+ (id)sharedManager {
	@synchronized(self) {
		if(sharedMeetupConnectionManager == nil)
			sharedMeetupConnectionManager = [[self alloc] initDefault];
	}
	return sharedMeetupConnectionManager;
}

+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if(sharedMeetupConnectionManager == nil)  {
			sharedMeetupConnectionManager = [super allocWithZone:zone];
			return sharedMeetupConnectionManager;
		}
	}
	return nil;
}

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

- (id)retain {
	return self;
}

- (unsigned)retainCount {
	return UINT_MAX; //denotes an object that cannot be released
}

- (void)release {
	// never release
}

- (id)autorelease {
	return self;
}

#pragma mark - MPOAuthAPIDelegate Methods -

- (NSURL *)callbackURLForCompletedUserAuthorization {
	// The x-com-mpoauth-mobile URI is a claimed URI Type
	// check Info.plist for details
	return [NSURL URLWithString:@"x-com-meetup-snapup://success"];
}

- (NSString *)oauthVerifierForCompletedUserAuthorization {
	return _oauthVerifier;
}

- (BOOL)automaticallyRequestAuthenticationFromURL:(NSURL *)inAuthURL withCallbackURL:(NSURL *)inCallbackURL {
	return YES;
}

- (void)authenticationDidFailWithError:(NSError *)error {
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
	
	if (_oauthFailDelegate && [_oauthFailDelegate respondsToSelector:@selector(authenticationDidFailWithError:)]) {
		[_oauthFailDelegate authenticationDidFailWithError:error];
	}
}

@end
