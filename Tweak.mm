#import <substrate.h>
#import <libweather.h>
#import <execinfo.h>
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

static void callStackSymbols()
{
	void* callstack[128]; 
	int i, frames = backtrace(callstack, 128); 
	char** strs = backtrace_symbols(callstack, frames); 
	for (i = 0; i < frames; ++i) 
	{ 
		printf("%s\n", strs[i]); 
	} 
	free(strs);
}

@interface UIScreen (WIAdditions)

-(float) scale;

@end

@interface UIImage (WIAdditions)
- (id)wi_initWithContentsOfResolutionIndependentFile:(NSString *)path;
+ (UIImage*)wi_imageWithContentsOfResolutionIndependentFile:(NSString *)path;
@end

@implementation UIImage (WIAdditions)

- (id)wi_initWithContentsOfResolutionIndependentFile:(NSString *)path
{
        float scale = ( [[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? (float)[[UIScreen mainScreen] scale] : 1.0);
        if ( scale == 2.0)
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

@interface WeatherIconController : NSObject <UIAlertViewDelegate>
{
	NSConditionLock* lock;
}

	// image caches
@property (nonatomic, retain) UIImageView* statusBarIndicatorViewMode0;
@property (nonatomic, retain) UIImageView* statusBarIndicatorViewMode1;
@property (nonatomic, retain) UIImageView* statusBarIndicatorViewMode2;
@property (nonatomic, retain) UIImage* weatherIcon;

	// refresh date info
@property (nonatomic, retain) NSDictionary* theme;
@property (nonatomic, retain) NSDictionary* currentCondition;
@property (nonatomic, retain) NSMutableDictionary* preferences;
@property (nonatomic, retain) id dmc;


- (id)init;
- (BOOL)isWeatherIcon:(NSString*) displayIdentifier;
- (UIImage*)icon;

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
@synthesize weatherIcon;
@synthesize statusBarIndicatorViewMode0;
@synthesize statusBarIndicatorViewMode1;
@synthesize statusBarIndicatorViewMode2;

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

	if (NSString* themePrefs = [springBoardBundle pathForResource:@"com.ashman.WeatherIcon" ofType:@"plist"])
	{
		[dict addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:themePrefs]];
		NSLog(@"WI: Loading theme from SB bundle: %@", dict);
	}
	else if (NSString* themePrefs = [weatherIconBundle pathForResource:@"Theme" ofType:@"plist"])
	{
		[dict addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:themePrefs]];
		NSLog(@"WI: Loading theme from WI bundle: %@", dict);
	}

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

- (BOOL) alwaysThemeWeather
{
	if (!self.enabled)
		return false;

	if (NSNumber* n = [self.theme objectForKey:@"AlwaysThemeWeather"])
		return [n boolValue];

	if (NSNumber* v = [self.preferences objectForKey:@"AlwaysThemeWeather"])
		return [v boolValue];

	return false;
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

- (BOOL) showStatusBarWeather
{
	return (self.showStatusBarTemp || self.showStatusBarImage);
}

- (void) loadPreferences
{
	NSString* bundleIdentifier = [self.bundleIdentifier retain];

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

	[self setBadge:nil];

	self.preferences = prefs;
	[self loadTheme];

	[self updateBadge];

	[self resetWeatherIcon:bundleIdentifier];
	[self resetWeatherIcon:self.bundleIdentifier];
	[self resetWeatherIcon:@"com.apple.weather"];

/*
	if (![bundleIdentifier isEqualToString:self.bundleIdentifier])
	{
		NSLog(@"WI: Reset weather icon for %@ because identifier changed.", self.bundleIdentifier);
	}

	if (!self.showWeatherIcon)
	{
		NSLog(@"WI: Reset weather icon for %@ because not showing icon.", self.bundleIdentifier);
	}
*/

	[bundleIdentifier release];

/*
	if (self.showStatusBarWeather && objc_getClass("UIStatusBar") && objc_getClass("UIStatusBarCustomItem") == nil)
	{
		UIAlertView* sheet = nil;

		sheet = [[UIAlertView alloc] initWithTitle:@"WeatherIcon" message:@"Status bar weather information requires libstatusbar.  Please open Cydia and install libstatusbar." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];

		[sheet show];
	}
*/
}

-(void) alertView:(UIAlertView*) view clickedButtonAtIndex:(int) index
{
	if (index == 1)
		[[UIApplication sharedApplication] applicationOpenURL:[NSURL URLWithString:@"cydia://package/libstatusbar"]];
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
	[self loadPreferences];
	self.currentCondition = [[LibWeatherController sharedInstance] currentCondition];

	if (objc_getClass("UIStatusBar"))
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

	return nil;
}

- (NSString*) findWeatherImagePath:(NSString*) prefix withDefault:(BOOL) d
{
	NSNumber* code = [self.currentCondition objectForKey:@"code"];
	NSNumber* night = [self.currentCondition objectForKey:@"night"];

	NSString* path = [self findWeatherImagePath:prefix code:(code ? 
				code.stringValue : @"3200") night:night.boolValue];

	if (path || !d)
		return path;

	return [self defaultImagePath:code night:night.boolValue];
}

- (UIImage*) findWeatherImage:(NSString*) prefix withDefault:(BOOL) d
{
	NSString* path = [self findWeatherImagePath:prefix withDefault:d];
	NSLog(@"WI: Found image %@ for prefix %@", path, prefix);
	return (path ? [UIImage wi_imageWithContentsOfResolutionIndependentFile:path] : nil);
}

- (BOOL) isWeatherIcon:(NSString*) displayIdentifier
{
	if ([displayIdentifier isEqualToString:self.bundleIdentifier]
	 	|| (self.alwaysThemeWeather && [displayIdentifier isEqualToString:@"com.apple.weather"]))
	{
		// make sure to reload the theme here
		[self loadTheme];
		return self.showWeatherIcon;
	}

	return false;
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
		NSString* image = [self findWeatherImagePath:@"weatherstatus" withDefault:NO];
		// save the status bar image
		if (!image)
			image = [self findWeatherImagePath:@"weather" withDefault:YES];

		[dict setValue:image forKey:@"image"];
		[dict setValue:[NSNumber numberWithDouble:self.statusBarImageScale] forKey:@"imageScale"];
	}

	return dict;
}

- (UIImage*) createIndicator:(int) mode
{
	NSNumber* temp = [self.currentCondition objectForKey:@"temp"];
	NSString* t = [temp.stringValue stringByAppendingString: @"\u00B0"];

	UIImage* image = [self findWeatherImage:@"weatherstatus" withDefault:NO];
	// save the status bar image
	if (!image)
		image = [self findWeatherImage:@"weather" withDefault:YES];

	[image retain];

	UIFont* font = [UIFont boldSystemFontOfSize:14];
	CGSize tempSize = CGSizeMake(0, 20);
        CGSize sbSize = CGSizeMake(0, 20);

        if (self.showStatusBarTemp)
	{
	        tempSize = [t sizeWithFont:font];
                sbSize.width += tempSize.width;
	}

        if (self.showStatusBarImage && image)
                sbSize.width += ceil(image.size.width * self.statusBarImageScale);

        UIGraphicsBeginImageContext(sbSize);

        if (self.showStatusBarTemp)
        {
		if (mode == 0)
                {
                        [[[UIColor whiteColor] colorWithAlphaComponent:0.8] set];
                        [t drawAtPoint:CGPointMake(0, 1) withFont:font];
                }

                float colorValue = 0.3 + (0.7 * mode);
                [[UIColor colorWithRed:colorValue green:colorValue blue:colorValue alpha:1] set];
                [t drawAtPoint:CGPointMake(0, 0) withFont:font];
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

	[image release];

	return indicator;
}

- (UIImage*) createIcon
{
	UIImage* bgIcon = [[self findWeatherImage:@"weatherbg" withDefault:YES] retain];
	UIImage* weatherImage = [[self findWeatherImage:@"weather" withDefault:YES] retain];
	CGSize size = (bgIcon ? bgIcon.size : CGSizeMake(59, 60));

	NSLog(@"WI: Icon size: %f, %f, %f", size.width, size.height, self.imageScale);

	if (objc_getClass("UIStatusBar"))
		UIGraphicsBeginImageContextWithOptions(size, NO, 0.0); 
	else 
		UIGraphicsBeginImageContext(size);

	if (bgIcon)
	{
		[bgIcon drawInRect:CGRectMake(0, 0, size.width, size.height)];	
		[bgIcon release];
	}

	if (weatherImage)
	{
		float width = weatherImage.size.width * self.imageScale;
		float height = weatherImage.size.height * self.imageScale;
	        CGRect iconRect = CGRectMake((size.width - width) / 2, self.imageMarginTop, width, height);
		[weatherImage drawInRect:iconRect];
		[weatherImage release];
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
	UIGraphicsEndImageContext();

	return icon;
}

- (void) updateIndicator
{
	[[UIApplication sharedApplication] addStatusBarImageNamed:@"WeatherIcon"];

	if (SBStatusBarController* statusBarController = [$SBStatusBarController sharedStatusBarController])
	{
		NSLog(@"WI: Refreshing indicator...");
		self.statusBarIndicatorViewMode0.image = [self createIndicator:0];
		[self.statusBarIndicatorViewMode0 setNeedsDisplay];

		self.statusBarIndicatorViewMode1.image = [self createIndicator:1];
		[self.statusBarIndicatorViewMode1 setNeedsDisplay];

		self.statusBarIndicatorViewMode2.image = [self createIndicator:2];
		[self.statusBarIndicatorViewMode2 setNeedsDisplay];
	}
	else
	{
		notify_post("weathericon_changed");
	}
}

-(SBApplicationIcon*) applicationIcon:(NSString*) bundleIdentifier
{
	SBIconModel* model = [$SBIconModel sharedInstance];
	SBApplicationIcon* applicationIcon = nil;
	if ([model respondsToSelector:@selector(applicationIconForDisplayIdentifier:)])
		applicationIcon = [model applicationIconForDisplayIdentifier:bundleIdentifier];
	else
		applicationIcon = [model iconForDisplayIdentifier:bundleIdentifier];

	return applicationIcon;
}

-(SBApplicationIcon*) applicationIcon
{
	return [self applicationIcon:self.bundleIdentifier];
}

- (void) resetWeatherIcon:(NSString*) bundleIdentifier withImage:(UIImage*) image
{
	SBIconModel* model = [$SBIconModel sharedInstance];
	SBApplicationIcon* applicationIcon = [self applicationIcon];

	if ([model respondsToSelector:@selector(reloadIconImageForDisplayIdentifier:)])
		[model reloadIconImageForDisplayIdentifier:bundleIdentifier];
	else if (image && [applicationIcon respondsToSelector:@selector(setDisplayedIconImage:)])
		[applicationIcon setDisplayedIconImage:image];
	else if ([applicationIcon respondsToSelector:@selector(reloadIconImage)])
		[applicationIcon reloadIconImage];
}

- (void) resetWeatherIcon:(NSString*) bundleIdentifier
{
	[self resetWeatherIcon:bundleIdentifier withImage:nil];
}

- (void) updateWeatherIcon
{
	if (self.showWeatherIcon)
	{
		BOOL reload = (self.weatherIcon != nil);
		self.weatherIcon = [self createIcon];

		if (reload)
		{
			[self resetWeatherIcon:self.bundleIdentifier withImage:self.weatherIcon];
			[self resetWeatherIcon:@"com.apple.weather" withImage:self.weatherIcon];
		}
	}

	// now the status bar image
	if (self.showStatusBarWeather)
		[self updateIndicator];
	else
		[[UIApplication sharedApplication] removeStatusBarImageNamed:@"WeatherIcon"];

	[self updateBadge];
}

-(void) setBadge:(NSString*) badge
{
	SBApplicationIcon* applicationIcon = [self applicationIcon];

	if (self.showWeatherBadge)
		[applicationIcon setBadge:badge];
	else
		[applicationIcon setBadge:nil];
}

-(void) updateBadge
{
	NSNumber* temp = [self.currentCondition objectForKey:@"temp"];
	[self setBadge:[temp.stringValue stringByAppendingString: @"\u00B0"]];
}

-(void) update:(NSNotification*) notif
{
        NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	self.currentCondition = [[notif.userInfo copy] autorelease];
        [self performSelectorOnMainThread:@selector(updateWeatherIcon) withObject:nil waitUntilDone:NO];
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

@end
 
static SBStatusBarContentView* _sb0;
static SBStatusBarContentView* _sb1;
static NSTimeInterval lastPrefsUpdate = 0;

@interface SBStatusBarContentView3 : SBStatusBarContentView
-(BOOL) showOnLeft;
-(BOOL) isVisible;
@end

MSHook(int, priority, SBStatusBarContentView* self, SEL sel)
{
	if ([[self indicatorName] isEqualToString:@"WeatherIcon"])
	{
		return 3;
	}

	return _priority(self, sel);
}

MSHook(id, initWithNameAndMode, SBStatusBarContentView* self, SEL sel, NSString* name, int mode)
{
	NSLog(@"WI: Initing for mode %d and name %@", mode, name);
	UIView* ind = _initWithNameAndMode(self, sel, name, mode);

	if ([name isEqualToString:@"WeatherIcon"])
	{
		UIImageView* image = [ind.subviews objectAtIndex:0];

		switch (mode)
		{
			case 0:
				_controller.statusBarIndicatorViewMode0 = image;
				break;
			case 1:
				_controller.statusBarIndicatorViewMode1 = image;
				break;
			case 2:
				_controller.statusBarIndicatorViewMode2 = image;
				break;
		}

		image.image = [_controller createIndicator:mode];
		NSLog(@"WI: Indicator: %@", image);
		
		CGRect r = ind.frame;
		r.size.height = image.image.size.height;
		r.size.width = image.image.size.width;
		ind.frame = r;
		image.frame = ind.bounds;
	}

	return ind;
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
        				[_controller performSelectorOnMainThread:@selector(updateWeatherIcon) withObject:nil waitUntilDone:NO];
				}
			}
		}
	}
}

MSHook(void, setDisplayedIconImage, SBIcon *self, SEL sel, id image)
{
	if (_controller.showWeatherIcon && [self respondsToSelector:@selector(leafIdentifier)] && [_controller isWeatherIcon:[self leafIdentifier]])
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
	NSLog(@"WI: Getting cached image for %@", icon.displayIdentifier);
	if (!small && _controller.showWeatherIcon && [_controller isWeatherIcon:icon.displayIdentifier])
	{
		return _controller.icon;
	}

	return _getCachedImagedForIcon(self, sel, icon, small);
}

#define Hook(cls, sel, imp) \
        _ ## imp = MSHookMessage($ ## cls, @selector(sel), &$ ## imp)

MSHook(id, uiInit, id self, SEL sel)
{
	Class $SBIconModel = objc_getClass("SBIconModel");
	Hook(SBIconModel, getCachedImagedForIcon:smallIcon:, getCachedImagedForIcon);

	id ret = _uiInit(self, sel);
	_controller = [[WeatherIconController alloc] init];
	return ret;
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

extern "C" void TweakInit() {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	springBoardBundle = [NSBundle bundleWithPath:@"/System/Library/CoreServices/SpringBoard.app"];
	weatherIconBundle = [NSBundle bundleWithPath:@"/Library/WeatherIcon"];

	// MSHookMessage is what we use to redirect the methods to our own
	Class $SBApplication = objc_getClass("SBApplication");
	Hook(SBApplication, deactivated, deactivated);

	Class $SBIcon = objc_getClass("SBIcon");
	Hook(SBIcon, setDisplayedIconImage:, setDisplayedIconImage);

	// only hook these in 3.0
	Class $SBStatusBarIndicatorView = objc_getClass("SBStatusBarIndicatorView");
	Hook(SBStatusBarIndicatorView, initWithName:andMode:, initWithNameAndMode);
	Hook(SBStatusBarIndicatorView, priority, priority);
	
	Class $SBUIController = objc_getClass("SBUIController");
       	Hook(SBUIController, init, uiInit);

	[pool release];
}
