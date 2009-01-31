/*
 *  ReflectionView.h
 *  
 *
 *  Created by David Ashman on 1/12/09.
 *  Copyright 2009 David Ashman. All rights reserved.
 *
 */

#import <SpringBoard/SBIcon.h>
#import <UIKit/UIKit.h>

@interface WeatherView : UIView 

@property(nonatomic, retain) SBIcon* applicationIcon;

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
@property(nonatomic) BOOL highlighted;

@property(nonatomic, retain) UIImage* bgIcon;
@property(nonatomic, retain) UIImage* weatherImage;
@property(nonatomic, retain) UIImage* weatherIcon;
@property(nonatomic, retain) UIImage* shadow;

@property(nonatomic) BOOL isCelsius;
@property(nonatomic) BOOL overrideLocation;
@property(nonatomic) BOOL showFeelsLike;
@property(nonatomic, retain) NSString* location;
@property(nonatomic) int refreshInterval;

@property(nonatomic, retain) NSDate* nextRefreshTime;
@property(nonatomic, retain) NSDate* lastUpdateTime;

+ (NSMutableDictionary*) preferences;
- (void) _parsePreferences;
- (void) _parseWeatherPreferences;
- (id)initWithIcon:(SBIcon*)icon;
- (void)updateWeatherView;
- (void)refresh;
- (void)_refresh;
- (void)drawRect:(CGRect) rect;
- (void)dealloc;

@end
