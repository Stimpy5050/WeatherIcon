/*
 *  WeatherIcon.mm
 *  
 *
 *  Created by David Ashman on 1/12/09.
 *  Copyright 2009 David Ashman. All rights reserved.
 *
 */

#include <substrate.h>
#import "WeatherIconController.h"
#import <SpringBoard/SBIcon.h>
#import <SpringBoard/SBIconList.h>
#import <SpringBoard/SBIconController.h>
#import <SpringBoard/SBUIController.h>
#import <SpringBoard/SBStatusBarController.h>
#import <SpringBoard/SBStatusBarContentsView.h>
#import <SpringBoard/SBStatusBarContentView.h>
#import <SpringBoard/SBStatusBarIndicatorsView.h>
#import <SpringBoard/SBWidgetApplicationIcon.h>
#import <SpringBoard/SBInstalledApplicationIcon.h>
#import <SpringBoard/SBBookmarkIcon.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBAwayView.h>
#import <SpringBoard/SBAwayController.h>
#import <SpringBoard/SBIconModel.h>
#import <SpringBoard/SpringBoard.h>
#import <UIKit/UIKit.h>
 
@protocol WeatherIcon
- (id) wi_init;
- (id) wi_initWithApplication:(id) app;
- (id) wi_initWithWebClip:(id) clip;
- (void) wi_unscatter:(BOOL) b startTime:(double) time;
- (void) wi_deactivated;
- (void) wi_reloadIndicators;
- (void) wi_updateInterface;
@end

static Class $WIInstalledApplicationIcon;
static Class $WIApplicationIcon;
static Class $WIBookmarkIcon;
static Class $WISpringBoard;

static WeatherIconController* _controller;

static void $SBAwayView$updateInterface(SBAwayView<WeatherIcon> *self, SEL sel)
{
	[self wi_updateInterface];

	// refresh the weather model
	BOOL refresh = !self.dimmed;
	if (!refresh)
	{
		// check AC
		Class cls = objc_getClass("SBUIController");
		SBUIController* sbui = [cls sharedInstance];
		refresh = [sbui isOnAC];
	}

	if (refresh)
		[_controller refresh];
}

static void $SBIconController$unscatter$(SBIconController<WeatherIcon> *self, SEL sel, BOOL b, double time) 
{
	// refresh the weather model
	[_controller refresh];

	// do the unscatter
	[self wi_unscatter:b startTime:time];
}

static id weatherIcon(SBIcon *self, SEL sel) 
{
//	NSLog(@"WI: Calling icon method.");
	return [_controller icon];
}

static void $SBStatusBarIndicatorsView$reloadIndicators(SBStatusBarIndicatorsView<WeatherIcon> *self, SEL sel) 
{
	[self wi_reloadIndicators];

	int mode = [self effectiveModeForImages];
	UIImage* indicator = [_controller statusBarIndicator:mode];

	if (indicator)
	{
		UIImageView* weatherView = [[UIImageView alloc] initWithImage:indicator];
		NSArray* views = [self subviews];
		if (views.count > 0)
		{
			// if there are already indicators, move the weather view
			UIView* last = [views objectAtIndex:views.count - 1];
			weatherView.frame = CGRectMake(last.frame.origin.x + last.frame.size.width + 6, 0, weatherView.frame.size.width, weatherView.frame.size.height);
		}

		[self addSubview:weatherView];
		self.frame = CGRectMake(0, 0, weatherView.frame.origin.x + weatherView.frame.size.width, 20);

//		NSLog(@"WI: weatherView: %f, %f, %f, %f", weatherView.frame.origin.x, weatherView.frame.origin.y, weatherView.frame.size.width, weatherView.frame.size.height); 
//		NSLog(@"WI: indicators: %f, %f, %f, %f", self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height); 
	}
}

static void $SBApplication$deactivated(SBApplication<WeatherIcon> *self, SEL sel) 
{
	if ([self.displayIdentifier isEqualToString:@"com.apple.weather"] ||
	    [_controller isWeatherIcon:self.displayIdentifier])
	{
		// refresh the weather model
		[_controller refreshNow];
	}

	[self wi_deactivated];
}

static id $SBApplicationIcon$initWithApplication$(SBApplicationIcon<WeatherIcon> *self, SEL sel, id app) 
{
	self = [self wi_initWithApplication:app];

	if ([_controller isWeatherIcon:self.displayIdentifier])
	{
		NSLog(@"WI: Replacing icon for %@.", self.displayIdentifier);
		if ([self class] == objc_getClass("SBInstalledApplicationIcon"))
			object_setClass(self, $WIInstalledApplicationIcon);
		else
			object_setClass(self, $WIApplicationIcon);
	}

	return self;
}

static id $SBBookmarkIcon$initWithWebClip$(SBBookmarkIcon<WeatherIcon> *self, SEL sel, id clip) 
{
	self = [self wi_initWithWebClip:clip];

	if ([_controller isWeatherIcon:self.displayIdentifier])
	{
		NSLog(@"WI: Replacing icon for %@.", self.displayIdentifier);
		object_setClass(self, $WIBookmarkIcon);
	}

	return self;
}

static id $SpringBoard$init(SpringBoard<WeatherIcon> *self, SEL sel) 
{
	self = [self wi_init];
	object_setClass(self, $WISpringBoard);
	return self;
}

static id weatherIconController(SpringBoard<WeatherIcon>* self, SEL sel)
{
	return _controller;
}

extern "C" void WeatherIconInitialize() {
	if (objc_getClass("SpringBoard") == nil)
		return;

	$WIApplicationIcon = objc_allocateClassPair(objc_getClass("SBApplicationIcon"), "WIApplicationIcon", 0);
	class_replaceMethod($WIApplicationIcon, @selector(icon), (IMP)&weatherIcon, "@@:");
	objc_registerClassPair($WIApplicationIcon);

	$WIInstalledApplicationIcon = objc_allocateClassPair(objc_getClass("SBInstalledApplicationIcon"), "WIInstalledApplicationIcon", 0);
	class_replaceMethod($WIInstalledApplicationIcon, @selector(icon), (IMP)&weatherIcon, "@@:");
	objc_registerClassPair($WIInstalledApplicationIcon);

	$WIBookmarkIcon = objc_allocateClassPair(objc_getClass("SBBookmarkIcon"), "WIBookmarkIcon", 0);
	class_replaceMethod($WIBookmarkIcon, @selector(icon), (IMP)&weatherIcon, "@@:");
	objc_registerClassPair($WIBookmarkIcon);

	$WISpringBoard = objc_allocateClassPair(objc_getClass("SpringBoard"), "WISpringBoard", 0);
	class_addMethod($WISpringBoard, @selector(weatherIconController), (IMP)&weatherIconController, "@@:");
	objc_registerClassPair($WISpringBoard);

	Class $SpringBoard = objc_getClass("SpringBoard");
	Class $SBAwayView = objc_getClass("SBAwayView");
	Class $SBIconController = objc_getClass("SBIconController");
	Class $SBBookmarkIcon = objc_getClass("SBBookmarkIcon");
	Class $SBApplicationIcon = objc_getClass("SBApplicationIcon");
	Class $SBApplication = objc_getClass("SBApplication");
	Class $SBStatusBarIndicatorsView = objc_getClass("SBStatusBarIndicatorsView");
	
	// MSHookMessage is what we use to redirect the methods to our own
//	MSHookMessage($SpringBoard, @selector(init), (IMP) &$SpringBoard$init, "wi_");

	MSHookMessage($SBIconController, @selector(unscatter:startTime:), (IMP) &$SBIconController$unscatter$, "wi_");
	MSHookMessage($SBApplication, @selector(deactivated), (IMP) &$SBApplication$deactivated, "wi_");
	MSHookMessage($SBApplicationIcon, @selector(initWithApplication:), (IMP) &$SBApplicationIcon$initWithApplication$, "wi_");
	MSHookMessage($SBBookmarkIcon, @selector(initWithWebClip:), (IMP) &$SBBookmarkIcon$initWithWebClip$, "wi_");
	MSHookMessage($SBStatusBarIndicatorsView, @selector(reloadIndicators), (IMP) &$SBStatusBarIndicatorsView$reloadIndicators, "wi_");
	MSHookMessage($SBAwayView, @selector(updateInterface), (IMP) &$SBAwayView$updateInterface, "wi_");
	
	NSLog(@"WI: Init weather controller.");
	_controller = [WeatherIconController sharedInstance];
}
