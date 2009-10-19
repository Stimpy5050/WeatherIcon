#include "PluginDelegate.h"
#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

static NSArray* dayNames = [[NSArray arrayWithObjects:@"SUN", @"MON", @"TUE", @"WED", @"THU", @"FRI", @"SAT", nil] retain];

static NSString* prefsPath = @"/User/Library/Preferences/com.ashman.WeatherIcon.Condition.plist";

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

@interface WIHeaderView : UIView

@property (nonatomic, retain) UIImage* icon;
@property (nonatomic, retain) NSString* city;
@property (nonatomic) int temp;
@property (nonatomic, retain) NSString* condition;

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
		if (NSNumber* n = [theme objectForKey:@"LockInfoImageScale"])
			scale = n.doubleValue;

	LITableView* table = findTableView(self);
	for (int i = 0; i < self.forecast.count && i < 6; i++)
	{
		id image = [self.icons objectAtIndex:i];
		if (image != [NSNull null])
		{
			CGSize s = [image size];
			s.width *= scale;
			s.height *= scale;

			CGRect r = CGRectMake(rect.origin.x + (width * i) + (width / 2) - (s.width / 2), rect.origin.y + 18 - (s.height / 2), s.width, s.height);
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
        	[table.shadowColor set];
		[str drawInRect:r withFont:table.detailFont lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];

        	r.origin.y -= 1;
        	[table.summaryColor set];
		[str drawInRect:r withFont:table.detailFont lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];


		str = [NSString stringWithFormat:@" %@\u00B0", [day objectForKey:@"low"]];
        	r = CGRectMake(rect.origin.x + (width * i) + r.size.width, rect.origin.y + 1, (width / 2), 11);
        	[table.shadowColor set];
		[str drawInRect:r withFont:table.detailFont lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentLeft];

        	r.origin.y -= 1;
        	[table.detailColor set];
		[str drawInRect:r withFont:table.detailFont lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentLeft];
	}
}

@end

@implementation WIForecastDaysView

-(void) drawRect:(struct CGRect) rect
{
	int width = (rect.size.width / 6);
	LITableView* table = findTableView(self);
	for (int i = 0; i < self.forecast.count && i < 6; i++)
	{
		NSDictionary* day = [self.forecast objectAtIndex:i];
		
		NSNumber* daycode = [day objectForKey:@"daycode"];
		NSString* str = [dayNames objectAtIndex:daycode.intValue];
        	CGRect r = CGRectMake(rect.origin.x + (width * i), rect.origin.y + 1, width, 13);
        	[table.shadowColor set];
		[str drawInRect:r withFont:table.detailFont lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];

        	r.origin.y -= 1;
        	[table.summaryColor set];
		[str drawInRect:r withFont:table.detailFont lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
	}
}

@end

@implementation WIHeaderView

@synthesize icon, city, temp, condition;

-(void) drawRect:(struct CGRect) rect
{
	NSLog(@"LI:WeatherIcon: Drawing section header");

	if (self.icon != nil)
	{
		double scale = 0.33;

		NSBundle* bundle = [NSBundle mainBundle];
		NSString* path = [bundle pathForResource:@"com.ashman.WeatherIcon" ofType:@"plist"];
		if (NSDictionary* theme = [NSDictionary dictionaryWithContentsOfFile:path])
			if (NSNumber* n = [theme objectForKey:@"StatusBarImageScale"])
				scale = n.doubleValue;

		CGSize s = self.icon.size;
		s.width = s.width * scale;
		s.height = s.height * scale;

        	[self.icon drawInRect:CGRectMake((rect.size.height / 2) - (s.width / 2), (rect.size.height / 2) - (s.height / 2), s.width, s.height)];
	}

	// find the tableview
	LITableView* table;
	UIView* view = self;
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

	NSString* city = self.city;
	NSRange r = [city rangeOfString:@","];
	if (r.location != NSNotFound)
		city = [city substringToIndex:r.location];

        NSString* str = [NSString stringWithFormat:@"%@: %d\u00B0", city, self.temp];
        [table.shadowColor set];
	int x = (self.icon == nil ? 5 : 24);
	[str drawInRect:CGRectMake(x, 3, 137, 22) withFont:[UIFont boldSystemFontOfSize:14] lineBreakMode:UILineBreakModeClip];
	[self.condition drawInRect:CGRectMake(165, 4, 150, 21) withFont:[UIFont boldSystemFontOfSize:12] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];

        [table.headerColor set];
	[str drawInRect:CGRectMake(x, 2, 137, 22) withFont:[UIFont boldSystemFontOfSize:14] lineBreakMode:UILineBreakModeClip];
	[self.condition drawInRect:CGRectMake(165, 3, 150, 21) withFont:[UIFont boldSystemFontOfSize:12] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];
}

@end

@interface WeatherIconPlugin : NSObject <LIPluginDelegate, UITableViewDataSource>
{
	double lastUpdate;
}

@property (nonatomic, retain) NSMutableDictionary* iconCache;
@property (nonatomic, retain) NSDictionary* dataCache;
@property (nonatomic, retain) NSDictionary* preferences;

@end

@implementation WeatherIconPlugin

@synthesize preferences, dataCache, iconCache;

-(id) init
{
	self.iconCache = [NSMutableDictionary dictionaryWithCapacity:10];
	return [super init];
}

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

- (UIView *)tableView:(LITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	WIHeaderView* v = [[[WIHeaderView alloc] initWithFrame:CGRectMake(0, 0, 320, 23)] autorelease];
	v.backgroundColor = [UIColor clearColor];

	NSDictionary* weather = [self.dataCache objectForKey:@"weather"];
	v.icon = [self loadIcon:[weather objectForKey:@"icon"]];
	v.city = [weather objectForKey:@"city"];
	v.temp = [[weather objectForKey:@"temp"] intValue];
	v.condition = [weather objectForKey:@"description"];

	return v;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row == 1)
	{
		NSDictionary* weather = [self.dataCache objectForKey:@"weather"];
		NSArray* forecast = [weather objectForKey:@"forecast"];
		BOOL hasIcon = false;

		for (int i = 0; i < forecast.count && i < 6; i++)
		{
			NSDictionary* day = [forecast objectAtIndex:i];
			hasIcon |= ([self loadIcon:[day objectForKey:@"icon"]] != nil);
		}

		int height = (hasIcon ? 34 : 4);
		return height;
	}
	else
	{
		return 16;
	}
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
				fcv = [[[WIForecastIconView alloc] initWithFrame:CGRectMake(10, 0, 300, 34)] autorelease];
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
			[arr addObject:(icon == nil ? [NSNull null] : icon)];
		}
		fcv.icons = arr;
	}

	// mark dirty
	[fcv setNeedsDisplay];

	return fc;
}

-(NSDictionary*) data
{
	NSDate* modDate = nil;
	NSFileManager* fm = [NSFileManager defaultManager];
	if (NSDictionary* attrs = [fm fileAttributesAtPath:prefsPath traverseLink:true])
		if (modDate = [attrs objectForKey:NSFileModificationDate])
			if ([modDate timeIntervalSinceReferenceDate] <= lastUpdate)
				return nil;

	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:1];

	if (NSDictionary* current = [NSDictionary dictionaryWithContentsOfFile:prefsPath])
	{
		[dict setObject:current forKey:@"weather"];
		lastUpdate = (modDate == nil ? lastUpdate : [modDate timeIntervalSinceReferenceDate]);
	}

	[dict setObject:self.preferences forKey:@"preferences"];

	self.dataCache = dict;

	return dict;
}

@end
