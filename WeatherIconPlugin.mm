#include "WeatherIconPlugin.h"
#include <UIKit/UIKit.h>
#include <UIKit/UIScreen.h>
#include <substrate.h>

@interface UIScreen (WeatherIcon)

-(float) scale;

@end

@interface UIImage (WIPAdditions)
- (id)wip_initWithContentsOfResolutionIndependentFile:(NSString *)path;
+ (UIImage*)wip_imageWithContentsOfResolutionIndependentFile:(NSString *)path;
@end

@implementation UIImage (WIPAdditions)

- (id)wip_initWithContentsOfResolutionIndependentFile:(NSString *)path
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

+ (UIImage*) wip_imageWithContentsOfResolutionIndependentFile:(NSString *)path
{
        return [[[UIImage alloc] wip_initWithContentsOfResolutionIndependentFile:path] autorelease];
}

@end


#define localize(str) \
        [self.plugin.bundle localizedStringForKey:str value:str table:nil]

@implementation WIForecastView

@synthesize forecast, icons, theme, pluginTheme;
@synthesize timestamp, updatedString;

-(void) drawIcons:(struct CGRect) rect
{
	int width = ((rect.size.width - 10) / 6);
	double scale = 0.66;

	NSBundle* bundle = [NSBundle mainBundle];
	if (NSNumber* n = [self.pluginTheme objectForKey:@"LockInfoImageScale"])
		scale = n.doubleValue;

	for (int i = 0; i < self.forecast.count && i < 6; i++)
	{
		id image = [self.icons objectAtIndex:i];
		if (image != [NSNull null])
		{
			UIImage* realImage = (UIImage*) image;
			CGSize s = realImage.size;
			s.width *= scale;
			s.height *= scale;

			CGRect r = CGRectMake(rect.origin.x + 5 + (width * i) + (width / 2) - (s.width / 2), rect.origin.y + (rect.size.height / 2) - (s.height / 2), s.width, s.height);
			[image drawInRect:r];
		}
	}
}

-(void) drawTemps:(struct CGRect) rect
{
	int width = ((rect.size.width - 10) / 6);
	CGSize size = [@"Test" sizeWithFont:self.theme.detailStyle.font];

	LIStyle* hiStyle = [self.theme.detailStyle copy];
	hiStyle.textColor = self.theme.summaryStyle.textColor;

        CGRect r = CGRectMake(rect.origin.x + 5, rect.origin.y, (width / 2), size.height);
	for (int i = 0; i < self.forecast.count && i < 6; i++)
	{
		NSDictionary* day = [self.forecast objectAtIndex:i];

		NSString* str = [NSString stringWithFormat:@"%@\u00B0", [day objectForKey:@"high"]];
		[str drawInRect:CGRectOffset(r, (width * i), 0) withLIStyle:hiStyle lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];

		str = [NSString stringWithFormat:@" %@\u00B0", [day objectForKey:@"low"]];
		[str drawInRect:CGRectOffset(r, (width * i) + r.size.width, 0) withLIStyle:self.theme.detailStyle lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentLeft];
	}

	[hiStyle release];

	if (self.timestamp)
	{
		NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
		df.dateStyle = NSDateFormatterShortStyle;
		df.timeStyle = NSDateFormatterShortStyle;
		NSString* str = [NSString stringWithFormat:@"%@ %@", self.updatedString, [df stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.timestamp.doubleValue]]];

		CGRect r = CGRectMake(rect.origin.x, rect.origin.y + size.height + 2, rect.size.width, size.height);
		[str drawInRect:r withLIStyle:self.theme.detailStyle lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
	}
}

-(void) drawDays:(struct CGRect) rect
{
        NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
        NSArray* weekdays = df.shortStandaloneWeekdaySymbols;

	int width = ((rect.size.width - 10) / 6);

	CGSize size = [@"Test" sizeWithFont:self.theme.detailStyle.font];
        CGRect r = CGRectMake(rect.origin.x + 5, rect.origin.y, width, size.height);
	for (int i = 0; i < self.forecast.count && i < 6; i++)
	{
		NSDictionary* day = [self.forecast objectAtIndex:i];
		
		NSNumber* daycode = [day objectForKey:@"daycode"];
		NSString* str = [[weekdays objectAtIndex:daycode.intValue] uppercaseString];

		[str drawInRect:CGRectOffset(r, (width * i), 0) withLIStyle:self.theme.detailStyle lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
	}
}

-(void) drawRect:(struct CGRect) rect
{
	CGSize sz = [@"Test" sizeWithFont:self.theme.detailStyle.font];
	float height = sz.height;

	[self drawDays:CGRectMake(0, 1, rect.size.width, height)];
	[self drawIcons:CGRectMake(0, height, rect.size.width, 30)];
	[self drawTemps:CGRectMake(0, height + 30, rect.size.width, (self.timestamp ? 2 * height : height))];
}

@end

extern "C" UIImage *_UIImageWithName(NSString *);

@implementation WeatherIconPlugin

@synthesize dataCache, iconCache, plugin, forecastView, updateLock, reloadCondition, theme;

- (void) loadTheme
{
        NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:10];

        if (NSString* themePrefs = [[NSBundle mainBundle] pathForResource:@"com.ashman.WeatherIcon" ofType:@"plist"])
        {
                [dict addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:themePrefs]];
                NSLog(@"WIP: Loading theme from SB bundle: %@", dict);
        }
        else if (NSString* themePrefs = [self.plugin.bundle pathForResource:@"Theme" ofType:@"plist"])
        {
                [dict addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:themePrefs]];
                NSLog(@"WIP: Loading theme from WI bundle: %@", dict);
        }

        self.theme = dict;
}

-(id) loadIcon:(NSString*) path
{
	id icon = [self.iconCache objectForKey:path];

	if (path != nil && icon == nil)
	{
		icon = [UIImage wip_imageWithContentsOfResolutionIndependentFile:path];
		[self.iconCache setValue:icon forKey:path];
	}

	return icon;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
        return 1;
}

- (NSString *)tableView:(LITableView *)tableView detailForHeaderInSection:(NSInteger)section
{
	BOOL hide = false;
	if (NSNumber* b = [self.plugin.preferences objectForKey:@"HideDescription"])
		hide = b.boolValue;

	if (hide)
		return @"";
	
	NSDictionary* weather = [self.dataCache objectForKey:@"weather"];
	if (NSNumber* code = [weather objectForKey:@"code"])
	{
		if (code.intValue >= 0 && code.intValue < descriptions.count)
		{
			return localize([descriptions objectAtIndex:code.intValue]);
		}
	}

	return localize([weather objectForKey:@"description"]);
}

-(UIImage*) defaultIcon:(NSNumber*) code night:(BOOL) night
{
	if (code)
	{
		NSArray* icons = (night ? defaultNightIcons : defaultIcons);
		if (code.intValue >= 0 && code.intValue < icons.count)
			if (NSString* path = [self.plugin.bundle pathForResource:[icons objectAtIndex:code.intValue] ofType:@"png"])
				return [self loadIcon:path];
	}

	return nil;
}

-(UIImage*) defaultIcon:(NSNumber*) code
{
	return [self defaultIcon:code night:false];
}

-(UIImageView*) weatherIcon
{
	double scale = 0.33;

	NSDictionary* weather = [self.dataCache objectForKey:@"weather"];
	UIImage* icon = [self loadIcon:[weather objectForKey:@"icon"]];
	if (icon == nil)
	{
		BOOL night = false;
		if (NSNumber* b = [weather objectForKey:@"night"])
			night = b.boolValue;

		icon = [self defaultIcon:[weather objectForKey:@"code"] night:night];
		scale = 0.45;
	}

	if (icon)
	{
		if (NSNumber* n = [self.theme objectForKey:@"StatusBarImageScale"])
			scale = n.doubleValue;

		CGSize s = icon.size;
		s.width = s.width * scale;
		s.height = s.height * scale;

        	UIImageView* view = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, s.width, s.height)] autorelease];
		view.image = icon;
		return view;
	}

	return nil;
}

- (UIImageView *)tableView:(LITableView *)tableView iconForHeaderInSection:(NSInteger)section
{
	return [self weatherIcon];
}

- (CGFloat)tableView:(LITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGSize sz = [@"Test" sizeWithFont:tableView.theme.detailStyle.font];

	float height = sz.height;

	BOOL show = false;
	if (NSNumber* n = [self.plugin.preferences objectForKey:@"ShowUpdateTime"])
		show = n.boolValue;

	return (show ? (height * 3) + 4 : (height * 2)) + 30;
}

- (NSString *)tableView:(LITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSDictionary* weather = [self.dataCache objectForKey:@"weather"];
	NSString* city = [weather objectForKey:@"city"];
	NSRange r = [city rangeOfString:@","];
	if (r.location != NSNotFound)
		city = [city substringToIndex:r.location];

	return [NSString stringWithFormat:@"%@: %d\u00B0", city, [[weather objectForKey:@"temp"] intValue]];
}

-(void) updateWeatherViews
{
	[self loadTheme];

	NSDictionary* weather = [self.dataCache objectForKey:@"weather"];
	NSArray* forecast = [[weather objectForKey:@"forecast"] copy];

	self.forecastView.forecast = forecast;

	NSMutableArray* arr = [NSMutableArray arrayWithCapacity:6];
	for (int i = 0; i < forecast.count && i < 6; i++)
	{
		NSDictionary* day = [forecast objectAtIndex:i];
		UIImage* icon = [self loadIcon:[day objectForKey:@"icon"]];

		if (icon == nil)
			icon = [self defaultIcon:[day objectForKey:@"code"]];

		[arr addObject:(icon == nil ? [NSNull null] : icon)];
	}
	self.forecastView.icons = arr;
	self.forecastView.pluginTheme = self.theme;

	BOOL show = false;
	if (NSNumber* n = [self.plugin.preferences objectForKey:@"ShowUpdateTime"])
		show = n.boolValue;

	self.forecastView.updatedString = localize(@"Updated");
	self.forecastView.timestamp = (show ? [weather objectForKey:@"timestamp"] : nil);
	[self.forecastView setNeedsDisplay];

	[forecast release];
}

- (UITableViewCell *)tableView:(LITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *fc = [tableView dequeueReusableCellWithIdentifier:@"WIForecast"];
	if (fc == nil)
	{
		fc = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"WIForecast"] autorelease];
		fc.backgroundColor = [UIColor clearColor];
	}

	[fc.contentView addSubview:self.forecastView];
	self.forecastView.theme = tableView.theme;

	NSDictionary* weather = [[self.dataCache objectForKey:@"weather"] copy];
	NSArray* forecast = [weather objectForKey:@"forecast"];
	self.forecastView.forecast = forecast;

	NSMutableArray* arr = [NSMutableArray arrayWithCapacity:6];
	for (int i = 0; i < forecast.count && i < 6; i++)
	{
		NSDictionary* day = [forecast objectAtIndex:i];
		UIImage* icon = [self loadIcon:[day objectForKey:@"icon"]];

		if (icon == nil)
			icon = [self defaultIcon:[day objectForKey:@"code"]];

		[arr addObject:(icon == nil ? [NSNull null] : icon)];
	}
	self.forecastView.icons = arr;

	BOOL show = false;
	if (NSNumber* n = [self.plugin.preferences objectForKey:@"ShowUpdateTime"])
		show = n.boolValue;

	self.forecastView.updatedString = localize(@"Updated");
	self.forecastView.timestamp = (show ? [weather objectForKey:@"timestamp"] : nil);
	self.forecastView.frame = fc.contentView.bounds;

	// mark dirty
	[self.forecastView setNeedsDisplay];

	[weather release];

	return fc;
}

-(id) initWithPlugin:(LIPlugin*) plugin 
{
	self = [super init];
	self.plugin = plugin;
	self.dataCache = [NSMutableDictionary dictionaryWithCapacity:10];
	self.iconCache = [NSMutableDictionary dictionaryWithCapacity:10];

	self.forecastView = [[[WIForecastView alloc] init] autorelease];
	self.forecastView.backgroundColor = [UIColor clearColor];
	self.forecastView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	self.forecastView.contentMode = UIViewContentModeRedraw;

	self.reloadCondition = [[[NSCondition alloc] init] autorelease];
	self.updateLock = [[[NSLock alloc] init] autorelease];
	
	plugin.tableViewDataSource = self;
	plugin.tableViewDelegate = self;

        NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(update:) name:LIViewReadyNotification object:nil];
        [center addObserver:self selector:@selector(updateOnUpdate:) name:@"LWWeatherUpdatedNotification" object:nil];

	[self loadTheme];

	return self;
}

-(void) notifyLockInfo
{
	[self.plugin updateView:self.dataCache];
}

-(void) updateWeather:(NSDictionary*) weather
{
	if (!self.plugin.enabled)
		return;

	if ([self.updateLock tryLock])
	{
		NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:weather, @"weather", nil];
		[self.dataCache setDictionary:dict];
		[self performSelectorOnMainThread:@selector(updateWeatherViews) withObject:nil waitUntilDone:YES];
		[self notifyLockInfo];
		[self.updateLock unlock];
	}
}

- (NSString *)tableView:(LITableView *)tableView reloadDataInSection:(NSInteger)section
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"LWRefreshNotification" object:nil];
	[self.reloadCondition lock];
	[self.reloadCondition wait];
	[self.reloadCondition unlock];
}

-(void) updateOnUpdate:(NSNotification*) notif
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	[self updateWeather:notif.userInfo];
	[self.reloadCondition broadcast];
	[pool release];
}

-(void) update:(NSNotification*) notif
{
	if (!self.plugin.enabled)
		return;

	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	if (NSDictionary* current = [[objc_getClass("LibWeatherController") sharedInstance] currentCondition])
	{
//		NSLog(@"LI:Weather: Updating when view is ready");
		[self updateWeather:current];
	}

	[pool release];
}

@end
