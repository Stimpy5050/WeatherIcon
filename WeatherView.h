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
	UIImageView *_image;
	CLLocationManager *_locationManager;
}

@property(nonatomic) BOOL isCelsius;
@property(nonatomic) BOOL overrideLocation;
@property(nonatomic retain) NSString* location;
@property(nonatomic retain) NSString* temp;
@property(nonatomic retain) NSString* code;
@property(nonatomic retain) NSString* tempStyle;
@property(nonatomic) int refreshInterval;
@property(nonatomic retain) NSDate* nextRefreshTime;
@property(nonatomic retain) NSDate* lastUpdateTime;

+ (NSDictionary*)preferences;
- (void) _parseWeatherPreferences;
- (id)initWithIcon:(SBApplicationIcon*)icon;
- (void)refresh;
- (void)_refresh;
- (void)drawRect:(CGRect)rect;

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation;

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error;

@end
