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
#import <UIKit/UIKit.h>

@interface WeatherIconModel : NSObject
{
	SBIconController* controller;
	NSMutableString* parserContent;
}

@property(nonatomic, retain) NSString* temp;
@property(nonatomic, retain) NSString* windChill;
@property(nonatomic, retain) NSString* code;
@property(nonatomic, retain) NSString* sunrise;
@property(nonatomic, retain) NSString* sunset;
@property(nonatomic, retain) NSString* longitude;
@property(nonatomic, retain) NSString* latitude;
@property(nonatomic) BOOL night;

@property(nonatomic, retain) NSString* type;
@property(nonatomic, retain) NSString* tempStyle;
@property(nonatomic, retain) NSString* tempStyleNight;
@property(nonatomic) float imageScale;
@property(nonatomic) int imageMarginTop;

@property(nonatomic, retain) UIImage* weatherIcon;

@property(nonatomic) BOOL isCelsius;
@property(nonatomic) BOOL useLocalTime;
@property(nonatomic) BOOL overrideLocation;
@property(nonatomic) BOOL showFeelsLike;
@property(nonatomic, retain) NSString* location;
@property(nonatomic) int refreshInterval;
@property(nonatomic, retain) NSString* bundleIdentifier;
@property(nonatomic) BOOL debug;

@property(nonatomic, retain) NSDate* nextRefreshTime;
@property(nonatomic, retain) NSDate* lastUpdateTime;
@property(nonatomic, retain) NSDate* localWeatherTime;

+ (NSMutableDictionary*) preferences;
- (void) _parsePreferences;
- (void) _parseWeatherPreferences;
- (id)init;
- (void)setIconController:(SBIconController*) iconController;
- (BOOL)isWeatherIcon:(SBIcon*) icon;
- (void)setNeedsRefresh;
- (void)refresh;
- (void)_refresh;
- (void)_refreshInBackground;
- (void)_updateWeatherIcon;
- (UIImage*)icon;
- (void)dealloc;

@end
