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


@interface WeatherIconController : NSObject
{
	BOOL refreshing;
	BOOL themeLoaded;
	BOOL prefsLoaded;
	BOOL weatherPrefsLoaded;
	int failedCount;
}

	// image caches
@property (nonatomic, retain) UIImage* statusBarIndicator;
@property (nonatomic, retain) UIImage* statusBarIndicatorFSO;
@property (nonatomic, retain) UIImage* icon;

	// current temp info
@property (nonatomic, retain) NSString* temp;
@property (nonatomic, retain) NSString* code;
@property (nonatomic, retain) NSString* sunrise;
@property (nonatomic, retain) NSString* sunset;
@property (nonatomic, retain) NSTimeZone* timeZone;
@property (nonatomic, retain) NSDate* localWeatherTime;
@property (nonatomic, retain) BOOL isNight;

	// refresh date info
@property (nonatomic, retain) NSDate* nextRefreshTime;
@property (nonatomic, retain) NSDate* lastUpdateTime;


@property (nonatomic, retain) NSDictionary* theme;
@property (nonatomic, retain) NSDictionary* weatherPreferences;
@property (nonatomic, retain) NSMutableDictionary* preferences;
@property (nonatomic, retain) NSMutableDictionary* currentCondition;

- (id)init;
- (BOOL)isWeatherIcon:(NSString*) displayIdentifier;
- (void)checkPreferences;
- (void)setNeedsRefresh;
- (void)refresh;
- (void)refreshNow;
- (NSDate*)lastUpdateTime;
- (UIImage*)statusBarIndicator:(int) mode;
- (void)dealloc;

@end

static Class $SBStatusBarController = objc_getClass("SBStatusBarController");
static Class $SBIconController = objc_getClass("SBIconController");

static NSString* prefsPath = @"/var/mobile/Library/Preferences/com.ashman.WeatherIcon.plist";
static NSString* conditionPath = @"/var/mobile/Library/Preferences/com.ashman.WeatherIcon.Condition.plist";
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

static WeatherIconController* instance = nil;

@implementation WeatherIconController

- (NSString*) bundleIdentifier
{
	NSString* id = [self.preferences objectForKey:@"WeatherBundleIdentifier"])

	if (id != nil && [id isEqualToString:@"Custom"])
		if (NSString* custom = [self.preferences objectForKey:@"CustomWeatherBundleIdentifier"])
			return custom;

	return id;
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
	self.sunrise = nil;
	self.sunset = nil;
	self.timeZone = nil;
	self.localWeatherTime = nil;
}

- (void) parseWeatherPreferences
{
	if (weatherPrefsLoaded)
		return;


	if (dict)
	{
		NSLog(@"WI: Parsing weather preferences...");
		isCelsius = [[dict objectForKey:@"Celsius"] boolValue];

//		NSNumber* activeCity = [dict objectForKey:@"ActiveCity"];
	}

	weatherPrefsLoaded = true;
}

- (void) loadPreferences:(BOOL) force
{
	if (!force && prefsLoaded)
		return;

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

	NSMutableDictionary current = [NSMutableDictionary dictionaryWithContentsOfFile:conditionPath];
	if (current == nil)
		current = [NSMutableDictionary dictionaryWithCapacity:5];
	
	self.currentCondition = current;

	NSDictionary* dict = nil;

	NSBundle* bundle = [NSBundle mainBundle];
	if (NSString* themePrefs = [bundle pathForResource:@"com.ashman.WeatherIcon" ofType:@"plist"])
		dict = [NSDictionary dictionaryWithContentsOfFile:themePrefs];

	if (dict == nil)
		dict = [NSDictionary dictionary];

	self.theme = dict;

	prefsLoaded = true;
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

- (BOOL) showWeatherIcon
{
	if (NSNumber* v = [self.preferences objectForKey:@"ShowWeatherIcon"])
		return [v boolValue];

	return true;
}

- (BOOL) showStatusBarImage
{
	if (NSNumber* v = [self.preferences objectForKey:@"ShowStatusBarImage"])
		return [v boolValue];
	
	return false;
}

- (BOOL) showStatusBarTemp
{
	if (NSNumber* v = [self.preferences objectForKey:@"ShowStatusBarTemp"])
		return [v boolValue];
	
	return false;
}

- (NSTimeInterval) refreshInterval
{
	if (NSNumber* interval = [prefs objectForKey:@"RefreshInterval"])
		return ([interval intValue] * 60);

	return 900;
}

- (void) loadTheme
{
	if (themeLoaded)
		return;

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
	failedCount = 0;

	self.temp = defaultTemp;
	self.code = defaultCode;
	self.nextRefreshTime = [NSDate date];
	refreshing = false;

	return self;
}

- (NSString*) mapImage:(NSString*) prefix
{
	// no mappings
	if (self.mappings == nil)
		return nil;

	NSString* suffix = (night ? @"_night" : @"_day");	
	if (NSString* mapped = [self.mappings objectForKey:[NSString stringWithFormat:@"%@%@%@", prefix, self.code, suffix]])
		return mapped;

	if (NSString* mapped = [self.mappings objectForKey:[NSString stringWithFormat:@"%@%@", prefix, self.code]])
		return mapped;

	if (NSString* mapped = [self.mappings objectForKey:[NSString stringWithFormat:@"%@%@", prefix, suffix]])
		return mapped;

	if (NSString* mapped = [self.mappings objectForKey:prefix])
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
	if (useLocalTime && [elementName isEqualToString:@"result"])
	{
		NSDate* tmp = localWeatherTime;
		double timestamp = [[attributeDict objectForKey:@"timestamp"] doubleValue];
		localWeatherTime = [[NSDate dateWithTimeIntervalSince1970:timestamp] retain];
		[tmp release];
	}
	else if (showFeelsLike && [elementName isEqualToString:@"wind"]))
	{
		NSString* tmp = temp;
		temp = [[attributeDict objectForKey:@"chill"] retain];
		[tmp release];

		[currentCondition setValue:[NSNumber numberWithInt:[temp intValue]] forKey:@"temp"];
		NSLog(@"WI: Temp: %@", temp);
	}
	else if ([elementName isEqualToString:@"location"])
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
	if ([displayIdentifier isEqualToString:bundleIdentifier])
	{
		// make sure to reload the theme here
		[self loadTheme];
		return showWeatherIcon;
	}

	return false;
}

- (BOOL) showStatusBarWeather
{
	return (showStatusBarTemp || showStatusBarImage);
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
	// reparse the preferences
	[self loadPreferences:true];

	if (!location)
	{
		NSLog(@"WI: No location set.");
		return false;
	}

	// clear the current forecast
	[currentCondition removeObjectForKey:@"forecast"];

	NSLog(@"WI: Refreshing weather for %@...", location);
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

	NSXMLParser* parser = [[NSXMLParser alloc] initWithData:data];
	[parser setDelegate:self];
	[parser parse];
	[parser release];

	if (debug)
		NSLog(@"WI:Debug: Done refreshing weather.");

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
static Class $SBTelephonyManager;

static WeatherIconController* _controller;
static SBStatusBarContentView* _sb0;
static SBStatusBarContentView* _sb1;

@interface SBStatusBarContentView3 : SBStatusBarContentView
-(BOOL) showOnLeft;
-(BOOL) isVisible;
@end

static void refreshController(BOOL now)
{
	SBTelephonyManager* mgr = [$SBTelephonyManager sharedTelephonyManager];
//	NSLog(@"WI: Telephony: %d, %d, %d", mgr.inCall, mgr.incomingCallExists, mgr.activeCallExists);
	if (mgr != nil && !mgr.inCall && !mgr.incomingCallExists && !mgr.activeCallExists && !mgr.outgoingCallExists)
	{
		if (now)
			[_controller refreshNow];
		else
			[_controller refresh];
	}
}

MSHook(void, updateInterface, SBAwayView *self, SEL sel)
{
	_updateInterface(self, sel);

	// refresh the weather model
	BOOL refresh = !self.dimmed;

	if (!refresh)
	{
		// check AC
		Class cls = objc_getClass("SBUIController");
		SBUIController* sbui = [cls sharedInstance];
		refresh = [sbui isOnAC];
	}

//	NSLog(@"WI: Refreshing? %d", refresh);
	if (refresh)
		refreshController(false);
}

MSHook(void, unscatter, SBIconController *self, SEL sel, BOOL b, double time) 
{
	// do the unscatter
	_unscatter(self, sel, b, time);

//	NSLog(@"WI: Refreshing on unscatter.");

	// refresh the weather model
	if (_controller.lastUpdateTime == nil)
		refreshController(false);
}

static id weatherIcon(SBIcon *self, SEL sel) 
{
	NSLog(@"WI: Calling icon method for %@", self.displayIdentifier);
	return [_controller icon];
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
			Class sbClass = objc_getClass("SBStatusBarContentView");
			weatherView = [[[sbClass alloc] initWithContentsView:self] autorelease];
			weatherView.tag = -1;
			[weatherView setAlpha:[$SBStatusBarContentsView contentAlphaForMode:mode]];
			[weatherView setMode:mode];

			UIImageView* iv = [[[UIImageView alloc] initWithImage:indicator] autorelease];
			[weatherView addSubview:iv];

			if (mode == 0)
				_sb0 = [weatherView retain];
			else
				_sb1 = [weatherView retain];
		}

		float x = findStart(self, "_batteryView", "_showBatteryView", 480);
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

	NSLog(@"WI: Reloading indicators");
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

	if ([self.displayIdentifier isEqualToString:@"com.apple.weather"] ||
	    [_controller isWeatherIcon:self.displayIdentifier])
	{
		// refresh the weather model
		refreshController(true);
	}

	if ([self.displayIdentifier isEqualToString:@"com.apple.Preferences"])
	{
		[_controller checkPreferences];
	}
}

MSHook(id, initWithApplication, SBApplicationIcon *self, SEL sel, id app) 
{
	self = _initWithApplication(self, sel, app);

	if ([_controller isWeatherIcon:self.displayIdentifier])
	{
		NSLog(@"WI: Replacing icon for %@.", self.displayIdentifier);
		if ([self class] == objc_getClass("SBInstalledApplicationIcon"))
			object_setClass(self, $WIInstalledApplicationIcon);
		else
			object_setClass(self, $WIApplicationIcon);
	}

	return self;
}

MSHook(id, initWithWebClip, SBBookmarkIcon *self, SEL sel, id clip) 
{
	self = _initWithWebClip(self, sel, clip);

	if ([_controller isWeatherIcon:self.displayIdentifier])
	{
		NSLog(@"WI: Replacing icon for %@.", self.displayIdentifier);
		object_setClass(self, $WIBookmarkIcon);
	}

	return self;
}

#define Hook(cls, sel, imp) \
        _ ## imp = MSHookMessage($ ## cls, @selector(sel), &$ ## imp)

extern "C" void TweakInit() {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	if (objc_getClass("SpringBoard") == nil)
		return;

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
	Class $SBIconController = objc_getClass("SBIconController");
	Class $SBBookmarkIcon = objc_getClass("SBBookmarkIcon");
	Class $SBApplicationIcon = objc_getClass("SBApplicationIcon");
	Class $SBApplication = objc_getClass("SBApplication");
	Class $SBStatusBarBluetoothView = objc_getClass("SBStatusBarBluetoothView");
	Class $SBStatusBarBluetoothBatteryView = objc_getClass("SBStatusBarBluetoothBatteryView");
	Class $SBStatusBarIndicatorView = objc_getClass("SBStatusBarIndicatorView");
	Class $SBStatusBarIndicatorsView = objc_getClass("SBStatusBarIndicatorsView");
	$SBStatusBarContentsView = objc_getClass("SBStatusBarContentsView");
	$SBTelephonyManager = objc_getClass("SBTelephonyManager");
	
	NSLog(@"WI: Init weather controller.");
	_controller = [[[WeatherIconController alloc] init] retain];

	// MSHookMessage is what we use to redirect the methods to our own
	Hook(SBIconController, unscatter:startTime:, unscatter);
	Hook(SBApplication, deactivated), deactivated);
	Hook(SBApplicationIcon, initWithApplication:, initWithApplication);
	Hook(SBBookmarkIcon, initWithWebClip:, initWithWebClip);
	Hook(SBStatusBarIndicatorsView, reloadIndicators, reloadIndicators);
	Hook(SBAwayView, updateInterface, updateInterface);

	// only hook these in 3.0
	if ($SBStatusBarIndicatorsView == nil)
	{
		Hook(SBStatusBarIndicatorView, setFrame:, indicatorSetFrame);
		Hook(SBStatusBarBluetoothView, setFrame:, btSetFrame);
		Hook(SBStatusBarBluetoothBatteryView, setFrame:, btbSetFrame);
		Hook(SBStatusBarContentsView, reflowContentViewsNow, reflowContentViewsNow);
	}
	
	[pool release];
}
