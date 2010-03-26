//
//  MPOAuthAuthenticationMethodAuthExchange.h
//  MPOAuthMobile
//
//  Created by Karl Adam on 09.12.20.
//  Copyright 2009 matrixPointer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPOAuthAPI.h"
#import "MPOAuthAuthenticationMethod.h"

@protocol MPOAuthAuthenticationMethodAuthExchangeDelegate;

@interface MPOAuthAuthenticationMethodAuthExchange : MPOAuthAuthenticationMethod <MPOAuthAPIInternalClient> {
	id <MPOAuthAuthenticationMethodAuthExchangeDelegate> delegate_;
}

@property (nonatomic, readwrite, assign) id <MPOAuthAuthenticationMethodAuthExchangeDelegate> delegate;

@end

@protocol MPOAuthAuthenticationMethodAuthExchangeDelegate <NSObject>
- (void)authenticationDidSucceed;
- (void)authenticationDidFailWithError:(NSError *)error;
@end