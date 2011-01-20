#include "BaseWeatherPlugin.h"
#include <UIKit/UIScreen.h>

@implementation LockHeaderView

@synthesize dateFormat, timeFormat;
@synthesize showCalendar;

/*
-(void) setFrame:(CGRect) f
{
	[super setFrame:f];
	[self setNeedsLayout];
}
*/

-(id) initWithFrame:(CGRect) frame
{
	self = [super initWithFrame:frame];
	self.contentMode = UIViewContentModeRedraw;
	self.dateFormat = [[NSString stringWithFormat:@"EEE, %@", (NSString*)UIDateFormatStringForFormatType(CFSTR("UIAbbreviatedMonthDayFormat"))] retain];
        self.timeFormat = [(NSString*)UIDateFormatStringForFormatType(CFSTR("UINoAMPMTimeFormat")) retain];
	[self updateTime];
	return self;
}

-(void) touchesEnded:(NSSet*) touches withEvent:(UIEvent*) event
{
	UITouch* touch = [touches anyObject];
	CGPoint p = [touch locationInView:self];
	self.showCalendar = (p.x < self.frame.size.width / 2);
	return [self.nextResponder touchesEnded:touches withEvent:event];
}

-(void) updateTime
{
}

@end

MSHook(void, _undimScreen, id self, SEL sel)
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"com.ashman.lockinfo.BaseWeatherPlugin.updateTime" object:nil];
	__undimScreen(self, sel);
}

@implementation BaseWeatherPlugin

@synthesize headerView;
@synthesize calendarScrollView;

-(void) _updateTime
{
        [self.headerView updateTime];
}

-(void) updateTime
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateTime) object:nil];
	NSDate* now = [NSDate date];
        NSCalendar* cal = [NSCalendar currentCalendar];
        NSDateComponents* comps = [cal components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit fromDate:now];
        [self performSelector:@selector(updateTime) withObject:nil afterDelay:(60 - comps.second)];


	[self _updateTime];

	if (self.calendarScrollView)
		if (comps.hour == 0 && comps.minute == 0)
			[self.calendarScrollView setDate:now];
}

-(void) notifyLockInfo
{
	//NOOP
}

-(void) updateWeatherViews
{
	[super updateWeatherViews];

	if (self.headerView == nil)
		self.headerView = [self createHeaderView];

	[self updateTime];
}

-(BOOL) showCalendar
{
	int detail = 0;
	if (NSNumber* n = [self.plugin.preferences objectForKey:@"Detail"])
		detail = n.intValue;

	if (detail == 2)
	{
		return self.headerView.showCalendar;
	}

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
			CGFloat height = [self tableView:tableView heightForRowAtIndexPath:indexPath];
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, height) reuseIdentifier:@"LWCalendarCell"] autorelease];
			
			UIImage* marker = [UIImage li_imageWithContentsOfResolutionIndependentFile:[self.plugin.bundle pathForResource:[NSString stringWithFormat:@"%@_LIClockTodayMarker", tableView.theme.sectionIconSet] ofType:@"png"]];
			UIImage* jump = [UIImage li_imageWithContentsOfResolutionIndependentFile:[self.plugin.bundle pathForResource:[NSString stringWithFormat:@"%@_LICurrentMonth", tableView.theme.sectionIconSet] ofType:@"png"]];
			
			CalendarScrollView* scroll = [[[CalendarScrollView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, height) marker:marker jump:jump] autorelease];
			scroll.tag = 9494;
			self.calendarScrollView = scroll;
			[cell.contentView addSubview:scroll];
			 
		}
		 
		CalendarScrollView* scroll = [cell.contentView viewWithTag:9494];

		BOOL showWeeks = NO;
		if (NSNumber* n = [self.plugin.preferences objectForKey:@"ShowCalendarWeeks"])
			showWeeks = n.boolValue;

		[scroll showWeeks:showWeeks];
		[scroll setTheme:tableView.theme];

		return cell;
	}
	
	return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

-(LockHeaderView*) createHeaderView
{
	return nil;
}

-(UIView*) tableView:(LITableView*) tableView viewForHeaderInSection:(NSInteger) section
{
	[self updateWeatherViews];
	[self.headerView setNeedsLayout];
	return self.headerView;
}

-(id) initWithPlugin:(LIPlugin*) plugin
{
	self = [super initWithPlugin:plugin];

	Class $SBAwayController = objc_getClass("SBAwayController");
	Hook(SBAwayController, _undimScreen, _undimScreen);

	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(updateTime) name:@"com.ashman.lockinfo.BaseWeatherPlugin.updateTime" object:nil];

	return self;
}

@end
