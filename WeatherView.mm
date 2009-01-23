/*
 *  ReflectiveDock.mm
 *  
 *
 *  Created by David Ashman on 1/12/09.
 *  Copyright 2009 David Ashman. All rights reserved.
 *
 */

#import "WeatherView.h"
#import <substrate.h>
#import <SpringBoard/SBApplicationIcon.h>
#import <SpringBoard/SleepProofTimer.h>
#import <UIKit/UIStringDrawing.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <Foundation/NSObjCRuntime.h>

@implementation WeatherView

@synthesize temp, code, tempStyle, imageScale, imageMarginTop;

@synthesize isCelsius;
@synthesize overrideLocation;
@synthesize location;
@synthesize refreshInterval;
@synthesize nextRefreshTime;
@synthesize lastUpdateTime;

+ (NSMutableDictionary*) preferences
{
	NSString* prefsPath = @"/User/Library/Preferences/com.ashman.WeatherIcon.plist";
	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithContentsOfFile:prefsPath];
	[dict autorelease];
	return dict;
}

- (void) _parsePreferences
{
	NSMutableDictionary* prefs = [WeatherView preferences];
	if (prefs)
	{
		if (NSNumber* ol = [prefs objectForKey:@"OverrideLocation"])
			self.overrideLocation = [ol boolValue];
		NSLog(@"WI: Location: %@", self.location);

		if (self.overrideLocation)
		{
			if (NSString* loc = [prefs objectForKey:@"Location"])
				self.location = [[NSString alloc] initWithString:loc];

			if (NSNumber* celsius = [prefs objectForKey:@"Celsius"])
				self.isCelsius = [celsius boolValue];
		}
		else
		{
			[self _parseWeatherPreferences];
		}

		NSLog(@"WI: Location: %@", self.location);
		NSLog(@"WI: Celsius: %@", (self.isCelsius ? @"YES" : @"NO"));

		if (NSNumber* interval = [prefs objectForKey:@"RefreshInterval"])
			self.refreshInterval = ([interval intValue] * 60);
		NSLog(@"WI: Refresh Interval: %d seconds", self.refreshInterval);
	}
	else
	{
		prefs = [NSMutableDictionary dictionaryWithCapacity:4];
		[prefs setValue:[NSNumber numberWithBool:self.overrideLocation] forKey:@"OverrideLocation"];
		[prefs setValue:self.location forKey:@"Location"];
		[prefs setValue:[NSNumber numberWithBool:self.isCelsius] forKey:@"Celsius"];
		[prefs setValue:[NSNumber numberWithInt:(int)(self.refreshInterval / 60)] forKey:@"RefreshInterval"];
		[prefs setValue:@"com.apple.weather" forKey:@"WeatherBundleIdentifier"];

	        NSString* prefsPath = @"/User/Library/Preferences/com.ashman.WeatherIcon.plist";
		[prefs writeToFile:prefsPath atomically:YES];
	}

	NSBundle* bundle = [NSBundle mainBundle];
	NSString* themePrefs = [bundle pathForResource:@"com.ashman.WeatherIcon" ofType:@"plist"];
	if (themePrefs)
	{
		NSDictionary* dict = [[NSDictionary alloc] initWithContentsOfFile:themePrefs];
		if (dict)
		{
			if (NSString* style = [dict objectForKey:@"TempStyle"])
				self.tempStyle = [[NSString alloc] initWithString:style];

			if (NSNumber* scale = [dict objectForKey:@"ImageScale"])
				self.imageScale = [scale floatValue];

			if (NSNumber* top = [dict objectForKey:@"ImageMarginTop"])
				self.imageMarginTop = [top intValue];
		}
	}	
}

- (void) _parseWeatherPreferences
{
	NSString* prefsPath = @"/User/Library/Preferences/com.apple.weather.plist";
	NSDictionary* dict = [[NSDictionary alloc] initWithContentsOfFile:prefsPath];
	[dict autorelease];

	if (dict)
	{
		self.isCelsius = [[dict objectForKey:@"Celsius"] boolValue];

		NSNumber* activeCity = [dict objectForKey:@"ActiveCity"];
		NSArray* cities = [dict objectForKey:@"Cities"];
		NSDictionary* city = [cities objectAtIndex:0];
		self.location = [[city objectForKey:@"Zip"] substringToIndex:8];
	}
}

- (id) initWithIcon:(SBApplicationIcon*)icon
{
        CGRect rect = CGRectMake(0, 0, icon.frame.size.width, icon.frame.size.height);
        id ret = [self initWithFrame:rect];

        _icon = icon;

	self.temp = @"?";
	self.code = @"3200";
	self.imageScale = 1.0;
	self.imageMarginTop = 0;
	self.isCelsius = false;
	self.overrideLocation = false;
	self.refreshInterval = 900;

	self.opaque = NO;
	self.userInteractionEnabled = NO;

	[self _parsePreferences];

	self.nextRefreshTime = [NSDate date];

/*
	_locationManager = [[[CLLocationManager alloc] init] autorelease];
	_locationManager.delegate = self; // Tells the location manager to send updates to this object
	_locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
	[_locationManager startUpdatingLocation];
	NSLog(@"WI: Location: %@", _locationManager.location);
*/

	return ret;
}


- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
namespaceURI:(NSString *)namespaceURI
qualifiedName:(NSString *)qName
   attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"yweather:condition"])
	{
		self.temp = [[NSString alloc] initWithString:[attributeDict objectForKey:@"temp"]];
		NSLog(@"WI: Temp: %@", self.temp);
		self.code = [[NSString alloc] initWithString:[attributeDict objectForKey:@"code"]];
		NSLog(@"WI: Code: %@", self.code);

		self.lastUpdateTime = [[NSDate alloc] init];
	}
}

- (void)parser:(NSXMLParser *)parser
didEndElement:(NSString *)elementName
namespaceURI:(NSString *)namespaceURI
qualifiedName:(NSString *)qName
{
}


- (void)parser:(NSXMLParser *)parser
foundCharacters:(NSString *)string
{   
}

- (void) refresh
{
	NSDate* now = [NSDate date];
//	NSLog(@"WI: Checking refresh dates: %@ vs %@", now, self.nextRefreshTime);

	// are we ready for an update?
	if ([now compare:self.nextRefreshTime] == NSOrderedAscending)
	{
//		NSLog(@"WI: No refresh yet.");
		return;
	}

	[NSThread detachNewThreadSelector:@selector(_refresh) toTarget:self withObject:nil];
}

- (void) _refresh
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	// reparse the preferences
	if (!self.overrideLocation)
		[self _parseWeatherPreferences];

	if (!self.location)
	{
		NSLog(@"WI: No location set.");
		return;
	}

	NSLog(@"WI: Refreshing weather for %@...", self.location);
	NSString* urlStr = [NSString stringWithFormat:@"http://weather.yahooapis.com/forecastrss?p=%@&u=%@", self.location, (self.isCelsius ? @"c" : @"f")];
	NSURL* url = [NSURL URLWithString:urlStr];
	NSXMLParser* parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
	[parser setDelegate:self];
	[parser parse];
	[parser release];

	NSLog(@"WI: Did the update succeed? %@ vs %@", self.lastUpdateTime, self.nextRefreshTime);
	if (!self.lastUpdateTime || [self.lastUpdateTime compare:self.nextRefreshTime] == NSOrderedAscending)
	{
		NSLog(@"WI: Update failed.");
		return;
	}

	if (!self.temp)
		self.temp = @"?";

	if (!self.code)
		self.code = @"3200";

	[self setNeedsDisplay];

	self.nextRefreshTime = [[NSDate alloc] initWithTimeIntervalSinceNow:self.refreshInterval];
	NSLog(@"WI: Next refresh time: %@", self.nextRefreshTime);

	[pool release];
}

- (void) drawRect:(CGRect) rect
{
        NSBundle* sb = [NSBundle mainBundle];
        NSString* iconName = [@"weather" stringByAppendingString:self.code];
        NSString* iconPath = [sb pathForResource:iconName ofType:@"png"];

        if (iconPath)
        {
                UIImage* weatherIcon = [UIImage imageWithContentsOfFile:iconPath];
		float width = weatherIcon.size.width * self.imageScale;
		float height = weatherIcon.size.height * self.imageScale;
                CGRect iconRect = CGRectMake((self.frame.size.width - width) / 2, self.imageMarginTop, width, height);
                [weatherIcon drawInRect:iconRect];
        }

        NSString* t = [self.temp stringByAppendingString: @"\u00B0"];
        NSString* tempStyle(@""
                "font-family: Helvetica; "
                "font-weight: bold; "
                "font-size: 13px; "
                "color: white; "
                "margin-top: 38px; "
                "margin-left: 3px; "
                "width: 59px; "
                "text-align: center; "
                "text-shadow: rgba(0, 0, 0, 0.2) -1px -1px 1px; "
        "");

        if (self.tempStyle && [self.tempStyle length] > 0)
                tempStyle = [tempStyle stringByAppendingString:self.tempStyle];

        [t drawAtPoint:CGPointMake(0, 0) withStyle:tempStyle];
}

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
	NSLog(@"WI: New location: %@", newLocation);
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
	NSLog(@"WI: Location Error: %@", error);
}
@end
