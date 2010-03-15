#import <substrate.h>
#import <SpringBoard/SBIcon.h>
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
#import <SpringBoard/SBIconList.h>
#import <SpringBoard/SBTelephonyManager.h>
#import <SpringBoard/SBIconController.h>
#import <SpringBoard/SBUIController.h>
#import <SpringBoard/SBStatusBarController.h>
#import <SpringBoard/SBStatusBarContentsView.h>
#import <SpringBoard/SBStatusBarContentView.h>
#import <SpringBoard/SBStatusBarIndicatorsView.h>
#import <SpringBoard/SBWidgetApplicationIcon.h>
#import <SpringBoard/SBInstalledApplicationIcon.h>
#import <SpringBoard/SBBookmarkIcon.h>
#import <SpringBoard/SBAwayView.h>
#import <SpringBoard/SBAwayController.h>
#import <UIKit/UIStringDrawing.h>
#import <UIKit/UIKit.h>
#import <Foundation/NSObjCRuntime.h>
#include "Constants.h"


@interface WeatherIconController : NSObject
{
	NSConditionLock* lock;
}

@property (nonatomic, retain) NSTimer* timer;
@property (nonatomic, retain) NSDate* nextRefresh;

	// image caches
@property (nonatomic, retain) UIImage* statusBarIndicator;
@property (nonatomic, retain) UIImage* statusBarIndicatorFSO;
@property (nonatomic, retain) UIImage* weatherIcon;

	// current temp info
@property (nonatomic, retain) NSString* temp;
@property (nonatomic, retain) NSString* code;
@property (nonatomic, retain) NSString* sunrise;
@property (nonatomic, retain) NSString* sunset;
@property (nonatomic, retain) NSDate* localWeatherTime;
@property (nonatomic) BOOL isNight;

	// refresh date info
@property (nonatomic, retain) NSDictionary* theme;
@property (nonatomic, retain) NSDictionary* weatherPreferences;
@property (nonatomic, retain) NSMutableDictionary* preferences;
@property (nonatomic, retain) NSMutableDictionary* currentCondition;
//@property BOOL lockInfo;

- (id)init;
- (BOOL)isWeatherIcon:(NSString*) displayIdentifier;

-(void) manualRefresh;
-(void) startTimer;
-(void) stopTimer;

- (UIImage*)icon;
- (UIImage*)statusBarIndicator:(int) mode;

@end

static Class $SBStatusBarController = objc_getClass("SBStatusBarController");
static Class $SBUIController = objc_getClass("SBUIController");
static Class $SBIconController = objc_getClass("SBIconController");
static Class $SBImageCache = objc_getClass("SBImageCache");
static Class $SBTelephonyManager = objc_getClass("SBTelephonyManager");
static Class $SBAwayController = objc_getClass("SBAwayController");

static NSBundle* weatherIconBundle;

static NSString* prefsPath = @"/var/mobile/Library/Preferences/com.ashman.WeatherIcon.plist";
//static NSString* lockInfoPrefs = @"/var/mobile/Library/Preferences/com.ashman.lockinfo.WeatherIconPlugin.plist";
static NSString* conditionPath = @"/var/mobile/Library/Caches/com.ashman.WeatherIcon.cache.plist";
static NSString* weatherPrefsPath = @"/var/mobile/Library/Preferences/com.apple.weather.plist";
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

@implementation WeatherIconController

@synthesize timer, nextRefresh;

// image cache
@synthesize statusBarIndicator, statusBarIndicatorFSO, weatherIcon;

// current temp info
@synthesize temp, code, sunrise, sunset, localWeatherTime, isNight;

// preferences
@synthesize theme, weatherPreferences, preferences, currentCondition;

- (NSString*) bundleIdentifier
{
	NSString* id = [self.preferences objectForKey:@"WeatherBundleIdentifier"];

	if (id != nil && [id isEqualToString:@"Custom"])
		if (NSString* custom = [self.preferences objectForKey:@"CustomWeatherBundleIdentifier"])
			return custom;

	return id;
}

- (void) loadTheme
{
	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:10];

	if (NSString* themePrefs = [weatherIconBundle pathForResource:@"Theme" ofType:@"plist"])
		[dict addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:themePrefs]];

	NSBundle* bundle = [NSBundle mainBundle];
	if (NSString* themePrefs = [bundle pathForResource:@"com.ashman.WeatherIcon" ofType:@"plist"])
		[dict addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:themePrefs]];

	self.theme = dict;
}

- (void) loadPreferences
{
	NSMutableDictionary* prefs = [NSMutableDictionary dictionaryWithContentsOfFile:prefsPath];
	if (prefs == nil)
	{
		prefs = [NSMutableDictionary dictionaryWithCapacity:10];
		[prefs setValue:[NSNumber numberWithBool:false] forKey:@"OverrideLocation"];
		[prefs setValue:[NSNumber numberWithBool:false] forKey:@"Celsius"];
		[prefs setValue:[NSNumber numberWithBool:false] forKey:@"ShowFeelsLike"];
		[prefs setValue:[NSNumber numberWithBool:true] forKey:@"ShowWeatherIcon"];
		[prefs setValue:[NSNumber numberWithBool:false] forKey:@"ShowStatusBarImage"];
		[prefs setValue:[NSNumber numberWithBool:false] forKey:@"ShowStatusBarTemp"];
		[prefs setValue:[NSNumber numberWithBool:false] forKey:@"UseLocalTime"];
		[prefs setValue:[NSNumber numberWithInt:900] forKey:@"RefreshInterval"];
		[prefs setValue:@"com.apple.weather" forKey:@"WeatherBundleIdentifier"];
		[prefs writeToFile:prefsPath atomically:YES];
	}

	self.preferences = prefs;

	NSDictionary* weather = [NSDictionary dictionaryWithContentsOfFile:weatherPrefsPath];
	if (weather == nil)
		weather = [NSDictionary dictionary];

	self.weatherPreferences = weather;

/*
	BOOL b = false;
	if (NSDictionary* liPrefs = [NSDictionary dictionaryWithContentsOfFile:lockInfoPrefs])
		if (NSNumber* e = [liPrefs objectForKey:@"Enabled"])
			b = e.boolValue;	
	self.lockInfo = b;
*/

	[self loadTheme];
}

- (BOOL) showFeelsLike
{
	if (NSNumber* chill = [self.preferences objectForKey:@"ShowFeelsLike"])
		return [chill boolValue];

	return false;
}

- (NSString*) location
{
	BOOL overrideLocation = false;
	if (NSNumber* b = [self.preferences objectForKey:@"OverrideLocation"])
		overrideLocation = [b boolValue];

	if (overrideLocation)
	{
		return [self.preferences objectForKey:@"Location"];
	}
	else
	{
		NSArray* cities = [self.weatherPreferences objectForKey:@"Cities"];
		if (cities.count > 0)
		{
			NSDictionary* city = [cities objectAtIndex:0];
			return [[city objectForKey:@"Zip"] substringToIndex:8];
		}	
	}

	return nil;
}

-(NSString*) city
{
	BOOL overrideLocation = false;
	if (NSNumber* b = [self.preferences objectForKey:@"OverrideLocation"])
		overrideLocation = [b boolValue];

	if (!overrideLocation)
	{
		NSArray* cities = [self.weatherPreferences objectForKey:@"Cities"];
		if (cities.count > 0)
		{
			NSDictionary* city = [cities objectAtIndex:0];
			return [city objectForKey:@"Name"];
		}	
	}

	return nil;
}


- (BOOL) isCelsius
{
	BOOL overrideLocation = false;
	if (NSNumber* b = [self.preferences objectForKey:@"OverrideLocation"])
		overrideLocation = [b boolValue];

	if (overrideLocation)
	{
		if (NSNumber* celsius = [self.preferences objectForKey:@"Celsius"])
			return [celsius boolValue];
	}
	else
	{
		if (NSNumber* b = [self.weatherPreferences objectForKey:@"Celsius"])
			return [b boolValue];
	}

	return false;
}

- (BOOL) useLocalTime
{
	if (NSNumber* v = [self.preferences objectForKey:@"UseLocalTime"])
		return [v boolValue];

	return false;
}


- (NSTimeInterval) refreshInterval
{
	if (NSNumber* interval = [self.preferences objectForKey:@"RefreshInterval"])
		return ([interval intValue] * 60);

	return 900;
}

- (NSString*) tempStyle
{
	if (NSString* style = [self.theme objectForKey:@"TempStyle"])
		return [defaultTempStyle stringByAppendingString:style];
	else
		return defaultTempStyle;
}

- (NSString*) tempStyleNight
{
	if (NSString* style = [self.theme objectForKey:@"TempStyleNight"])
		return [self.tempStyle stringByAppendingString:style];
	else
		return self.tempStyle;
}

- (NSString*) statusBarTempStyle
{
	if (NSString* style = [self.theme objectForKey:@"StatusBarTempStyle"])
		return [defaultStatusBarTempStyle stringByAppendingString:style];
	else
		return defaultStatusBarTempStyle;
}

- (NSString*) statusBarTempStyleFSO
{
	if (NSString* style = [self.theme objectForKey:@"StatusBarTempStyleFSO"])
		return [defaultStatusBarTempStyleFSO stringByAppendingString:style];
	else
		return defaultStatusBarTempStyleFSO;
}

- (float) statusBarImageScale
{
	if (NSNumber* scale = [self.theme objectForKey:@"StatusBarImageScale"])
		return [scale floatValue];

	return 1;
}

- (float) imageScale
{
	if (NSNumber* scale = [self.theme objectForKey:@"ImageScale"])
		return [scale floatValue];

	return 1;
}

- (int) imageMarginTop
{
	if (NSNumber* n = [self.theme objectForKey:@"ImageMarginTop"])
		return [n intValue];

	return 1;
}

- (BOOL) enabled
{
	if (NSNumber* v = [self.preferences objectForKey:@"Enabled"])
		return [v boolValue];

	return true;
}

- (BOOL) showWeatherIcon
{
	if (!self.enabled)
		return false;

	if (NSNumber* n = [self.theme objectForKey:@"ShowWeatherIcon"])
		return [n boolValue];

	if (NSNumber* v = [self.preferences objectForKey:@"ShowWeatherIcon"])
		return [v boolValue];

	return true;
}

- (BOOL) showWeatherBadge
{
	if (!self.enabled)
		return false;

	if (NSNumber* n = [self.theme objectForKey:@"ShowWeatherBadge"])
		return [n boolValue];

	if (NSNumber* v = [self.preferences objectForKey:@"ShowWeatherBadge"])
		return [v boolValue];

	return false;
}

- (BOOL) showStatusBarImage
{
	if (!self.enabled)
		return false;

	if (NSNumber* n = [self.theme objectForKey:@"ShowStatusBarImage"])
		return [n boolValue];

	if (NSNumber* v = [self.preferences objectForKey:@"ShowStatusBarImage"])
		return [v boolValue];
	
	return false;
}

- (BOOL) showStatusBarTemp
{
	if (!self.enabled)
		return false;

	if (NSNumber* n = [self.theme objectForKey:@"ShowStatusBarTemp"])
		return [n boolValue];

	if (NSNumber* v = [self.preferences objectForKey:@"ShowStatusBarTemp"])
		return [v boolValue];
	
	return false;
}

- (NSDictionary*) mappings
{
	return [self.theme objectForKey:@"Mappings"];
}

-(void) dealloc
{
	[lock release];
	[super dealloc];
}

- (id) init
{
	self.temp = defaultTemp;
	self.code = defaultCode;
	self.nextRefresh = [NSDate date];

	lock = [[NSConditionLock alloc] init];

	if (self.currentCondition = [NSMutableDictionary dictionaryWithContentsOfFile:conditionPath])
	{
		if (NSNumber* n = [self.currentCondition objectForKey:@"temp"])
			self.temp = n.stringValue;

		if (NSNumber* n = [self.currentCondition objectForKey:@"code"])
			self.code = n.stringValue;

		NSLog(@"WI:Init: Current condition set to temp (%@), code (%@)", self.temp, self.code);
	}
	else
	{
		self.currentCondition = [NSMutableDictionary dictionaryWithCapacity:5];
	}

	[self loadPreferences];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(manualRefresh) name:@"WIRefreshNotification" object:nil];

	// first refresh
	[self startTimer];

	return self;
}

-(void) scheduleRefreshOnMainThread:(NSDate*) next
{
	NSTimeInterval i = next.timeIntervalSinceNow;
	if (i < 0)
		i = 0;

	self.timer = [[NSTimer scheduledTimerWithTimeInterval:i target:self selector:@selector(refreshFromTimer:) userInfo:nil repeats:NO] retain];
	NSLog(@"WI:Timer: Starting refresh timer for %@.", self.timer.fireDate);
}

-(void) stopTimer
{
	NSLog(@"WI:Timer: Cancelling timer for next refresh at %@.", self.timer.fireDate);
	[self.timer invalidate];
}

-(void) startTimer
{
	[self performSelectorOnMainThread:@selector(scheduleRefreshOnMainThread:) withObject:self.nextRefresh waitUntilDone:NO];
}

-(void) scheduleNextRefresh
{
	self.nextRefresh = [NSDate dateWithTimeIntervalSinceNow:self.refreshInterval];
	if (![[$SBAwayController sharedAwayController] isDimmed] || [[$SBUIController sharedInstance] isOnAC])
		[self performSelectorOnMainThread:@selector(scheduleRefreshOnMainThread:) withObject:self.nextRefresh waitUntilDone:NO];
	else
		NSLog(@"WI:Timer: Not scheduling next refresh because device is asleep.");
}

-(void) refreshFromTimer:(NSTimer*) timer
{
	[self refresh];
	[self scheduleNextRefresh];
}

-(void) manualRefresh
{
	NSLog(@"WI:Timer: Manual refresh requested.  Invalidating timer scheduled for %@.", self.timer.fireDate);
	[self stopTimer];
	[self refresh];
	[self scheduleNextRefresh];
}

- (NSString*) mapImage:(NSString*) prefix code:(NSString*) code night:(BOOL) night
{
	// no mappings
	NSDictionary* mappings = self.mappings;
	if (mappings == nil)
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
		return path;
	}

	return nil;
}

-(NSString*) defaultImagePath:(NSNumber*) code night:(BOOL) night
{
        if (code)
        {
                NSArray* icons = (night ? defaultNightIcons : defaultIcons);
                if (code.intValue >= 0 && code.intValue < icons.count)
                        return [weatherIconBundle pathForResource:[icons objectAtIndex:code.intValue] ofType:@"png"];
        }

        return nil;
}

- (NSString*) findWeatherImagePath:(NSString*) prefix code:(NSString*) code night:(BOOL) night
{
	NSString* suffix = (night ? @"_night" : @"_day");	

	if (NSString* mapped = [self mapImage:prefix code:code night:night])
	{
		prefix = mapped;
	}

        NSBundle* bundle = [NSBundle mainBundle];
	if (NSString* img = [self findImage:bundle name:[NSString stringWithFormat:@"%@%@%@", prefix, code, suffix]])
		return img;

	if (NSString* img = [self findImage:bundle name:[NSString stringWithFormat:@"%@%@", prefix, code]])
		return img;

	if (NSString* img = [self findImage:bundle name:[NSString stringWithFormat:@"%@%@", prefix, suffix]])
		return img;

	if (NSString* img = [self findImage:bundle name:prefix])
		return img;

//	return [self defaultImagePath:code night:night];
	return nil;
}

- (NSString*) findWeatherImagePath:(NSString*) prefix
{
	return [self findWeatherImagePath:prefix code:self.code night:self.isNight];
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
	if ([elementName isEqualToString:@"astronomy"])
        {
                self.sunrise = [attributeDict objectForKey:@"sunrise"];
//                NSLog(@"WI: Sunrise: %@", self.sunrise);

                self.sunset = [attributeDict objectForKey:@"sunset"];
//                NSLog(@"WI: Sunset: %@", self.sunset);
        }
	else if ([elementName isEqualToString:@"result"])
	{
		if (self.useLocalTime)
		{
			double timestamp = [[attributeDict objectForKey:@"timestamp"] doubleValue];
			self.localWeatherTime = [NSDate dateWithTimeIntervalSince1970:timestamp];
//			NSLog(@"WI: Weather Time (forecast): %@", self.localWeatherTime);
		}

		// clear the current forecast
		[self.currentCondition setObject:[NSMutableArray arrayWithCapacity:6] forKey:@"forecast"];
		NSLog(@"WI: Successfully loaded forecast.");
	}
	else if ([elementName isEqualToString:@"yweather:wind"])
	{
		NSString* chill = [attributeDict objectForKey:@"chill"];
		[self.currentCondition setValue:[NSNumber numberWithInt:[chill intValue]] forKey:@"chill"];	
//		NSLog(@"WI: Chill: %@", chill);
	}
	else if ([elementName isEqualToString:@"yweather:location"])
	{
		NSString* city = self.city;

		if (city == nil)
			city = [attributeDict objectForKey:@"city"];

		[self.currentCondition setValue:city forKey:@"city"];
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

		NSMutableArray* arr = [self.currentCondition objectForKey:@"forecast"];
		if (arr == nil)
		{
			arr = [NSMutableArray arrayWithCapacity:7];
			[self.currentCondition setValue:arr forKey:@"forecast"];
		}

		[arr addObject:forecast];
	}
	else if ([elementName isEqualToString:@"yweather:condition"])
	{
		self.temp = [attributeDict objectForKey:@"temp"];
		[self.currentCondition setValue:[NSNumber numberWithInt:[self.temp intValue]] forKey:@"temp"];
//		NSLog(@"WI: Temp: %@", self.temp);

		self.code = [attributeDict objectForKey:@"code"];
		[self.currentCondition setValue:[NSNumber numberWithInt:[self.code intValue]] forKey:@"code"];

		NSString* desc = [attributeDict objectForKey:@"text"];
		[self.currentCondition setValue:desc forKey:@"description"];

//		NSLog(@"WI: Code: %@", self.code);

		if (!self.useLocalTime)
		{
			NSString* str = [attributeDict objectForKey:@"date"];
			NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
	                [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
       			[df setDateFormat:@"EEE, dd MMM yyyy h:mm a z"];
			self.localWeatherTime = [df dateFromString:str];
//			NSLog(@"WI: Weather Time (datafeed): %@", self.localWeatherTime);
		}

		NSLog(@"WI: Successfully loaded current condition.");
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

- (BOOL) isWeatherIcon:(NSString*) displayIdentifier
{
	if ([displayIdentifier isEqualToString:self.bundleIdentifier])
	{
		// make sure to reload the theme here
		[self loadTheme];
		return self.showWeatherIcon;
	}

	return false;
}

- (BOOL) showStatusBarWeather
{
	return (self.showStatusBarTemp || self.showStatusBarImage);
}

- (void) updateNightSetting
{
	BOOL night = false;
	if (self.localWeatherTime && self.sunrise && self.sunset)
	{
		NSDate* weatherDate = self.localWeatherTime;

		NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
		[df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
		[df setDateFormat:@"dd MMM yyyy HHmm"];

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

		NSDate* sunriseDate = [df dateFromString:sunriseFullDateStr];
		NSDate* sunsetDate = [df dateFromString:sunsetFullDateStr];

//		NSLog(@"WI: Sunset/Sunrise:%@, %@", sunriseDate, sunsetDate);
		night = ([weatherDate compare:sunriseDate] == NSOrderedAscending ||
				[weatherDate compare:sunsetDate] == NSOrderedDescending);
	}

	self.isNight = night;
	[self.currentCondition setValue:[NSNumber numberWithBool:night] forKey:@"night"];
//	NSLog(@"WI: Night? %d", self.isNight);
}

- (UIImage*) createIndicator:(int) mode
{
	NSString* t = [self.temp stringByAppendingString: @"\u00B0"];

	UIImage* image = [self findWeatherImage:@"weatherstatus"];
	// save the status bar image
	if (!image)
		image = [self findWeatherImage:@"weather"];

	UIFont* font = [UIFont boldSystemFontOfSize:13];
	CGSize tempSize = CGSizeMake(0, 20);
        CGSize sbSize = CGSizeMake(0, 20);

	NSString* style = (mode == 0 ? self.statusBarTempStyle : self.statusBarTempStyleFSO);

        if (self.showStatusBarTemp)
	{
	        tempSize = [t sizeWithStyle:style forWidth:40];
                sbSize.width += tempSize.width;
	}

        if (self.showStatusBarImage && image)
                sbSize.width += ceil(image.size.width * self.statusBarImageScale);

        UIGraphicsBeginImageContext(sbSize);

        if (self.showStatusBarTemp)
        {
                [t drawAtPoint:CGPointMake(0, 0) withStyle:style];
        }

        if (self.showStatusBarImage && image)
        {
        	float width = image.size.width * self.statusBarImageScale;
                float height = image.size.height * self.statusBarImageScale;
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
		float width = weatherImage.size.width * self.imageScale;
		float height = weatherImage.size.height * self.imageScale;
	        CGRect iconRect = CGRectMake((size.width - width) / 2, self.imageMarginTop, width, height);
		[weatherImage drawInRect:iconRect];
	}

	NSString* t = [self.temp stringByAppendingString: @"\u00B0"];
	NSString* style = [NSString stringWithFormat:(self.isNight ? self.tempStyleNight : self.tempStyle), (int)size.width];
       	[t drawAtPoint:CGPointMake(0, 0) withStyle:style];

	UIImage* icon = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	return icon;
}

- (void) updateIcon
{
	self.weatherIcon = [self createIcon];

	SBIconController* iconController = [$SBIconController sharedInstance];
	if (self.weatherIcon != nil && iconController)
	{
		NSLog(@"WI: Refreshing icon...");

	        // now force the icon to refresh
	        if (SBIconModel* model = MSHookIvar<SBIconModel*>(iconController, "_iconModel"))
		{
			if (SBIcon* applicationIcon = [model iconForDisplayIdentifier:self.bundleIdentifier])
			{
		        	[model reloadIconImageForDisplayIdentifier:self.bundleIdentifier];
	
				if ($SBImageCache != nil)
			        	if (SBImageCache* cache = MSHookIvar<SBImageCache*>(model, "_iconImageCache"))
						if ([cache respondsToSelector:@selector(removeImageForKey:)])
							[cache removeImageForKey:self.bundleIdentifier];

				if (UIImageView* imageView = MSHookIvar<UIImageView*>(applicationIcon, "_image"))
				{
					imageView.bounds = CGRectMake(0, 0, self.weatherIcon.size.width, self.weatherIcon.size.height);
					imageView.image = self.weatherIcon;
					[imageView setNeedsDisplay];
				}
			}
		}

//		NSLog(@"WI: Done refreshing icon.");
	}
}

- (void) updateIndicator
{
	self.statusBarIndicator = [self createIndicator:0];
	self.statusBarIndicatorFSO = [self createIndicator:1];

	if (SBStatusBarController* statusBarController = [$SBStatusBarController sharedStatusBarController])
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
//		NSLog(@"WI: Done refreshing indicator.");
	}
}

- (void) updateWeatherIcon
{
	[self updateNightSetting];

	if (self.showWeatherIcon)
		[self updateIcon];

	// now the status bar image
	if (self.showStatusBarWeather)
		[self updateIndicator];

	if (SBIconController* iconController = [$SBIconController sharedInstance])
	{
		if (SBIconModel* model = MSHookIvar<SBIconModel*>(iconController, "_iconModel"))
		{
			if (SBIcon* applicationIcon = [model iconForDisplayIdentifier:self.bundleIdentifier])
			{
				if (self.showWeatherBadge)
				{
					[applicationIcon setBadge:[self.temp stringByAppendingString: @"\u00B0"]];
				}
				else
				{
			        	if (SBIconBadge* badge = MSHookIvar<SBIconBadge*>(applicationIcon, "_badge"))
			        		if (NSString* badgeStr = MSHookIvar<NSString*>(badge, "_badge"))
							if ([badgeStr hasSuffix:@"\u00B0"])
								[applicationIcon setBadge:nil];
				}
			}
		}
	}
	
	// save the current condition
	NSString* iconPath = [self findWeatherImagePath:@"weatherstatus"];
	if (iconPath == nil)
		iconPath = [self findWeatherImagePath:@"weather"];
	[self.currentCondition setValue:iconPath forKey:@"icon"];

	if (self.localWeatherTime != nil)
		[self.currentCondition setValue:[NSNumber numberWithDouble:self.localWeatherTime.timeIntervalSince1970] forKey:@"timestamp"];

	[self.currentCondition writeToFile:conditionPath atomically:YES];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"WIWeatherUpdatedNotification" object:self userInfo:self.currentCondition];
}

- (BOOL) _refresh
{
	// reparse the preferences
	[self loadPreferences];

	if (!self.location)
	{
		NSLog(@"WI: No location set.");
		return false;
	}

	NSLog(@"WI: Refreshing weather for %@...", self.location);

	NSString* yahooStr = [NSString stringWithFormat:@"http://weather.yahooapis.com/forecastrss?p=%@&u=%@", self.location, (self.isCelsius ? @"c" : @"f")];
	NSURL* yahooURL = [NSURL URLWithString:yahooStr];
	NSXMLParser* parser = [[NSXMLParser alloc] initWithContentsOfURL:yahooURL];
	[parser setDelegate:self];
	[parser parse];
	[parser release];

	NSString* urlStr = @"http://iphone-wu.apple.com/dgw?imei=B7693A01-F383-4327-8771-501ABD85B5C1&apptype=weather&t=4";
	NSURL* url = [NSURL URLWithString:urlStr];
	NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url];
	req.HTTPMethod = @"POST";
	NSString* body = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?><request devtype=\"Apple iPhone v2.2\" deployver=\"Apple iPhone v2.2\" app=\"YGoiPhoneClient\" appver=\"1.0.0.5G77\" api=\"weather\" apiver=\"1.0.0\" acknotification=\"0000\"><query id=\"30\" timestamp=\"0\" type=\"getforecastbylocationid\"><list><id>%@</id></list><language>en_US</language><unit>%@</unit></query></request>", self.location, (self.isCelsius ? @"c" : @"f")];
	req.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];
	[req setValue:@"Apple iPhone v2.2 Weather v1.0.0.5G77" forHTTPHeaderField:@"User-Agent"];
	[req setValue:@"*/*" forHTTPHeaderField:@"Accept"];
	[req setValue:@"en-us" forHTTPHeaderField:@"Accept-Language"];
	[req setValue:@"" forHTTPHeaderField:@"Accept-Encoding"];
	[req setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
	NSData* data = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];

	parser = [[NSXMLParser alloc] initWithData:data];
	[parser setDelegate:self];
	[parser parse];
	[parser release];

	if (self.showFeelsLike)
	{
		if (NSNumber* n = [self.currentCondition objectForKey:@"chill"])
		{
			self.temp = n.stringValue;
			[self.currentCondition setValue:n forKey:@"temp"];
		}
	}

	return true;
}

- (void) refreshInBackground
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	if ([lock tryLock])
	{
		if ([self _refresh])
			[self performSelectorOnMainThread:@selector(updateWeatherIcon) withObject:nil waitUntilDone:YES];
		[lock unlock];
	}
	else
	{
		NSLog(@"LI:Weather: Already refreshing.");
	}

	[pool release];
}

- (void) refresh
{
	if (!self.enabled)
	{
		NSLog(@"WI: Disabled.  No refresh.");
		return;
	}

/*
	if (!self.lockInfo && !self.showWeatherIcon && !self.showWeatherBadge && !self.showStatusBarWeather)
	{
		NSLog(@"WI: No weather views are active.  No refresh.");
		return;
	}
*/

	if (SBTelephonyManager* mgr = [$SBTelephonyManager sharedTelephonyManager])
	{
		if (mgr.inCall || mgr.incomingCallExists || mgr.activeCallExists || mgr.outgoingCallExists)
		{
			NSLog(@"WI: On a call.  Skipping refresh.");
			return;
		}
	}

	if ((self.showWeatherIcon && !self.weatherIcon) || (self.showStatusBarWeather && !self.statusBarIndicator && !self.statusBarIndicatorFSO))
		[self performSelectorOnMainThread:@selector(updateWeatherIcon) withObject:nil waitUntilDone:YES];

	[self performSelectorInBackground:@selector(refreshInBackground) withObject:nil];
}


- (UIImage*) icon
{
	if (self.weatherIcon == nil)
	{
//		NSLog(@"WI: Creating temporary icon.");
		return [self createIcon];
	}

	return self.weatherIcon;
}

- (UIImage*) statusBarIndicator:(int)mode
{
	return (mode == 0 ? self.statusBarIndicator : self.statusBarIndicatorFSO);
}

@end
/*
 *  WeatherIcon.mm
 *  
 *
 *  Created by David Ashman on 1/12/09.
 *  Copyright 2009 David Ashman. All rights reserved.
 *
 */

#import <UIKit/UIKit.h>
 
static Class $WIInstalledApplicationIcon;
static Class $WIApplicationIcon;
static Class $WIBookmarkIcon;
static Class $SBStatusBarContentsView;

static WeatherIconController* _controller;
static SBStatusBarContentView* _sb0;
static SBStatusBarContentView* _sb1;
static NSTimeInterval lastPrefsUpdate = 0;

@interface SBStatusBarContentView3 : SBStatusBarContentView
-(BOOL) showOnLeft;
-(BOOL) isVisible;
@end

MSHook(void, undimScreen, SBAwayController *self, SEL sel)
{
	// do the unscatter
	_undimScreen(self, sel);

	[_controller startTimer];
}

MSHook(void, dimScreen, SBAwayController *self, SEL sel, BOOL b)
{
	// do the unscatter
	_dimScreen(self, sel, b);

	[_controller stopTimer];
}

static float findStart(SBStatusBarContentsView* self, const char* varName, const char* visibleVarName, float currentStart)
{
	if (SBStatusBarContentView3* icon  = MSHookIvar<NSMutableArray*>(self, varName))
	{
//		BOOL visible  = MSHookIvar<BOOL>(icon, visibleVarName);
//		NSLog(@"WI: findStart: Icon %@ is visible? %d", icon, visible);	
		return (icon.superview == self && icon.frame.origin.x > 0 && icon.isVisible && icon.frame.origin.x < currentStart ? icon.frame.origin.x : currentStart);
	}

	return currentStart;
}

static void updateWeatherView(SBStatusBarContentsView* self)
{	
	SBStatusBar* sb = [self statusBar];
	int mode = [sb mode];

	if (UIImage* indicator = [_controller statusBarIndicator:mode])
	{
		SBStatusBarContentView* weatherView = (mode == 0 ? _sb0 : _sb1);
		if (weatherView == nil)
		{
//			NSLog(@"WI: Creating new weather indicator view for mode %d", mode);
			Class sbClass = objc_getClass("SBStatusBarContentView");
			weatherView = [[[sbClass alloc] initWithContentsView:self] autorelease];
			weatherView.tag = -1;
			weatherView.alpha = [$SBStatusBarContentsView contentAlphaForMode:mode];
			[weatherView setMode:mode];

			UIImageView* iv = [[[UIImageView alloc] initWithImage:indicator] autorelease];
			[weatherView addSubview:iv];

			if (mode == 0)
				_sb0 = [weatherView retain];
			else
				_sb1 = [weatherView retain];
		}

		BOOL landscape = (sb.orientation == 90 || sb.orientation == -90);
		float x = findStart(self, "_batteryView", "_showBatteryView", (landscape ? 480 : 320));
		x = findStart(self, "_batteryPercentageView", "_showBatteryPercentageView", x);
//		x = findStart(self, "_bluetoothView", "_showBluetoothView", x);
//		x = findStart(self, "_bluetoothBatteryView", "_showBluetoothBatteryView", x);

//		NSLog(@"WI: Moving weather view to %f", x - indicator.size.width - 3);	
		weatherView.frame = CGRectMake(x - indicator.size.width - 3, 0, indicator.size.width, indicator.size.height);	

		// clear the content view
		UIImageView* iv = [[weatherView subviews] objectAtIndex:0];
		if (iv.image != indicator)
		{
			iv.frame = CGRectMake(0, 0, indicator.size.width, indicator.size.height);
			iv.image = indicator;
		}

		if ([[self subviews] indexOfObject:weatherView] == NSNotFound)
		{
//			NSLog(@"WI: Adding weather view");
			[self addSubview:weatherView];
		}
	}
}

static void updateWeatherView(SBStatusBarContentView* view)
{
	if (!((SBStatusBarContentView3*)view).showOnLeft)
	{
		SBStatusBarContentsView* contents = MSHookIvar<SBStatusBarContentsView*>(view, "_contentsView");
		updateWeatherView(contents);
	}
}

MSHook(void, reflowContentViewsNow, SBStatusBarContentsView* self, SEL sel)
{	
//	NSLog(@"WI: reflowContentViewsNow");
	_reflowContentViewsNow(self, sel);
	updateWeatherView(self);
}

MSHook(void, btSetFrame, SBStatusBarContentView* self, SEL sel, CGRect rect)
{
	int mode = [self effectiveModeForImages];
	UIImage* indicator = [_controller statusBarIndicator:mode];
	float offset = (indicator == nil ? 0 : indicator.size.width + 2);
	_btSetFrame(self, sel, CGRectMake(rect.origin.x - offset, rect.origin.y, rect.size.width, rect.size.height));
}

MSHook(void, btbSetFrame, SBStatusBarContentView* self, SEL sel, CGRect rect)
{
	int mode = [self effectiveModeForImages];
	UIImage* indicator = [_controller statusBarIndicator:mode];
	float offset = (indicator == nil ? 0 : indicator.size.width + 2);
	_btbSetFrame(self, sel, CGRectMake(rect.origin.x - offset, rect.origin.y, rect.size.width, rect.size.height));
}

MSHook(void, indicatorSetFrame, SBStatusBarContentView* self, SEL sel, CGRect rect) 
{
	int mode = [self effectiveModeForImages];
	UIImage* indicator = [_controller statusBarIndicator:mode];
	float offset = (indicator == nil ? 0 : indicator.size.width + 2);
	_indicatorSetFrame(self, sel, CGRectMake(rect.origin.x - offset, rect.origin.y, rect.size.width, rect.size.height));
}

MSHook(void, reloadIndicators, SBStatusBarIndicatorsView *self, SEL sel) 
{
	_reloadIndicators(self, sel);

	int mode = [self effectiveModeForImages];
	UIImage* indicator = [_controller statusBarIndicator:mode];

//	NSLog(@"WI: Reloading indicators");
	if (indicator)
	{
		UIImageView* weatherView = [[UIImageView alloc] initWithImage:indicator];
		NSArray* views = [self subviews];
		if (views.count > 0)
		{
			// if there are already indicators, move the weather view
			UIView* last = [views objectAtIndex:views.count - 1];
			weatherView.frame = CGRectMake(last.frame.origin.x + last.frame.size.width + 6, 0, weatherView.frame.size.width, weatherView.frame.size.height);
		}

		[self addSubview:weatherView];
		self.frame = CGRectMake(0, 0, weatherView.frame.origin.x + weatherView.frame.size.width, 20);

//		NSLog(@"WI: weatherView: %f, %f, %f, %f", weatherView.frame.origin.x, weatherView.frame.origin.y, weatherView.frame.size.width, weatherView.frame.size.height); 
//		NSLog(@"WI: indicators: %f, %f, %f, %f", self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height); 
	}
}

MSHook(void, deactivated, SBApplication *self, SEL sel) 
{
	_deactivated(self, sel);

	BOOL refresh = false;

	if ([self.displayIdentifier isEqualToString:@"com.apple.Preferences"])
	{
		NSFileManager* fm = [NSFileManager defaultManager];
                if (NSDictionary* attrs = [fm fileAttributesAtPath:prefsPath traverseLink:true])
                {
                        if (NSDate* modDate = [attrs objectForKey:NSFileModificationDate])
                        {
                                if ([modDate timeIntervalSinceReferenceDate] > lastPrefsUpdate)
                                {
					lastPrefsUpdate = [modDate timeIntervalSinceReferenceDate];
					refresh = true;
					[_controller loadPreferences];
				}
			}
		}
	}

	if ([self.displayIdentifier isEqualToString:@"com.apple.weather"] ||
	    [_controller isWeatherIcon:self.displayIdentifier])
	{
		// refresh the weather model
		refresh = true;
	}

	if (refresh)
		[_controller manualRefresh];
}

MSHook(id, initWithApplication, SBApplicationIcon *self, SEL sel, id app) 
{
	self = _initWithApplication(self, sel, app);

	if ([_controller isWeatherIcon:self.displayIdentifier])
	{
		NSLog(@"WI: Application: %@.", self.displayIdentifier);
		if ([self class] == objc_getClass("SBInstalledApplicationIcon"))
			object_setClass(self, $WIInstalledApplicationIcon);
		else
			object_setClass(self, $WIApplicationIcon);
	}

	return self;
}

MSHook(id, getCachedImagedForIcon, SBIconModel *self, SEL sel, SBIcon* icon, BOOL small) 
{
	if (!small && [_controller isWeatherIcon:icon.displayIdentifier])
	{
		return _controller.icon;
	}

	return _getCachedImagedForIcon(self, sel, icon, small);
}

MSHook(id, initWithWebClip, SBBookmarkIcon *self, SEL sel, id clip) 
{
	self = _initWithWebClip(self, sel, clip);

	if ([_controller isWeatherIcon:self.displayIdentifier])
	{
		NSLog(@"WI: Application: %@.", self.displayIdentifier);
		object_setClass(self, $WIBookmarkIcon);
	}

	return self;
}

static id weatherIcon(SBIcon *self, SEL sel) 
{
	return _controller.icon;
}

static void undimScreenOnNotif(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
//	NSLog(@"WI:Display: undim");
	[_controller startTimer];
}

static void dimScreenOnNotif(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
//	NSLog(@"WI:Display: undim");
	[_controller stopTimer];
}

static void updatePrefs(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
//	NSLog(@"WI:Display: undim");
	[_controller stopTimer];
}

#define Hook(cls, sel, imp) \
        _ ## imp = MSHookMessage($ ## cls, @selector(sel), &$ ## imp)

extern "C" void TweakInit() {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	if (objc_getClass("SpringBoard") == nil)
		return;

	weatherIconBundle = [NSBundle bundleWithPath:@"/Library/WeatherIcon"];

	$WIApplicationIcon = objc_allocateClassPair(objc_getClass("SBApplicationIcon"), "WIApplicationIcon", 0);
	class_replaceMethod($WIApplicationIcon, @selector(icon), (IMP)&weatherIcon, "@@:");
	objc_registerClassPair($WIApplicationIcon);

	$WIInstalledApplicationIcon = objc_allocateClassPair(objc_getClass("SBInstalledApplicationIcon"), "WIInstalledApplicationIcon", 0);
	class_replaceMethod($WIInstalledApplicationIcon, @selector(icon), (IMP)&weatherIcon, "@@:");
	objc_registerClassPair($WIInstalledApplicationIcon);

	$WIBookmarkIcon = objc_allocateClassPair(objc_getClass("SBBookmarkIcon"), "WIBookmarkIcon", 0);
	class_replaceMethod($WIBookmarkIcon, @selector(icon), (IMP)&weatherIcon, "@@:");
	objc_registerClassPair($WIBookmarkIcon);

	Class $SBAwayView = objc_getClass("SBAwayView");
	Class $SBIconModel = objc_getClass("SBIconModel");
	Class $SBIconController = objc_getClass("SBIconController");
	Class $SBBookmarkIcon = objc_getClass("SBBookmarkIcon");
	Class $SBApplicationIcon = objc_getClass("SBApplicationIcon");
	Class $SBApplication = objc_getClass("SBApplication");
	Class $SBStatusBarBluetoothView = objc_getClass("SBStatusBarBluetoothView");
	Class $SBStatusBarBluetoothBatteryView = objc_getClass("SBStatusBarBluetoothBatteryView");
	Class $SBStatusBarIndicatorView = objc_getClass("SBStatusBarIndicatorView");
	Class $SBStatusBarIndicatorsView = objc_getClass("SBStatusBarIndicatorsView");
	$SBStatusBarContentsView = objc_getClass("SBStatusBarContentsView");
	
	_controller = [[[WeatherIconController alloc] init] retain];

	// MSHookMessage is what we use to redirect the methods to our own
	Hook(SBApplication, deactivated, deactivated);
	Hook(SBApplicationIcon, initWithApplication:, initWithApplication);
	Hook(SBBookmarkIcon, initWithWebClip:, initWithWebClip);
	Hook(SBStatusBarIndicatorsView, reloadIndicators, reloadIndicators);
	Hook(SBIconModel, getCachedImagedForIcon:smallIcon:, getCachedImagedForIcon);

	// only hook these in 3.0
	if ($SBStatusBarIndicatorsView == nil)
	{
		Hook(SBStatusBarIndicatorView, setFrame:, indicatorSetFrame);
		Hook(SBStatusBarBluetoothView, setFrame:, btSetFrame);
		Hook(SBStatusBarBluetoothBatteryView, setFrame:, btbSetFrame);
		Hook(SBStatusBarContentsView, reflowContentViewsNow, reflowContentViewsNow);

	        CFNotificationCenterAddObserver(
       	        	CFNotificationCenterGetDarwinNotifyCenter(), //center
	                NULL, // observer
	                undimScreenOnNotif, // callback
	                (CFStringRef)@"SBDidTurnOnDisplayNotification",
	                NULL, // object
	                CFNotificationSuspensionBehaviorHold);

	        CFNotificationCenterAddObserver(
       	        	CFNotificationCenterGetDarwinNotifyCenter(), //center
	                NULL, // observer
	                dimScreenOnNotif, // callback
	                (CFStringRef)@"SBDidTurnOffDisplayNotification",
	                NULL, // object
	                CFNotificationSuspensionBehaviorHold);
	}
	else
	{
		Hook(SBAwayController, undimScreen, undimScreen);
		Hook(SBAwayController, dimScreen:, dimScreen);
	}
	
	[pool release];
}
