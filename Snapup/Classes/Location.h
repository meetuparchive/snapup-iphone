//
//  Location.h
//  Meetup
//
//  Created by Vernon Thommeret on 7/22/09.
//  Copyright 2009 Vernon Thommeret. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Location : NSObject {
	NSString *_title;
	NSString *_address1;
	NSString *_address2;
	NSString *_address3;
	NSString *_city;
	NSString *_state;
	NSString *_country;
	NSString *_zip;
	double _lat;
	double _lon;
	NSString *_phone;
}

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *address1;
@property (nonatomic, copy) NSString *address2;
@property (nonatomic, copy) NSString *address3;
@property (nonatomic, copy) NSString *city;
@property (nonatomic, copy) NSString *state;
@property (nonatomic, copy) NSString *country;
@property (nonatomic, copy) NSString *zip;
@property (nonatomic, assign) double lat;
@property (nonatomic, assign) double lon;
@property (nonatomic, copy) NSString *phone;

- (NSString *)mapDescription;
- (NSString *)shortDescription;

@end
