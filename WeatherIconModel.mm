/*
 *  WeatherView.mm
 *  
 *
 *  Created by David Ashman on 1/12/09.
 *  Copyright 2009 David Ashman. All rights reserved.
 *
 */

#import "WeatherIconModel.h"
#import <substrate.h>
#import <SpringBoard/SBIconModel.h>
#import <SpringBoard/SBIconController.h>
#import <SpringBoard/SBApplicationIcon.h>
#import <SpringBoard/SleepProofTimer.h>
#import <UIKit/UIStringDrawing.h>
#import <UIKit/UIKit.h>
#import <Foundation/NSObjCRuntime.h>

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

static NSMutableDictionary* kweatherMapping;

static void initKweatherMapping()
{
	if (kweatherMapping)
		return;

	kweatherMapping = [[NSMutableDictionary alloc] initWithCapacity:50];
	[kweatherMapping setValue:@"tstorm3" forKey:@"0"];
	[kweatherMapping setValue:@"tstorm3" forKey:@"1"];
	[kweatherMapping setValue:@"tstorm3" forKey:@"2"];
	[kweatherMapping setValue:@"tstorm3" forKey:@"3"];
	[kweatherMapping setValue:@"tstorm2" forKey:@"4"];
	[kweatherMapping setValue:@"sleet" forKey:@"5"];
	[kweatherMapping setValue:@"sleet" forKey:@"6"];
	[kweatherMapping setValue:@"sleet" forKey:@"7"];
	[kweatherMapping setValue:@"hail" forKey:@"8"];
	[kweatherMapping setValue:@"light_rain" forKey:@"9"];
	[kweatherMapping setValue:@"hail" forKey:@"10"];
	[kweatherMapping setValue:@"shower2" forKey:@"11"];
	[kweatherMapping setValue:@"shower2" forKey:@"12"];
	[kweatherMapping setValue:@"snow1" forKey:@"13"];
	[kweatherMapping setValue:@"snow2" forKey:@"14"];
	[kweatherMapping setValue:@"snow3" forKey:@"15"];
	[kweatherMapping setValue:@"snow4" forKey:@"16"];
	[kweatherMapping setValue:@"hail" forKey:@"17"];
	[kweatherMapping setValue:@"sleet" forKey:@"18"];
	[kweatherMapping setValue:@"mist" forKey:@"19"];
	[kweatherMapping setValue:@"fog" forKey:@"20"];
	[kweatherMapping setValue:@"mist" forKey:@"21"];
	[kweatherMapping setValue:@"fog" forKey:@"22"];
	[kweatherMapping setValue:@"sunny" forKey:@"23"];
	[kweatherMapping setValue:@"fog" forKey:@"24"];
	[kweatherMapping setValue:@"cloudy5" forKey:@"25"];
	[kweatherMapping setValue:@"cloudy5" forKey:@"26"];
	[kweatherMapping setValue:@"cloudy4" forKey:@"27"];
	[kweatherMapping setValue:@"cloudy4" forKey:@"28"];
	[kweatherMapping setValue:@"cloudy2" forKey:@"29"];
	[kweatherMapping setValue:@"cloudy2" forKey:@"30"];
	[kweatherMapping setValue:@"sunny" forKey:@"31"];
	[kweatherMapping setValue:@"sunny" forKey:@"32"];
	[kweatherMapping setValue:@"cloudy1" forKey:@"33"];
	[kweatherMapping setValue:@"cloudy1" forKey:@"34"];
	[kweatherMapping setValue:@"hail" forKey:@"35"];
	[kweatherMapping setValue:@"sunny" forKey:@"36"];
	[kweatherMapping setValue:@"tstorm1" forKey:@"37"];
	[kweatherMapping setValue:@"tstorm2" forKey:@"38"];
	[kweatherMapping setValue:@"tstorm2" forKey:@"39"];
	[kweatherMapping setValue:@"shower1" forKey:@"40"];
	[kweatherMapping setValue:@"snow5" forKey:@"41"];
	[kweatherMapping setValue:@"snow3" forKey:@"42"];
	[kweatherMapping setValue:@"snow5" forKey:@"43"];
	[kweatherMapping setValue:@"cloudy2" forKey:@"44"];
	[kweatherMapping setValue:@"tstorm2" forKey:@"45"];
	[kweatherMapping setValue:@"snow3" forKey:@"46"];
	[kweatherMapping setValue:@"tstorm1" forKey:@"47"];
	[kweatherMapping setValue:@"dunno" forKey:@"3200"];
}

@implementation WeatherIconModel

@synthesize temp, windChill, code, tempStyle, tempStyleNight, imageScale, imageMarginTop, type;
@synthesize latitude, longitude, localWeatherTime;
@synthesize sunset, sunrise, night;
@synthesize weatherIcon;
@synthesize isCelsius, useLocalTime, overrideLocation, showFeelsLike, location, refreshInterval, bundleIdentifier, debug;
@synthesize nextRefreshTime, lastUpdateTime;

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
				self.location = [NSString stringWithString:loc];

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
		[prefs setValue:[NSNumber numberWithInt:(int)(self.refreshInterval / 60)] forKey:@"RefreshInterval"];
		[prefs setValue:@"com.apple.weather" forKey:@"WeatherBundleIdentifier"];

	        NSString* prefsPath = @"/var/mobile/Library/Preferences/com.ashman.WeatherIcon.plist";
		[prefs writeToFile:prefsPath atomically:YES];
	}
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

			if (NSString* type = [dict objectForKey:@"Type"])
			{
				self.type = [NSString stringWithString:type];
				initKweatherMapping();
			}
	
			// reset the temp style
			self.tempStyle = defaultTempStyle;

			if (NSString* style = [dict objectForKey:@"TempStyle"])
				self.tempStyle = [self.tempStyle stringByAppendingString:style];

			if (NSString* nstyle = [dict objectForKey:@"TempStyleNight"])
			        self.tempStyleNight = [self.tempStyle stringByAppendingString:nstyle];
			else
				self.tempStyleNight = self.tempStyle;

			if (NSNumber* scale = [dict objectForKey:@"ImageScale"])
				self.imageScale = [scale floatValue];

			if (NSNumber* top = [dict objectForKey:@"ImageMarginTop"])
				self.imageMarginTop = [top intValue];
		}
	}	
}

- (void) _parseWeatherPreferences
{
	NSString* prefsPath = @"/var/mobile/Library/Preferences/com.apple.weather.plist";
	NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:prefsPath];

	if (dict)
	{
		self.isCelsius = [[dict objectForKey:@"Celsius"] boolValue];

//		NSNumber* activeCity = [dict objectForKey:@"ActiveCity"];
		NSArray* cities = [dict objectForKey:@"Cities"];
		if (cities.count > 0)
		{
			NSDictionary* city = [cities objectAtIndex:0];
			self.location = [[city objectForKey:@"Zip"] substringToIndex:8];
		}	
	}
}

- (id) init
{
	self.temp = @"?";
	self.code = @"3200";
	self.tempStyle = defaultTempStyle;
	self.tempStyleNight = self.tempStyle;
	self.imageScale = 1.0;
	self.imageMarginTop = 0;
	self.isCelsius = false;
	self.useLocalTime = false;
	self.overrideLocation = false;
	self.showFeelsLike = false;
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
	else if ([elementName isEqualToString:@"localtime"])
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

		
		NSString* weatherDate = [attributeDict objectForKey:@"date"];
		NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
		[df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
		[df setDateFormat:@"EEE, dd MMM yyyy hh:mm a"];
		self.localWeatherTime = [df dateFromString:weatherDate];
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
	else if ([elementName isEqualToString:@"localtime"])
	{
		NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
		[df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
		[df setDateFormat:@"dd MMM yyyy HH:mm:ss"];
		self.localWeatherTime = [df dateFromString:parserContent];
		[parserContent release];
		parserContent = nil;
		NSLog(@"WI: Local Weather Time: %@", self.localWeatherTime);
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

- (BOOL) isWeatherIcon:(SBIcon*) icon
{
	return [icon.displayIdentifier isEqualToString:self.bundleIdentifier];
}

- (void) refresh:(SBIconController*) controller
{
	if (!self.weatherIcon)
		[self _updateWeatherIcon:controller];

	NSDate* now = [NSDate date];
//	NSLog(@"WI: Checking refresh dates: %@ vs %@", now, self.nextRefreshTime);

	// are we ready for an update?
	if ([now compare:self.nextRefreshTime] == NSOrderedAscending && !self.debug)
	{
//		NSLog(@"WI: No refresh yet.");
		return;
	}

	[NSThread detachNewThreadSelector:@selector(_refreshInBackground:) toTarget:self withObject:controller];
}

- (void) _refresh
{
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

	if (self.useLocalTime)
	{
		NSLog(@"WI: Checking local time for %@...", self.location);
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

- (void) _refreshInBackground:(SBIconController*) controller
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self _refresh];
	[pool release];

	// update the weather info
	[self performSelectorOnMainThread:@selector(_updateWeatherIcon:) withObject:controller waitUntilDone:NO];
}

- (UIImage*) findWeatherImage:(NSBundle*) bundle prefix:(NSString*) prefix code:(NSString*) code suffix:(NSString*) suffix
{
	NSString* name = [[prefix stringByAppendingString:code] stringByAppendingString:suffix];
	NSString* path = [bundle pathForResource:name ofType:@"png"];
	UIImage* image = (path ? [UIImage imageWithContentsOfFile:path] : nil);
	if (image)
	{
		NSLog(@"WI: Found %@ Image: %@", prefix, path);
		return image;
	}

	return nil;
}

- (UIImage*) findWeatherImage:(BOOL) background
{
	NSString* blank = @"";
	NSString* prefix = (background ? @"weatherbg" : @"weather");
	NSString* code = self.code;

	if (!background && [self.type isEqualToString:@"kweather"])
	{
		code = [kweatherMapping objectForKey:self.code];
		NSLog(@"WI: Mapping %@ to %@", self.code, code);
		prefix = blank;
	}

	NSLog(@"WI: Find image for %@", code);
        NSBundle* bundle = [NSBundle mainBundle];
	NSString* suffix = (self.night ? @"_night" : @"_day");	

	if (UIImage* img = [self findWeatherImage:bundle prefix:prefix code:code suffix:suffix])
		return img;

	if (UIImage* img = [self findWeatherImage:bundle prefix:prefix code:blank suffix:suffix])
		return img;

	if (UIImage* img = [self findWeatherImage:bundle prefix:prefix code:code suffix:blank])
		return img;

	if (UIImage* img = [self findWeatherImage:bundle prefix:prefix code:blank suffix:blank])
		return img;

	return nil;
}

- (void) _updateWeatherIcon:(SBIconController*) controller
{
	// handle debug case
	self.night = (self.debug ? !self.night : false);
	if (!self.debug && self.localWeatherTime && self.sunrise && self.sunset)
	{
		NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
		[df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
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

	// parse the theme settings
	[self _loadTheme];

	UIImage* bgIcon = [self findWeatherImage:YES];
	UIImage* weatherImage = [self findWeatherImage:NO];
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
	UIGraphicsEndImageContext();

	if (controller)
	{
	        // now force the icon to refresh
	        SBIconModel* model(MSHookIvar<SBIconModel*>(controller, "_iconModel"));
	        [model reloadIconImageForDisplayIdentifier:self.bundleIdentifier];

		// get the SBIconController and refresh the contentView
		[controller.contentView setNeedsDisplay];

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
