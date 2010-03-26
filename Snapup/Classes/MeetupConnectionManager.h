//
//  MeetupConnectionManager.h
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

#import "MPOAuthAPI.h"
#import "MPOAuthAuthenticationMethodOAuth.h"

#define kOAuthErrorCode		-42400;

@class SnapupAppDelegate;
@class User;

@interface MeetupConnectionManager : NSObject <MPOAuthAuthenticationMethodOAuthDelegate> {
	MPOAuthAPI *_oauthAPI;
	NSString   *_oauthVerifier;
	User       *_authenticatedMember;
	
	BOOL       _oauthErrorOccurred;
	id		   _oauthFailDelegate;
}

@property (nonatomic, retain) MPOAuthAPI *oauthAPI;
@property (nonatomic, copy)   NSString   *oauthVerifier;
@property (nonatomic, retain) User       *authenticatedMember;

@property                     BOOL       oauthErrorOccurred;

@property (nonatomic, retain) id         oauthFailDelegate;

+ (id)sharedManager;

- (BOOL)isLoggedIn;
- (void)logout;

- (void)authenticateMember;
- (void)authenticateMemberWithOAuthVerifier:(NSString *)oauthVerifier withTarget:(id)target andSelector:(SEL)selector andErrorSelector:(SEL)errorSelector;
- (void)deauthenticateMember;

- (User *)getAuthenticatedMember;

@end
