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
@property (nonatomic, retain) UILabel* description;

@property (nonatomic, retain) UILabel* time;
@property (nonatomic, retain) UILabel* date;

-(void) updateTime;

@end

@implementation WIHeaderView

@synthesize icon, city, temp, description, time, date;

-(void) updateTime
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

        NSDate* now = [NSDate date];
        NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];

        df.dateFormat = [NSString stringWithFormat:@"cccc, %@", (NSString*)UIDateFormatStringForFormatType(CFSTR("UIAbbreviatedMonthDayFormat"))];
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


@implementation ElementWeatherPlugin

-(CGFloat) tableView:(UITableView*) tableView heightForHeaderInSection:(NSInteger) section
{
	return 96;
}

-(UIView*) tableView:(LITableView*) tableView viewForHeaderInSection:(NSInteger) section
{
	WIHeaderView* view = [[[WIHeaderView alloc] initWithFrame:CGRectMake(0, 0, 320, 96)] autorelease];

	UIImage* image = nil;
	if (NSString* path = [self.plugin.bundle pathForResource:@"LIElementHeader" ofType:@"png"])
		image = [UIImage imageWithContentsOfFile:path];
	else
		image = _UIImageWithName(@"UILCDBackground.png");

	UIImageView* iv = [[[UIImageView alloc] initWithFrame:view.bounds] autorelease];
	iv.image = image;
	[view addSubview:iv];

	UIView* timeDate = [[[UIView alloc] initWithFrame:CGRectMake(5, 9, 175, 73)] autorelease];
	timeDate.backgroundColor = [UIColor clearColor];
	[view addSubview:timeDate];

	view.time = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, timeDate.frame.size.width, 59)] autorelease];
	view.time.font = [UIFont fontWithName:@"LockClock-Light" size:59];
	view.time.textAlignment = UITextAlignmentCenter;
	view.time.textColor = [UIColor whiteColor];
	view.time.backgroundColor = [UIColor clearColor];
	[timeDate addSubview:view.time];

	view.date = [[[UILabel alloc] initWithFrame:CGRectMake(0, 55, timeDate.frame.size.width, 18)] autorelease];
	view.date.font = [UIFont boldSystemFontOfSize:14];
	view.date.textAlignment = UITextAlignmentCenter;
	view.date.textColor = [UIColor whiteColor];
	view.date.backgroundColor = [UIColor clearColor];
	[timeDate addSubview:view.date];

	[view updateTime];

	UIView* weatherView = [[[UIView alloc] initWithFrame:CGRectMake(185, 14, 130, 68)] autorelease];
	weatherView.backgroundColor = [UIColor clearColor];
	[view addSubview:weatherView];

	view.icon = [self tableView:tableView iconForHeaderInSection:section];
	view.icon.frame = CGRectMake(0, 0, 50, 50);
	[weatherView addSubview:view.icon];

	view.city = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, weatherView.frame.size.width, 18)] autorelease];
	[weatherView addSubview:view.city];
	view.city.font = [UIFont boldSystemFontOfSize:14];
	view.city.textColor = [UIColor lightGrayColor];
	view.city.backgroundColor = [UIColor clearColor];

	view.temp = [[[UILabel alloc] initWithFrame:CGRectMake(0, 19, weatherView.frame.size.width, 30)] autorelease];
	[weatherView addSubview:view.temp];
	view.temp.font = [UIFont fontWithName:@"LockClock-Light" size:30];
	view.temp.textColor = [UIColor whiteColor];
	view.temp.backgroundColor = [UIColor clearColor];

	view.description = [[[UILabel alloc] initWithFrame:CGRectMake(0, 50, weatherView.frame.size.width, 18)] autorelease];
	[weatherView addSubview:view.description];
	view.description.font = [UIFont boldSystemFontOfSize:14];
	view.description.textColor = [UIColor lightGrayColor];
	view.description.backgroundColor = [UIColor clearColor];
	
	NSDictionary* weather = [[self.dataCache objectForKey:@"weather"] retain];
	NSString* city = [weather objectForKey:@"city"];
	NSRange r = [city rangeOfString:@","];
	if (r.location != NSNotFound)
		city = [city substringToIndex:r.location];
	view.city.text = city;

	view.temp.text = [NSString stringWithFormat:@"%d\u00B0", [[weather objectForKey:@"temp"] intValue]];
	view.description.text = [self tableView:tableView detailForHeaderInSection:section];

	CGSize ts = [view.temp.text sizeWithFont:view.temp.font];
	view.icon.center = CGPointMake(ts.width + 17, view.temp.frame.origin.y + 16);

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
