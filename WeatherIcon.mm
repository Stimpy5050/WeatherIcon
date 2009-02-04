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
- (id) wi_initWithApplication:(id) app;
- (id) wi_initWithWebClip:(id) clip;
- (void) wi_unscatter:(BOOL) b startTime:(double) time;
- (UIImage*) wi_getCachedImagedForIcon:(SBIcon*) icon;
@end

static NSString* _weatherBundleIdentifier;
static WeatherIconModel* _model;

static NSString* bundleIdentifier()
{
	if (!_weatherBundleIdentifier)
	{
		NSString* bundleIdentifier = @"com.apple.weather";
	
		NSDictionary* prefs = [WeatherIconModel preferences];
		if (prefs)
			if (NSString* bi = [prefs objectForKey:@"WeatherBundleIdentifier"])
				bundleIdentifier = bi;

		_weatherBundleIdentifier = [[NSString stringWithString:bundleIdentifier] retain];
	}

	return _weatherBundleIdentifier;
}

static void $SBIconController$unscatter$(SBIconController<WeatherIcon> *self, SEL sel, BOOL b, double time) 
{
//	NSLog(@"WI: Unscattering springboard.");

	// refresh the weather model
	[_model refresh];

	// now force the icon to refresh
	SBIconModel* model(MSHookIvar<SBIconModel*>(self, "_iconModel"));
	[model reloadIconImageForDisplayIdentifier:bundleIdentifier()];

	// do the unscatter
	[self wi_unscatter:b startTime:time];
}

static id $SBBookmarkIcon$initWithWebClip$(SBBookmarkIcon<WeatherIcon> *self, SEL sel, id clip) 
{
//	NSLog(@"WI: Link to %@?", self.displayIdentifier);
	self = [self wi_initWithWebClip:clip];

	if ([self.displayIdentifier isEqualToString:bundleIdentifier()])
	{
		NSLog(@"WI: Init weather model.");
		_model = [[WeatherIconModel alloc] initWithIcon:self];
	}

	return self;
}

static UIImage* $SBIconModel$getCachedImagedForIcon$(SBIconModel<WeatherIcon> *self, SEL sel, SBIcon* icon) 
{
	if ([icon.displayIdentifier isEqualToString:bundleIdentifier()])
	{
		NSLog(@"WI: Asking for cached weather icon.");
		return [_model icon];
	}

	return [self wi_getCachedImagedForIcon:icon];
}

static id $SBApplicationIcon$icon(SBApplicationIcon<WeatherIcon> *self, SEL sel) 
{
	if ([[self displayIdentifier] isEqualToString:bundleIdentifier()])
	{
		NSLog(@"WI: Asking for weather icon.");
		return [_model icon];
	}

	return [self wi_icon];
}

static id $SBBookmarkIcon$icon(SBBookmarkIcon<WeatherIcon> *self, SEL sel) 
{
	if ([[self displayIdentifier] isEqualToString:bundleIdentifier()])
	{
		NSLog(@"WI: Asking for weather icon.");
		return [_model icon];
	}

	return [self wi_clip_icon];
}

static id $SBApplicationIcon$initWithApplication$(SBApplicationIcon<WeatherIcon> *self, SEL sel, id app) 
{
	self = [self wi_initWithApplication:app];

/*
// Create new LiveIcon class
 liveIconClass = objc_allocateClassPair(objc_getClass("SBApplicationIcon"), "LiveClockApplicationIcon", 0);
 class_replaceMethod(liveIconClass, @selector(icon), (IMP)&SBApplicationIcon_icon, "@@:");
 objc_registerClassPair(liveIconClass);
*/

	if ([self.displayIdentifier isEqualToString:bundleIdentifier()])
	{
		NSLog(@"WI: Init weather model.");
		_model = [[WeatherIconModel alloc] initWithIcon:self];
	}

	return self;
}

extern "C" void WeatherIconInitialize() {
	if (objc_getClass("SpringBoard") == nil)
		return;

	// Get the SBIcon class
	Class $SBIconController = objc_getClass("SBIconController");
	Class $SBBookmarkIcon = objc_getClass("SBBookmarkIcon");
	Class $SBApplicationIcon = objc_getClass("SBApplicationIcon");
	Class $SBIconModel = objc_getClass("SBIconModel");
	
	// MSHookMessage is what we use to redirect the methods to our own
	MSHookMessage($SBIconController, @selector(unscatter:startTime:), (IMP) &$SBIconController$unscatter$, "wi_");
	MSHookMessage($SBIconModel, @selector(getCachedImagedForIcon:), (IMP) &$SBIconModel$getCachedImagedForIcon$, "wi_");
	MSHookMessage($SBBookmarkIcon, @selector(initWithWebClip:), (IMP) &$SBBookmarkIcon$initWithWebClip$, "wi_");
	MSHookMessage($SBBookmarkIcon, @selector(icon), (IMP) &$SBBookmarkIcon$icon, "wi_clip_");
	MSHookMessage($SBApplicationIcon, @selector(initWithApplication:), (IMP) &$SBApplicationIcon$initWithApplication$, "wi_");
	MSHookMessage($SBApplicationIcon, @selector(icon), (IMP) &$SBApplicationIcon$icon, "wi_");
}
