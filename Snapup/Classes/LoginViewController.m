//
//  LoginViewController.m
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

#import "LoginViewController.h"
#import "MeetupConnectionManager.h"

@implementation LoginViewController

@synthesize loginButton = _loginButton;

@synthesize devLabel = _devLabel;
@synthesize devSwitch = _devSwitch;

-(void)showLoginPrompt {
	UIAlertView *loginAlert = [[UIAlertView alloc]
							   initWithTitle:@"Authenticating Meetup.com Account" 
							   message:@"To get started, please click Login to launch Safari and login to your Meetup account."
							   delegate:self
							   cancelButtonTitle:@"Login"
							   otherButtonTitles:nil];
	[loginAlert show];
	[loginAlert release];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

	_loginButton.enabled = YES;
	_loginButton.alpha = 1.0f;	
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	self.loginButton = nil;
	self.devSwitch = nil;
	self.devLabel = nil;
}


- (void)dealloc {
	[_loginButton release];
	[_devSwitch release];
	[_devLabel release];
	
    [super dealloc];
}

- (void)authenticationDidFailWithError:(NSError *)error {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
	_loginButton.enabled = YES;
	_loginButton.alpha = 1.0f;
}

#pragma mark - UIAlertViewDelegate Methods -

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if ( buttonIndex == [alertView cancelButtonIndex] ) {
		_loginButton.enabled = NO;
		_loginButton.alpha = 0.5f;
		
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
		
		MeetupConnectionManager *manager = [MeetupConnectionManager sharedManager];
		manager.oauthFailDelegate = self;
		[manager authenticateMember];
	}
}

@end
