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
#import <SpringBoard/SBIcon.h>
#import <SpringBoard/SBWidgetApplicationIcon.h>
#import <SpringBoard/SBBookmarkIcon.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBAwayController.h>
#import <UIKit/UIKit.h>
 
@protocol WeatherIcon
- (id) wi_initWithApplication:(id) app;
- (void) wi__unlockWithSound:(BOOL) b;
- (BOOL) wi_deactivate;
- (void) wi_setHighlighted:(BOOL) b;
@end

static NSString* _weatherBundleIdentifier;
static WeatherView* _view;

static void $initView$(SBApplicationIcon *icon) 
{
	_view = [[WeatherView alloc] initWithIcon:icon];
	[icon addSubview:_view];

	[_view refresh];
}

static BOOL $SBApplication$deactivate(SBApplication<WeatherIcon> *self, SEL sel) 
{
	BOOL ret = [self wi_deactivate];

	if (_view)
	{
//		if ([[self bundleIdentifier] isEqualToString:_weatherBundleIdentifier] || [[self bundleIdentifier] isEqualToString:@"com.apple.weather"])
//			_view.nextRefreshTime = [[NSDate alloc] initWithTimeIntervalSinceNow:-10];

		[_view refresh];
	}

	return ret;
}

static void $SBAwayController$_unlockWithSound$(SBAwayController<WeatherIcon> *self, SEL sel, BOOL b) 
{
	[self wi__unlockWithSound:b];

	if (_view)
		[_view refresh];
}

static void $SBIcon$setHighlighted$(SBIcon<WeatherIcon> *self, SEL sel, BOOL b) 
{
	[self wi_setHighlighted:b];

	if (_view && [self.displayIdentifier isEqualToString:_weatherBundleIdentifier])
	{
		_view.highlighted = b;
		[_view setNeedsDisplay];
	}
}

static id $SBApplicationIcon$initWithApplication$(SBApplicationIcon<WeatherIcon> *self, SEL sel, id app) 
{
	id ret = [self wi_initWithApplication:app];

	if (!_weatherBundleIdentifier)
	{
		NSString* bundleIdentifier = @"com.apple.weather";
	
		NSDictionary* prefs = [WeatherView preferences];
		if (prefs)
			if (NSString* bi = [prefs objectForKey:@"WeatherBundleIdentifier"])
				bundleIdentifier = bi;

		_weatherBundleIdentifier = [[NSString stringWithString:bundleIdentifier] retain];
	}

	if ([[app bundleIdentifier] isEqualToString:_weatherBundleIdentifier])
	{
		NSLog(@"WI: Linking weather icon to %@", _weatherBundleIdentifier);
		$initView$(self);
	}

	return ret;
}

extern "C" void WeatherIconInitialize() {
	if (objc_getClass("SpringBoard") == nil)
		return;

	// Get the SBIcon class
	Class $SBIcon = objc_getClass("SBIcon");
	Class $SBBookmarkIcon = objc_getClass("SBBookmarkIcon");
	Class $SBApplicationIcon = objc_getClass("SBApplicationIcon");
	Class $SBApplication = objc_getClass("SBApplication");
	Class $SBAwayController = objc_getClass("SBAwayController");
	
	// MSHookMessage is what we use to redirect the methods to our own
	MSHookMessage($SBIcon, @selector(setHighlighted:), (IMP) &$SBIcon$setHighlighted$, "wi_");
//	MSHookMessage($SBBookmarkIcon, @selector(icon), (IMP) &$SBBookmarkIcon$icon, "wi_clip_");
	MSHookMessage($SBApplicationIcon, @selector(initWithApplication:), (IMP) &$SBApplicationIcon$initWithApplication$, "wi_");
	MSHookMessage($SBApplication, @selector(deactivate), (IMP) &$SBApplication$deactivate, "wi_");
	MSHookMessage($SBAwayController, @selector(_unlockWithSound:), (IMP) &$SBAwayController$_unlockWithSound$, "wi_");
}
