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
}

@property(nonatomic, retain) NSString* temp;
@property(nonatomic, retain) NSString* windChill;
@property(nonatomic, retain) NSString* code;
@property(nonatomic, retain) NSString* sunrise;
@property(nonatomic, retain) NSString* sunset;
@property(nonatomic, retain) NSString* longitude;
@property(nonatomic, retain) NSString* latitude;
@property(nonatomic, retain) NSTimeZone* timeZone;
@property(nonatomic) BOOL night;

@property(nonatomic, retain) NSString* tempStyle;
@property(nonatomic, retain) NSString* tempStyleNight;
@property(nonatomic, retain) NSDictionary* mappings;
@property(nonatomic) float imageScale;
@property(nonatomic) int imageMarginTop;
@property(nonatomic) float statusBarImageScale;

@property(nonatomic, retain) UIImage* weatherIcon;
@property(nonatomic, retain) UIImage* weatherImage;
@property(nonatomic, retain) UIImage* statusBarImage;

@property(nonatomic) BOOL isCelsius;
@property(nonatomic) BOOL overrideLocation;
@property(nonatomic) BOOL showFeelsLike;
@property(nonatomic) BOOL showWeatherIcon;
@property(nonatomic) BOOL showStatusBarImage;
@property(nonatomic) BOOL showStatusBarTemp;
@property(nonatomic, retain) NSString* location;
@property(nonatomic) int refreshInterval;
@property(nonatomic, retain) NSString* bundleIdentifier;
@property(nonatomic) BOOL useLocalTime;
@property(nonatomic) BOOL debug;

@property(nonatomic, retain) NSDate* nextRefreshTime;
@property(nonatomic, retain) NSDate* lastUpdateTime;
@property(nonatomic, retain) NSDate* localWeatherTime;

+ (NSMutableDictionary*) preferences;
- (void) _parsePreferences;
- (void) _parseWeatherPreferences;
- (id)init;
- (BOOL)isWeatherIcon:(SBIcon*) icon;
- (void)setNeedsRefresh;
- (void)refresh;
- (void)_refresh;
- (void)_refreshInBackground;
- (void)_updateWeatherIcon;
- (BOOL) showStatusBarWeather;
- (UIImage*)icon;
- (void)dealloc;

@end
