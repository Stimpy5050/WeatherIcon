/*
 *  ReflectionView.h
 *  
 *
 *  Created by David Ashman on 1/12/09.
 *  Copyright 2009 David Ashman. All rights reserved.
 *
 */

#import <SpringBoard/SBApplicationIcon.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@interface WeatherView : UIView <CLLocationManagerDelegate>
{
	SBApplicationIcon *_icon;
	CLLocationManager *_locationManager;
}

@property(nonatomic) NSString* temp;
@property(nonatomic) NSString* tempStyle;
@property(nonatomic) NSString* code;
@property(nonatomic) float imageScale;
@property(nonatomic) int imageMarginTop;

@property(nonatomic) BOOL isCelsius;
@property(nonatomic) BOOL overrideLocation;
@property(nonatomic retain) NSString* location;
@property(nonatomic) int refreshInterval;

@property(nonatomic retain) NSDate* nextRefreshTime;
@property(nonatomic retain) NSDate* lastUpdateTime;

+ (NSMutableDictionary*) preferences;
- (void) _parsePreferences;
- (void) _parseWeatherPreferences;
- (id)initWithIcon:(SBApplicationIcon*)icon;
- (void)refresh;
- (void)_refresh;
- (void)drawRect:(CGRect) rect;

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation;

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error;

@end
