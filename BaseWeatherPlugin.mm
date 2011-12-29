#include "BaseWeatherPlugin.h"
#include <UIKit/UIScreen.h>
#include <UIKit/UITapGestureRecognizer.h>

@implementation LockHeaderView

@synthesize dateFormat, timeFormat;
@synthesize showCalendar;

-(id) initWithFrame:(CGRect) frame
{
	self = [super initWithFrame:frame];
	self.contentMode = UIViewContentModeRedraw;
	self.backgroundColor = [UIColor clearColor];
	self.dateFormat = [[NSString stringWithFormat:@"EEE, %@", (NSString*)UIDateFormatStringForFormatType(CFSTR("UIAbbreviatedMonthDayFormat"))] retain];
    self.timeFormat = [(NSString*)UIDateFormatStringForFormatType(CFSTR("UINoAMPMTimeFormat")) retain];
    
	UITapGestureRecognizer* gr = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headerTapped:)] autorelease];
	gr.delegate = self;
	[self addGestureRecognizer:gr];
    
	[self updateTime];
	return self;
}

-(BOOL) gestureRecognizer:(UIGestureRecognizer*)gr shouldReceiveTouch:(UITouch*) touch
{
	CGPoint p = [touch locationInView:self];
	self.showCalendar = (p.x < self.frame.size.width / 2);
	return NO;
}

-(void) headerTapped:(UIGestureRecognizer*) gr
{
}

/*
 -(void) touchesBegan:(NSSet*) touches withEvent:(UIEvent*) event
 {
 UITouch* touch = [touches anyObject];
 CGPoint p = [touch locationInView:self];
 self.showCalendar = (p.x < self.frame.size.width / 2);
 return [self.nextResponder touchesBegan:touches withEvent:event];
 }
 */

-(void) updateTime
{
}

@end

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

-(void) viewWillAppear:(BOOL) animated
{
    [super viewWillAppear:animated];
    [self updateTime];
}

-(void) notifyLockInfo
{
	//NOOP
}

-(void) updateWeatherViews
{
	[super updateWeatherViews];
    
	if (self.headerView == nil)
		self.headerView = self.view;
    
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
			int height = [self tableView:tableView heightForRowAtIndexPath:indexPath];
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, height) reuseIdentifier:@"LWCalendarCell"] autorelease];
			
			NSString* iconSet = @"Silver";
			
			if ([tableView.theme respondsToSelector:@selector(sectionIconSet)])
                iconSet = tableView.theme.sectionIconSet;
			
			UIImage* marker = [UIImage li_imageWithContentsOfResolutionIndependentFile:[self.plugin.bundle pathForResource:[NSString stringWithFormat:@"%@_LIClockTodayMarker", iconSet] ofType:@"png"]];
			UIImage* jump = [UIImage li_imageWithContentsOfResolutionIndependentFile:[self.plugin.bundle pathForResource:[NSString stringWithFormat:@"%@_LICurrentMonth", iconSet] ofType:@"png"]];
			
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
        
        [scroll setNeedsLayout];
        
		return cell;
	}
	
	return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

-(LockHeaderView*) createHeaderView
{
	return nil;
}

-(void) loadView
{
    self.view = [self createHeaderView];
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
    
	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(updateTime) name:LIUndimScreenNotification object:nil];
    
	return self;
}

@end
