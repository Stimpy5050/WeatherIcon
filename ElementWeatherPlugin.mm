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

//        df.dateFormat = (NSString*)UIDateFormatStringForFormatType(CFSTR("UIWeekdayNoYearDateFormat"));
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

	view.time = [[[UILabel alloc] initWithFrame:CGRectMake(5, 10, 160, 55)] autorelease];
	view.time.font = [UIFont fontWithName:@"LockClock-Light" size:55];
	view.time.textAlignment = UITextAlignmentCenter;
/*
	view.time = [[[UILabel alloc] initWithFrame:CGRectMake(0, 10, 150, 55)] autorelease];
	view.time.font = [UIFont fontWithName:@"LockClock-Light" size:55];
	view.time.textAlignment = UITextAlignmentRight;
*/
	view.time.textColor = [UIColor whiteColor];
	view.time.backgroundColor = [UIColor clearColor];
	[view addSubview:view.time];

	view.date = [[[UILabel alloc] initWithFrame:CGRectMake(5, 63, 160, 18)] autorelease];
	view.date.font = [UIFont boldSystemFontOfSize:14];
/*
	view.date = [[[UILabel alloc] initWithFrame:CGRectMake(0, 67, 320, 17)] autorelease];
	view.date.font = [UIFont systemFontOfSize:17];
*/
	view.date.textAlignment = UITextAlignmentCenter;
	view.date.textColor = [UIColor whiteColor];
	view.date.backgroundColor = [UIColor clearColor];
	[view addSubview:view.date];

	[view updateTime];

	UIView* weatherView = [[[UIView alloc] initWithFrame:CGRectMake(180, 15, 130, 65)] autorelease];
	weatherView.backgroundColor = [UIColor clearColor];
	[view addSubview:weatherView];

	view.icon = [self tableView:tableView iconForHeaderInSection:section];
//	view.icon.frame = CGRectMake(140, 10, 70, 70);
//	[view addSubview:view.icon];
	view.icon.frame = CGRectMake(0, 0, 50, 50);
	[weatherView addSubview:view.icon];

//	view.city = [[[UILabel alloc] initWithFrame:CGRectMake(207, 15, 110, 14)] autorelease];
//	[view addSubview:view.city];

	view.city = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 130, 18)] autorelease];
	[weatherView addSubview:view.city];
	view.city.font = [UIFont boldSystemFontOfSize:14];
	view.city.textColor = [UIColor lightGrayColor];
	view.city.backgroundColor = [UIColor clearColor];

/*	
	view.temp = [[[UILabel alloc] initWithFrame:CGRectMake(207, 31, 110, 30)] autorelease];
	[view addSubview:view.temp];
*/

	view.temp = [[[UILabel alloc] initWithFrame:CGRectMake(0, 18, 100, 30)] autorelease];
	[weatherView addSubview:view.temp];
	view.temp.font = [UIFont fontWithName:@"LockClock-Light" size:30];
//	view.temp.font = [UIFont systemFontOfSize:30];
	view.temp.textColor = [UIColor whiteColor];
	view.temp.backgroundColor = [UIColor clearColor];

/*	
	view.hilo = [[[UILabel alloc] initWithFrame:CGRectMake(207, 63, 110, 13)] autorelease];
	[view addSubview:view.hilo];
*/

	view.hilo = [[[UILabel alloc] initWithFrame:CGRectMake(0, 48, 130, 18)] autorelease];
	[weatherView addSubview:view.hilo];
	view.hilo.font = [UIFont boldSystemFontOfSize:14];
	view.hilo.textColor = [UIColor lightGrayColor];
	view.hilo.backgroundColor = [UIColor clearColor];
	
	NSDictionary* weather = [[self.dataCache objectForKey:@"weather"] retain];
	NSString* city = [weather objectForKey:@"city"];
	NSRange r = [city rangeOfString:@","];
	if (r.location != NSNotFound)
		city = [city substringToIndex:r.location];
	view.city.text = city;

	view.temp.text = [NSString stringWithFormat:@"%d\u00B0", [[weather objectForKey:@"temp"] intValue]];
	view.hilo.text = [self tableView:tableView detailForHeaderInSection:section];

	CGSize ts = [view.temp.text sizeWithFont:view.temp.font];
	view.icon.center = CGPointMake(ts.width + 20, view.temp.frame.origin.y + 15);

/*	
	NSArray* forecast = [weather objectForKey:@"forecast"];
	if (forecast.count > 0)
	{
		NSDictionary* today = [forecast objectAtIndex:0];
		view.hilo.text = [NSString stringWithFormat:@"H %d\u00B0   L %d\u00B0", [[today objectForKey:@"high"] intValue], [[today objectForKey:@"low"] intValue]];
	}
*/

	[weather release];

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
