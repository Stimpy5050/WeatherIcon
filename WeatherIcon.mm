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
#import "WeatherIconSettings.h"
#import <SpringBoard/SBIcon.h>
#import <SpringBoard/SBIconList.h>
#import <SpringBoard/SBTelephonyManager.h>
#import <SpringBoard/SBIconController.h>
#import <SpringBoard/SBUIController.h>
#import <SpringBoard/SBStatusBar.h>
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
- (id) wi_initWithApplication:(id) app;
- (id) wi_initWithWebClip:(id) clip;
- (void) wi_unscatter:(BOOL) b startTime:(double) time;
- (void) wi_deactivated;
- (void) wi_buildContentViews;
- (void) wi_reloadIndicators;
//- (void) wi__initializeIndicatorViewsWithNames:(id) names;
- (void) wi_indicatorsChanged;
- (void) wi_updateInterface;
- (NSString*) wi_pathForResource:(NSString*) name ofType:(NSString*) type;
@end

static Class $WIIconModel;
static Class $WIInstalledApplicationIcon;
static Class $WIApplicationIcon;
static Class $WIBookmarkIcon;
static Class $SBStatusBarContentsView;

static WeatherIconController* _controller;
static SBStatusBarContentView* _sb0;
static SBStatusBarContentView* _sb1;

@interface SBStatusBarContentView3 : SBStatusBarContentView
-(BOOL) showOnLeft;
-(BOOL) isVisible;
@end

static void refreshController(BOOL now)
{
	Class cls = objc_getClass("SBTelephonyManager");
	SBTelephonyManager* mgr = [cls sharedTelephonyManager];
//	NSLog(@"WI: Telephony: %d, %d, %d", mgr.inCall, mgr.incomingCallExists, mgr.activeCallExists);
	if (!mgr.inCall && !mgr.incomingCallExists && !mgr.activeCallExists && !mgr.outgoingCallExists)
	{
		if (now)
			[_controller refreshNow];
		else
			[_controller refresh];
	}
}

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

//	NSLog(@"WI: Refreshing? %d", refresh);
	if (refresh)
		refreshController(false);
}

static void $SBIconController$unscatter$(SBIconController<WeatherIcon> *self, SEL sel, BOOL b, double time) 
{
	// do the unscatter
	[self wi_unscatter:b startTime:time];

//	NSLog(@"WI: Refreshing on unscatter.");

	// refresh the weather model
	if (_controller.lastUpdateTime == nil)
		refreshController(false);
}

static id weatherIcon(SBIcon *self, SEL sel) 
{
	NSLog(@"WI: Calling icon method for %@", self.displayIdentifier);
	return [_controller icon];
}

static float findStart(SBStatusBarContentsView* self, const char* varName, const char* visibleVarName, float currentStart)
{
	if (SBStatusBarContentView3* icon  = MSHookIvar<NSMutableArray*>(self, varName))
	{
//		BOOL visible  = MSHookIvar<BOOL>(icon, visibleVarName);
//		NSLog(@"WI: findStart: Icon %@ is visible? %d", icon, visible);	
		return (icon.superview == self && icon.frame.origin.x > 0 && icon.isVisible && icon.frame.origin.x < currentStart ? icon.frame.origin.x : currentStart);
	}

	return currentStart;
}

static void updateWeatherView(SBStatusBarContentsView* self)
{	
	SBStatusBar* sb = [self statusBar];
	int mode = [sb mode];

	if (UIImage* indicator = [_controller statusBarIndicator:mode])
	{
		SBStatusBarContentView* weatherView = (mode == 0 ? _sb0 : _sb1);
		if (weatherView == nil)
		{
			Class sbClass = objc_getClass("SBStatusBarContentView");
			weatherView = [[[sbClass alloc] initWithContentsView:self] autorelease];
			weatherView.tag = -1;
			[weatherView setAlpha:[$SBStatusBarContentsView contentAlphaForMode:mode]];
			[weatherView setMode:mode];

			UIImageView* iv = [[[UIImageView alloc] initWithImage:indicator] autorelease];
			[weatherView addSubview:iv];

			if (mode == 0)
				_sb0 = [weatherView retain];
			else
				_sb1 = [weatherView retain];
		}

		float x = findStart(self, "_batteryView", "_showBatteryView", 480);
		x = findStart(self, "_batteryPercentageView", "_showBatteryPercentageView", x);
//		x = findStart(self, "_bluetoothView", "_showBluetoothView", x);
//		x = findStart(self, "_bluetoothBatteryView", "_showBluetoothBatteryView", x);

//		NSLog(@"WI: Moving weather view to %f", x - indicator.size.width - 3);	
		weatherView.frame = CGRectMake(x - indicator.size.width - 3, 0, indicator.size.width, indicator.size.height);	

		// clear the content view
		UIImageView* iv = [[weatherView subviews] objectAtIndex:0];
		if (iv.image != indicator)
		{
			iv.frame = CGRectMake(0, 0, indicator.size.width, indicator.size.height);
			iv.image = indicator;
		}

		if ([[self subviews] indexOfObject:weatherView] == NSNotFound)
		{
//			NSLog(@"WI: Adding weather view");
			[self addSubview:weatherView];
		}
	}
}

static void updateWeatherView(SBStatusBarContentView* view)
{
	if (!((SBStatusBarContentView3*)view).showOnLeft)
	{
		SBStatusBarContentsView* contents = MSHookIvar<SBStatusBarContentsView*>(view, "_contentsView");
		updateWeatherView(contents);
	}
}

MSHook(void, reflowContentViewsNow, SBStatusBarContentsView* self, SEL sel)
{	
//	NSLog(@"WI: reflowContentViewsNow");
	_reflowContentViewsNow(self, sel);
	updateWeatherView(self);
}

MSHook(void, btSetFrame, SBStatusBarContentView* self, SEL sel, CGRect rect)
{
	int mode = [self effectiveModeForImages];
	UIImage* indicator = [_controller statusBarIndicator:mode];
	float offset = (indicator == nil ? 0 : indicator.size.width + 2);
	_btSetFrame(self, sel, CGRectMake(rect.origin.x - offset, rect.origin.y, rect.size.width, rect.size.height));
}

MSHook(void, btbSetFrame, SBStatusBarContentView* self, SEL sel, CGRect rect)
{
	int mode = [self effectiveModeForImages];
	UIImage* indicator = [_controller statusBarIndicator:mode];
	float offset = (indicator == nil ? 0 : indicator.size.width + 2);
	_btbSetFrame(self, sel, CGRectMake(rect.origin.x - offset, rect.origin.y, rect.size.width, rect.size.height));
}

MSHook(void, indicatorSetFrame, SBStatusBarContentView* self, SEL sel, CGRect rect) 
{
	int mode = [self effectiveModeForImages];
	UIImage* indicator = [_controller statusBarIndicator:mode];
	float offset = (indicator == nil ? 0 : indicator.size.width + 2);
	_indicatorSetFrame(self, sel, CGRectMake(rect.origin.x - offset, rect.origin.y, rect.size.width, rect.size.height));
}

static void $SBStatusBarIndicatorsView$reloadIndicators(SBStatusBarIndicatorsView<WeatherIcon> *self, SEL sel) 
{
	[self wi_reloadIndicators];

	int mode = [self effectiveModeForImages];
	UIImage* indicator = [_controller statusBarIndicator:mode];

	NSLog(@"WI: Reloading indicators");
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
	[self wi_deactivated];

	if ([self.displayIdentifier isEqualToString:@"com.apple.weather"] ||
	    [_controller isWeatherIcon:self.displayIdentifier])
	{
		// refresh the weather model
		refreshController(true);
	}

	if ([self.displayIdentifier isEqualToString:@"com.apple.Preferences"])
	{
		[_controller checkPreferences];
	}
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

#define Hook(cls, sel, imp) \
        _ ## imp = MSHookMessage($ ## cls, @selector(sel), &$ ## imp)

extern "C" void TweakInit() {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

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

	Class $NSBundle = objc_getClass("NSBundle");
	Class $SBAwayView = objc_getClass("SBAwayView");
	Class $SBIconController = objc_getClass("SBIconController");
	Class $SBBookmarkIcon = objc_getClass("SBBookmarkIcon");
	Class $SBApplicationIcon = objc_getClass("SBApplicationIcon");
	Class $SBApplication = objc_getClass("SBApplication");
	Class $SBIconModel = objc_getClass("SBIconModel");
	Class $SBStatusBarController = objc_getClass("SBStatusBarController");
	Class $SBStatusBarBatteryView = objc_getClass("SBStatusBarBatteryView");
	Class $SBStatusBarBluetoothView = objc_getClass("SBStatusBarBluetoothView");
	Class $SBStatusBarBluetoothBatteryView = objc_getClass("SBStatusBarBluetoothBatteryView");
	Class $SBStatusBarContentView = objc_getClass("SBStatusBarContentView");
	Class $SBStatusBarIndicatorView = objc_getClass("SBStatusBarIndicatorView");
	Class $SBStatusBarIndicatorsView = objc_getClass("SBStatusBarIndicatorsView");
	$SBStatusBarContentsView = objc_getClass("SBStatusBarContentsView");
	
	// MSHookMessage is what we use to redirect the methods to our own
	MSHookMessage($SBIconController, @selector(unscatter:startTime:), (IMP) &$SBIconController$unscatter$, "wi_");
	MSHookMessage($SBApplication, @selector(deactivated), (IMP) &$SBApplication$deactivated, "wi_");
	MSHookMessage($SBApplicationIcon, @selector(initWithApplication:), (IMP) &$SBApplicationIcon$initWithApplication$, "wi_");
	MSHookMessage($SBBookmarkIcon, @selector(initWithWebClip:), (IMP) &$SBBookmarkIcon$initWithWebClip$, "wi_");
	MSHookMessage($SBStatusBarIndicatorsView, @selector(reloadIndicators), (IMP) &$SBStatusBarIndicatorsView$reloadIndicators, "wi_");
	MSHookMessage($SBAwayView, @selector(updateInterface), (IMP) &$SBAwayView$updateInterface, "wi_");

	// only hook these in 3.0
	if ($SBStatusBarIndicatorsView == nil)
	{
		Hook(SBStatusBarIndicatorView, setFrame:, indicatorSetFrame);
		Hook(SBStatusBarBluetoothView, setFrame:, btSetFrame);
		Hook(SBStatusBarBluetoothBatteryView, setFrame:, btbSetFrame);
		Hook(SBStatusBarContentsView, reflowContentViewsNow, reflowContentViewsNow);
	}
	
	NSLog(@"WI: Init weather controller.");
	_controller = [WeatherIconController sharedInstance];

	[pool release];
}
