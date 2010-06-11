#include "CalendarScrollView.h"

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

@implementation CalendarScrollView

@synthesize scrollView, jumpButton;
@synthesize lastMonth, nextMonth, currentMonth;

-(void) setFrame:(CGRect) r
{
	[super setFrame:r];
	self.lastMonth.frame = CGRectMake(0, 0, r.size.width, r.size.height);
	self.currentMonth.frame = CGRectMake(r.size.width, 0, r.size.width, r.size.height);
	self.nextMonth.frame = CGRectMake(r.size.width * 2, 0, r.size.width, r.size.height);

	self.scrollView.frame = self.bounds;
	self.scrollView.contentSize = CGSizeMake(r.size.width * 3, r.size.height);
	self.scrollView.contentOffset = CGPointMake(r.size.width, 0);
}

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
	if (view.contentOffset.x == view.frame.size.width)
		return;

	CGPoint offset = view.contentOffset;

	if (offset.x == 0)
	{
		[self setDate:self.lastMonth.date];
		offset.x = view.frame.size.width - adj;
	}
	else
	{
		[self setDate:self.nextMonth.date];
		offset.x = view.frame.size.width + adj;
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

-(void) showWeeks:(BOOL) weeks
{
	self.currentMonth.showWeeks = weeks;
	self.lastMonth.showWeeks = weeks;
	self.nextMonth.showWeeks = weeks;
}

-(void) setTheme:(LITheme*) theme
{
	self.currentMonth.headerStyle = theme.summaryStyle;
        self.currentMonth.dayStyle = theme.detailStyle;
        [self.currentMonth setNeedsDisplay];

        self.nextMonth.headerStyle = theme.summaryStyle;
        self.nextMonth.dayStyle = theme.detailStyle;
        [self.nextMonth setNeedsDisplay];

        self.lastMonth.headerStyle = theme.summaryStyle;
        self.lastMonth.dayStyle = theme.detailStyle;
        [self.lastMonth setNeedsDisplay];
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
		[self.scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
	}
	else if (nowMonths > dateMonths)
	{
		self.nextMonth.date = now;
		[self.nextMonth setNeedsDisplay];
		[self.scrollView setContentOffset:CGPointMake(self.frame.size.width * 2, 0) animated:YES];
	}
}

-(id) initWithFrame:(CGRect) frame marker:(UIImage*) marker jump:(UIImage*) jump
{
	self = [super initWithFrame:frame];
	self.autoresizesSubviews = YES;
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.backgroundColor = [UIColor clearColor];

	self.scrollView = [[[UIScrollView alloc] initWithFrame:self.bounds] autorelease];
	self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.scrollView.backgroundColor = [UIColor clearColor];
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.delegate = self;
        self.scrollView.pagingEnabled = YES;
	[self addSubview:self.scrollView];
 
        CalendarView* c1 = [[CalendarView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        c1.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        c1.backgroundColor = [UIColor clearColor];
        c1.marker = marker;
        self.lastMonth = c1;
        [self.scrollView addSubview:c1];
 
        CalendarView* c2 = [[CalendarView alloc] initWithFrame:CGRectMake(frame.size.width, 0, frame.size.width, frame.size.height)];
        c2.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        c2.backgroundColor = [UIColor clearColor];
        c2.marker = marker;
        self.currentMonth = c2;
        [self.scrollView addSubview:c2];

	CalendarView* c3 = [[CalendarView alloc] initWithFrame:CGRectMake(frame.size.width * 2, 0, frame.size.width, frame.size.height)];
	c3.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	c3.backgroundColor = [UIColor clearColor];
	c3.marker = marker;
	self.nextMonth = c3;
	[self.scrollView addSubview:c3];

	[self setDate:[NSDate date]];

	UIButton* b = [UIButton buttonWithType:UIButtonTypeCustom];
	b.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	b.frame = CGRectMake(frame.size.width - 40, 0, 40, 40);
	b.imageEdgeInsets = UIEdgeInsetsMake(3, b.frame.size.width - jump.size.width - 5, b.frame.size.height - jump.size.height - 3, 5);
	b.showsTouchWhenHighlighted = YES;
	[b setImage:jump forState:UIControlStateNormal];
	[b addTarget:self action:@selector(resetDate) forControlEvents:UIControlEventTouchUpInside];
	self.jumpButton = b;
	[self addSubview:b];

	return self;
}


@end


@implementation CalendarView

@synthesize headerStyle, dayStyle, marker, date, showWeeks;

-(void) setFrame:(CGRect) r
{
	[super setFrame:r];
	[self setNeedsDisplay];
}

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

		if (comp.weekday < firstWeekday)
			day += 7;

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
