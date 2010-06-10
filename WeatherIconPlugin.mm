#include "WeatherIconPlugin.h"
#include <UIKit/UIKit.h>
#include <UIKit/UIScreen.h>

#define localize(str) \
        [self.plugin.bundle localizedStringForKey:str value:str table:nil]

static NSString* prefsPath = @"/User/Library/Caches/com.ashman.WeatherIcon.cache.plist";

@implementation WIForecastView

@synthesize forecast, theme;

@end

@implementation WIForecastIconView

@synthesize icons;

-(void) setFrame:(CGRect) r
{
	[super setFrame:r];
	[self setNeedsDisplay];
}

-(void) drawRect:(struct CGRect) rect
{
	int width = (rect.size.width / 6);
	double scale = 0.66;

	NSBundle* bundle = [NSBundle mainBundle];
	NSString* path = [bundle pathForResource:@"com.ashman.WeatherIcon" ofType:@"plist"];
	if (NSDictionary* thm = [NSDictionary dictionaryWithContentsOfFile:path])
	{
//		if (NSNumber* n = [thm objectForKey:@"ImageScale"])
//			scale = n.doubleValue;

		if (NSNumber* n = [thm objectForKey:@"LockInfoImageScale"])
			scale = n.doubleValue;
	}

	for (int i = 0; i < self.forecast.count && i < 6; i++)
	{
		id image = [self.icons objectAtIndex:i];
		if (image != [NSNull null])
		{
			UIImage* realImage = (UIImage*) image;
			CGSize s = realImage.size;
			s.width *= scale;
			s.height *= scale;

			CGRect r = CGRectMake(rect.origin.x + (width * i) + (width / 2) - (s.width / 2), rect.origin.y + (rect.size.height / 2) - (s.height / 2), s.width, s.height);
			[image drawInRect:r];
		}
	}
}

@end

@implementation WIForecastTempView

@synthesize timestamp, updatedString;

-(void) setFrame:(CGRect) r
{
	[super setFrame:r];
	[self setNeedsDisplay];
}

-(void) drawRect:(struct CGRect) rect
{
	int width = (rect.size.width / 6);
	for (int i = 0; i < self.forecast.count && i < 6; i++)
	{
		NSDictionary* day = [self.forecast objectAtIndex:i];

		NSString* str = [NSString stringWithFormat:@"%@\u00B0", [day objectForKey:@"high"]];
        	CGRect r = CGRectMake(rect.origin.x + (width * i) - 5, rect.origin.y + 1, (width / 2) + 5, theme.detailStyle.font.pointSize);
        	[theme.detailStyle.shadowColor set];
		[str drawInRect:r withFont:theme.detailStyle.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];

        	r.origin.y -= 1;
        	[theme.summaryStyle.textColor set];
		[str drawInRect:r withFont:theme.detailStyle.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];

		str = [NSString stringWithFormat:@" %@\u00B0", [day objectForKey:@"low"]];
        	r = CGRectMake(rect.origin.x + (width * i) + r.size.width - 5, rect.origin.y + 1, (width / 2) + 5, theme.detailStyle.font.pointSize);
        	[theme.detailStyle.shadowColor set];
		[str drawInRect:r withFont:theme.detailStyle.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentLeft];

        	r.origin.y -= 1;
        	[theme.detailStyle.textColor set];
		[str drawInRect:r withFont:theme.detailStyle.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentLeft];
	}

	if (self.timestamp)
	{
		NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
		df.dateStyle = NSDateFormatterShortStyle;
		df.timeStyle = NSDateFormatterShortStyle;
		NSString* str = [NSString stringWithFormat:@"%@ %@", self.updatedString, [df stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.timestamp.doubleValue]]];

		UIFont* font = [UIFont boldSystemFontOfSize:(theme.detailStyle.font.pointSize - 2)];
		CGRect r = CGRectMake(0, rect.origin.y + theme.detailStyle.font.pointSize + 8, rect.size.width, font.pointSize);
        	[theme.detailStyle.shadowColor set];
		[str drawInRect:r withFont:font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];

        	r.origin.y -= 1;
        	[theme.detailStyle.textColor set];
		[str drawInRect:r withFont:font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
	}
}

@end

@implementation WIForecastDaysView

-(void) setFrame:(CGRect) r
{
	[super setFrame:r];
	[self setNeedsDisplay];
}

-(void) drawRect:(struct CGRect) rect
{
        NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
        NSArray* weekdays = df.shortStandaloneWeekdaySymbols;

	int width = (rect.size.width / 6);
	for (int i = 0; i < self.forecast.count && i < 6; i++)
	{
		NSDictionary* day = [self.forecast objectAtIndex:i];
		
		NSNumber* daycode = [day objectForKey:@"daycode"];
		NSString* str = [[weekdays objectAtIndex:daycode.intValue] uppercaseString];
        	CGRect r = CGRectMake(rect.origin.x + (width * i), rect.origin.y + 1, width, theme.detailStyle.font.pointSize + 2);
        	[theme.detailStyle.shadowColor set];
		[str drawInRect:r withFont:theme.detailStyle.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];

        	r.origin.y -= 1;
        	[theme.summaryStyle.textColor set];
		[str drawInRect:r withFont:theme.detailStyle.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
	}
}

@end

extern "C" UIImage *_UIImageWithName(NSString *);

@implementation WeatherIconPlugin

@synthesize dataCache, iconCache, plugin, daysView, iconView, tempView, updateLock, reloadCondition;

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
		NSBundle* wiBundle = [NSBundle bundleWithPath:@"/Library/WeatherIcon"];
		NSString* wiPath = [wiBundle pathForResource:@"Theme" ofType:@"plist"];
		if (NSDictionary* theme = [NSDictionary dictionaryWithContentsOfFile:wiPath])
			if (NSNumber* n = [theme objectForKey:@"StatusBarImageScale"])
				scale = n.doubleValue;

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

- (UIImageView *)tableView:(LITableView *)tableView iconForHeaderInSection:(NSInteger)section
{
	return [self weatherIcon];
}

- (CGFloat)tableView:(LITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.row)
	{
		case 0:
			return tableView.theme.detailStyle.font.pointSize + 6;
		case 1:
			return 30;
		case 2:
			BOOL show = false;
			if (NSNumber* n = [self.plugin.preferences objectForKey:@"ShowUpdateTime"])
				show = n.boolValue;

			float height = tableView.theme.detailStyle.font.pointSize + 6;
			return (show ? 2 * height : height);
	}
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
	NSDictionary* weather = [self.dataCache objectForKey:@"weather"];
	NSArray* forecast = [[weather objectForKey:@"forecast"] copy];

	self.daysView.forecast = forecast;
	[self.daysView setNeedsDisplay];

	self.iconView.forecast = forecast;

	NSMutableArray* arr = [NSMutableArray arrayWithCapacity:6];
	for (int i = 0; i < forecast.count && i < 6; i++)
	{
		NSDictionary* day = [forecast objectAtIndex:i];
		UIImage* icon = [self loadIcon:[day objectForKey:@"icon"]];

		if (icon == nil)
			icon = [self defaultIcon:[day objectForKey:@"code"]];

		[arr addObject:(icon == nil ? [NSNull null] : icon)];
	}
	self.iconView.icons = arr;
	[self.iconView setNeedsDisplay];

	BOOL show = false;
	if (NSNumber* n = [self.plugin.preferences objectForKey:@"ShowUpdateTime"])
		show = n.boolValue;

	self.tempView.forecast = forecast;
	self.tempView.updatedString = localize(@"Updated");
	self.tempView.timestamp = (show ? [weather objectForKey:@"timestamp"] : nil);
	[self.tempView setNeedsDisplay];

	[forecast release];
}

- (UITableViewCell *)tableView:(LITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString* reuse = [NSString stringWithFormat:@"Forecast%d", indexPath.row];
	UITableViewCell *fc = [tableView dequeueReusableCellWithIdentifier:reuse];

	int height = [self tableView:tableView heightForRowAtIndexPath:indexPath];
	if (fc == nil)
	{
		fc = [[[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, height) reuseIdentifier:reuse] autorelease];
		fc.backgroundColor = [UIColor clearColor];
		
		WIForecastView* fcv = nil;
		switch (indexPath.row)
		{
			case 0:
				fcv = self.daysView;
				break;
			case 1:
				fcv = self.iconView;
				break;
			case 2:
				fcv = self.tempView;
				break;
		}

		fcv.frame = CGRectMake(10, (indexPath.row == 0 ? 2 : 0), [UIScreen mainScreen].bounds.size.width - 10, height);
		fcv.backgroundColor = [UIColor clearColor];
		fcv.tag = 42;
		[fc.contentView addSubview:fcv];
	}

	WIForecastView* fcv = [fc viewWithTag:42];
	fcv.theme = tableView.theme;

	NSDictionary* weather = [self.dataCache objectForKey:@"weather"];
	NSArray* forecast = [[weather objectForKey:@"forecast"] copy];
	fcv.forecast = forecast;

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
		self.iconView.icons = arr;
	}

	[forecast release];

	BOOL show = false;
	if (NSNumber* n = [self.plugin.preferences objectForKey:@"ShowUpdateTime"])
		show = n.boolValue;

	self.tempView.updatedString = localize(@"Updated");
	self.tempView.timestamp = (show ? [weather objectForKey:@"timestamp"] : nil);

	// mark dirty
	[fcv setNeedsDisplay];

	return fc;
}

-(id) initWithPlugin:(LIPlugin*) plugin 
{
	self = [super init];
	self.plugin = plugin;
	self.dataCache = [NSMutableDictionary dictionaryWithCapacity:10];
	self.iconCache = [NSMutableDictionary dictionaryWithCapacity:10];

	self.daysView = [[[WIForecastDaysView alloc] init] autorelease];
	self.daysView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.iconView = [[[WIForecastIconView alloc] init] autorelease];
	self.iconView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.tempView = [[[WIForecastTempView alloc] init] autorelease];
	self.tempView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

	self.reloadCondition = [[[NSCondition alloc] init] autorelease];
	self.updateLock = [[[NSLock alloc] init] autorelease];

	plugin.tableViewDataSource = self;
	plugin.tableViewDelegate = self;

        NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(update:) name:LIViewReadyNotification object:nil];
        [center addObserver:self selector:@selector(updateOnUpdate:) name:@"WIWeatherUpdatedNotification" object:nil];

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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"WIRefreshNotification" object:nil];
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

	if (NSDictionary* current = [NSDictionary dictionaryWithContentsOfFile:prefsPath])
	{
//		NSLog(@"LI:Weather: Updating when view is ready");
		[self updateWeather:current];
	}

	[pool release];
}

@end
