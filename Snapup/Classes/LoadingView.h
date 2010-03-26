//
//  LoadingView.h
//  LoadingView
//
//  Created by Matt Gallagher on 12/04/09.
//  Copyright Matt Gallagher 2009. All rights reserved.
// 
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//
//  MU: Slightly modified to customize text and progress bar.

#import <UIKit/UIKit.h>

@interface LoadingView : UIView
{
}

+ (id)loadingViewInView:(UIView *)aSuperview;
+ (id)loadingViewInView:(UIView *)aSuperview withLabel:(NSString *)textLabel;
+ (id)loadingViewInView:(UIView *)aSuperview withLabel:(NSString *)textLabel useProgressBar:(BOOL)isBar;

- (void)updateProgressBar:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;
- (void)cancelProgressBar;

- (void)removeView;

@end
