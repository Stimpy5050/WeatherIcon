#include "LockWeatherPlugin.h"
#include "substrate.h"
#include <SpringBoard/SBAwayDateView.h>
#include <SpringBoard/SBStatusBarController.h>
#include <SpringBoard/SBStatusBarTimeView.h>
#include <UIKit/UIKit.h>

#define localize(str) \
        [self.plugin.bundle localizedStringForKey:str value:str table:nil]

#define Hook(cls, sel, imp) \
        _ ## imp = MSHookMessage($ ## cls, @selector(sel), &$ ## imp)

extern "C" UIImage *_UIImageWithName(NSString *);
extern "C" CFStringRef UIDateFormatStringForFormatType(CFStringRef type);

BOOL showCalendar = false;
CalendarView* calendarView;
WIHeaderView* cachedView;
NSString* dateFormat;
NSString* timeFormat;

@implementation CalendarView

@synthesize headerStyle, dayStyle, marker;

-(void) drawRect:(CGRect) rect
{
        int width = rect.size.width / 7;
        NSCalendar* cal = [NSCalendar currentCalendar];
        NSDate* now = [NSDate date];

        NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
		df.dateFormat = @"MMMM";
        CGRect r = CGRectMake(0, 2, rect.size.width, self.headerStyle.font.pointSize);
        NSString* s = [[df stringFromDate:now] uppercaseString];
        [self.dayStyle.textColor set];
        [s drawInRect:r withFont:self.dayStyle.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];

        [self.headerStyle.textColor set];
		r.size.width = width;
		r.origin.y += self.headerStyle.font.pointSize + 3;

        int firstWeekday = cal.firstWeekday;

        NSArray* weekdays = df.shortStandaloneWeekdaySymbols;
        for (int i = 0; i < 7; i++)
        {
                r.origin.x = i * width;
                int index = (i + firstWeekday - 1);
                NSString* s = [[weekdays objectAtIndex:(index >= weekdays.count ? index - weekdays.count : index)] uppercaseString];
                [s drawInRect:r withFont:self.dayStyle.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
        }

        NSRange dayRange = [cal rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:now];
        NSDateComponents* comp = [cal components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:now];
        int today = comp.day;

        comp.day = 1;
        NSDate* first = [cal dateFromComponents:comp];
        comp = [cal components:NSWeekdayCalendarUnit fromDate:first];

        for (int i = 0; i < dayRange.length; i++)
        {
                int day = i + comp.weekday - (firstWeekday - 1);
                int week = (day - 1) / 7;
                int index = (day - 1) % 7;
                r.origin.x = (index * width);
                r.origin.y = (week * (self.dayStyle.font.pointSize + 6)) + (self.headerStyle.font.pointSize * 2) + 9;
                NSString* s = [[NSNumber numberWithInt:i + 1] stringValue];

                if (self.dayStyle.shadowColor)
		{
                        [self.dayStyle.shadowColor set];

                        [s drawInRect:CGRectOffset(r, self.dayStyle.shadowOffset.width, self.dayStyle.shadowOffset.height) withFont:self.dayStyle.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
                }

                if (today == i + 1)
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
		[calendarView setNeedsDisplay];
	}
	
	df.dateFormat = timeFormat;
	NSString* timeStr = [df stringFromDate:now];
	if (![timeStr isEqualToString:self.date.text])
		self.time.text = [df stringFromDate:now];
	
	[pool release];
}

@end

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

	        // calculate the number of weeks in the month
	        NSCalendar* cal = [NSCalendar currentCalendar];
	        NSDate* now = [NSDate date];
	        NSRange dayRange = [cal rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:now];
	        NSDateComponents* comp = [cal components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:now];

	        comp.day = 1;
	        NSDate* first = [cal dateFromComponents:comp];
	        comp = [cal components:NSWeekdayCalendarUnit fromDate:first];

	        int total = (comp.weekday - 1) + dayRange.length;
	        int weeks = (int)(total / 7);
	        if (total % 7 > 0)
	                weeks++;

	       	 return (weeks * (tableView.theme.detailStyle.font.pointSize + 6)) + (tableView.theme.headerStyle.font.pointSize * 2) + 9;
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

	                if (calendarView == nil)
	                {
	                        calendarView = [[CalendarView alloc] initWithFrame:CGRectMake(20, 0, 280, 20)];
	                        calendarView.tag = 1010;
	                        calendarView.backgroundColor = [UIColor clearColor];
	                        calendarView.marker = [UIImage imageWithContentsOfFile:[self.plugin.bundle pathForResource:@"LIClockTodayMarker" ofType:@"png"]];
	                }

	                [cell.contentView addSubview:calendarView];
	        }

	        int height = [self tableView:tableView heightForRowAtIndexPath:indexPath];
	        calendarView.frame = CGRectMake(20, 0, 280, height);

	        BOOL update = (calendarView.headerStyle.font.pointSize != tableView.theme.summaryStyle.font.pointSize ||
	                        calendarView.dayStyle.font.pointSize != tableView.theme.detailStyle.font.pointSize);

	        calendarView.headerStyle = tableView.theme.summaryStyle;
	        calendarView.dayStyle = tableView.theme.detailStyle;

	        if (update)
	                [calendarView setNeedsDisplay];

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
	
	dateFormat = [[NSString stringWithFormat:@"EEE, %@", (NSString*)UIDateFormatStringForFormatType(CFSTR("UIAbbreviatedMonthDayFormat"))] retain];
	timeFormat = [(NSString*)UIDateFormatStringForFormatType(CFSTR("UINoAMPMTimeFormat")) retain];
	
	return [super initWithPlugin:plugin];
}

@end
