//
//  LoadingView.m
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

#import "LoadingView.h"
#import <QuartzCore/QuartzCore.h>

#define PROGRESS_VIEW_TAG_ID		42001
#define PROGRESS_LABEL_TAG_ID		42002
#define ACTIVITY_INDICATOR_TAG_ID	42003

#define PROGRESS_LABEL_FONT_SIZE	12.0

//
// NewPathWithRoundRect
//
// Creates a CGPathRect with a round rect of the given radius.
//
CGPathRef NewPathWithRoundRect(CGRect rect, CGFloat cornerRadius)
{
	//
	// Create the boundary path
	//
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL,
		rect.origin.x,
		rect.origin.y + rect.size.height - cornerRadius);

	// Top left corner
	CGPathAddArcToPoint(path, NULL,
		rect.origin.x,
		rect.origin.y,
		rect.origin.x + rect.size.width,
		rect.origin.y,
		cornerRadius);

	// Top right corner
	CGPathAddArcToPoint(path, NULL,
		rect.origin.x + rect.size.width,
		rect.origin.y,
		rect.origin.x + rect.size.width,
		rect.origin.y + rect.size.height,
		cornerRadius);

	// Bottom right corner
	CGPathAddArcToPoint(path, NULL,
		rect.origin.x + rect.size.width,
		rect.origin.y + rect.size.height,
		rect.origin.x,
		rect.origin.y + rect.size.height,
		cornerRadius);

	// Bottom left corner
	CGPathAddArcToPoint(path, NULL,
		rect.origin.x,
		rect.origin.y + rect.size.height,
		rect.origin.x,
		rect.origin.y,
		cornerRadius);

	// Close the path at the rounded rect
	CGPathCloseSubpath(path);
	
	return path;
}

@implementation LoadingView

//
// loadingViewInView:
//
// Constructor for this view. Creates and adds a loading view for covering the
// provided aSuperview.
//
// Parameters:
//    aSuperview - the superview that will be covered by the loading view
//
// returns the constructed view, already added as a subview of the aSuperview
//	(and hence retained by the superview)
//
+ (id)loadingViewInView:(UIView *)aSuperview {
	return [self loadingViewInView:aSuperview withLabel:NSLocalizedString(@"Loading...", nil)];
}

+ (id)loadingViewInView:(UIView *)aSuperview withLabel:(NSString *)textLabel {
	return [self loadingViewInView:aSuperview withLabel:textLabel useProgressBar:NO];
}

+ (id)loadingViewInView:(UIView *)aSuperview withLabel:(NSString *)textLabel useProgressBar:(BOOL)usingProgressBar {
	LoadingView *loadingView =
		[[[LoadingView alloc] initWithFrame:[aSuperview bounds]] autorelease];
	if (!loadingView)
	{
		return nil;
	}
	
	loadingView.opaque = NO;
	loadingView.autoresizingMask =
		UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[aSuperview addSubview:loadingView];

	const CGFloat DEFAULT_LABEL_WIDTH = 280.0;
	const CGFloat DEFAULT_LABEL_HEIGHT = 50.0;
	CGRect labelFrame = CGRectMake(0, 0, DEFAULT_LABEL_WIDTH, DEFAULT_LABEL_HEIGHT);
	UILabel *loadingLabel =
		[[[UILabel alloc]
			initWithFrame:labelFrame]
		autorelease];
	loadingLabel.text = textLabel;
	loadingLabel.textColor = [UIColor whiteColor];
	loadingLabel.backgroundColor = [UIColor clearColor];
	loadingLabel.textAlignment = UITextAlignmentCenter;
	loadingLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
	loadingLabel.autoresizingMask =
		UIViewAutoresizingFlexibleLeftMargin |
		UIViewAutoresizingFlexibleRightMargin |
		UIViewAutoresizingFlexibleTopMargin |
		UIViewAutoresizingFlexibleBottomMargin;
	[loadingView addSubview:loadingLabel];

	CGFloat totalHeight = loadingLabel.frame.size.height;
	
	UIActivityIndicatorView *activityIndicatorView = nil;
	UIProgressView *progressView = nil;
	UILabel *progressLabel = nil;
	
	activityIndicatorView =
		[[[UIActivityIndicatorView alloc]
		  initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge]
		 autorelease];
	[loadingView addSubview:activityIndicatorView];
	activityIndicatorView.autoresizingMask =
		UIViewAutoresizingFlexibleLeftMargin |
		UIViewAutoresizingFlexibleRightMargin |
		UIViewAutoresizingFlexibleTopMargin |
		UIViewAutoresizingFlexibleBottomMargin;
	activityIndicatorView.tag = ACTIVITY_INDICATOR_TAG_ID;
	[activityIndicatorView startAnimating];
	
	totalHeight += activityIndicatorView.frame.size.height;
	
	if (usingProgressBar) {	
		// hide activity indicator for progress bar initially
		activityIndicatorView.hidden = YES;
		
		const CGFloat DEFAULT_PROGRESS_BAR_WIDTH = 200.0;
		const CGFloat DEFAULT_PROGRESS_BAR_HEIGHT = 20.0;
		CGRect progressFrame = CGRectMake(0, 0, DEFAULT_PROGRESS_BAR_WIDTH, DEFAULT_PROGRESS_BAR_HEIGHT);
		progressView =
			[[[UIProgressView alloc]
			  initWithFrame:progressFrame]
			 autorelease];
		[progressView setProgressViewStyle:UIProgressViewStyleDefault];
		[progressView setProgress:0.0f];
		[loadingView addSubview:progressView];
		progressView.autoresizingMask =
			UIViewAutoresizingFlexibleLeftMargin |
			UIViewAutoresizingFlexibleRightMargin |
			UIViewAutoresizingFlexibleTopMargin |
			UIViewAutoresizingFlexibleBottomMargin;
		progressView.tag = PROGRESS_VIEW_TAG_ID;
		
		totalHeight += progressView.frame.size.height;
		
		const CGFloat DEFAULT_PROGRESS_LABEL_WIDTH = 280.0;
		const CGFloat DEFAULT_PROGRESS_LABEL_HEIGHT = 30.0;
		CGRect progressLabelFrame = CGRectMake(0, 0, DEFAULT_PROGRESS_LABEL_WIDTH, DEFAULT_PROGRESS_LABEL_HEIGHT);
		progressLabel =
			[[[UILabel alloc]
			  initWithFrame:progressLabelFrame]
			 autorelease];
		progressLabel.text = @"";
		progressLabel.textColor = [UIColor grayColor];
		progressLabel.backgroundColor = [UIColor clearColor];
		progressLabel.textAlignment = UITextAlignmentCenter;
		progressLabel.font = [UIFont systemFontOfSize:PROGRESS_LABEL_FONT_SIZE];
		progressLabel.autoresizingMask =
			UIViewAutoresizingFlexibleLeftMargin |
			UIViewAutoresizingFlexibleRightMargin |
			UIViewAutoresizingFlexibleTopMargin |
			UIViewAutoresizingFlexibleBottomMargin;
		[loadingView addSubview:progressLabel];
		progressLabel.tag = PROGRESS_LABEL_TAG_ID;
		
		totalHeight += progressLabel.frame.size.height;
	}

	labelFrame.origin.x = floor(0.5 * (loadingView.frame.size.width - DEFAULT_LABEL_WIDTH));
	labelFrame.origin.y = floor(0.5 * (loadingView.frame.size.height - totalHeight));
	loadingLabel.frame = labelFrame;

	CGFloat progressBarLabelHeight = 0;
	if (usingProgressBar) {	
		CGRect progressRect = progressView.frame;
		progressRect.origin.x =
			0.5 * (loadingView.frame.size.width - progressRect.size.width);
		progressRect.origin.y =
			loadingLabel.frame.origin.y + loadingLabel.frame.size.height;
		progressView.frame = progressRect;
		
		CGRect progressLabelRect = progressLabel.frame;
		progressLabelRect.origin.x =
			0.5 * (loadingView.frame.size.width - progressLabelRect.size.width);
		progressLabelRect.origin.y =
			loadingLabel.frame.origin.y + loadingLabel.frame.size.height + progressRect.size.height;
		progressLabel.frame = progressLabelRect;
		
		progressBarLabelHeight = progressRect.size.height + progressLabelRect.size.height;
	}
	
	CGRect activityIndicatorRect = activityIndicatorView.frame;
	activityIndicatorRect.origin.x = 
		0.5 * (loadingView.frame.size.width - activityIndicatorRect.size.width);
	activityIndicatorRect.origin.y =
		loadingLabel.frame.origin.y + loadingLabel.frame.size.height + progressBarLabelHeight + 5.0;
	activityIndicatorView.frame = activityIndicatorRect;
	
	// Set up the fade-in animation
	CATransition *animation = [CATransition animation];
	[animation setType:kCATransitionFade];
	[[aSuperview layer] addAnimation:animation forKey:@"layerAnimation"];
	
	return loadingView;
}

//
// removeView
//
// Animates the view out from the superview. As the view is removed from the
// superview, it will be released.
//
- (void)removeView
{
	UIView *aSuperview = [self superview];
	[super removeFromSuperview];

	// Set up the animation
	CATransition *animation = [CATransition animation];
	[animation setType:kCATransitionFade];
	
	[[aSuperview layer] addAnimation:animation forKey:@"layerAnimation"];
}

- (void)updateProgressBar:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
	UIProgressView *progressView = (UIProgressView *)[self viewWithTag:PROGRESS_VIEW_TAG_ID];
	UILabel *progressLabel = (UILabel *)[self viewWithTag:PROGRESS_LABEL_TAG_ID];
	UIActivityIndicatorView *activityIndicatorView = (UIActivityIndicatorView *)[self viewWithTag:ACTIVITY_INDICATOR_TAG_ID];
	
	if (progressView && progressLabel) {
		if (totalBytesExpectedToWrite < 0) {
			[progressView setProgress:0.0];
			progressLabel.text = @"Initializing transfer...";
			
			activityIndicatorView.hidden = YES;
		}
		else if (totalBytesWritten == totalBytesExpectedToWrite) {
			[progressView setProgress:1.0];
			progressLabel.text = @"Transfer complete! Please wait...";
			
			activityIndicatorView.hidden = NO;
			[activityIndicatorView startAnimating];
		}
		else {
			float totalBytesWrittenFloat = [[NSNumber numberWithInteger:totalBytesWritten] floatValue];
			float totalBytesExpectedToWriteFloat = [[NSNumber numberWithInteger: totalBytesExpectedToWrite] floatValue];
			
			CGFloat progress = totalBytesWrittenFloat / totalBytesExpectedToWriteFloat;
			NSInteger percentInt = progress * 100.0;

			[progressView setProgress:progress];
			progressLabel.text = [NSString stringWithFormat:@"Uploaded %d/%d (%d%%) Bytes", totalBytesWritten, totalBytesExpectedToWrite, percentInt];

			activityIndicatorView.hidden = YES;
		}		
	}
}

- (void)cancelProgressBar {
	UIProgressView *progressView = (UIProgressView *)[self viewWithTag:PROGRESS_VIEW_TAG_ID];
	UILabel *progressLabel = (UILabel *)[self viewWithTag:PROGRESS_LABEL_TAG_ID];
	UIActivityIndicatorView *activityIndicatorView = (UIActivityIndicatorView *)[self viewWithTag:ACTIVITY_INDICATOR_TAG_ID];

	if (progressView && progressLabel) {
		progressLabel.text = @"Cancelling transfer...";
			
		activityIndicatorView.hidden = NO;
	}
}

- (void)drawRect:(CGRect)rect
{
	rect.size.height -= 1;
	rect.size.width -= 1;
	
	const CGFloat RECT_PADDING = 8.0;
	rect = CGRectInset(rect, RECT_PADDING, RECT_PADDING);
	
	const CGFloat ROUND_RECT_CORNER_RADIUS = 5.0;
	CGPathRef roundRectPath = NewPathWithRoundRect(rect, ROUND_RECT_CORNER_RADIUS);
	
	CGContextRef context = UIGraphicsGetCurrentContext();

	const CGFloat BACKGROUND_OPACITY = 0.85;
	CGContextSetRGBFillColor(context, 0, 0, 0, BACKGROUND_OPACITY);
	CGContextAddPath(context, roundRectPath);
	CGContextFillPath(context);

	const CGFloat STROKE_OPACITY = 0.25;
	CGContextSetRGBStrokeColor(context, 1, 1, 1, STROKE_OPACITY);
	CGContextAddPath(context, roundRectPath);
	CGContextStrokePath(context);
	
	CGPathRelease(roundRectPath);
}


- (void)dealloc
{
    [super dealloc];
}

@end
