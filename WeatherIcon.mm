/*
 *  WeatherIcon.mm
 *  
 *
 *  Created by David Ashman on 1/12/09.
 *  Copyright 2009 David Ashman. All rights reserved.
 *
 */

#include <substrate.h>
#import "WeatherIconModel.h"
#import <SpringBoard/SBIcon.h>
#import <SpringBoard/SBIconList.h>
#import <SpringBoard/SBIconController.h>
#import <SpringBoard/SBWidgetApplicationIcon.h>
#import <SpringBoard/SBInstalledApplicationIcon.h>
#import <SpringBoard/SBBookmarkIcon.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBAwayController.h>
#import <SpringBoard/SBIconModel.h>
#import <UIKit/UIKit.h>
 
@protocol WeatherIcon
- (id) wi_icon;
- (id) wi_clip_icon;
- (void) wi_unscatter:(BOOL) b startTime:(double) time;
@end

static WeatherIconModel* _model;


static void $SBIconController$unscatter$(SBIconController<WeatherIcon> *self, SEL sel, BOOL b, double time) 
{
//	NSLog(@"WI: Unscattering springboard.");

	// refresh the weather model
	[_model refresh:self];

	// do the unscatter
	[self wi_unscatter:b startTime:time];
}

static id $SBApplicationIcon$icon(SBApplicationIcon<WeatherIcon> *self, SEL sel) 
{
	if ([_model isWeatherIcon:self])
	{
//		NSLog(@"WI: Asking for weather icon.");
		return [_model icon];
	}

	return [self wi_icon];
}

static id $SBBookmarkIcon$icon(SBBookmarkIcon<WeatherIcon> *self, SEL sel) 
{
	if ([_model isWeatherIcon:self])
	{
		NSLog(@"WI: Asking for weather icon.");
		return [_model icon];
	}

	return [self wi_clip_icon];
}

extern "C" void WeatherIconInitialize() {
	if (objc_getClass("SpringBoard") == nil)
		return;

	// Get the SBIcon class
	Class $SBIconController = objc_getClass("SBIconController");
	Class $SBBookmarkIcon = objc_getClass("SBBookmarkIcon");
	Class $SBApplicationIcon = objc_getClass("SBApplicationIcon");
	
	// MSHookMessage is what we use to redirect the methods to our own
	MSHookMessage($SBIconController, @selector(unscatter:startTime:), (IMP) &$SBIconController$unscatter$, "wi_");
	MSHookMessage($SBBookmarkIcon, @selector(icon), (IMP) &$SBBookmarkIcon$icon, "wi_clip_");
	MSHookMessage($SBApplicationIcon, @selector(icon), (IMP) &$SBApplicationIcon$icon, "wi_");
	
	NSLog(@"WI: Init weather model.");
	_model = [[WeatherIconModel alloc] init];
}
