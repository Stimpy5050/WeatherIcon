#include "Plugin.h"
#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

#define localize(str) \
        [self.plugin.bundle localizedStringForKey:str value:str table:nil]

static NSString* prefsPath = @"/User/Library/Caches/com.ashman.WeatherIcon.cache.plist";

static NSArray* defaultIcons = [[NSArray arrayWithObjects:
	@"tstorms", @"tstorms", @"tstorms", @"tstorms", @"tstorms",
	@"snow", @"snow", @"snow", @"showers", @"showers",
	@"showers", @"showers", @"showers", @"snow", @"snow",
	@"snow", @"snow", @"snow", @"snow", @"cloudy",
	@"cloudy", @"cloudy", @"cloudy", @"cloudy", @"cloudy",
	@"sunny", @"cloudy", @"cloudy", @"cloudy", @"partly_cloudy",
	@"partly_cloudy", @"sunny", @"sunny", @"sunny", @"sunny",
	@"showers", @"sunny", @"tstorms", @"tstorms", @"tstorms",
	@"showers", @"snow", @"snow", @"snow", @"partly_cloudy",
	@"tstorms", @"snow", @"tstorms", nil] retain];

static NSArray* defaultNightIcons = [[NSArray arrayWithObjects:
	@"tstorms", @"tstorms", @"tstorms", @"tstorms", @"tstorms",
	@"snow", @"snow", @"snow", @"showers", @"showers",
	@"showers", @"showers", @"showers", @"snow", @"snow",
	@"snow", @"snow", @"snow", @"snow", @"cloudy",
	@"cloudy", @"cloudy", @"cloudy", @"cloudy", @"cloudy",
	@"sunny", @"cloudy", @"cloudy", @"cloudy", @"partly_cloudy_night",
	@"partly_cloudy_night", @"moon", @"moon", @"moon", @"moon",
	@"showers", @"sunny", @"tstorms", @"tstorms", @"tstorms",
	@"showers", @"snow", @"snow", @"snow", @"partly_cloudy_night",
	@"tstorms", @"snow", @"tstorms", nil] retain];

static NSArray* descriptions = [[NSArray arrayWithObjects:
	@"Tornado", @"Tropical Storm", @"Hurricane", @"Severe Thunderstorms", @"Thunderstorms",
	@"Mixed Rain and Snow", @"Mixed Rain and Sleet", @"Mixed Snow and Sleet", @"Freezing Drizzle", @"Drizzle",
	@"Freezing Rain", @"Showers", @"Showers", @"Snow Flurries", @"Light Snow Showers",
	@"Blowing Snow", @"Snow", @"Hail", @"Sleet", @"Dust",
	@"Foggy", @"Haze", @"Smoky", @"Blustery", @"Windy",
	@"Cold", @"Cloudy", @"Mostly Cloudy", @"Mostly Cloudy", @"Partly Cloudy",
	@"Partly Cloudy", @"Clear", @"Sunny", @"Fair", @"Fair",
	@"Mixed Rain and Hail", @"Hot", @"Isolated Thunderstorms", @"Scattered Thunderstorms", @"Scattered Thunderstorms",
	@"Scattered Showers", @"Heavy Snow", @"Scattered Snow Showers", @"Heavy Snow", @"Partly Cloudy",
	@"Thunderstorms", @"Snow Showers", @"Isolated Thunderstorms", nil] retain];

static LITableView* findTableView(UIView* view)
{
	LITableView* table = nil;
	while (true)
	{
		view = view.superview;
		if (view == nil)
			break;	

		if ([view isKindOfClass:[UITableView class]])
		{
			table = (LITableView*)view;
			break;
		}
	}

	return table;
}

@interface WIForecastView : UIView

@property (nonatomic, retain) NSArray* icons;
@property (nonatomic, retain) NSArray* forecast;

@end

@implementation WIForecastView

@synthesize forecast, icons;

@end

@interface WIForecastDaysView : WIForecastView
@end

@interface WIForecastIconView : WIForecastView
@end

@interface WIForecastTempView : WIForecastView
@end

@implementation WIForecastIconView

-(void) drawRect:(struct CGRect) rect
{
	int width = (rect.size.width / 6);
	double scale = 0.66;

	NSBundle* bundle = [NSBundle mainBundle];
	NSString* path = [bundle pathForResource:@"com.ashman.WeatherIcon" ofType:@"plist"];
	if (NSDictionary* theme = [NSDictionary dictionaryWithContentsOfFile:path])
	{
//		if (NSNumber* n = [theme objectForKey:@"ImageScale"])
//			scale = n.doubleValue;

		if (NSNumber* n = [theme objectForKey:@"LockInfoImageScale"])
			scale = n.doubleValue;
	}

	for (int i = 0; i < self.forecast.count && i < 6; i++)
	{
		id image = [self.icons objectAtIndex:i];
		if (image != [NSNull null])
		{
			CGSize s = [image size];
			s.width *= scale;
			s.height *= scale;

			CGRect r = CGRectMake(rect.origin.x + (width * i) + (width / 2) - (s.width / 2), rect.origin.y + (rect.size.height / 2) - (s.height / 2), s.width, s.height);
			[image drawInRect:r];
		}
	}
}

@end

@implementation WIForecastTempView

-(void) drawRect:(struct CGRect) rect
{
	int width = (rect.size.width / 6);
	LITableView* table = findTableView(self);
	for (int i = 0; i < self.forecast.count && i < 6; i++)
	{
		NSDictionary* day = [self.forecast objectAtIndex:i];

		NSString* str = [NSString stringWithFormat:@"%@\u00B0", [day objectForKey:@"high"]];
        	CGRect r = CGRectMake(rect.origin.x + (width * i), rect.origin.y + 1, (width / 2), 11);
        	[table.theme.detailStyle.shadowColor set];
		[str drawInRect:r withFont:table.theme.detailStyle.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];

        	r.origin.y -= 1;
        	[table.theme.summaryStyle.textColor set];
		[str drawInRect:r withFont:table.theme.detailStyle.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];


		str = [NSString stringWithFormat:@" %@\u00B0", [day objectForKey:@"low"]];
        	r = CGRectMake(rect.origin.x + (width * i) + r.size.width, rect.origin.y + 1, (width / 2), 11);
        	[table.theme.detailStyle.shadowColor set];
		[str drawInRect:r withFont:table.theme.detailStyle.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentLeft];

        	r.origin.y -= 1;
        	[table.theme.detailStyle.textColor set];
		[str drawInRect:r withFont:table.theme.detailStyle.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentLeft];
	}
}

@end

@implementation WIForecastDaysView

-(void) drawRect:(struct CGRect) rect
{
        NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
        NSArray* weekdays = df.shortStandaloneWeekdaySymbols;

	int width = (rect.size.width / 6);
	LITableView* table = findTableView(self);
	for (int i = 0; i < self.forecast.count && i < 6; i++)
	{
		NSDictionary* day = [self.forecast objectAtIndex:i];
		
		NSNumber* daycode = [day objectForKey:@"daycode"];
		NSString* str = [[weekdays objectAtIndex:daycode.intValue] uppercaseString];
        	CGRect r = CGRectMake(rect.origin.x + (width * i), rect.origin.y + 1, width, 13);
        	[table.theme.detailStyle.shadowColor set];
		[str drawInRect:r withFont:table.theme.detailStyle.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];

        	r.origin.y -= 1;
        	[table.theme.summaryStyle.textColor set];
		[str drawInRect:r withFont:table.theme.detailStyle.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
	}
}

@end

@interface WeatherIconPlugin : NSObject <LIPluginController, LITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) LIPlugin* plugin;
@property (nonatomic, retain) NSMutableDictionary* iconCache;
@property (nonatomic, retain) NSDictionary* dataCache;

@end

@implementation WeatherIconPlugin

@synthesize dataCache, iconCache, plugin;

-(id) loadIcon:(NSString*) path
{
	id icon = [self.iconCache objectForKey:path];

	if (path != nil && icon == nil)
	{
		icon = [UIImage imageWithContentsOfFile:path];
		[self.iconCache setValue:icon forKey:path];
	}

	return icon;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
        return 3;
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


- (UIImage *)tableView:(LITableView *)tableView iconForHeaderInSection:(NSInteger)section
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
		NSBundle* bundle = [NSBundle mainBundle];
		NSString* path = [bundle pathForResource:@"com.ashman.WeatherIcon" ofType:@"plist"];
		if (NSDictionary* theme = [NSDictionary dictionaryWithContentsOfFile:path])
			if (NSNumber* n = [theme objectForKey:@"StatusBarImageScale"])
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return (indexPath.row == 1 ? 30 : 17);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary* weather = [self.dataCache objectForKey:@"weather"];
	NSArray* forecast = [weather objectForKey:@"forecast"];
        	
	NSString* reuse;
	switch (indexPath.row)
	{
		case 0:
			reuse = @"ForecastDays";
			break;
		case 1:
			reuse = @"ForecastIcon";
			break;
		case 2:
			reuse = @"ForecastTemp";
			break;
	}

	UITableViewCell *fc = [tableView dequeueReusableCellWithIdentifier:reuse];

	if (fc == nil)
	{
		fc = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:reuse] autorelease];
		fc.backgroundColor = [UIColor clearColor];
		
		WIForecastView* fcv = nil;

		switch (indexPath.row)
		{
			case 0:
				fcv = [[[WIForecastDaysView alloc] initWithFrame:CGRectMake(10, 2, 300, 15)] autorelease];
				break;
			case 1:
				fcv = [[[WIForecastIconView alloc] initWithFrame:CGRectMake(10, 0, 300, 30)] autorelease];
				break;
			case 2:
				fcv = [[[WIForecastTempView alloc] initWithFrame:CGRectMake(10, 0, 300, 15)] autorelease];
				break;
		}

		fcv.backgroundColor = [UIColor clearColor];
		fcv.tag = 42;
		[fc.contentView addSubview:fcv];
	}

	WIForecastView* fcv = [fc viewWithTag:42];
	NSArray* forecastCopy = [forecast copy];
	fcv.forecast = forecastCopy;
	[forecastCopy release];

	if (indexPath.row == 1)
	{
		NSMutableArray* arr = [NSMutableArray arrayWithCapacity:6];
		for (int i = 0; i < forecast.count && i < 6; i++)
		{
			NSDictionary* day = [forecast objectAtIndex:i];
			UIImage* icon = [self loadIcon:[day objectForKey:@"icon"]];

			if (icon == nil)
				icon = [self defaultIcon:[day objectForKey:@"code"]];

			[arr addObject:(icon == nil ? [NSNull null] : icon)];
		}
		fcv.icons = arr;
	}

	// mark dirty
	[fcv setNeedsDisplay];

	return fc;
}

-(id) initWithPlugin:(LIPlugin*) plugin 
{
	self = [super init];
	self.plugin = plugin;
	self.iconCache = [NSMutableDictionary dictionaryWithCapacity:10];

	plugin.tableViewDataSource = self;
	plugin.tableViewDelegate = self;

        NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
//        [center addObserver:self selector:@selector(update:) name:LITimerNotification object:nil];
        [center addObserver:self selector:@selector(update:) name:LIViewReadyNotification object:nil];
        [center addObserver:self selector:@selector(updateOnUpdate:) name:@"WIWeatherUpdatedNotification" object:nil];

	return self;
}

-(void) updateWeather:(NSDictionary*) weather
{
	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:1];
	[dict setValue:weather forKey:@"weather"];

	if (![dict isEqualToDictionary:self.dataCache])
	{
		[self performSelectorOnMainThread:@selector(setDataCache:) withObject:dict waitUntilDone:YES];
		[[NSNotificationCenter defaultCenter] postNotificationName:LIUpdateViewNotification object:self.plugin userInfo:dict];
	}
}

-(void) updateOnUpdate:(NSNotification*) notif
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
//	NSLog(@"LI:Weather: Updating from WI update");
	[self updateWeather:notif.userInfo];
	[pool release];
}

-(void) update:(NSNotification*) notif
{
	if (!self.plugin.enabled)
		return;

	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	if (NSDictionary* current = [NSDictionary dictionaryWithContentsOfFile:prefsPath])
	{
//		NSLog(@"LI:Weather: Updating when view is ready");
		[self updateWeather:current];
	}

	[pool release];
}

@end
