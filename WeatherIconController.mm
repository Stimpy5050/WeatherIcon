/*
 *  WeatherView.mm
 *  
 *
 *  Created by David Ashman on 1/12/09.
 *  Copyright 2009 David Ashman. All rights reserved.
 *
 */

#import "WeatherIconController.h"
#import "substrate.h"
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>
#import <SpringBoard/SBImageCache.h>
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

static NSString* prefsPath = @"/var/mobile/Library/Preferences/com.ashman.WeatherIcon.plist";
static NSString* conditionPath = @"/var/mobile/Library/Preferences/com.ashman.WeatherIcon.Condition.plist";
static NSString* defaultStatusBarTempStyleFSO(@""
	"font-family: Helvetica; "
	"font-weight: bold; "
	"font-size: 14px; "
	"color: #efefef; "
	"height: 20px;"
"");
//static NSString* defaultStatusBarTempStyleFST = defaultStatusBarTempStyleFSO;
static NSString* defaultStatusBarTempStyle(@""
	"font-family: Helvetica; "
	"font-weight: bold; "
	"font-size: 14px; "
	"color: #1111111; "
	"text-shadow: rgba(255, 255, 255, 0.6) 0px 1px 0px; "
	"height: 20px;"
"");
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
static NSString* defaultTemp = @"?";
static NSString* defaultCode = @"3200";

static NSArray* dayCodes = [[NSArray alloc] initWithObjects:@"SUN", @"MON", @"TUE", @"WED", @"THU", @"FRI", @"SAT", nil];

static WeatherIconController* instance = nil;

@implementation WeatherIconController

+ (WeatherIconController*) sharedInstance
{
	@synchronized(self)
	{
		if (instance == nil)
		{
			NSLog(@"WI:Debug: Creating controller instance");
			[[self alloc] init];
		}
	}

	NSLog(@"WI:Debug: Returning %@", instance);
	return instance;	
}

+ (id) allocWithZone:(NSZone*) zone
{
	@synchronized(self)
	{
		if (instance == nil)
		{
			NSLog(@"WI:Debug: Allocating new instance.");
			instance = [super allocWithZone:zone];
			return instance;
		}
	}

	return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (unsigned)retainCount

{
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

- (NSString*) bundleIdentifier
{
	return bundleIdentifier;
}

- (NSDate*) lastUpdateTime
{
	return lastUpdateTime;
}

- (BOOL) needsRefresh
{
        NSDate* now = [NSDate date];

        // are we ready for an update?
        if ([now compare:nextRefreshTime] == NSOrderedAscending)
	{
		if (debug)
			NSLog(@"WI:Debug: %@ is before %@", now, nextRefreshTime);
                return false;
	}

	if (debug)
		NSLog(@"WI:Debug: Are we already refreshing? %d", refreshing);

	return !refreshing;
}

- (void) releaseTempInfo
{
/*
	[temp release];
	temp = nil;

	[code release];
	code = nil;
*/
	[sunrise release];
	sunrise = nil;

	[sunset release];
	sunset = nil;

	[latitude release];
	latitude = nil;

	[longitude release];
	longitude = nil;

	[timeZone release];
	timeZone = nil;

	[localWeatherTime release];
	localWeatherTime = nil;
}

- (void) parseWeatherPreferences
{
	if (weatherPrefsLoaded)
		return;

	NSString* weatherPrefsPath = @"/var/mobile/Library/Preferences/com.apple.weather.plist";
	NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:weatherPrefsPath];

	if (dict)
	{
		NSLog(@"WI: Parsing weather preferences...");
		isCelsius = [[dict objectForKey:@"Celsius"] boolValue];

//		NSNumber* activeCity = [dict objectForKey:@"ActiveCity"];
		NSArray* cities = [dict objectForKey:@"Cities"];
		if (cities.count > 0)
		{
			NSDictionary* city = [cities objectAtIndex:0];
			NSString* zip = [[city objectForKey:@"Zip"] substringToIndex:8];

			if (![zip isEqualToString:location])
			{
				NSString* tmp = timeZone;
				timeZone = nil;
				[tmp release];
			}

			NSString* tmp = location;
			location = [zip retain];
			[tmp release];
		}	
	}

	weatherPrefsLoaded = true;
}

- (void) parsePreferences
{
	if (prefsLoaded)
		return;

	NSMutableDictionary* prefs = [NSMutableDictionary dictionaryWithContentsOfFile:prefsPath];
	if (prefs)
	{
		NSDictionary* tmpPrefs = currentPrefs;
		currentPrefs = [prefs retain];
		[tmpPrefs release];

		NSDictionary* tmpCondition = currentCondition;
		currentCondition = [[NSMutableDictionary dictionaryWithContentsOfFile:conditionPath] retain];
		[tmpCondition release];

		if (currentCondition == nil)
			currentCondition = [[NSMutableDictionary dictionaryWithCapacity:5] retain];


		if (NSNumber* ol = [prefs objectForKey:@"OverrideLocation"])
			overrideLocation = [ol boolValue];
		NSLog(@"WI: Override Location: %d", overrideLocation);

		if (NSNumber* chill = [prefs objectForKey:@"ShowFeelsLike"])
			showFeelsLike = [chill boolValue];
		NSLog(@"WI: Show Feels Like: %d", showFeelsLike);

		if (overrideLocation)
		{
			if (NSString* loc = [prefs objectForKey:@"Location"])
			{
				if (![loc isEqualToString:location])
				{
					NSString* tmpTZ = timeZone;
					timeZone = nil;
					[tmpTZ release];
				}

				NSString* tmpLoc = location;
				location = [[NSString stringWithString:loc] retain];
				[tmpLoc release];
			}

			if (NSNumber* celsius = [prefs objectForKey:@"Celsius"])
				isCelsius = [celsius boolValue];
		}
		else
		{
			[self parseWeatherPreferences];
		}

		NSLog(@"WI: Location: %@", location);
		NSLog(@"WI: Celsius: %d", isCelsius);

		if (NSNumber* v = [prefs objectForKey:@"UseLocalTime"])
			useLocalTime = [v boolValue];
		NSLog(@"WI: Use Local Time: %d", useLocalTime);

		if (NSNumber* v = [prefs objectForKey:@"ShowWeatherIcon"])
			showWeatherIcon = [v boolValue];
		NSLog(@"WI: Show Weather Icon: %d", showWeatherIcon);

		if (NSNumber* v = [prefs objectForKey:@"ShowStatusBarImage"])
			showStatusBarImage = [v boolValue];
		NSLog(@"WI: Show Status Bar Image: %d", showStatusBarImage);

		if (NSNumber* v = [prefs objectForKey:@"ShowStatusBarTemp"])
			showStatusBarTemp = [v boolValue];
		NSLog(@"WI: Show Status Bar Temp: %d", showStatusBarTemp);

		if (NSString* id = [prefs objectForKey:@"WeatherBundleIdentifier"])
		{
			if ([id isEqualToString:@"Custom"])
			{
				if (NSString* custom = [prefs objectForKey:@"CustomWeatherBundleIdentifier"])
				{
					NSString* tmp = bundleIdentifier;
					bundleIdentifier = [custom retain];
					[tmp release];
				}
			}
			else
			{
				NSString* tmp = bundleIdentifier;
				bundleIdentifier = [id retain];
				[tmp release];
			}
		}
		NSLog(@"WI: Weather Bundle Identifier: %@", bundleIdentifier);

		if (NSNumber* interval = [prefs objectForKey:@"RefreshInterval"])
			refreshInterval = ([interval intValue] * 60);
		NSLog(@"WI: Refresh Interval: %d seconds", refreshInterval);

		if (NSNumber* d = [prefs objectForKey:@"Debug"])
		{
			debug = [d boolValue];
			NSLog(@"WI: Debug: %d", debug);
		}
	}
	else
	{
		prefs = [NSMutableDictionary dictionaryWithCapacity:10];
		[prefs setValue:[NSNumber numberWithBool:overrideLocation] forKey:@"OverrideLocation"];
		[prefs setValue:location forKey:@"Location"];
		[prefs setValue:[NSNumber numberWithBool:isCelsius] forKey:@"Celsius"];
		[prefs setValue:[NSNumber numberWithBool:showFeelsLike] forKey:@"ShowFeelsLike"];
		[prefs setValue:[NSNumber numberWithBool:showWeatherIcon] forKey:@"ShowWeatherIcon"];
		[prefs setValue:[NSNumber numberWithBool:showStatusBarImage] forKey:@"ShowStatusBarImage"];
		[prefs setValue:[NSNumber numberWithBool:showStatusBarTemp] forKey:@"ShowStatusBarTemp"];
		[prefs setValue:[NSNumber numberWithBool:useLocalTime] forKey:@"UseLocalTime"];
		[prefs setValue:[NSNumber numberWithInt:(int)(refreshInterval / 60)] forKey:@"RefreshInterval"];
		[prefs setValue:@"com.apple.weather" forKey:@"WeatherBundleIdentifier"];

		[prefs writeToFile:prefsPath atomically:YES];
	}

	prefsLoaded = true;
}

- (void) loadTheme
{
	if (themeLoaded)
		return;

	NSBundle* bundle = [NSBundle mainBundle];
	NSString* themePrefs = [bundle pathForResource:@"com.ashman.WeatherIcon" ofType:@"plist"];
	if (themePrefs)
	{
		NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:themePrefs];
		if (dict)
		{
			NSLog(@"WI: Loading theme prefs: %@", themePrefs);

			// reset the temp style
			NSString* tmp = tempStyle;
			if (NSString* style = [dict objectForKey:@"TempStyle"])
				tempStyle = [[defaultTempStyle stringByAppendingString:style] retain];
			else
				tempStyle = [defaultTempStyle retain];
			[tmp release];

			tmp = tempStyleNight;
			if (NSString* nstyle = [dict objectForKey:@"TempStyleNight"])
			        tempStyleNight = [[tempStyle stringByAppendingString:nstyle] retain];
			else
				tempStyleNight = [tempStyle retain];
			[tmp release];

			tmp = statusBarTempStyle;
			if (NSString* style = [dict objectForKey:@"StatusBarTempStyle"])
				statusBarTempStyle = [[defaultStatusBarTempStyle stringByAppendingString:style] retain];
			else
				statusBarTempStyle = [defaultStatusBarTempStyle retain];
			[tmp release];

			tmp = statusBarTempStyleFSO;
			if (NSString* nstyle = [dict objectForKey:@"StatusBarTempStyleFSO"])
			        statusBarTempStyleFSO = [[defaultStatusBarTempStyleFSO stringByAppendingString:nstyle] retain];
			else
				statusBarTempStyleFSO = [defaultStatusBarTempStyleFSO retain];
			[tmp release];

			if (NSNumber* scale = [dict objectForKey:@"StatusBarImageScale"])
				statusBarImageScale = [scale floatValue];

			if (NSNumber* scale = [dict objectForKey:@"ImageScale"])
				imageScale = [scale floatValue];

			if (NSNumber* top = [dict objectForKey:@"ImageMarginTop"])
				imageMarginTop = [top intValue];
			NSLog(@"WI: Image Margin Top: %d", imageMarginTop);

			if (NSNumber* v = [dict objectForKey:@"ShowWeatherIcon"])
				showWeatherIcon = [v boolValue];
			NSLog(@"WI: Show Weather Icon: %d", showWeatherIcon);
	
			if (NSNumber* v = [dict objectForKey:@"ShowStatusBarImage"])
				showStatusBarImage = [v boolValue];
			NSLog(@"WI: Show Status Bar Image: %d", showStatusBarImage);
	
			if (NSNumber* v = [dict objectForKey:@"ShowStatusBarTemp"])
				showStatusBarTemp = [v boolValue];
			NSLog(@"WI: Show Status Bar Temp: %d", showStatusBarTemp);
	
			// get the mappings for the theme
			NSDictionary* tmpMappings = mappings;
			mappings = [[dict objectForKey:@"Mappings"] retain];
			[tmpMappings release];
		}
	}	

	themeLoaded = true;
}

- (id) init
{
	yahooRSS = false;
	tempStyle = [defaultTempStyle retain];
	tempStyleNight = [tempStyle retain];
	statusBarTempStyle = [defaultStatusBarTempStyle retain];
	statusBarTempStyleFSO = [defaultStatusBarTempStyleFSO retain];
	statusBarImageScale = 1.0;
	imageScale = 1.0;
	imageMarginTop = 0;
	isCelsius = false;
	overrideLocation = false;
	useLocalTime = false;
	showFeelsLike = false;
	showWeatherIcon = true;
	showStatusBarImage = false;
	showStatusBarTemp = false;
	refreshInterval = 900;
	failedCount = 0;

	temp = [defaultTemp retain];
	code = [defaultCode retain];
	nextRefreshTime = [[NSDate date] retain];
	refreshing = false;

	[self parsePreferences];

	return self;
}

- (NSString*) mapImage:(NSString*) prefix
{
	// no mappings
	if (!mappings)
		return nil;

	NSString* suffix = (night ? @"_night" : @"_day");	
	if (NSString* mapped = [mappings objectForKey:[NSString stringWithFormat:@"%@%@%@", prefix, code, suffix]])
		return mapped;

	if (NSString* mapped = [mappings objectForKey:[NSString stringWithFormat:@"%@%@", prefix, code]])
		return mapped;

	if (NSString* mapped = [mappings objectForKey:[NSString stringWithFormat:@"%@%@", prefix, suffix]])
		return mapped;

	if (NSString* mapped = [mappings objectForKey:prefix])
		return mapped;

	return nil;
}

- (NSString*) findImage:(NSBundle*) bundle name:(NSString*) name
{
	NSString* path = [bundle pathForResource:name ofType:@"png"];
	if (path)
	{
		if (debug)
			NSLog(@"WI:Debug: Found %@ Image: %@", name, path);

		return path;
	}

	return nil;
}

- (NSString*) findWeatherImagePath:(NSString*) prefix code:(NSString*) code night:(BOOL) night
{
	NSString* suffix = (night ? @"_night" : @"_day");	

	if (NSString* mapped = [self mapImage:prefix])
	{
		if (debug)
			NSLog(@"WI:Debug: Mapped %@%@%@ to %@", prefix, code, suffix, mapped);
		prefix = mapped;
	}

	if (debug)
		NSLog(@"WI:Debug: Find image for %@%@%@", prefix, code, suffix);

        NSBundle* bundle = [NSBundle mainBundle];
	if (NSString* img = [self findImage:bundle name:[NSString stringWithFormat:@"%@%@%@", prefix, code, suffix]])
		return img;

	if (NSString* img = [self findImage:bundle name:[NSString stringWithFormat:@"%@%@", prefix, code]])
		return img;

	if (NSString* img = [self findImage:bundle name:[NSString stringWithFormat:@"%@%@", prefix, suffix]])
		return img;

	if (NSString* img = [self findImage:bundle name:prefix])
		return img;

	if (debug)
		NSLog(@"WI:Debug: No image found for %@%@%@", prefix, code, suffix);

	return nil;
}

- (NSString*) findWeatherImagePath:(NSString*) prefix
{
	return [self findWeatherImagePath:prefix code:code night:night];
}

- (UIImage*) findWeatherImage:(NSString*) prefix
{
	NSString* path = [self findWeatherImagePath:prefix];
	return (path ? [UIImage imageWithContentsOfFile:path] : nil);
}

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
namespaceURI:(NSString *)namespaceURI
qualifiedName:(NSString *)qName
   attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"yweather:astronomy"] || [elementName isEqualToString:@"astronomy"])
	{
		NSString* tmpSunrise = sunrise;
		NSString* tmpSunset = sunset;

		sunrise = [[attributeDict objectForKey:@"sunrise"] retain];
		sunset = [[attributeDict objectForKey:@"sunset"] retain];

		[tmpSunrise release];
		[tmpSunset release];

		NSLog(@"WI: Sunrise: %@", sunrise);
		NSLog(@"WI: Sunset: %@", sunset);
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
	else if ([elementName isEqualToString:@"result"])
	{
		if (useLocalTime)
		{
			NSDate* tmp = localWeatherTime;
			double timestamp = [[attributeDict objectForKey:@"timestamp"] doubleValue];
			localWeatherTime = [[NSDate dateWithTimeIntervalSince1970:timestamp] retain];
			[tmp release];
		}
	}
	else if (showFeelsLike && ([elementName isEqualToString:@"yweather:wind"] || [elementName isEqualToString:@"wind"]))
	{
		NSString* tmp = temp;
		temp = [[attributeDict objectForKey:@"chill"] retain];
		[tmp release];

		[currentCondition setValue:[NSNumber numberWithInt:[temp intValue]] forKey:@"temp"];
		NSLog(@"WI: Temp: %@", temp);
	}
	else if ([elementName isEqualToString:@"yweather:location"] || [elementName isEqualToString:@"location"])
	{
		NSString* city = [attributeDict objectForKey:@"city"];
		[currentCondition setValue:city forKey:@"city"];
	}
	else if ([elementName isEqualToString:@"forecast"])
	{
		NSString* day = [attributeDict objectForKey:@"dayofweek"];
		NSString* low = [attributeDict objectForKey:@"low"];
		NSString* high = [attributeDict objectForKey:@"high"];
		NSString* code = [attributeDict objectForKey:@"code"];
		NSString* desc = [attributeDict objectForKey:@"text"];

		NSMutableDictionary* forecast = [NSMutableDictionary dictionaryWithCapacity:6];
		[forecast setValue:[NSNumber numberWithInt:[low intValue]] forKey:@"low"];
		[forecast setValue:[NSNumber numberWithInt:[high intValue]] forKey:@"high"];
		[forecast setValue:[NSNumber numberWithInt:[code intValue]] forKey:@"code"];
		[forecast setValue:desc forKey:@"description"];
		[forecast setValue:[NSNumber numberWithInt:([day intValue] - 1)] forKey:@"daycode"];

		NSString* iconPath = [self findWeatherImagePath:@"weatherstatus" code:code night:false];
		if (iconPath == nil)
			iconPath = [self findWeatherImagePath:@"weather" code:code night:false];
		[forecast setValue:iconPath forKey:@"icon"];

		NSMutableArray* arr = [currentCondition objectForKey:@"forecast"];
		if (arr == nil)
		{
			arr = [NSMutableArray arrayWithCapacity:7];
			[currentCondition setObject:arr forKey:@"forecast"];
		}

		[arr addObject:forecast];
	}
	else if ([elementName isEqualToString:@"yweather:forecast"])
	{
		NSString* day = [attributeDict objectForKey:@"day"];
		NSString* low = [attributeDict objectForKey:@"low"];
		NSString* high = [attributeDict objectForKey:@"high"];
		NSString* code = [attributeDict objectForKey:@"code"];
		NSString* desc = [attributeDict objectForKey:@"text"];

		NSMutableDictionary* forecast = [NSMutableDictionary dictionaryWithCapacity:6];
		[forecast setValue:[NSNumber numberWithInt:[low intValue]] forKey:@"low"];
		[forecast setValue:[NSNumber numberWithInt:[high intValue]] forKey:@"high"];
		[forecast setValue:[NSNumber numberWithInt:[code intValue]] forKey:@"code"];
		[forecast setValue:desc forKey:@"description"];

		[forecast setValue:[NSNumber numberWithInt:[dayCodes indexOfObject:[day uppercaseString]]] forKey:@"daycode"];

		NSString* iconPath = [self findWeatherImagePath:@"weatherstatus" code:code night:false];
		if (iconPath == nil)
			iconPath = [self findWeatherImagePath:@"weather" code:code night:false];
		[forecast setValue:iconPath forKey:@"icon"];

		NSMutableArray* arr = [currentCondition objectForKey:@"forecast"];
		if (arr == nil)
		{
			arr = [NSMutableArray arrayWithCapacity:3];
			[currentCondition setObject:arr forKey:@"forecast"];
		}

		[arr addObject:forecast];
	}
	else if ([elementName isEqualToString:@"condition"])
	{
		if (!showFeelsLike)
		{
			NSString* tmp = temp;
			temp = [[attributeDict objectForKey:@"temp"] retain];
			[tmp release];

			[currentCondition setValue:[NSNumber numberWithInt:[temp intValue]] forKey:@"temp"];
			NSLog(@"WI: Temp: %@", temp);
		}

		NSString* tmp = code;
		code = [[attributeDict objectForKey:@"code"] retain];
		[tmp release];
		[currentCondition setValue:[NSNumber numberWithInt:[code intValue]] forKey:@"code"];

		NSString* desc = [attributeDict objectForKey:@"text"];
		[currentCondition setValue:desc forKey:@"description"];

		NSLog(@"WI: Code: %@", code);

		NSDate* tmpDate = lastUpdateTime;
		lastUpdateTime = [[NSDate date] retain];
		[tmpDate release];
		NSLog(@"WI: Last Update Time: %@", lastUpdateTime);

		if (!useLocalTime)
		{
			double timestamp = [[attributeDict objectForKey:@"timestamp"] doubleValue];
			tmpDate = localWeatherTime;
			localWeatherTime = [[NSDate dateWithTimeIntervalSince1970:timestamp] retain];
			[tmpDate release];
		}
		NSLog(@"WI: Local Weather Time: %@", localWeatherTime);
	}
	else if ([elementName isEqualToString:@"yweather:condition"])
	{
		if (!showFeelsLike)
		{
			NSString* tmp = temp;
			temp = [[attributeDict objectForKey:@"temp"] retain];
			[tmp release];

			[currentCondition setValue:[NSNumber numberWithInt:[temp intValue]] forKey:@"temp"];
			NSLog(@"WI: Temp: %@", temp);
		}

		NSString* tmp = code;
		code = [[attributeDict objectForKey:@"code"] retain];
		[tmp release];

		[currentCondition setValue:[NSNumber numberWithInt:[code intValue]] forKey:@"code"];

		NSString* desc = [attributeDict objectForKey:@"text"];
		[currentCondition setValue:desc forKey:@"description"];

		NSLog(@"WI: Code: %@", code);

		NSDate* tmpDate = lastUpdateTime;
		lastUpdateTime = [[NSDate date] retain];
		[tmpDate release];
		NSLog(@"WI: Last Update Time: %@", lastUpdateTime);

		tmpDate = localWeatherTime;
		if (useLocalTime)
		{
			localWeatherTime = [lastUpdateTime retain];
		}
		else
		{
			NSString* weatherDate = [attributeDict objectForKey:@"date"];
			NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
			[df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
			[df setDateFormat:@"EEE, dd MMM yyyy hh:mm a"];
			localWeatherTime = [[df dateFromString:weatherDate] retain];
		}
		[tmpDate release];

		NSLog(@"WI: Local Weather Time: %@", localWeatherTime);
	}
}

- (void)parser:(NSXMLParser *)parser
didEndElement:(NSString *)elementName
namespaceURI:(NSString *)namespaceURI
qualifiedName:(NSString *)qName
{
	if (useLocalTime && [elementName isEqualToString:@"geo:lat"])
	{
		NSString* tmp = latitude;
		latitude = [parserContent retain];
		[tmp release];
		NSLog(@"WI: Latitude: %@", latitude);
	}
	else if (useLocalTime && [elementName isEqualToString:@"geo:long"])
	{
		NSString* tmp = longitude;
		longitude = [parserContent retain];
		[tmp release];
		NSLog(@"WI: Longitude: %@", longitude);
	}
	else if ([elementName isEqualToString:@"offset"])
	{
		int offset = [parserContent intValue];
		NSTimeZone* tmp = timeZone;
		timeZone = [[NSTimeZone timeZoneForSecondsFromGMT:(offset * 3600)] retain];
		[tmp release];
		NSLog(@"WI: Local time zone: %@", timeZone);
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

- (BOOL) isWeatherIcon:(NSString*) displayIdentifier
{
	if ([displayIdentifier isEqualToString:bundleIdentifier])
	{
		// make sure to reload the theme here
		[self loadTheme];
		return showWeatherIcon;
	}

	return false;
}

- (void) updateNightSetting
{
	night = false;
	if (localWeatherTime && sunrise && sunset)
	{
		NSDate* weatherDate = localWeatherTime;

		NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
		[df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
		if (timeZone)
			[df setTimeZone:timeZone];
		[df setDateFormat:(yahooRSS ? @"dd MMM yyyy hh:mm a" : @"dd MMM yyyy HHmm")];

		NSString* date = [df stringFromDate:localWeatherTime];
		NSArray* dateParts = [date componentsSeparatedByString:@" "];

		NSString* sunriseFullDateStr = [NSString stringWithFormat:@"%@ %@ %@ %@",
			[dateParts objectAtIndex:0],
			[dateParts objectAtIndex:1],
			[dateParts objectAtIndex:2],
			sunrise];

		NSString* sunsetFullDateStr = [NSString stringWithFormat:@"%@ %@ %@ %@",
			[dateParts objectAtIndex:0],
			[dateParts objectAtIndex:1],
			[dateParts objectAtIndex:2],
			sunset];

		NSDate* sunriseDate = [df dateFromString:sunriseFullDateStr];
		NSDate* sunsetDate = [df dateFromString:sunsetFullDateStr];

		NSLog(@"WI: Sunset/Sunrise:%@, %@", sunriseDate, sunsetDate);
		night = ([weatherDate compare:sunriseDate] == NSOrderedAscending ||
				[weatherDate compare:sunsetDate] == NSOrderedDescending);
	}
	NSLog(@"WI: Night? %d", night);
}

- (UIImage*) createIndicator:(int) mode
{
	NSString* t =[temp stringByAppendingString: @"\u00B0"];

	UIImage* image = [self findWeatherImage:@"weatherstatus"];
	// save the status bar image
	if (!image)
		image = [self findWeatherImage:@"weather"];

	UIFont* font = [UIFont boldSystemFontOfSize:13];
	CGSize tempSize = CGSizeMake(0, 20);
        CGSize sbSize = CGSizeMake(0, 20);

	NSString* style = (mode == 0 ? statusBarTempStyle : statusBarTempStyleFSO);

        if (showStatusBarTemp)
	{
	        tempSize = [t sizeWithStyle:style forWidth:40];
		NSLog(@"WI: Temp size: %f, %f", tempSize.width, tempSize.height);
                sbSize.width += tempSize.width;
	}

        if (showStatusBarImage && image)
                sbSize.width += ceil(image.size.width * statusBarImageScale);

	NSLog(@"WI:Debug: Status Bar Size: %f, %f", sbSize.width, sbSize.height);

        UIGraphicsBeginImageContext(sbSize);

        if (showStatusBarTemp)
        {
		if (debug) NSLog(@"WI:Debug: Drawing temp on status bar");
                [t drawAtPoint:CGPointMake(0, 0) withStyle:style];
        }

        if (showStatusBarImage && image)
        {
		if (debug) NSLog(@"WI:Debug: Drawing image on status bar");
        	float width = image.size.width * statusBarImageScale;
                float height = image.size.height * statusBarImageScale;
                CGRect rect = CGRectMake(tempSize.width, ((18 - height) / 2), width, height);
                [image drawInRect:rect];
        }

	UIImage* indicator = UIGraphicsGetImageFromCurrentImageContext();

        UIGraphicsEndImageContext();

	return indicator;
}

- (UIImage*) createIcon
{
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
		float width = weatherImage.size.width * imageScale;
		float height = weatherImage.size.height * imageScale;
	        CGRect iconRect = CGRectMake((size.width - width) / 2, imageMarginTop, width, height);
		[weatherImage drawInRect:iconRect];
	}

	NSString* t =[temp stringByAppendingString: @"\u00B0"];
	NSString* style = [NSString stringWithFormat:(night ? tempStyleNight : tempStyle), (int)size.width];
       	[t drawAtPoint:CGPointMake(0, 0) withStyle:style];

	UIImage* icon = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	return icon;
}

- (void) updateIcon
{
	UIImage* tmpIcon = weatherIcon;
	weatherIcon = [[self createIcon] retain];
	[tmpIcon release];

	SBIconController* iconController = [$SBIconController sharedInstance];
	if (weatherIcon != nil && iconController)
	{
		NSLog(@"WI: Refreshing icon...");

	        // now force the icon to refresh
	        if (SBIconModel* model = MSHookIvar<SBIconModel*>(iconController, "_iconModel"))
		{
			if (SBIcon* applicationIcon = [model iconForDisplayIdentifier:bundleIdentifier])
			{
		        	[model reloadIconImageForDisplayIdentifier:bundleIdentifier];
	
			        if (SBImageCache* cache = MSHookIvar<SBImageCache*>(model, "_iconImageCache"))
					if ([cache respondsToSelector:@selector(removeImageForKey:)])
						[cache removeImageForKey:bundleIdentifier];

				if (UIImageView* imageView = MSHookIvar<UIImageView*>(applicationIcon, "_image"))
				{
					imageView.bounds = CGRectMake(0, 0, weatherIcon.size.width, weatherIcon.size.height);
					imageView.image = weatherIcon;
					[imageView setNeedsDisplay];
				}
			}
		}

		NSLog(@"WI: Done refreshing icon.");
	}
}

- (void) updateIndicator
{
	UIImage* tmpImg = statusBarIndicatorMode0;
	statusBarIndicatorMode0 = [[self createIndicator:0] retain];
	[tmpImg release];

	tmpImg = statusBarIndicatorMode1;
	statusBarIndicatorMode1 = [[self createIndicator:1] retain];
	[tmpImg release];

	SBStatusBarController* statusBarController = [$SBStatusBarController sharedStatusBarController];
	if (statusBarController)
	{
		NSLog(@"WI: Refreshing indicator...");
		if ([statusBarController respondsToSelector:@selector(showBatteryPercentageChanged)])
		{
			// 3.x
			[statusBarController addStatusBarItem:@"WeatherIcon"];
			[statusBarController removeStatusBarItem:@"WeatherIcon"];
		}
		else
		{
			// 2.x
			[statusBarController removeStatusBarItem:@"WeatherIcon"];
			[statusBarController addStatusBarItem:@"WeatherIcon"];
		}
		NSLog(@"WI: Done refreshing indicator.");
	}
}

- (void) updateWeatherIcon
{
	[self loadTheme];
	[self updateNightSetting];

	if (debug)
		NSLog(@"WI:Debug: Updating with temp: %@, code: %@, night: %d", temp, code, night);

	if (showWeatherIcon)
		[self updateIcon];

	// now the status bar image
	if (self.showStatusBarWeather)
		[self updateIndicator];

	// save the current condition
	NSString* iconPath = [self findWeatherImagePath:@"weatherstatus"];
	if (iconPath == nil)
		iconPath = [self findWeatherImagePath:@"weather"];
	[currentCondition setValue:iconPath forKey:@"icon"];

	[currentCondition writeToFile:conditionPath atomically:YES];

	// release the temp data to save memory
	[self releaseTempInfo];
/*
	temp = [defaultTemp retain];
	code = [defaultCode retain];
*/
}

- (BOOL) _refresh
{
	themeLoaded = false;
	prefsLoaded = false;
	weatherPrefsLoaded = false;
	
	// reparse the preferences
	[self parsePreferences];

	if (!location)
	{
		NSLog(@"WI: No location set.");
		return false;
	}

	// clear the current forecast
	[currentCondition removeObjectForKey:@"forecast"];

	NSLog(@"WI: Refreshing weather for %@...", location);
	if (yahooRSS)
	{
		NSString* urlStr = [NSString stringWithFormat:@"http://weather.yahooapis.com/forecastrss?p=%@&u=%@", location, (isCelsius ? @"c" : @"f")];
		NSURL* url = [NSURL URLWithString:urlStr];
		NSXMLParser* parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
		[parser setDelegate:self];
		[parser parse];
		[parser release];
	}
	else
	{
		NSString* urlStr = @"http://iphone-wu.apple.com/dgw?imei=B7693A01-F383-4327-8771-501ABD85B5C1&apptype=weather&t=4";
		NSURL* url = [NSURL URLWithString:urlStr];
		NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url];
		req.HTTPMethod = @"POST";
		NSString* body = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?><request devtype=\"Apple iPhone v2.2\" deployver=\"Apple iPhone v2.2\" app=\"YGoiPhoneClient\" appver=\"1.0.0.5G77\" api=\"weather\" apiver=\"1.0.0\" acknotification=\"0000\"><query id=\"30\" timestamp=\"0\" type=\"getforecastbylocationid\"><list><id>%@</id></list><language>en_US</language><unit>%@</unit></query></request>", location, (isCelsius ? @"c" : @"f")];
		req.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];
		[req setValue:@"Apple iPhone v2.2 Weather v1.0.0.5G77" forHTTPHeaderField:@"User-Agent"];
		[req setValue:@"*/*" forHTTPHeaderField:@"Accept"];
		[req setValue:@"en-us" forHTTPHeaderField:@"Accept-Language"];
		[req setValue:@"" forHTTPHeaderField:@"Accept-Encoding"];
		[req setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
		NSData* data = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];
//		NSString* retData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//		NSLog(@"WI: Data: %@", retData);
//		[retData release];

		NSXMLParser* parser = [[NSXMLParser alloc] initWithData:data];
		[parser setDelegate:self];
		[parser parse];
		[parser release];
	}

	if (debug)
		NSLog(@"WI:Debug: Done refreshing weather.");

	if (useLocalTime && !timeZone && longitude && latitude)
	{
		NSLog(@"WI: Refreshing time zone for %@...", location);
		NSString* urlStr = [NSString stringWithFormat:@"http://www.earthtools.org/timezone/%@/%@", latitude, longitude];
		NSURL* url = [NSURL URLWithString:urlStr];
		NSXMLParser* parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
		[parser setDelegate:self];
		[parser parse];
		[parser release];
	}

	if (debug)
		NSLog(@"WI:Debug: Done refreshing timezone.");

	BOOL success = true;
	if (!lastUpdateTime || [lastUpdateTime compare:nextRefreshTime] == NSOrderedAscending)
	{
		NSLog(@"WI: Update failed.");
		success = false;
		
		if (failedCount++ < 3)
			return success;
	}

	failedCount = 0;

	NSDate* tmpDate = nextRefreshTime;
	nextRefreshTime = [[NSDate dateWithTimeIntervalSinceNow:refreshInterval] retain];
	[tmpDate release];

	NSLog(@"WI: Next refresh time: %@", nextRefreshTime);
	return success;
}

- (void) refreshInBackground
{
	// mark as refreshing
	refreshing = true;

	@try
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		BOOL success = [self _refresh];
		[pool release];

		// update the weather info
		if (success)
			[self performSelectorOnMainThread:@selector(updateWeatherIcon) withObject:nil waitUntilDone:NO];
	}
	@finally
	{
		refreshing = false;
	}
}

- (void) setNeedsRefresh
{
	if (debug) NSLog(@"WI:Debug: Marking for refresh.");
	NSDate* tmpDate = nextRefreshTime;
	nextRefreshTime = [[NSDate date] retain];
	[tmpDate release];
}

- (void) refreshNow
{
	[self setNeedsRefresh];
	[self refresh];
}

- (void) refresh
{
	if (!showWeatherIcon && !self.showStatusBarWeather)
		return;

	if ((showWeatherIcon && !weatherIcon) || (self.showStatusBarWeather && !statusBarIndicatorMode0 && !statusBarIndicatorMode1))
		[self updateWeatherIcon];

	if ([self needsRefresh])
		[NSThread detachNewThreadSelector:@selector(refreshInBackground) toTarget:self withObject:nil];
	else
		 if (debug) NSLog(@"WI:Debug: No need to refresh.");
}

- (UIImage*) icon
{
	if (weatherIcon == nil)
	{
		NSLog(@"WI: Creating temporary icon.");
		return [self createIcon];
	}

	NSLog(@"WI: returning %@", weatherIcon);
	return weatherIcon;
}

- (BOOL) showStatusBarWeather
{
	return (showStatusBarTemp || showStatusBarImage);
}

- (void) checkPreferences
{
	if (debug) NSLog(@"WI:Debug: Checking preferences");
	NSDictionary* prefs = [NSDictionary dictionaryWithContentsOfFile:prefsPath];
	if (currentPrefs && prefs && ![prefs isEqualToDictionary:currentPrefs])
	{
		if (debug) NSLog(@"WI:Debug: Preferences changed.");
		[self refreshNow];
	}
}

- (UIImage*) statusBarIndicator:(int)mode
{
	return (mode == 0 ? statusBarIndicatorMode0 : statusBarIndicatorMode1);
}

- (void) dealloc
{
	[self releaseTempInfo];

	[temp release];
	[code release];

	[location release];
	[bundleIdentifier release];
	[lastUpdateTime release];
	[nextRefreshTime release];

	[weatherIcon release];
	[statusBarIndicatorMode0 release];
	[statusBarIndicatorMode1 release];

	[tempStyle release];
	[tempStyleNight release];

	[statusBarTempStyle release];
	[statusBarTempStyleFSO release];
//	[statusBarTempStyleFST release];

	[currentCondition release];
	[currentPrefs release];

	[super dealloc];
}

@end
