//
//  MPOAuthURLRequest.m
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.05.
//  Copyright 2008 matrixPointer. All rights reserved.
//

#import "MPOAuthURLRequest.h"
#import "MPURLRequestParameter.h"
#import "MPOAuthSignatureParameter.h"

#import "NSURL+MPURLParameterAdditions.h"
#import "NSString+URLEscapingAdditions.h"

static NSString* kStringBoundary = @"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f";

@interface MPOAuthURLRequest ()
@property (nonatomic, readwrite, retain) NSURLRequest *urlRequest;
@end

@implementation MPOAuthURLRequest

- (id)initWithURL:(NSURL *)inURL andParameters:(NSArray *)inParameters {
	if (self = [super init]) {
		self.url = inURL;
		_parameters = inParameters ? [inParameters mutableCopy] : [[NSMutableArray alloc] initWithCapacity:10];
		self.HTTPMethod = @"GET";
	}
	return self;
}

- (id)initWithURLRequest:(NSURLRequest *)inRequest {
	if (self = [super init]) {
		self.url = [[inRequest URL] urlByRemovingQuery];
		self.parameters = [[MPURLRequestParameter parametersFromString:[[inRequest URL] query]] mutableCopy];
		self.HTTPMethod = [inRequest HTTPMethod];
	}
	return self;
}

- (oneway void)dealloc {
	self.url = nil;
	self.HTTPMethod = nil;
	self.urlRequest = nil;
	self.parameters = nil;
	self.image = nil;
	self.imageParamName = nil;
	
	[super dealloc];
}

@synthesize url = _url;
@synthesize HTTPMethod = _httpMethod;
@synthesize urlRequest = _urlRequest;
@synthesize parameters = _parameters;
@synthesize image = _image;
@synthesize imageParamName = _imageParamName;

#pragma mark -

- (NSURLRequest  *)urlRequestSignedWithSecret:(NSString *)inSecret usingMethod:(NSString *)inScheme {
	[self.parameters sortUsingSelector:@selector(compare:)];

	NSMutableURLRequest *aRequest = [[NSMutableURLRequest alloc] init];
	NSMutableString *parameterString = [[NSMutableString alloc] initWithString:[MPURLRequestParameter parameterStringForParameters:self.parameters]];
	MPOAuthSignatureParameter *signatureParameter = [[MPOAuthSignatureParameter alloc] initWithText:parameterString andSecret:inSecret forRequest:self usingMethod:inScheme];
	[parameterString appendFormat:@"&%@", [signatureParameter URLEncodedParameterString]];
	
	[aRequest setHTTPMethod:self.HTTPMethod];
	
	// timeout if connection idles for too long
	[aRequest setTimeoutInterval:10.0f];
	
	if ([[self HTTPMethod] isEqualToString:@"GET"] && [self.parameters count]) {
		NSString *urlString = [NSString stringWithFormat:@"%@?%@", [self.url absoluteString], parameterString];
		MPLog( @"urlString - %@", urlString);
		
		[aRequest setURL:[NSURL URLWithString:urlString]];
	} else if ([[self HTTPMethod] isEqualToString:@"POST"]) {
		// if post includes parameter with image, then do a multipart post
		if (self.image && self.imageParamName) {
			// shamelessly adapted from three20's TTURLRequest
			NSMutableData *body = [NSMutableData data];
			NSString *beginLine = [NSString stringWithFormat:@"\r\n--%@\r\n", kStringBoundary];
			
			//[body appendData:[[NSString stringWithFormat:@"--%@\r\n", kStringBoundary]
			//  dataUsingEncoding:NSUTF8StringEncoding]];
			
			// only put the image in the multipart post
			UIImage* image = self.image;
			CGFloat quality = 0.75;
			NSData* data = UIImageJPEGRepresentation(image, quality);
					
			[body appendData:[beginLine dataUsingEncoding:NSUTF8StringEncoding]];
			[body appendData:[[NSString stringWithFormat:
								@"Content-Disposition: form-data; name=\"%@\"; filename=\"image.jpg\"\r\n",
								self.imageParamName]
								dataUsingEncoding:NSUTF8StringEncoding]];
			[body appendData:[[NSString
								stringWithFormat:@"Content-Length: %d\r\n", data.length]
								dataUsingEncoding:NSUTF8StringEncoding]];  
			[body appendData:[[NSString
								stringWithString:@"Content-Type: image/jpeg\r\n\r\n"]
								dataUsingEncoding:NSUTF8StringEncoding]];  
			[body appendData:data];
			
			[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", kStringBoundary]
							  dataUsingEncoding:NSUTF8StringEncoding]];
			
			NSString *urlString = [NSString stringWithFormat:@"%@?%@", [self.url absoluteString], parameterString];
			MPLog( @"urlString - %@", urlString);
			
			[aRequest setURL:[NSURL URLWithString:urlString]];
			[aRequest setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"];
			[aRequest setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", kStringBoundary] forHTTPHeaderField:@"Content-Type"];
			[aRequest setHTTPBody:body];
		}
		else {
			NSData *postData = [parameterString dataUsingEncoding:NSUTF8StringEncoding];
			MPLog(@"urlString - %@", self.url);
			MPLog(@"postDataString - %@", parameterString);
		
			[aRequest setURL:self.url];
			[aRequest setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
			[aRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
			[aRequest setHTTPBody:postData];
		}
	} else {
		[NSException raise:@"UnhandledHTTPMethodException" format:@"The requested HTTP method, %@, is not supported", self.HTTPMethod];
	}
	
	[parameterString release];
	[signatureParameter release];		
	
	self.urlRequest = aRequest;
	[aRequest release];
		
	return aRequest;
}

#pragma mark -

- (void)addParameters:(NSArray *)inParameters {
	[self.parameters addObjectsFromArray:inParameters];
}

@end
