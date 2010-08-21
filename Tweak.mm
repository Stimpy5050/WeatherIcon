#import <substrate.h>
#import <notify.h>
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
#import <SpringBoard/SBAwayController.h>
#import <UIKit/UIStringDrawing.h>
#import <UIKit/UIKit.h>
#import <Foundation/NSObjCRuntime.h>
#include "Constants.h"

extern "C" void UIGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale);


@interface UIScreen (WIAdditions)

-(double) scale;

@end

@interface UIImage (WIAdditions)
- (id)wi_initWithContentsOfResolutionIndependentFile:(NSString *)path;
+ (UIImage*)wi_imageWithContentsOfResolutionIndependentFile:(NSString *)path;
@end

@implementation UIImage (WIAdditions)

- (id)wi_initWithContentsOfResolutionIndependentFile:(NSString *)path
{
        double scale = ( [[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? (double)[[UIScreen mainScreen] scale] : 1.0);
        if ( scale != 1.0)
        {
                NSString *path2x = [[path stringByDeletingLastPathComponent]
                        stringByAppendingPathComponent:[NSString stringWithFormat:@"%@@2x.%@",
                                [[path lastPathComponent] stringByDeletingPathExtension],
                                [path pathExtension]]];

                if ( [[NSFileManager defaultManager] fileExistsAtPath:path2x] )
                {
                        return [self initWithContentsOfFile:path2x];
                }
        }

        return [self initWithContentsOfFile:path];
}

+ (UIImage*) wi_imageWithContentsOfResolutionIndependentFile:(NSString *)path
{
        return [[[UIImage alloc] wi_initWithContentsOfResolutionIndependentFile:path] autorelease];
}

@end

@interface WeatherIconController : NSObject
{
	NSConditionLock* lock;
}

	// image caches
@property (nonatomic, retain) UIImage* statusBarIndicator;
@property (nonatomic, retain) UIImage* statusBarIndicatorFSO;
@property (nonatomic, retain) UIImageView* statusBarIndicatorView;
@property (nonatomic, retain) UIImageView* statusBarIndicatorFSOView;
@property (nonatomic, retain) UIImage* weatherIcon;

	// refresh date info
@property (nonatomic, retain) NSDictionary* theme;
@property (nonatomic, retain) NSDictionary* currentCondition;
@property (nonatomic, retain) NSMutableDictionary* preferences;
@property (nonatomic, retain) id dmc;


- (id)init;
- (BOOL)isWeatherIcon:(NSString*) displayIdentifier;
- (UIImage*)icon;
- (UIImage*)statusBarIndicator:(int) mode;
- (UIImageView*)statusBarIndicatorView:(int) mode;

@end

static Class $SBStatusBarController = objc_getClass("SBStatusBarController");
static Class $SBUIController = objc_getClass("SBUIController");
static Class $SBApplicationIcon = objc_getClass("SBApplicationIcon");
static Class $SBIconController = objc_getClass("SBIconController");
static Class $SBIconModel = objc_getClass("SBIconModel");
static Class $SBImageCache = objc_getClass("SBImageCache");
static Class $SBTelephonyManager = objc_getClass("SBTelephonyManager");
static Class $SBAwayController = objc_getClass("SBAwayController");
static Class $UIStatusBarItem;

static NSBundle* springBoardBundle;
static NSBundle* weatherIconBundle;
static WeatherIconController* _controller;

static NSString* prefsPath = @"/var/mobile/Library/Preferences/com.ashman.WeatherIcon.plist";
static NSString* conditionPath = @"/var/mobile/Library/Caches/com.ashman.LibWeather.cache.plist";
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

@implementation WeatherIconController

// image cache
@synthesize statusBarIndicator, statusBarIndicatorFSO, weatherIcon;
@synthesize statusBarIndicatorView, statusBarIndicatorFSOView;

// preferences
@synthesize theme, preferences, currentCondition;
@synthesize dmc;

+(id) sharedInstance
{
	return _controller;
}

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

	if (NSString* themePrefs = [springBoardBundle pathForResource:@"com.ashman.WeatherIcon" ofType:@"plist"])
		[dict addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:themePrefs]];

	self.theme = dict;
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

- (void) loadPreferences
{
	NSString* bundleIdentifier = [_controller.bundleIdentifier retain];

	NSMutableDictionary* prefs = [NSMutableDictionary dictionaryWithContentsOfFile:prefsPath];
	if (prefs == nil)
	{
		prefs = [NSMutableDictionary dictionaryWithCapacity:10];
		[prefs setValue:[NSNumber numberWithBool:true] forKey:@"ShowWeatherIcon"];
		[prefs setValue:[NSNumber numberWithBool:false] forKey:@"ShowStatusBarImage"];
		[prefs setValue:[NSNumber numberWithBool:false] forKey:@"ShowStatusBarTemp"];
		[prefs setValue:@"com.apple.weather" forKey:@"WeatherBundleIdentifier"];
		[prefs writeToFile:prefsPath atomically:YES];
	}

	BOOL badge = self.showWeatherBadge;

	self.preferences = prefs;
	[self loadTheme];

	if (!self.showWeatherBadge && badge)
	{
	        SBIconModel* model = [$SBIconModel sharedInstance];
		SBApplicationIcon* applicationIcon = nil;
       		if ([model respondsToSelector:@selector(applicationIconForDisplayIdentifier:)])
			applicationIcon = [model applicationIconForDisplayIdentifier:self.bundleIdentifier];
		else
			applicationIcon = [model iconForDisplayIdentifier:self.bundleIdentifier];

		[applicationIcon setBadge:nil];
	}

	if (![bundleIdentifier isEqualToString:_controller.bundleIdentifier])
		[_controller resetWeatherIcon:bundleIdentifier];

	[bundleIdentifier release];
}

-(void) dealloc
{
	[lock release];
	[super dealloc];
}

-(void) initMessaging
{
	self.dmc = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.ashman.WeatherIcon"];
	[self.dmc runServerOnCurrentThread];
	[self.dmc registerForMessageName: @"currentStatusBarCondition" target: self selector: @selector(currentStatusBarCondition)];

}

- (id) init
{
	lock = [[NSConditionLock alloc] init];
	self.currentCondition = [NSDictionary dictionaryWithContentsOfFile:conditionPath];
	[self loadPreferences];

//	[self performSelectorOnMainThread:@selector(initMessaging) withObject:nil waitUntilDone:NO];
	[self initMessaging];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update:) name:@"LWWeatherUpdatedNotification" object:nil];

	return self;
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

        NSBundle* bundle = springBoardBundle;
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
	NSNumber* code = [self.currentCondition objectForKey:@"code"];
	NSNumber* night = [self.currentCondition objectForKey:@"night"];
	return [self findWeatherImagePath:prefix 
		code:(code ? code.stringValue : @"3200")
		night:(night ? night.boolValue : NO)];
}

- (UIImage*) findWeatherImage:(NSString*) prefix
{
	NSString* path = [self findWeatherImagePath:prefix];
	return (path ? [UIImage wi_imageWithContentsOfResolutionIndependentFile:path] : nil);
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

-(NSDictionary*) currentStatusBarCondition
{
	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:2];

	if (self.showStatusBarTemp)
	{
		NSNumber* temp = [self.currentCondition objectForKey:@"temp"];
		[dict setValue:[temp.stringValue stringByAppendingString: @"\u00B0"] forKey:@"temp"];
	}

	if (self.showStatusBarImage)
	{
		NSString* image = [self findWeatherImagePath:@"weatherstatus"];
		// save the status bar image
		if (!image)
			image = [self findWeatherImagePath:@"weather"];

		[dict setValue:image forKey:@"image"];
		[dict setValue:[NSNumber numberWithDouble:self.statusBarImageScale] forKey:@"imageScale"];
	}

	return dict;
}

- (UIImage*) createIndicator:(int) mode
{
	NSNumber* temp = [self.currentCondition objectForKey:@"temp"];
	NSString* t = [temp.stringValue stringByAppendingString: @"\u00B0"];

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
//	        tempSize = [t sizeWithStyle:style forWidth:40];
                sbSize.width += tempSize.width;
	}

        if (self.showStatusBarImage && image)
                sbSize.width += ceil(image.size.width * self.statusBarImageScale);

        UIGraphicsBeginImageContext(sbSize);

        if (self.showStatusBarTemp)
        {
//                [t drawAtPoint:CGPointMake(0, 0) withStyle:style];
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

	if (UIGraphicsBeginImageContextWithOptions!=NULL)
		UIGraphicsBeginImageContextWithOptions(size, NO, 0.0); 
	else 
		UIGraphicsBeginImageContext(size);

	if (bgIcon)
	{
		[bgIcon drawInRect:CGRectMake(0, 0, size.width, size.height)];	
	}

	if (weatherImage)
	{
		float width = weatherImage.size.width * self.imageScale;
		float height = weatherImage.size.height * self.imageScale;
	        CGRect iconRect = CGRectMake((size.width - width) / 2, self.imageMarginTop, width, height);
		[weatherImage drawInRect:iconRect];
	}

	NSNumber* temp = [self.currentCondition objectForKey:@"temp"];
	NSNumber* night = [self.currentCondition objectForKey:@"night"];

	NSString* t = [temp.stringValue stringByAppendingString: @"\u00B0"];

//	NSString* style = [NSString stringWithFormat:(night.boolValue ? self.tempStyleNight : self.tempStyle), (int)size.width];
//     	[t drawAtPoint:CGPointMake(0, 0) withStyle:style];

     	UIFont* font = [UIFont boldSystemFontOfSize:13];
	CGSize ts = [t sizeWithFont:font];
	[[[UIColor blackColor] colorWithAlphaComponent:0.2] set];
     	[t drawAtPoint:CGPointMake((int)(size.width / 2) - (ts.width / 2) + 3, 41) withFont:font];
	[[UIColor whiteColor] set];
     	[t drawAtPoint:CGPointMake((int)(size.width / 2) - (ts.width / 2) + 3, 40) withFont:font];

	UIImage* icon = UIGraphicsGetImageFromCurrentImageContext();
	NSLog(@"WI: Icon scale: %f", [icon scale]);
	UIGraphicsEndImageContext();

	return icon;
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
	else
	{
		notify_post("weathericon_changed");
		[[UIApplication sharedApplication] removeStatusBarImageNamed:@"WeatherIcon"];
		[[UIApplication sharedApplication] addStatusBarImageNamed:@"WeatherIcon"];
	}
}

- (void) resetWeatherIcon:(NSString*) bundleIdentifier
{
	SBIconModel* model = [$SBIconModel sharedInstance];
	SBApplicationIcon* applicationIcon = nil;
	if ([model respondsToSelector:@selector(applicationIconForDisplayIdentifier:)])
		applicationIcon = [model applicationIconForDisplayIdentifier:bundleIdentifier];
	else
		applicationIcon = [model iconForDisplayIdentifier:bundleIdentifier];

	if (self.showWeatherIcon)
	{
		if ([model respondsToSelector:@selector(reloadIconImageForDisplayIdentifier:)])
			[model reloadIconImageForDisplayIdentifier:bundleIdentifier];
		else if ([applicationIcon respondsToSelector:@selector(reloadIconImage)])
			[applicationIcon reloadIconImage];
	}

}

- (void) updateWeatherIcon
{
	SBIconModel* model = [$SBIconModel sharedInstance];
	SBApplicationIcon* applicationIcon = nil;
	if ([model respondsToSelector:@selector(applicationIconForDisplayIdentifier:)])
		applicationIcon = [model applicationIconForDisplayIdentifier:self.bundleIdentifier];
	else
		applicationIcon = [model iconForDisplayIdentifier:self.bundleIdentifier];

	if (self.showWeatherIcon)
	{
		BOOL reload = (self.weatherIcon != nil);
		self.weatherIcon = [self createIcon];
		if (reload)
		{
			if ([model respondsToSelector:@selector(reloadIconImageForDisplayIdentifier:)])
				[model reloadIconImageForDisplayIdentifier:self.bundleIdentifier];
			else if ([applicationIcon respondsToSelector:@selector(setDisplayedIconImage:)])
				[applicationIcon setDisplayedIconImage:self.weatherIcon];
			else if ([applicationIcon respondsToSelector:@selector(reloadIconImage)])
				[applicationIcon reloadIconImage];
		}
	}

	// now the status bar image
	if (self.showStatusBarWeather)
		[self updateIndicator];

	if (applicationIcon)
	{
		if (self.showWeatherBadge)
		{
			NSNumber* temp = [self.currentCondition objectForKey:@"temp"];
			[applicationIcon setBadge:[temp.stringValue stringByAppendingString: @"\u00B0"]];
		}
	}
}

-(void) update:(NSNotification*) notif
{
        NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	self.currentCondition = [[notif.userInfo copy] autorelease];
        [self updateWeatherIcon];
        [pool release];
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
	if (self.statusBarIndicator == nil)
		[self updateIndicator];

	return (mode == 0 ? self.statusBarIndicator : self.statusBarIndicatorFSO);
}

- (UIImageView*) statusBarIndicatorView:(int)mode
{
	UIImage* img = [self statusBarIndicator:mode];
	UIImageView* v = (mode == 0 ? self.statusBarIndicatorView : self.statusBarIndicatorFSOView);
	
	if (v == nil)
	{
		v = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, img.size.width, 20)] autorelease];
		if (mode == 0)
			self.statusBarIndicatorView = v;
		else
			self.statusBarIndicatorFSOView = v;
	}

	CGRect r = v.frame;
	r.size.width = img.size.width;
	v.frame = r;
	v.image = img;

	return v;
}

@end
 
static Class $SBStatusBarContentsView;

static SBStatusBarContentView* _sb0;
static SBStatusBarContentView* _sb1;
static NSTimeInterval lastPrefsUpdate = 0;

@interface SBStatusBarContentView3 : SBStatusBarContentView
-(BOOL) showOnLeft;
-(BOOL) isVisible;
@end

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
					[_controller updateWeatherIcon];
				}
			}
		}
	}
}

MSHook(void, reflowWithVisibleItems, id self, SEL sel, NSArray* items, double duration)
{
	_reflowWithVisibleItems(self, sel, items, duration);

	int region = MSHookIvar<int>(self, "_region");
	if (region == 1)
	{
		NSLog(@"WI: Views: %@", [self _itemViews]);
		NSArray* views = [self _itemViews];

		float x = [[UIScreen mainScreen] bounds].size.width;
		if (views.count > 0)
		{
			UIView* last = [views objectAtIndex:views.count - 1];
			x = last.frame.origin.x;
		}

		UIImageView* view = [_controller statusBarIndicatorView:(int)[[self foregroundView] foregroundStyle]];
		CGRect r = view.frame;
		r.origin.x = x - r.size.width - 3;
		view.frame = r;
		NSLog(@"WI: Adding: %@ to status bar", view);
		[[self foregroundView] addSubview:view];
	}
}

MSHook(void, setDisplayedIconImage, SBIcon *self, SEL sel, id image)
{
	if ([self respondsToSelector:@selector(leafIdentifier)] && [[self leafIdentifier] isEqualToString:_controller.bundleIdentifier])
	{
		NSLog(@"WI: Overriding weather icon");
		_setDisplayedIconImage(self, sel, _controller.icon);
	}
	else
	{
		_setDisplayedIconImage(self, sel, image);
	}
}

MSHook(id, getCachedImagedForIcon, SBIconModel *self, SEL sel, SBIcon* icon, BOOL small) 
{
	if (!small && [_controller isWeatherIcon:icon.displayIdentifier])
	{
		return _controller.icon;
	}

	return _getCachedImagedForIcon(self, sel, icon, small);
}

MSHook(id, itemWithType, id self, SEL sel, int type)
{
	if (type >= 20)
		return [[[$UIStatusBarItem alloc] initWithType:type] autorelease];

	return _itemWithType(self, sel, type);
}

MSHook(id, kitImageNamed, id self, SEL sel, NSString* name)
{
	if ([name isEqualToString:@"Silver_WeatherIcon.png"])
		return [_controller statusBarIndicator:0];
	else if ([name isEqualToString:@"Black_WeatherIcon.png"])
		return [_controller statusBarIndicator:1];
	else
		return _kitImageNamed(self, sel, name);
}

MSHook(id, viewClass, id self, SEL sel)
{
	int type = (int)[self type];
	if (type == 40)
		return objc_getClass("WIStatusBarItemView");

	return _viewClass(self, sel);
}

static id contentsImageForStyle(id self, SEL sel, int style) 
{
	return [_controller statsuBarIndicator:style];
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
	if (![[$SBUIController sharedInstance] isOnAC])
		[_controller stopTimer];
}

static void updatePrefs(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[_controller stopTimer];
}

#define Hook(cls, sel, imp) \
        _ ## imp = MSHookMessage($ ## cls, @selector(sel), &$ ## imp)

extern "C" void TweakInit() {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	springBoardBundle = [NSBundle bundleWithPath:@"/System/Library/CoreServices/SpringBoard.app"];
	weatherIconBundle = [NSBundle bundleWithPath:@"/Library/WeatherIcon"];

	_controller = [[[WeatherIconController alloc] init] retain];

/*
	Class $UIStatusBarLayoutManager = objc_getClass("UIStatusBarLayoutManager");
	Hook(UIStatusBarLayoutManager, reflowWithVisibleItems:duration:, reflowWithVisibleItems);

	Class $WIStatusBarItemView = objc_allocateClassPair(objc_getClass("UIStatusBarItemView"), "WIStatusBarItemView", 0);
	class_addMethod($WIStatusBarItemView, @selector(contentsImageForStyle:), (IMP) contentsImageForStyle, "@@:i");
	objc_registerClassPair($WIStatusBarItemView);

	$UIStatusBarItem = objc_getClass("UIStatusBarItem");
	Hook(UIStatusBarItem, viewClass, viewClass);

	Class $UIStatusBarItemClass = object_getClass($UIStatusBarItem);
	Hook(UIStatusBarItemClass, itemWithType, itemWithType);
*/

	Class $UIImageClass = object_getClass(objc_getClass("UIImage"));
	Hook(UIImageClass, kitImageNamed:, kitImageNamed);

	if (objc_getClass("SpringBoard") != nil)
	{
		Class $SBIcon = objc_getClass("SBIcon");
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
	
		// MSHookMessage is what we use to redirect the methods to our own
		Hook(SBApplication, deactivated, deactivated);
		Hook(SBStatusBarIndicatorsView, reloadIndicators, reloadIndicators);
		Hook(SBIconModel, getCachedImagedForIcon:smallIcon:, getCachedImagedForIcon);
		Hook(SBIcon, setDisplayedIconImage:, setDisplayedIconImage);
	
		// only hook these in 3.0
		if ($SBStatusBarIndicatorsView == nil)
		{
			Hook(SBStatusBarIndicatorView, setFrame:, indicatorSetFrame);
			Hook(SBStatusBarBluetoothView, setFrame:, btSetFrame);
			Hook(SBStatusBarBluetoothBatteryView, setFrame:, btbSetFrame);
			Hook(SBStatusBarContentsView, reflowContentViewsNow, reflowContentViewsNow);
		}
	}
	
	[pool release];
}
