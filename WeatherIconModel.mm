/*
 *  WeatherView.mm
 *  
 *
 *  Created by David Ashman on 1/12/09.
 *  Copyright 2009 David Ashman. All rights reserved.
 *
 */

#import "WeatherIconModel.h"
#import "WeatherIndicatorView.h"
#import <substrate.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>
#import <SpringBoard/SBIconModel.h>
#import <SpringBoard/SBIconController.h>
#import <SpringBoard/SBStatusBar.h>
#import <SpringBoard/SBStatusBarContentsView.h>
#import <SpringBoard/SBStatusBarIndicatorsView.h>
#import <SpringBoard/SBStatusBarController.h>
#import <SpringBoard/SBApplicationIcon.h>
#import <SpringBoard/SleepProofTimer.h>
#import <UIKit/UIStringDrawing.h>
#import <UIKit/UIKit.h>
#import <Foundation/NSObjCRuntime.h>

static Class $SBStatusBarController = objc_getClass("SBStatusBarController");
static Class $SBIconController = objc_getClass("SBIconController");

static NSString* defaultTempStyle(@""
	"font-family: Helvetica; "
	"font-weight: bold; "
	"font-size: 13px; "
	"color: white; "
	"margin-top: 40px; "
	"margin-left: 3px; "
	"width: %dpx; "
	"text-align: center; "
	"text-shadow: rgba(0, 0, 0, 0.2) 1px 1px 0px; "
"");

@implementation WeatherIconModel

@synthesize temp, windChill, code, tempStyle, tempStyleNight, statusBarImageScale, imageScale, imageMarginTop, mappings;
@synthesize latitude, longitude, timeZone;
@synthesize sunset, sunrise, night;
@synthesize weatherIcon, weatherImage, statusBarImage;
@synthesize isCelsius, overrideLocation, showFeelsLike, location, refreshInterval, bundleIdentifier, debug, useLocalTime, showStatusBarImage, showStatusBarTemp;
@synthesize nextRefreshTime, lastUpdateTime, localWeatherTime;

+ (NSMutableDictionary*) preferences
{
	NSString* prefsPath = @"/var/mobile/Library/Preferences/com.ashman.WeatherIcon.plist";
	return [NSMutableDictionary dictionaryWithContentsOfFile:prefsPath];
}


- (void) _parsePreferences
{
	NSMutableDictionary* prefs = [WeatherIconModel preferences];
	if (prefs)
	{
		if (NSNumber* ol = [prefs objectForKey:@"OverrideLocation"])
			self.overrideLocation = [ol boolValue];
		NSLog(@"WI: Override Location: %d", self.overrideLocation);

		if (NSNumber* chill = [prefs objectForKey:@"ShowFeelsLike"])
			self.showFeelsLike = [chill boolValue];
		NSLog(@"WI: Show Feels Like: %d", self.showFeelsLike);

		if (self.overrideLocation)
		{
			if (NSString* loc = [prefs objectForKey:@"Location"])
			{
				if (![loc isEqualToString:self.location])
					self.timeZone = nil;
				self.location = [NSString stringWithString:loc];
			}

			if (NSNumber* celsius = [prefs objectForKey:@"Celsius"])
				self.isCelsius = [celsius boolValue];
		}
		else
		{
			[self _parseWeatherPreferences];
		}

		NSLog(@"WI: Location: %@", self.location);
		NSLog(@"WI: Celsius: %@", (self.isCelsius ? @"YES" : @"NO"));

		if (NSNumber* v = [prefs objectForKey:@"UseLocalTime"])
			self.useLocalTime = [v boolValue];
		NSLog(@"WI: Use Local Time: %d", self.useLocalTime);

		if (NSNumber* v = [prefs objectForKey:@"ShowStatusBarImage"])
			self.showStatusBarImage = [v boolValue];
		NSLog(@"WI: Show Status Bar Image: %d", self.showStatusBarImage);

		if (NSNumber* v = [prefs objectForKey:@"ShowStatusBarTemp"])
			self.showStatusBarTemp = [v boolValue];
		NSLog(@"WI: Show Status Bar Temp: %d", self.showStatusBarTemp);

		if (NSString* id = [prefs objectForKey:@"WeatherBundleIdentifier"])
			self.bundleIdentifier = [NSString stringWithString:id];
		NSLog(@"WI: Weather Bundle Identifier: %@", self.bundleIdentifier);

		if (NSNumber* interval = [prefs objectForKey:@"RefreshInterval"])
			self.refreshInterval = ([interval intValue] * 60);
		NSLog(@"WI: Refresh Interval: %d seconds", self.refreshInterval);

		if (NSNumber* d = [prefs objectForKey:@"Debug"])
		{
			self.debug = [d boolValue];
			NSLog(@"WI: Debug: %d", self.debug);
		}

		if (self.debug)
			self.refreshInterval = 1;
	}
	else
	{
		prefs = [NSMutableDictionary dictionaryWithCapacity:4];
		[prefs setValue:[NSNumber numberWithBool:self.overrideLocation] forKey:@"OverrideLocation"];
		[prefs setValue:self.location forKey:@"Location"];
		[prefs setValue:[NSNumber numberWithBool:self.isCelsius] forKey:@"Celsius"];
		[prefs setValue:[NSNumber numberWithBool:self.showFeelsLike] forKey:@"ShowFeelsLike"];
		[prefs setValue:[NSNumber numberWithBool:self.showStatusBarImage] forKey:@"ShowStatusBarImage"];
		[prefs setValue:[NSNumber numberWithBool:self.showStatusBarTemp] forKey:@"ShowStatusBarTemp"];
		[prefs setValue:[NSNumber numberWithBool:self.useLocalTime] forKey:@"UseLocalTime"];
		[prefs setValue:[NSNumber numberWithInt:(int)(self.refreshInterval / 60)] forKey:@"RefreshInterval"];
		[prefs setValue:@"com.apple.weather" forKey:@"WeatherBundleIdentifier"];

	        NSString* prefsPath = @"/var/mobile/Library/Preferences/com.ashman.WeatherIcon.plist";
		[prefs writeToFile:prefsPath atomically:YES];
	}
}

- (void) setNeedsRefresh
{
	NSLog(@"WI: Marking weather icon for refresh.");
	self.nextRefreshTime = [NSDate date];
}

- (void) _loadTheme
{
	NSBundle* bundle = [NSBundle mainBundle];
	NSString* themePrefs = [bundle pathForResource:@"com.ashman.WeatherIcon" ofType:@"plist"];
	if (themePrefs)
	{
		NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:themePrefs];
		if (dict)
		{
			NSLog(@"WI: Loading theme prefs: %@", themePrefs);

			// reset the temp style
			self.tempStyle = defaultTempStyle;

			if (NSString* style = [dict objectForKey:@"TempStyle"])
				self.tempStyle = [self.tempStyle stringByAppendingString:style];

			if (NSString* nstyle = [dict objectForKey:@"TempStyleNight"])
			        self.tempStyleNight = [self.tempStyle stringByAppendingString:nstyle];
			else
				self.tempStyleNight = self.tempStyle;

			if (NSNumber* scale = [dict objectForKey:@"StatusBarImageScale"])
				self.statusBarImageScale = [scale floatValue];

			if (NSNumber* scale = [dict objectForKey:@"ImageScale"])
				self.imageScale = [scale floatValue];

			if (NSNumber* top = [dict objectForKey:@"ImageMarginTop"])
				self.imageMarginTop = [top intValue];

			// get the mappings for the theme
			self.mappings = [dict objectForKey:@"Mappings"];
		}
	}	
}

- (void) _parseWeatherPreferences
{
	NSString* prefsPath = @"/var/mobile/Library/Preferences/com.apple.weather.plist";
	NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:prefsPath];

	if (dict)
	{
		NSLog(@"WI: Parsing weather preferences...");
		self.isCelsius = [[dict objectForKey:@"Celsius"] boolValue];

//		NSNumber* activeCity = [dict objectForKey:@"ActiveCity"];
		NSArray* cities = [dict objectForKey:@"Cities"];
		if (cities.count > 0)
		{
			NSDictionary* city = [cities objectAtIndex:0];
			NSString* zip = [[city objectForKey:@"Zip"] substringToIndex:8];

			if (![zip isEqualToString:self.location])
				self.timeZone = nil;

			self.location = zip;
		}	
	}
}

- (id) init
{
	self.temp = @"?";
	self.code = @"3200";
	self.tempStyle = defaultTempStyle;
	self.tempStyleNight = self.tempStyle;
	self.statusBarImageScale = 1.0;
	self.imageScale = 1.0;
	self.imageMarginTop = 0;
	self.isCelsius = false;
	self.overrideLocation = false;
	self.useLocalTime = false;
	self.showFeelsLike = false;
	self.showStatusBarImage = false;
	self.showStatusBarTemp = false;
	self.refreshInterval = 900;
	self.nextRefreshTime = [NSDate date];

	[self _parsePreferences];

	return self;
}

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
namespaceURI:(NSString *)namespaceURI
qualifiedName:(NSString *)qName
   attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"yweather:astronomy"])
	{
		self.sunrise = [NSString stringWithString:[attributeDict objectForKey:@"sunrise"]];
		self.sunset = [NSString stringWithString:[attributeDict objectForKey:@"sunset"]];
		NSLog(@"WI: Sunrise: %@", self.sunrise);
		NSLog(@"WI: Sunset: %@", self.sunset);
	}
	else if ([elementName isEqualToString:@"geo:lat"])
	{
		parserContent = [[NSMutableString alloc] init];
	}
	else if ([elementName isEqualToString:@"geo:long"])
	{
		parserContent = [[NSMutableString alloc] init];
	}
	else if ([elementName isEqualToString:@"offset"])
	{
		parserContent = [[NSMutableString alloc] init];
	}
	else if ([elementName isEqualToString:@"yweather:wind"])
	{
		self.windChill = [NSString stringWithString:[attributeDict objectForKey:@"chill"]];
		NSLog(@"WI: Wind Chill: %@", self.windChill);
	}
	else if ([elementName isEqualToString:@"yweather:condition"])
	{
		self.temp = [NSString stringWithString:[attributeDict objectForKey:@"temp"]];
		NSLog(@"WI: Temp: %@", self.temp);
		self.code = [NSString stringWithString:[attributeDict objectForKey:@"code"]];
		NSLog(@"WI: Code: %@", self.code);

		self.lastUpdateTime = [NSDate date];
		NSLog(@"WI: Last Update Time: %@", self.lastUpdateTime);

		if (self.useLocalTime)
		{
			self.localWeatherTime = self.lastUpdateTime;
		}
		else
		{
			NSString* weatherDate = [attributeDict objectForKey:@"date"];
			NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
			[df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
			[df setDateFormat:@"EEE, dd MMM yyyy hh:mm a"];
			self.localWeatherTime = [df dateFromString:weatherDate];
		}
		NSLog(@"WI: Local Weather Time: %@", self.localWeatherTime);
	}
}

- (void)parser:(NSXMLParser *)parser
didEndElement:(NSString *)elementName
namespaceURI:(NSString *)namespaceURI
qualifiedName:(NSString *)qName
{
	if ([elementName isEqualToString:@"geo:lat"])
	{
		self.latitude = parserContent;
		parserContent = nil;
		NSLog(@"WI: Latitude: %@", self.latitude);
	}
	else if ([elementName isEqualToString:@"geo:long"])
	{
		self.longitude = parserContent;
		parserContent = nil;
		NSLog(@"WI: Longitude: %@", self.longitude);
	}
	else if ([elementName isEqualToString:@"offset"])
	{
		int offset = [parserContent intValue];
		self.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:(offset * 3600)];
		NSLog(@"WI: Local time zone: %@", self.timeZone);
	}
}


- (void)parser:(NSXMLParser *)parser
foundCharacters:(NSString *)string
{   
	if (parserContent)
	{
//		NSLog(@"WI: Appending %@ to content.", string);
		[parserContent appendString:string];
	}
}

- (BOOL) showStatusBarWeather
{
	return (self.showStatusBarTemp || self.showStatusBarImage);
}

- (BOOL) isWeatherIcon:(SBIcon*) icon
{
	return [icon.displayIdentifier isEqualToString:self.bundleIdentifier];
}

- (void) refresh
{
	if (!self.weatherIcon)
		[self _updateWeatherIcon];

	NSDate* now = [NSDate date];
//	NSLog(@"WI: Checking refresh dates: %@ vs %@", now, self.nextRefreshTime);

	// are we ready for an update?
	if ([now compare:self.nextRefreshTime] == NSOrderedAscending && !self.debug)
	{
//		NSLog(@"WI: No refresh yet.");
		return;
	}

	[NSThread detachNewThreadSelector:@selector(_refreshInBackground) toTarget:self withObject:nil];
}

- (void) _refresh
{
	// reparse the preferences
	[self _parsePreferences];

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

	if (self.useLocalTime && !self.timeZone)
	{
		NSLog(@"WI: Refreshing time zone for %@...", self.location);
		urlStr = [NSString stringWithFormat:@"http://www.earthtools.org/timezone/%@/%@", self.latitude, self.longitude];
		url = [NSURL URLWithString:urlStr];
		parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
		[parser setDelegate:self];
		[parser parse];
		[parser release];
	}

//	NSLog(@"WI: Did the update succeed? %@ vs %@", self.lastUpdateTime, self.nextRefreshTime);
	if (!self.lastUpdateTime || [self.lastUpdateTime compare:self.nextRefreshTime] == NSOrderedAscending)
	{
		NSLog(@"WI: Update failed.");
		return;
	}

	if (!self.temp)
		self.temp = @"?";

	if (!self.code)
		self.code = @"3200";

	self.nextRefreshTime = [NSDate dateWithTimeIntervalSinceNow:self.refreshInterval];
	NSLog(@"WI: Next refresh time: %@", self.nextRefreshTime);

}

- (void) _refreshInBackground
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self _refresh];
	[pool release];

	// update the weather info
	[self performSelectorOnMainThread:@selector(_updateWeatherIcon) withObject:nil waitUntilDone:NO];
}

- (NSString*) mapImage:(NSString*) prefix
{
	// no mappings
	if (!self.mappings)
		return nil;

	NSString* suffix = (self.night ? @"_night" : @"_day");	
	if (NSString* mapped = [self.mappings objectForKey:[NSString stringWithFormat:@"%@%@%@", prefix, self.code, suffix]])
		return mapped;

	if (NSString* mapped = [self.mappings objectForKey:[NSString stringWithFormat:@"%@%@", prefix, suffix]])
		return mapped;

	if (NSString* mapped = [self.mappings objectForKey:[NSString stringWithFormat:@"%@%@", prefix, self.code]])
		return mapped;

	if (NSString* mapped = [self.mappings objectForKey:prefix])
		return mapped;

	return nil;
}

- (UIImage*) findImage:(NSBundle*) bundle name:(NSString*) name
{
	NSString* path = [bundle pathForResource:name ofType:@"png"];
	UIImage* image = (path ? [UIImage imageWithContentsOfFile:path] : nil);
	if (image)
	{
		NSLog(@"WI: Found %@ Image: %@", name, path);
		return image;
	}

	return nil;
}

- (UIImage*) findWeatherImage:(NSString*) prefix
{
	NSString* suffix = (self.night ? @"_night" : @"_day");	

	if (NSString* mapped = [self mapImage:prefix])
	{
		NSLog(@"Mapped %@%@%@ to %@", prefix, self.code, suffix, mapped);
		prefix = mapped;
	}

	NSLog(@"WI: Find image for %@%@%@", prefix, self.code, suffix);
        NSBundle* bundle = [NSBundle mainBundle];
	if (UIImage* img = [self findImage:bundle name:[NSString stringWithFormat:@"%@%@%@", prefix, self.code, suffix]])
		return img;

	if (UIImage* img = [self findImage:bundle name:[NSString stringWithFormat:@"%@%@", prefix, suffix]])
		return img;

	if (UIImage* img = [self findImage:bundle name:[NSString stringWithFormat:@"%@%@", prefix, self.code]])
		return img;

	if (UIImage* img = [self findImage:bundle name:prefix])
		return img;

	NSLog(@"WI: No image found for %@%@%@", prefix, self.code, suffix);
	return nil;
}

- (void) _updateWeatherIcon
{
	[self _loadTheme];

	// handle debug case
	self.night = (self.debug ? !self.night : false);
	if (!self.debug && self.localWeatherTime && self.sunrise && self.sunset)
	{
		NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
		[df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
		if (self.timeZone)
			[df setTimeZone:self.timeZone];
		[df setDateFormat:@"dd MMM yyyy hh:mm a"];

		NSString* date = [df stringFromDate:self.localWeatherTime];
		NSArray* dateParts = [date componentsSeparatedByString:@" "];

		NSString* sunriseFullDateStr = [NSString stringWithFormat:@"%@ %@ %@ %@",
			[dateParts objectAtIndex:0],
			[dateParts objectAtIndex:1],
			[dateParts objectAtIndex:2],
			self.sunrise];

		NSString* sunsetFullDateStr = [NSString stringWithFormat:@"%@ %@ %@ %@",
			[dateParts objectAtIndex:0],
			[dateParts objectAtIndex:1],
			[dateParts objectAtIndex:2],
			self.sunset];

//		NSLog(@"WI: Full Sunrise/Sunset:%@, %@", sunriseFullDateStr, sunsetFullDateStr);

		NSDate* weatherDate = self.localWeatherTime;
		NSDate* sunriseDate = [df dateFromString:sunriseFullDateStr];
		NSDate* sunsetDate = [df dateFromString:sunsetFullDateStr];
		NSLog(@"WI: Sunset/Sunrise:%@, %@", sunriseDate, sunsetDate);

		self.night = ([weatherDate compare:sunriseDate] == NSOrderedAscending ||
				[weatherDate compare:sunsetDate] == NSOrderedDescending);
	}
	NSLog(@"WI: Night? %d", self.night);

	UIImage* bgIcon = [self findWeatherImage:@"weatherbg"];
	UIImage* weatherImage = [self findWeatherImage:@"weather"];
	CGSize size = (bgIcon ? bgIcon.size : CGSizeMake(59, 60));

	UIGraphicsBeginImageContext(size);

	if (bgIcon)
	{
		[bgIcon drawAtPoint:CGPointMake(0, 0)];	
	}

	if (weatherImage)
	{
		float width = weatherImage.size.width * self.imageScale;
		float height = weatherImage.size.height * self.imageScale;
	        CGRect iconRect = CGRectMake((size.width - width) / 2, self.imageMarginTop, width, height);
		[weatherImage drawInRect:iconRect];
	}

//	NSLog(@"WI: Drawing Temperature");
	NSString* t =[(self.showFeelsLike ? self.windChill : self.temp) stringByAppendingString: @"\u00B0"];
	NSString* style = [NSString stringWithFormat:(self.night ? self.tempStyleNight : self.tempStyle), (int)size.width];
       	[t drawAtPoint:CGPointMake(0, 0) withStyle:style];

	self.weatherIcon = UIGraphicsGetImageFromCurrentImageContext();
	self.weatherImage = weatherImage;

	// save the status bar image
	self.statusBarImage = [self findWeatherImage:@"weatherstatus"];
	if (!self.statusBarImage)
		self.statusBarImage = weatherImage;

	UIGraphicsEndImageContext();

	SBStatusBarController* statusBarController = [$SBStatusBarController sharedStatusBarController];
	if (statusBarController)
	{
		NSLog(@"WI: Refreshing indicators...");
		[statusBarController removeStatusBarItem:@"WeatherIcon"];
		[statusBarController addStatusBarItem:@"WeatherIcon"];
	}

	SBIconController* iconController = [$SBIconController sharedInstance];
	if (iconController)
	{
		NSLog(@"WI: Refreshing icon...");
	        // now force the icon to refresh
	        SBIconModel* model(MSHookIvar<SBIconModel*>(iconController, "_iconModel"));
	        [model reloadIconImageForDisplayIdentifier:self.bundleIdentifier];

		// get the SBIconController and refresh the contentView
		[iconController.contentView setNeedsDisplay];

		// refresh all of the subviews to get the reflection right
		SBIcon* applicationIcon = [model iconForDisplayIdentifier:self.bundleIdentifier];
		if (applicationIcon)
		{
			NSArray* views = [applicationIcon subviews];
			for (int i = 0; i < views.count; i++)
				[[views objectAtIndex:i] setNeedsDisplay];
		}
	}
}

- (UIImage*) icon
{
	return self.weatherIcon;
}

- (void) dealloc
{
	[self.temp release];
	[self.tempStyle release];
	[self.code release];
	[self.location release];
	[self.lastUpdateTime release];
	[self.nextRefreshTime release];
	[super dealloc];
}
@end
