/*
 *  WeatherIcon.mm
 *  
 *
 *  Created by David Ashman on 1/12/09.
 *  Copyright 2009 David Ashman. All rights reserved.
 *
 */

#include <substrate.h>
#import "WeatherView.h"
#import <SpringBoard/SBApplicationIcon.h>
#import <SpringBoard/SBBookmarkIcon.h>
#import <SpringBoard/SBCalendarController.h>
#import <SpringBoard/CDStructures.h>
#import <UIKit/UIKit.h>
 
@protocol WeatherIcon
- (id) wi_initWithApplication:(id) app;
@end

static bool _settingsLoaded = false;
static bool _celsius = false;

static NSTimer  *_timer;
static WeatherView* _view;

static void $initView$(SBApplicationIcon *icon) 
{

	_view = [[WeatherView alloc] initWithIcon:icon];
	_view.opaque = NO;
	_view.userInteractionEnabled = NO;

	_timer = [NSTimer scheduledTimerWithTimeInterval:1800 target:_view selector:@selector(refresh) userInfo:nil repeats:YES];

	[icon addSubview:_view];
}

static id $SBApplicationIcon$initWithApplication$(SBApplicationIcon<WeatherIcon> *self, SEL sel, id app) 
{
	id ret =[self wi_initWithApplication:app];

	if ([[app bundleIdentifier] isEqualToString:@"com.apple.weather"])
	{
		$initView$(self);
	}

	return ret;
}

extern "C" void WeatherIconInitialize() {
	if (objc_getClass("SpringBoard") == nil)
		return;

	// Get the SBIcon class
	Class $SBApplicationIcon = objc_getClass("SBApplicationIcon");
	
	// MSHookMessage is what we use to redirect the methods to our own
	MSHookMessage($SBApplicationIcon, @selector(initWithApplication:), (IMP) &$SBApplicationIcon$initWithApplication$, "wi_");
}
