/*
 *  WeatherView.mm
 *  
 *
 *  Created by David Ashman on 1/12/09.
 *  Copyright 2009 David Ashman. All rights reserved.
 *
 */

#import "WeatherIconController.h"
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

static NSString* prefsPath = @"/var/mobile/Library/Preferences/com.ashman.WeatherIcon.plist";
static NSString* defaultStatusBarTempStyleFSO(@""
	"font-family: Helvetica; "
	"font-weight: bold; "
	"font-size: 14px; "
	"color: white; "
	"height: 20px;"
	"margin-top: 1px;"
"");
//static NSString* defaultStatusBarTempStyleFST = defaultStatusBarTempStyleFSO;
static NSString* defaultStatusBarTempStyle(@""
	"font-family: Helvetica; "
	"font-weight: bold; "
	"font-size: 14px; "
	"color: black; "
	"text-shadow: rgba(255, 255, 255, 0.6) 0px 1px 0px; "
	"height: 20px;"
	"margin-top: 1px;"
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
				[timeZone release];
				timeZone = nil;
			}

			[location release];
			location = [zip retain];
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
		[currentPrefs release];
		currentPrefs = [prefs retain];

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
					[timeZone release];
					timeZone = nil;
				}

				[location release];
				location = [[NSString stringWithString:loc] retain];
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
					[bundleIdentifier release];
					bundleIdentifier = [custom retain];
				}
			}
			else
			{
				[bundleIdentifier release];
				bundleIdentifier = [id retain];
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
			[tempStyle release];
			if (NSString* style = [dict objectForKey:@"TempStyle"])
				tempStyle = [[defaultTempStyle stringByAppendingString:style] retain];
			else
				tempStyle = [defaultTempStyle retain];

			[tempStyleNight release];
			if (NSString* nstyle = [dict objectForKey:@"TempStyleNight"])
			        tempStyleNight = [[tempStyle stringByAppendingString:nstyle] retain];
			else
				tempStyleNight = [tempStyle retain];

			[statusBarTempStyle release];
			if (NSString* style = [dict objectForKey:@"StatusBarTempStyle"])
				statusBarTempStyle = [[defaultStatusBarTempStyle stringByAppendingString:style] retain];
			else
				statusBarTempStyle = [defaultStatusBarTempStyle retain];

			[statusBarTempStyleFSO release];
			if (NSString* nstyle = [dict objectForKey:@"StatusBarTempStyleFSO"])
			        statusBarTempStyleFSO = [[defaultStatusBarTempStyleFSO stringByAppendingString:nstyle] retain];
			else
				statusBarTempStyleFSO = [defaultStatusBarTempStyleFSO retain];

/*
			[statusBarTempStyleFST release];
			if (NSString* nstyle = [dict objectForKey:@"StatusBarTempStyleFST"])
			        statusBarTempStyleFST = [[defaultStatusBarTempStyleFST stringByAppendingString:nstyle] retain];
			else
				statusBarTempStyleFST = [defaultStatusBarTempStyleFST retain];
*/

			if (NSNumber* scale = [dict objectForKey:@"StatusBarImageScale"])
				statusBarImageScale = [scale floatValue];

			if (NSNumber* scale = [dict objectForKey:@"ImageScale"])
				imageScale = [scale floatValue];

			if (NSNumber* top = [dict objectForKey:@"ImageMarginTop"])
				imageMarginTop = [top intValue];

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
			[mappings release];
			mappings = [[dict objectForKey:@"Mappings"] retain];
		}
	}	

	themeLoaded = true;
}

- (id) init
{
	tempStyle = [defaultTempStyle retain];
	tempStyleNight = [tempStyle retain];
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

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
namespaceURI:(NSString *)namespaceURI
qualifiedName:(NSString *)qName
   attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"yweather:astronomy"])
	{
		[sunrise release];
		[sunset release];

		sunrise = [[attributeDict objectForKey:@"sunrise"] retain];
		sunset = [[attributeDict objectForKey:@"sunset"] retain];

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
	else if (showFeelsLike && [elementName isEqualToString:@"yweather:wind"])
	{
		[temp release];
		temp = [[attributeDict objectForKey:@"chill"] retain];
		NSLog(@"WI: Temp: %@", temp);
	}
	else if ([elementName isEqualToString:@"yweather:condition"])
	{
		if (!showFeelsLike)
		{
			[temp release];
			temp = [[attributeDict objectForKey:@"temp"] retain];
			NSLog(@"WI: Temp: %@", temp);
		}

		[code release];
		code = [[attributeDict objectForKey:@"code"] retain];
		NSLog(@"WI: Code: %@", code);

		[lastUpdateTime release];
		lastUpdateTime = [[NSDate date] retain];
		NSLog(@"WI: Last Update Time: %@", lastUpdateTime);

		[localWeatherTime release];
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
		[latitude release];
		latitude = [parserContent retain];
		NSLog(@"WI: Latitude: %@", latitude);
	}
	else if (useLocalTime && [elementName isEqualToString:@"geo:long"])
	{
		[longitude release];
		longitude = [parserContent retain];
		NSLog(@"WI: Longitude: %@", longitude);
	}
	else if ([elementName isEqualToString:@"offset"])
	{
		int offset = [parserContent intValue];
		[timeZone release];
		timeZone = [[NSTimeZone timeZoneForSecondsFromGMT:(offset * 3600)] retain];
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

- (UIImage*) findImage:(NSBundle*) bundle name:(NSString*) name
{
	NSString* path = [bundle pathForResource:name ofType:@"png"];
	UIImage* image = (path ? [UIImage imageWithContentsOfFile:path] : nil);
	if (image)
	{
		if (debug)
			NSLog(@"WI:Debug: Found %@ Image: %@", name, path);

		return image;
	}

	return nil;
}

- (UIImage*) findWeatherImage:(NSString*) prefix
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
	if (UIImage* img = [self findImage:bundle name:[NSString stringWithFormat:@"%@%@%@", prefix, code, suffix]])
		return img;

	if (UIImage* img = [self findImage:bundle name:[NSString stringWithFormat:@"%@%@", prefix, code]])
		return img;

	if (UIImage* img = [self findImage:bundle name:[NSString stringWithFormat:@"%@%@", prefix, suffix]])
		return img;

	if (UIImage* img = [self findImage:bundle name:prefix])
		return img;

	if (debug)
		NSLog(@"WI:Debug: No image found for %@%@%@", prefix, code, suffix);

	return nil;
}

- (void) updateNightSetting
{
	night = false;
	if (localWeatherTime && sunrise && sunset)
	{
		NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
		[df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
		if (timeZone)
			[df setTimeZone:timeZone];
		[df setDateFormat:@"dd MMM yyyy hh:mm a"];

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

		NSDate* weatherDate = localWeatherTime;
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
                sbSize.width += tempSize.width;
	}

        if (showStatusBarImage && image)
                sbSize.width += ceil(image.size.width * statusBarImageScale);

	if (debug) NSLog(@"WI:Debug: Status Bar Size: %f, %f", sbSize.width, sbSize.height);

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

- (void) updateIcon
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

	[weatherIcon release];
	weatherIcon = [UIGraphicsGetImageFromCurrentImageContext() retain];

	UIGraphicsEndImageContext();

	SBIconController* iconController = [$SBIconController sharedInstance];
	if (iconController)
	{
		NSLog(@"WI: Refreshing icon...");
	        // now force the icon to refresh
	        SBIconModel* model(MSHookIvar<SBIconModel*>(iconController, "_iconModel"));
	        [model reloadIconImageForDisplayIdentifier:bundleIdentifier];

		// get the SBIconController and refresh the contentView
		[iconController.contentView setNeedsDisplay];

		// refresh all of the subviews to get the reflection right
		SBIcon* applicationIcon = [model iconForDisplayIdentifier:bundleIdentifier];
		if (applicationIcon)
		{
			NSArray* views = [applicationIcon subviews];
			for (int i = 0; i < views.count; i++)
				[[views objectAtIndex:i] setNeedsDisplay];
		}
	}
}

- (void) updateIndicator
{
	[statusBarIndicatorMode0 release];
	statusBarIndicatorMode0 = [[self createIndicator:0] retain];

	[statusBarIndicatorMode1 release];
	statusBarIndicatorMode1 = [[self createIndicator:1] retain];

	SBStatusBarController* statusBarController = [$SBStatusBarController sharedStatusBarController];
	if (statusBarController)
	{
		NSLog(@"WI: Refreshing indicator...");
		[statusBarController removeStatusBarItem:@"WeatherIcon"];
		[statusBarController addStatusBarItem:@"WeatherIcon"];
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

	NSLog(@"WI: Refreshing weather for %@...", location);
	NSString* urlStr = [NSString stringWithFormat:@"http://weather.yahooapis.com/forecastrss?p=%@&u=%@", location, (isCelsius ? @"c" : @"f")];
	NSURL* url = [NSURL URLWithString:urlStr];
	NSXMLParser* parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
	[parser setDelegate:self];
	[parser parse];
	[parser release];

	if (debug)
		NSLog(@"WI:Debug: Done refreshing weather.");

	if (useLocalTime && !timeZone && longitude && latitude)
	{
		NSLog(@"WI: Refreshing time zone for %@...", location);
		urlStr = [NSString stringWithFormat:@"http://www.earthtools.org/timezone/%@/%@", latitude, longitude];
		url = [NSURL URLWithString:urlStr];
		parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
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
	[nextRefreshTime release];
	nextRefreshTime = [[NSDate dateWithTimeIntervalSinceNow:refreshInterval] retain];

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
	[nextRefreshTime release];
	nextRefreshTime = [[NSDate date] retain];
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
	NSLog(@"WI: Mode: %d", mode);
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

	[currentPrefs release];

	[super dealloc];
}

@end
