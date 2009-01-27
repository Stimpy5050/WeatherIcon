/*
 *  WeatherView.mm
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
#import <Foundation/NSObjCRuntime.h>

@implementation WeatherView

@synthesize applicationIcon, highlighted;
@synthesize temp, windChill, code, night, tempStyle, imageScale, imageMarginTop;
@synthesize bgIcon, weatherIcon;
@synthesize isCelsius, overrideLocation, showFeelsLike, location, refreshInterval;
@synthesize nextRefreshTime, lastUpdateTime;

+ (NSMutableDictionary*) preferences
{
	NSString* prefsPath = @"/var/mobile/Library/Preferences/com.ashman.WeatherIcon.plist";
	return [NSMutableDictionary dictionaryWithContentsOfFile:prefsPath];
}

- (void) _parsePreferences
{
	NSMutableDictionary* prefs = [WeatherView preferences];
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

	        NSString* prefsPath = @"/var/mobile/Library/Preferences/com.ashman.WeatherIcon.plist";
		[prefs writeToFile:prefsPath atomically:YES];
	}

	NSBundle* bundle = [NSBundle mainBundle];
	NSString* themePrefs = [bundle pathForResource:@"com.ashman.WeatherIcon" ofType:@"plist"];
	if (themePrefs)
	{
		NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:themePrefs];
		if (dict)
		{
			if (NSString* style = [dict objectForKey:@"TempStyle"])
			{
        			NSString* defaultTempStyle(@""
			                "font-family: Helvetica; "
			                "font-weight: bold; "
			                "font-size: 13px; "
			                "color: white; "
			                "margin-top: 38px; "
			                "margin-left: 3px; "
			                "width: %dpx; "
			                "text-align: center; "
			                "text-shadow: rgba(0, 0, 0, 0.2) -1px -1px 1px; "
			        "");

				self.tempStyle = [NSString stringWithFormat:defaultTempStyle, (int)self.frame.size.width];

			        if (style && [style length] > 0)
			                self.tempStyle = [self.tempStyle stringByAppendingString:style];
			}

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
		NSDictionary* city = [cities objectAtIndex:0];
		self.location = [[city objectForKey:@"Zip"] substringToIndex:8];
	}
}

- (id) initWithIcon:(SBIcon*)icon
{
        CGRect rect = CGRectMake(0, -1, icon.frame.size.width, icon.frame.size.height);
        id ret = [self initWithFrame:rect];

	self.applicationIcon = icon;
	self.temp = @"?";
	self.code = @"3200";
	self.night = false;
	self.imageScale = 1.0;
	self.imageMarginTop = 0;
	self.isCelsius = false;
	self.overrideLocation = false;
	self.showFeelsLike = false;
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
	if ([elementName isEqualToString:@"yweather:astronomy"])
	{
		NSString* sunrise = [NSString stringWithString:[attributeDict objectForKey:@"sunrise"]];
		NSString* sunset = [NSString stringWithString:[attributeDict objectForKey:@"sunset"]];

		if (sunrise && sunset)
		{
			NSDate* now = [NSDate date];

			NSDateFormatter* format = [[[NSDateFormatter alloc] init] autorelease];
			[format setDateFormat:@"MM/dd/yyyy "];
			NSString* today = [format stringFromDate:now];

			[format setDateFormat:@"MM/dd/yyyy hh:mm a"];
			NSDate* sunriseDate = [format dateFromString:[today stringByAppendingString:sunrise]];
			NSDate* sunsetDate = [format dateFromString:[today stringByAppendingString:sunset]];
		
			self.night = ([sunriseDate compare:now] == NSOrderedDescending || [sunsetDate compare:now] == NSOrderedAscending);
			NSLog(@"WI: Dates: %@ to %@, Night? %d", sunriseDate, sunsetDate, self.night);
		}
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

	self.nextRefreshTime = [NSDate dateWithTimeIntervalSinceNow:self.refreshInterval];
	NSLog(@"WI: Next refresh time: %@", self.nextRefreshTime);

	[self performSelectorOnMainThread:@selector(updateImage) withObject:nil waitUntilDone:NO];

	[pool release];
}

- (void) updateImage
{
        NSBundle* sb = [NSBundle mainBundle];

	if (self.night)
	{
		// if it's night, always try the night icon first
	        NSString* bgPath = [sb pathForResource:@"weatherbg_night" ofType:@"png"];
	        self.bgIcon = (bgPath ? [UIImage imageWithContentsOfFile:bgPath] : nil);
	}

	if (!self.bgIcon)
	{
		// next try the code-specific one
 		NSString* bgName = [@"weatherbg" stringByAppendingString:self.code];
		NSString* bgPath = [sb pathForResource:bgName ofType:@"png"];
		self.bgIcon = (bgPath ? [UIImage imageWithContentsOfFile:bgPath] : nil);
	}

	if (!self.bgIcon)
	{
		// no code specific icon, so look for day
	        NSString* bgPath = [sb pathForResource:@"weatherbg_day" ofType:@"png"];
	        self.bgIcon = (bgPath ? [UIImage imageWithContentsOfFile:bgPath] : nil);
	}

        NSString* iconName = [@"weather" stringByAppendingString:self.code];
        NSString* iconPath = [sb pathForResource:iconName ofType:@"png"];
        self.weatherIcon = (iconPath ? [UIImage imageWithContentsOfFile:iconPath] : nil);

	[self.applicationIcon setNeedsDisplay];
	[self setNeedsDisplay];
}

- (void) drawRect:(CGRect) rect
{
	UIGraphicsBeginImageContext(self.frame.size);

	if (self.bgIcon)
		[self.bgIcon drawAtPoint:CGPointMake(0, 0)];	

	if (self.weatherIcon)
	{
		float width = self.weatherIcon.size.width * self.imageScale;
		float height = self.weatherIcon.size.height * self.imageScale;
               	CGRect iconRect = CGRectMake((self.frame.size.width - width) / 2, self.imageMarginTop, width, height);
	        [self.weatherIcon drawInRect:iconRect];
        }

	NSString* t =[(self.showFeelsLike ? self.windChill : self.temp) stringByAppendingString: @"\u00B0"];
        [t drawAtPoint:CGPointMake(0, 0) withStyle:self.tempStyle];

	UIImage* weather = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	if (self.highlighted)
	{
		NSLog(@"WI: Rendering highlight.");
		CGRect darkRect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
		UIGraphicsBeginImageContext(darkRect.size);
		CGContextRef ctx = UIGraphicsGetCurrentContext();
		[weather drawInRect:darkRect];
		CGContextSetFillColorWithColor(ctx, [[UIColor blackColor] CGColor]);
		CGContextSetBlendMode(ctx, kCGBlendModeSourceIn);
		CGContextFillRect(ctx, darkRect);
		UIImage* blackLayer = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
	        [blackLayer drawAtPoint:darkRect.origin];
		[weather drawAtPoint:CGPointMake(0, 0) blendMode:kCGBlendModeNormal alpha:0.60];
	}
	else
		[weather drawAtPoint:CGPointMake(0, 0)];
}

- (void) dealloc
{
	[self.applicationIcon release];
	[self.temp release];
	[self.tempStyle release];
	[self.code release];
	[self.location release];
	[self.lastUpdateTime release];
	[self.nextRefreshTime release];
	[super dealloc];
}
@end
