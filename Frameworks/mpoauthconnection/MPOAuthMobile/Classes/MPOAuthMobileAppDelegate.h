//
//  MPOAuthMobileAppDelegate.h
//  MPOAuthMobile
//
//  Created by Karl Adam on 08.12.14.
//  Copyright matrixPointer 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPOAuthAPI.h"
#import "MPOAuthAuthenticationMethodOAuth.h"

@interface MPOAuthMobileAppDelegate : NSObject <UIApplicationDelegate, MPOAuthAuthenticationMethodOAuthDelegate> {
	UIWindow *window;
    UINavigationController *navigationController;
	
	NSString *_oauthVerifier;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, copy) NSString *oauthVerifier;

@end

