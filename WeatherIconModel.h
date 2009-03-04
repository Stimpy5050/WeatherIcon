/*
 *  ReflectionView.h
 *  
 *
 *  Created by David Ashman on 1/12/09.
 *  Copyright 2009 David Ashman. All rights reserved.
 *
 */

#import <SpringBoard/SBIcon.h>
#import <SpringBoard/SBIconController.h>
#import <SpringBoard/SBStatusBarController.h>
#import <UIKit/UIKit.h>

@interface WeatherIconModel : NSObject
{
	NSMutableString* parserContent;
	BOOL refreshing;
	BOOL themeLoaded;
	BOOL prefsLoaded;
	BOOL weatherPrefsLoaded;

	// image caches
	UIImage* statusBarIndicatorMode0;
	UIImage* statusBarIndicatorMode1;
	UIImage* weatherIcon;

	// current temp info
	NSString* temp;
	NSString* code;
	NSString* sunrise;
	NSString* sunset;
	NSString* longitude;
	NSString* latitude;
	NSTimeZone* timeZone;
	NSDate* localWeatherTime;
	BOOL night;

	// refresh date info
	NSDate* nextRefreshTime;
	NSDate* lastUpdateTime;

	// theme info
	NSString* tempStyle;
	NSString* tempStyleNight;
	NSDictionary* mappings;
	float imageScale;
	int imageMarginTop;
	float statusBarImageScale;

	// user preferences
	BOOL isCelsius;
	BOOL overrideLocation;
	BOOL showFeelsLike;
	BOOL showWeatherIcon;
	BOOL showStatusBarImage;
	BOOL showStatusBarTemp;
	NSString* location;
	int refreshInterval;
	NSString* bundleIdentifier;
	BOOL useLocalTime;
	BOOL debug;

}

- (id)init;
- (BOOL)isWeatherIcon:(NSString*) displayIdentifier;
- (void)refresh;
- (void)refreshNow;
- (BOOL)showStatusBarWeather;
- (UIImage*)icon;
- (UIImage*)statusBarIndicator:(int) mode;
- (void)dealloc;

@end
