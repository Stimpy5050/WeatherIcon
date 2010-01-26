#include "WeatherIconPlugin.h"
#include <SpringBoard/SBAwayDateView.h>
#include <SpringBoard/SBStatusBarController.h>
#include <SpringBoard/SBStatusBarTimeView.h>
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
@property (nonatomic, retain) UILabel* high;
@property (nonatomic, retain) UILabel* low;

@property (nonatomic, retain) UILabel* time;
@property (nonatomic, retain) UILabel* date;

-(void) updateTime;

@end

@implementation WIHeaderView

@synthesize icon, city, temp, time, date, high, low;

-(void) updateTime
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

        NSDate* now = [NSDate date];
        NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];

        df.dateFormat = [NSString stringWithFormat:@"EEE, %@", (NSString*)UIDateFormatStringForFormatType(CFSTR("UIAbbreviatedMonthDayFormat"))];
//        df.dateFormat = [NSString stringWithFormat:@"cccc, %@", (NSString*)UIDateFormatStringForFormatType(CFSTR("UIAbbreviatedMonthDayFormat"))];
	NSString* dateStr = [df stringFromDate:now];
	if (![dateStr isEqualToString:self.time.text])
	        self.date.text = [df stringFromDate:now];

        df.dateFormat = (NSString*)UIDateFormatStringForFormatType(CFSTR("UINoAMPMTimeFormat"));
	NSString* timeStr = [df stringFromDate:now];
	if (![timeStr isEqualToString:self.date.text])
	        self.time.text = [df stringFromDate:now];

	[pool release];
}

@end

@interface LockWeatherPlugin : WeatherIconPlugin
@end

static WIHeaderView* cachedView;

MSHook(void, updateClock, SBAwayDateView *self, SEL sel)
{
        _updateClock(self, sel);
	[cachedView retain];
        [cachedView updateTime];
	[cachedView release];
}

MSHook(void, significantTimeChange, SBStatusBarController *self, SEL sel)
{
        _significantTimeChange(self, sel);
	[cachedView retain];
        [cachedView updateTime];
	[cachedView release];
}

MSHook(void, sbDrawRect, SBStatusBarTimeView *self, SEL sel, CGRect rect)
{
        _sbDrawRect(self, sel, rect);
	[cachedView retain];
        [cachedView updateTime];
	[cachedView release];
}


@implementation LockWeatherPlugin

-(CGFloat) tableView:(UITableView*) tableView heightForHeaderInSection:(NSInteger) section
{
	return 96;
}

-(UIView*) tableView:(LITableView*) tableView viewForHeaderInSection:(NSInteger) section
{
	WIHeaderView* view = [[[WIHeaderView alloc] initWithFrame:CGRectMake(0, 0, 320, 96)] autorelease];

	UIImage* image = _UIImageWithName(@"UILCDBackground.png");
	UIImageView* iv = [[[UIImageView alloc] initWithFrame:view.bounds] autorelease];
	iv.image = image;
	[view addSubview:iv];

	view.time = [[[UILabel alloc] initWithFrame:CGRectMake(0, 5, view.frame.size.width, 47)] autorelease];
	view.time.font = [UIFont fontWithName:@"LockClock-Light" size:47];
	view.time.textAlignment = UITextAlignmentCenter;
	view.time.textColor = [UIColor whiteColor];
	view.time.backgroundColor = [UIColor clearColor];
	[view addSubview:view.time];

	view.date = [[[UILabel alloc] initWithFrame:CGRectMake(5, 56, 120, 18)] autorelease];
	view.date.font = [UIFont boldSystemFontOfSize:14];
	view.date.textAlignment = UITextAlignmentRight;
	view.date.textColor = [UIColor whiteColor];
	view.date.backgroundColor = [UIColor clearColor];
	[view addSubview:view.date];

	view.city = [[[UILabel alloc] initWithFrame:CGRectMake(5, 73, 120, 18)] autorelease];
	[view addSubview:view.city];
	view.city.font = [UIFont boldSystemFontOfSize:14];
	view.city.textAlignment = UITextAlignmentRight;
	view.city.textColor = [UIColor lightGrayColor];
	view.city.backgroundColor = [UIColor clearColor];

	[view updateTime];

	view.icon = [self tableView:tableView iconForHeaderInSection:section];
	CGRect ir = view.icon.frame;
	ir.size.width *= 2.75;
	ir.size.height *= 2.75;
	view.icon.frame = ir;
	view.icon.center = CGPointMake(160, 73);
	[view addSubview:view.icon];

	view.temp = [[[UILabel alloc] initWithFrame:CGRectMake(195, 56, 120, 36)] autorelease];
	[view addSubview:view.temp];
	view.temp.font = [UIFont systemFontOfSize:36];
//	view.temp.font = [UIFont fontWithName:@"LockClock-Light" size:36];
	view.temp.textColor = [UIColor whiteColor];
	view.temp.backgroundColor = [UIColor clearColor];

	view.high = [[[UILabel alloc] initWithFrame:CGRectMake(195, 56, 120, 18)] autorelease];
	[view addSubview:view.high];
	view.high.font = [UIFont boldSystemFontOfSize:14];
	view.high.textColor = [UIColor lightGrayColor];
	view.high.backgroundColor = [UIColor clearColor];

	view.low = [[[UILabel alloc] initWithFrame:CGRectMake(195, 73, 120, 18)] autorelease];
	[view addSubview:view.low];
	view.low.font = [UIFont boldSystemFontOfSize:14];
	view.low.textColor = [UIColor lightGrayColor];
	view.low.backgroundColor = [UIColor clearColor];

	NSDictionary* weather = [[self.dataCache objectForKey:@"weather"] retain];
	NSString* city = [weather objectForKey:@"city"];
	NSRange r = [city rangeOfString:@","];
	if (r.location != NSNotFound)
		city = [city substringToIndex:r.location];
	view.city.text = city;

	if (NSArray* forecast = [weather objectForKey:@"forecast"])
	{
		if (forecast.count > 0)
		{
			NSDictionary* today = [forecast objectAtIndex:0];
			view.high.text = [NSString stringWithFormat:@"H %d\u00B0", [[today objectForKey:@"high"] intValue]];
			view.low.text = [NSString stringWithFormat:@"L %d\u00B0", [[today objectForKey:@"low"] intValue]];
		}
	}

	view.temp.text = [NSString stringWithFormat:@"%d\u00B0", [[weather objectForKey:@"temp"] intValue]];

	CGSize ts = [view.temp.text sizeWithFont:view.temp.font];

	CGRect tr = view.high.frame;
	tr.origin.x = view.temp.frame.origin.x + ts.width + 8;
	view.high.frame = tr;

	tr = view.low.frame;
	tr.origin.x = view.temp.frame.origin.x + ts.width + 8;
	view.low.frame = tr;

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
	Class $SBStatusBarController = objc_getClass("SBStatusBarController");
        Hook(SBStatusBarController, signicantTimeChange, significantTimeChange);
        Class $SBStatusBarTimeView = objc_getClass("SBStatusBarTimeView");
        Hook(SBStatusBarTimeView, drawRect:, sbDrawRect);

	return [super initWithPlugin:plugin];
}


@end
