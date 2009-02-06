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

@property(nonatomic, retain) NSString* temp;
@property(nonatomic, retain) NSString* windChill;
@property(nonatomic, retain) NSString* tempStyle;
@property(nonatomic, retain) NSString* tempStyleNight;
@property(nonatomic, retain) NSString* type;
@property(nonatomic, retain) NSString* code;
@property(nonatomic, retain) NSString* sunrise;
@property(nonatomic, retain) NSString* sunset;
@property(nonatomic) BOOL night;

@property(nonatomic) float imageScale;
@property(nonatomic) int imageMarginTop;

@property(nonatomic, retain) UIImage* weatherIcon;

@property(nonatomic) BOOL isCelsius;
@property(nonatomic) BOOL overrideLocation;
@property(nonatomic) BOOL showFeelsLike;
@property(nonatomic, retain) NSString* location;
@property(nonatomic) int refreshInterval;
@property(nonatomic, retain) NSString* bundleIdentifier;
@property(nonatomic) BOOL debug;

@property(nonatomic, retain) NSDate* nextRefreshTime;
@property(nonatomic, retain) NSDate* lastUpdateTime;

+ (NSMutableDictionary*) preferences;
- (void) _parsePreferences;
- (void) _parseWeatherPreferences;
- (id)init;
- (BOOL)isWeatherIcon:(SBIcon*) icon;
- (void)refresh:(SBIconController*) controller;
- (void)_refresh;
- (void)_refreshInBackground:(SBIconController*) controller;
- (void)_updateWeatherIcon:(SBIconController*) controller;
- (UIImage*)icon;
- (void)dealloc;

@end
