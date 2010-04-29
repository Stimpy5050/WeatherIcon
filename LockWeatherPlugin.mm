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

static NSString* dateFormat;
static NSString* timeFormat;

extern "C" UIImage *_UIImageWithName(NSString *);
extern "C" CFStringRef UIDateFormatStringForFormatType(CFStringRef type);

@interface CalendarView : UIView

@property BOOL showWeeks;
@property (nonatomic, retain) NSDate* date;
@property (nonatomic, retain) LIStyle* headerStyle;
@property (nonatomic, retain) LIStyle* dayStyle;
@property (nonatomic, retain) UIImage* marker;

@end

static BOOL showCalendar = false;

@interface NSDate (LICalendar)

-(NSDate*) lastMonth;
-(NSDate*) nextMonth;

@end

@implementation NSDate (LICalendar)

-(NSDate*) lastMonth
{
	NSCalendar* cal = [NSCalendar currentCalendar];
	NSDateComponents* comp = [cal components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self];
	comp.month -= 1;
	return [cal dateFromComponents:comp];
}

-(NSDate*) nextMonth
{
	NSCalendar* cal = [NSCalendar currentCalendar];
	NSDateComponents* comp = [cal components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self];
	comp.month += 1;
	return [cal dateFromComponents:comp];
}

@end

@interface CalendarScrollView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, retain) CalendarView* lastMonth;
@property (nonatomic, retain) CalendarView* currentMonth;
@property (nonatomic, retain) CalendarView* nextMonth;

@end

@implementation CalendarScrollView

@synthesize lastMonth, nextMonth, currentMonth;

-(void) setDate:(NSDate*) date
{
	self.currentMonth.date = date;
	[self.currentMonth setNeedsDisplay];

	self.lastMonth.date = [self.currentMonth.date lastMonth];
	[self.lastMonth setNeedsDisplay];

	self.nextMonth.date = [self.currentMonth.date nextMonth];
	[self.nextMonth setNeedsDisplay];
}

-(void) updateMonths:(UIScrollView*) view adjustment:(int) adj
{
	if (view.contentOffset.x == 320)
		return;

	CGPoint offset = view.contentOffset;

	if (offset.x == 0)
	{
		[self setDate:self.lastMonth.date];
		offset.x = 320 - adj;
	}
	else
	{
		[self setDate:self.nextMonth.date];
		offset.x = 320 + adj;
	}

	view.contentOffset = offset;
}

-(void) scrollViewDidEndDecelerating:(UIScrollView*) view
{
	[self updateMonths:view adjustment:1];
}

-(void) scrollViewDidEndScrollingAnimation:(UIScrollView*) view
{
	[self updateMonths:view adjustment:-1];
}

-(void) resetDate
{
	NSDate* now = [NSDate date];
	NSCalendar* cal = [NSCalendar currentCalendar];
        NSDateComponents* nowComps = [cal components:NSYearCalendarUnit | NSMonthCalendarUnit fromDate:now];
        NSDateComponents* dateComps = [cal components:NSYearCalendarUnit | NSMonthCalendarUnit fromDate:self.currentMonth.date];

	int nowMonths = (nowComps.year * 12) + nowComps.month;
	int dateMonths = (dateComps.year * 12) + dateComps.month;

	if (nowMonths < dateMonths)
	{
		self.lastMonth.date = now;
		[self.lastMonth setNeedsDisplay];
		[self setContentOffset:CGPointMake(0, 0) animated:YES];
	}
	else if (nowMonths > dateMonths)
	{
		self.nextMonth.date = now;
		[self.nextMonth setNeedsDisplay];
		[self setContentOffset:CGPointMake(640, 0) animated:YES];
	}
}

@end


@implementation CalendarView

@synthesize headerStyle, dayStyle, marker, date, showWeeks;

-(void) drawRect:(CGRect) viewRect
{
	CGRect rect = CGRectMake(viewRect.origin.x + (self.showWeeks ? 40 : 20), viewRect.origin.y, viewRect.size.width - 40, viewRect.size.height);
	
        int width = rect.size.width / 7;
        NSCalendar* cal = [NSCalendar currentCalendar];

        NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
	df.dateFormat = @"MMMM yyyy";
        CGRect r = CGRectMake(viewRect.origin.x, 2, viewRect.size.width, self.headerStyle.font.pointSize);
        NSString* s = [[df stringFromDate:self.date] uppercaseString];
        [self.dayStyle.textColor set];
        [s drawInRect:r withFont:self.dayStyle.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];

        [self.headerStyle.textColor set];
	r.size.width = width;
	r.origin.y += self.headerStyle.font.pointSize + 3;

        int firstWeekday = cal.firstWeekday;

        NSArray* weekdays = df.shortStandaloneWeekdaySymbols;
        for (int i = 0; i < 7; i++)
        {
                r.origin.x = rect.origin.x + (i * width);
                int index = (i + firstWeekday - 1);
                NSString* s = [[weekdays objectAtIndex:(index >= weekdays.count ? index - weekdays.count : index)] uppercaseString];
                [s drawInRect:r withFont:self.dayStyle.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
        }

        NSRange dayRange = [cal rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:self.date];
        NSDateComponents* comp = [cal components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self.date];
        int today = comp.day;

        comp.day = 1;
        NSDate* first = [cal dateFromComponents:comp];
        comp = [cal components:NSWeekdayCalendarUnit | NSWeekCalendarUnit fromDate:first];

        for (int i = 0; i < dayRange.length; i++)
        {
                int day = i + comp.weekday - (firstWeekday - 1);
                int week = (day - 1) / 7;
                int index = (day - 1) % 7;

                r.origin.x = rect.origin.x + (index * width);
                r.origin.y = (week * (self.dayStyle.font.pointSize + 6)) + (self.headerStyle.font.pointSize * 2) + 9;

		if (self.showWeeks && (index == 0 || i == 0))
		{
        		[self.headerStyle.textColor set];
                	NSString* s = [NSString stringWithFormat:@"W%d", comp.week + week];
			CGRect wr = CGRectMake(5, r.origin.y, 40, r.size.height);
	                [s drawInRect:wr withFont:self.dayStyle.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentLeft];
		}

                NSString* s = [[NSNumber numberWithInt:i + 1] stringValue];

                if (self.dayStyle.shadowColor)
		{
                        [self.dayStyle.shadowColor set];

                        [s drawInRect:CGRectOffset(r, self.dayStyle.shadowOffset.width, self.dayStyle.shadowOffset.height) withFont:self.dayStyle.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
                }

		BOOL showMarker = NO;
                if (today == i + 1)
                {
			// check the month too
        		NSDateComponents* thisComps = [cal components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self.date];
        		NSDateComponents* nowComps = [cal components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[NSDate date]];
			showMarker = (nowComps.month == thisComps.month && nowComps.year == thisComps.year);
		}

		if (showMarker)
		{
	        	CGRect rr = CGRectMake(r.origin.x + (r.size.width / 2) - (self.marker.size.width / 2), r.origin.y + (r.size.height / 2) - ((self.dayStyle.font.pointSize + 4) / 2), self.marker.size.width, self.dayStyle.font.pointSize + 5);
       	               	[self.marker drawInRect:rr];
			[self.headerStyle.textColor set];
                }
                else
                {
                        [self.dayStyle.textColor set];
                }

                [s drawInRect:r withFont:self.dayStyle.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
        }
}

@end

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

-(void) touchesBegan:(NSSet*) touches withEvent:(UIEvent*) event
{
	UITouch* touch = [touches anyObject];
	CGPoint p = [touch locationInView:self];
	showCalendar = (p.x < 160);
	return [self.nextResponder touchesBegan:touches withEvent:event];
}

-(void) updateTime
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

        NSDate* now = [NSDate date];
        NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];

        df.dateFormat = dateFormat;
	NSString* dateStr = [df stringFromDate:now];
	if (![dateStr isEqualToString:self.time.text])
	{
	        self.date.text = [df stringFromDate:now];
	}

        df.dateFormat = timeFormat;
	NSString* timeStr = [df stringFromDate:now];
	if (![timeStr isEqualToString:self.date.text])
	        self.time.text = [df stringFromDate:now];

	[pool release];
}

@end

@interface LockWeatherPlugin : WeatherIconPlugin

@property (nonatomic, retain) WIHeaderView* headerView;

@end

MSHook(void, updateClock, SBAwayDateView *self, SEL sel)
{
        _updateClock(self, sel);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"LWPUpdateTimeNotification" object:nil];
}

MSHook(void, significantTimeChange, SBStatusBarController *self, SEL sel)
{
        _significantTimeChange(self, sel);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"LWPUpdateTimeNotification" object:nil];
}

MSHook(void, sbDrawRect, SBStatusBarTimeView *self, SEL sel, CGRect rect)
{
        _sbDrawRect(self, sel, rect);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"LWPUpdateTimeNotification" object:nil];
}


@implementation LockWeatherPlugin

@synthesize headerView;

-(void) updateTime
{
        [self.headerView updateTime];
}

-(CGFloat) tableView:(UITableView*) tableView heightForHeaderInSection:(NSInteger) section
{
	return 96;
}

-(BOOL) showCalendar
{
	int detail = 0;
	if (NSNumber* n = [self.plugin.preferences objectForKey:@"Detail"])
		detail = n.intValue;

	if (detail == 2)
		return showCalendar;

	return (detail == 1);
}
        
- (CGFloat) tableView:(LITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.showCalendar)
	{
		if (indexPath.row > 0)
			return 0;

	       	 return (6 * (tableView.theme.detailStyle.font.pointSize + 6)) + (tableView.theme.headerStyle.font.pointSize * 2) + 9;
	}

	return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(LITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.showCalendar)
	{
		if (indexPath.row > 0)
		{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LWBlankCell"];
       			if (cell == nil)
			{
	                	cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"LWBlankCell"] autorelease];
			}
			return cell;
		}

		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LWCalendarCell"];

       		if (cell == nil)
		{
	                cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"LWCalendarCell"] autorelease];

	        	int height = [self tableView:tableView heightForRowAtIndexPath:indexPath];
			CalendarScrollView* scroll = [[[CalendarScrollView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, height)] autorelease];
			scroll.backgroundColor = [UIColor clearColor];
			scroll.showsHorizontalScrollIndicator = NO;
			scroll.delegate = scroll;
			scroll.pagingEnabled = YES;
			scroll.tag = 9494;
			scroll.contentSize = CGSizeMake(tableView.bounds.size.width * 3, scroll.frame.size.height);

	        	UIImage* marker = [UIImage imageWithContentsOfFile:[self.plugin.bundle pathForResource:@"LIClockTodayMarker" ofType:@"png"]];

	                CalendarView* c1 = [[CalendarView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, height)];
			c1.backgroundColor = [UIColor clearColor];
	        	c1.marker = marker;
			scroll.lastMonth = c1;
			[scroll addSubview:c1];

	                CalendarView* c2 = [[CalendarView alloc] initWithFrame:CGRectMake(tableView.bounds.size.width, 0, tableView.bounds.size.width, height)];
			c2.backgroundColor = [UIColor clearColor];
	        	c2.marker = marker;
			scroll.currentMonth = c2;
			[scroll addSubview:c2];

	                CalendarView* c3 = [[CalendarView alloc] initWithFrame:CGRectMake(tableView.bounds.size.width * 2, 0, tableView.bounds.size.width, height)];
			c3.backgroundColor = [UIColor clearColor];
	        	c3.marker = marker;
			scroll.nextMonth = c3;
			[scroll addSubview:c3];

			[scroll setDate:[NSDate date]];
	                [cell.contentView addSubview:scroll];

			UIImage* img = [UIImage imageWithContentsOfFile:[self.plugin.bundle pathForResource:@"LWCurrentMonth" ofType:@"png"]];
			UIButton* b = [UIButton buttonWithType:UIButtonTypeCustom];
			b.frame = CGRectMake(tableView.bounds.size.width - 40, 0, 40, 40);
			b.imageEdgeInsets = UIEdgeInsetsMake(3, b.frame.size.width - img.size.width - 5, b.frame.size.height - img.size.height - 3, 5);
			b.showsTouchWhenHighlighted = YES;
			[b setImage:img forState:UIControlStateNormal];
			[b addTarget:scroll action:@selector(resetDate) forControlEvents:UIControlEventTouchUpInside];
			[cell.contentView addSubview:b];
	        }

		CalendarScrollView* scroll = [cell.contentView viewWithTag:9494];
		scroll.contentOffset = CGPointMake(320, 0);

		BOOL showWeeks = NO;
		if (NSNumber* n = [self.plugin.preferences objectForKey:@"ShowCalendarWeeks"])
			showWeeks = n.boolValue;

		scroll.currentMonth.showWeeks = showWeeks;
		scroll.nextMonth.showWeeks = showWeeks;
		scroll.lastMonth.showWeeks = showWeeks;

		scroll.currentMonth.headerStyle = tableView.theme.summaryStyle;
		scroll.currentMonth.dayStyle = tableView.theme.detailStyle;
		[scroll.currentMonth setNeedsDisplay];

		scroll.nextMonth.headerStyle = tableView.theme.summaryStyle;
		scroll.nextMonth.dayStyle = tableView.theme.detailStyle;
		[scroll.nextMonth setNeedsDisplay];

		scroll.lastMonth.headerStyle = tableView.theme.summaryStyle;
		scroll.lastMonth.dayStyle = tableView.theme.detailStyle;
		[scroll.lastMonth setNeedsDisplay];

	        return cell;
	}
	
	return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

-(UIView*) tableView:(LITableView*) tableView viewForHeaderInSection:(NSInteger) section
{
	WIHeaderView* view = [[[WIHeaderView alloc] initWithFrame:CGRectMake(0, 0, 320, 96)] autorelease];

	UIImage* image = _UIImageWithName(@"UILCDBackground.png");
	UIImageView* iv = [[[UIImageView alloc] initWithFrame:view.bounds] autorelease];
	iv.image = image;
	[view addSubview:iv];

	view.time = [[[UILabel alloc] initWithFrame:CGRectMake(0, 4, view.frame.size.width, 50)] autorelease];
	view.time.font = [UIFont fontWithName:@"LockClock-Light" size:50];
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

	view.temp = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	[view addSubview:view.temp];
	view.temp.font = [UIFont systemFontOfSize:37];
//	view.temp.font = [UIFont fontWithName:@"LockClock-Light" size:36];
	view.temp.textColor = [UIColor whiteColor];
	view.temp.backgroundColor = [UIColor clearColor];
	view.temp.frame = CGRectMake(195, 52, 120, 37);

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

	BOOL showDescription = false;
	if (NSNumber* n = [self.plugin.preferences objectForKey:@"ShowDescription"])
		showDescription = n.boolValue;

	if (showDescription)
	{
		NSString* description = nil;
		if (NSNumber* code = [weather objectForKey:@"code"])
	        {
                	if (code.intValue >= 0 && code.intValue < descriptions.count)
	                {
	                        description = localize([descriptions objectAtIndex:code.intValue]);
	                }
	        }

		if (description == nil)
			description = localize([weather objectForKey:@"description"]);

		view.city.text = description;
	}
	else
	{
		NSString* city = [weather objectForKey:@"city"];
		NSRange r = [city rangeOfString:@","];
		if (r.location != NSNotFound)
			city = [city substringToIndex:r.location];
		view.city.text = city;
	}

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
	CGRect tr = view.temp.frame;
	tr.size.width = ts.width;
	tr.size.height = ts.height;
	view.temp.frame = tr;
	view.temp.center = CGPointMake(195 + (int)(tr.size.width / 2), 74);

	tr = view.high.frame;
	tr.origin.x = view.temp.frame.origin.x + ts.width + 8;
	view.high.frame = tr;

	tr = view.low.frame;
	tr.origin.x = view.temp.frame.origin.x + ts.width + 8;
	view.low.frame = tr;

	ts = [view.time.text sizeWithFont:view.time.font];
	tr = view.time.frame;
	tr.size.height = ts.height;
	view.time.frame = tr;
	view.time.center = CGPointMake(160, 29);

	[weather release];

	self.headerView = view;

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

	dateFormat = [[NSString stringWithFormat:@"EEE, %@", (NSString*)UIDateFormatStringForFormatType(CFSTR("UIAbbreviatedMonthDayFormat"))] retain];
        timeFormat = [(NSString*)UIDateFormatStringForFormatType(CFSTR("UINoAMPMTimeFormat")) retain];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTime) name:@"LWPUpdateTimeNotification" object:nil];

	return [super initWithPlugin:plugin];
}


@end
