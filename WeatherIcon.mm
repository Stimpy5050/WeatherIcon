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
- (id) wi_init;
- (id) wi_initWithApplication:(id) app;
- (id) wi_initWithWebClip:(id) clip;
- (void) wi_unscatter:(BOOL) b startTime:(double) time;
- (void) wi_deactivated;
@end

static Class $WIInstalledApplicationIcon;
static Class $WIApplicationIcon;
static Class $WIBookmarkIcon;

static WeatherIconModel* _model;


static id $SBIconController$init(SBIconController<WeatherIcon> *self, SEL sel)
{
	self = [self wi_init];
	[_model setIconController:self];
	return self;
}

static void $SBIconController$unscatter$(SBIconController<WeatherIcon> *self, SEL sel, BOOL b, double time) 
{
//	NSLog(@"WI: Unscattering springboard.");

	// refresh the weather model
	[_model refresh];

	// do the unscatter
	[self wi_unscatter:b startTime:time];
}

static id weatherIcon(SBIcon *self, SEL sel) 
{
//	NSLog(@"WI: Calling icon method.");
	return [_model icon];
}

static void $SBApplication$deactivated(SBApplication<WeatherIcon> *self, SEL sel) 
{
	if ([self.displayIdentifier isEqualToString:@"com.apple.weather"] ||
	    [self.displayIdentifier isEqualToString:_model.bundleIdentifier])
	{
		[_model setNeedsRefresh];

		// refresh the weather model
		[_model refresh];
	}

	[self wi_deactivated];
}

static id $SBApplicationIcon$initWithApplication$(SBApplicationIcon<WeatherIcon> *self, SEL sel, id app) 
{
	self = [self wi_initWithApplication:app];

	if ([_model isWeatherIcon:self])
	{
		NSLog(@"WI: Replacing icon method for %@.", self.displayIdentifier);
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

	if ([_model isWeatherIcon:self])
	{
		NSLog(@"WI: Replacing icon method for %@.", self.displayIdentifier);
		object_setClass(self, $WIBookmarkIcon);
	}

	return self;
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

	Class $SBIconController = objc_getClass("SBIconController");
	Class $SBBookmarkIcon = objc_getClass("SBBookmarkIcon");
	Class $SBApplicationIcon = objc_getClass("SBApplicationIcon");
	Class $SBApplication = objc_getClass("SBApplication");
	
	// MSHookMessage is what we use to redirect the methods to our own
	MSHookMessage($SBIconController, @selector(init), (IMP) &$SBIconController$init, "wi_");
	MSHookMessage($SBIconController, @selector(unscatter:startTime:), (IMP) &$SBIconController$unscatter$, "wi_");
	MSHookMessage($SBApplication, @selector(deactivated), (IMP) &$SBApplication$deactivated, "wi_");
	MSHookMessage($SBApplicationIcon, @selector(initWithApplication:), (IMP) &$SBApplicationIcon$initWithApplication$, "wi_");
	MSHookMessage($SBBookmarkIcon, @selector(initWithWebClip:), (IMP) &$SBBookmarkIcon$initWithWebClip$, "wi_");
	
	NSLog(@"WI: Init weather model.");
	_model = [[WeatherIconModel alloc] init];
}
