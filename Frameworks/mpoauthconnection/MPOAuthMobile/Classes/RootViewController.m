//
//  RootViewController.m
//  MPOAuthMobile
//
//  Created by Karl Adam on 08.12.14.
//  Copyright matrixPointer 2008. All rights reserved.
//

#import "RootViewController.h"
#import "MPOAuthMobileAppDelegate.h"
#import "MPOAuthAPI.h"
#import "MPURLRequestParameter.h"

#define kConsumerKey		@"1F9B3ECB0EB4B58090457A654FED0502"
#define kConsumerSecret		@"21262263D24C81E7685F75015BC0C5A0"

@implementation RootViewController

@synthesize methodInput;
@synthesize parametersInput;

- (void)dealloc {
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	//[self.navigationItem setPrompt:@"Performing Request Token Request"];
	[self.navigationItem setPrompt:@""];
	[self.navigationItem setTitle:@"OAuth Test"];
	[self.methodInput addTarget:self action:@selector(methodEntered:) forControlEvents:UIControlEventEditingDidEndOnExit];
	[self.parametersInput addTarget:self action:@selector(methodEntered:) forControlEvents:UIControlEventEditingDidEndOnExit];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestTokenReceived:) name:MPOAuthNotificationRequestTokenReceived object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accessTokenReceived:) name:MPOAuthNotificationAccessTokenReceived object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(errorOccurred:) name:MPOAuthNotificationAccessTokenRejected object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(errorOccurred:) name:MPOAuthNotificationRequestTokenRejected object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(errorOccurred:) name:MPOAuthNotificationErrorHasOccurred object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
	if (!_oauthAPI) {
		NSDictionary *credentials = [NSDictionary dictionaryWithObjectsAndKeys:	kConsumerKey, kMPOAuthCredentialConsumerKey,
									 kConsumerSecret, kMPOAuthCredentialConsumerSecret,
									 nil];
		_oauthAPI = [[MPOAuthAPI alloc] initWithCredentials:credentials
										  authenticationURL:[NSURL URLWithString:@"http://www.dev.meetup.com/authorize/"]
												 andBaseURL:[NSURL URLWithString:@"http://api.dev.meetup.com/"]
												  autoStart:NO];
		
		// XXX - if using MPOAuthAuthenticationMethodAuthExchange (4sq), no need for this delegate
		((MPOAuthAuthenticationMethodOAuth *)_oauthAPI.authenticationMethod).delegate = (id <MPOAuthAuthenticationMethodOAuthDelegate>)[UIApplication sharedApplication].delegate;
	}

	[_oauthAPI authenticate];
}

- (void)requestTokenReceived:(NSNotification *)inNotification {
	[self.navigationItem setPrompt:@"Awaiting User Authentication"];
}

- (void)accessTokenReceived:(NSNotification *)inNotification {
	[self.navigationItem setPrompt:@"Access Token Received"];
}

- (void)errorOccurred:(NSNotification *)inNotification {
	[self.navigationItem setPrompt:@"Error Occurred"];
	textOutput.text = [[inNotification userInfo] objectForKey:@"oauth_problem"];
}

- (void)_methodLoadedFromURL:(NSURL *)inURL withResponseString:(NSString *)inString {
	textOutput.text = inString;
}

- (void)methodEntered:(UITextField *)aTextField {
	NSString *method = methodInput.text;
	NSString *paramsString = parametersInput.text;
	
	NSArray *params = nil;
	if (paramsString.length > 0) {
		params = [MPURLRequestParameter parametersFromString:paramsString];
	}
	
	[_oauthAPI performMethod:method atURL:_oauthAPI.baseURL withParameters:params withTarget:self andAction:@selector(_methodLoadedFromURL:withResponseString:)];
}

- (void)clearCredentials {
	[self.navigationItem setPrompt:@"Credentials Cleared"];
	textOutput.text = @"";
	[_oauthAPI discardCredentials];
}

- (void)reauthenticate {
	[self.navigationItem setPrompt:@"Reauthenticating User"];
	textOutput.text = @"";
	[_oauthAPI authenticate];	
}

@end

