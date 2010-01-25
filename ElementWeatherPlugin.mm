#include "WeatherIconPlugin.h"
#include <SpringBoard/SBAwayDateView.h>
#include <UIKit/UIKit.h>
#include <substrate.h>

#define localize(str) \
        [self.plugin.bundle localizedStringForKey:str value:str table:nil]

#define Hook(cls, sel, imp) \
        _ ## imp = MSHookMessage($ ## cls, @selector(sel), &$ ## imp)


extern "C" UIImage *_UIImageWithName(NSString *);
extern "C" CFStringRef UIDateFormatStringForFormatType(CFStringRef type);

@interface WIHeaderView : UIView

@property (nonatomic, retain) UIImageView* icon;
@property (nonatomic, retain) UILabel* city;
@property (nonatomic, retain) UILabel* temp;
@property (nonatomic, retain) UILabel* hilo;

@property (nonatomic, retain) UILabel* time;
@property (nonatomic, retain) UILabel* date;

-(void) updateTime;

@end

@implementation WIHeaderView

@synthesize icon, city, temp, hilo, time, date;

-(void) updateTime
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

        NSDate* now = [NSDate date];
        NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];

        df.dateFormat = [NSString stringWithFormat:@"cccc, %@", (NSString*)UIDateFormatStringForFormatType(CFSTR("UIAbbreviatedMonthDayFormat"))];
        self.date.text = [df stringFromDate:now];

        df.dateFormat = (NSString*)UIDateFormatStringForFormatType(CFSTR("UINoAMPMTimeFormat"));
        self.time.text = [df stringFromDate:now];

	[pool release];
}

@end

@interface ElementWeatherPlugin : WeatherIconPlugin
@end

static WIHeaderView* cachedView;

MSHook(void, updateClock, SBAwayDateView *self, SEL sel)
{
        _updateClock(self, sel);
	[cachedView retain];
        [cachedView updateTime];
	[cachedView release];
}

@implementation ElementWeatherPlugin

-(CGFloat) tableView:(UITableView*) tableView heightForHeaderInSection:(NSInteger) section
{
	return 96;
}

-(UIView*) tableView:(LITableView*) tableView viewForHeaderInSection:(NSInteger) section
{
	WIHeaderView* view = [[[WIHeaderView alloc] initWithFrame:CGRectMake(0, 0, 320, 96)] autorelease];

	UIImageView* iv = [[[UIImageView alloc] initWithFrame:view.bounds] autorelease];
	iv.image = _UIImageWithName(@"UILCDBackground.png");
	[view addSubview:iv];

	view.icon = [self tableView:tableView iconForHeaderInSection:section];
	view.icon.frame = CGRectMake(140, 10, 70, 70);
	[view addSubview:view.icon];

	view.city = [[[UILabel alloc] initWithFrame:CGRectMake(207, 15, 110, 14)] autorelease];
	view.city.font = [UIFont boldSystemFontOfSize:14];
	view.city.textColor = [UIColor lightGrayColor];
	view.city.backgroundColor = [UIColor clearColor];
	[view addSubview:view.city];
	
	view.temp = [[[UILabel alloc] initWithFrame:CGRectMake(207, 31, 110, 30)] autorelease];
	view.temp.font = [UIFont systemFontOfSize:30];
	view.temp.textColor = [UIColor whiteColor];
	view.temp.backgroundColor = [UIColor clearColor];
	[view addSubview:view.temp];
	
	view.hilo = [[[UILabel alloc] initWithFrame:CGRectMake(207, 63, 110, 13)] autorelease];
	view.hilo.font = [UIFont boldSystemFontOfSize:13];
	view.hilo.textColor = [UIColor lightGrayColor];
	view.hilo.backgroundColor = [UIColor clearColor];
	[view addSubview:view.hilo];
	
	NSDictionary* weather = [[self.dataCache objectForKey:@"weather"] retain];
	NSString* city = [weather objectForKey:@"city"];
	NSRange r = [city rangeOfString:@","];
	if (r.location != NSNotFound)
		city = [city substringToIndex:r.location];
	view.city.text = city;

	view.temp.text = [NSString stringWithFormat:@"%d\u00B0", [[weather objectForKey:@"temp"] intValue]];
	
	NSArray* forecast = [weather objectForKey:@"forecast"];
	if (forecast.count > 0)
	{
		NSDictionary* today = [forecast objectAtIndex:0];
		view.hilo.text = [NSString stringWithFormat:@"H %d\u00B0   L %d\u00B0", [[today objectForKey:@"high"] intValue], [[today objectForKey:@"low"] intValue]];
	}

	[weather release];

	view.time = [[[UILabel alloc] initWithFrame:CGRectMake(5, 15, 125, 45)] autorelease];
	view.time.font = [UIFont systemFontOfSize:45];
	view.time.textAlignment = UITextAlignmentCenter;
	view.time.textColor = [UIColor whiteColor];
	view.time.backgroundColor = [UIColor clearColor];
	[view addSubview:view.time];

	view.date = [[[UILabel alloc] initWithFrame:CGRectMake(5, 63, 125, 13)] autorelease];
	view.date.font = [UIFont boldSystemFontOfSize:13];
	view.date.textAlignment = UITextAlignmentCenter;
	view.date.textColor = [UIColor whiteColor];
	view.date.backgroundColor = [UIColor clearColor];
	[view addSubview:view.date];

	[view updateTime];

	id tmp = cachedView;
	cachedView = [view retain];
	[tmp release];

	return view;
}

-(id) initWithPlugin:(LIPlugin*) plugin
{
        Class $SBAwayDateView = objc_getClass("SBAwayDateView");
        Hook(SBAwayDateView, updateClock, updateClock);

	return [super initWithPlugin:plugin];
}


@end
