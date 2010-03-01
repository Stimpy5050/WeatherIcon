#include "HTCPlugin.h"
#include "HTCConstants.h"
#include <UIKit/UIKit.h>

#define localize(str) \
[self.plugin.bundle localizedStringForKey:str value:str table:nil]

extern "C" UIImage *_UIImageWithName(NSString *);
extern "C" CFStringRef UIDateFormatStringForFormatType(CFStringRef type);

static NSString* dateFormat = [[NSString stringWithFormat:@"EEE, %@", (NSString*)UIDateFormatStringForFormatType(CFSTR("UIAbbreviatedMonthDayFormat"))] retain];
static HTCHeaderView* HTCView = [[HTCHeaderView alloc] init];
static BOOL twelveHour = false;

@implementation HTCHeaderView

@synthesize icon, city, temp, date, high, low, description, hourNumber, minuteNumber, hours, minutes;

-(void) touchesBegan:(NSSet*) touches withEvent:(UIEvent*) event
{
	UITouch* touch = [touches anyObject];
	CGPoint p = [touch locationInView:self];
	showCalendar = (p.x < 160);
	return [self.nextResponder touchesBegan:touches withEvent:event];
}

-(void) updateDigits
{	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSBundle* bundle = [NSBundle bundleWithIdentifier:@"com.ashman.lockinfo.HTCPlugin"];
	
	NSString* hoursPath = [bundle pathForResource:[digits objectAtIndex:self.hourNumber.intValue] ofType:@"png"];
	UIImage* hoursImage = [UIImage imageWithContentsOfFile:hoursPath];
	
	self.hours.image = hoursImage;	
	
	NSString* minutesPath = [bundle pathForResource:[digits objectAtIndex:self.minuteNumber.intValue] ofType:@"png"];
	UIImage* minutesImage = [UIImage imageWithContentsOfFile:minutesPath];
	
	self.minutes.image = minutesImage;
	
	[pool release];
}

-(void) updateTimeHTC

{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
    NSDate* now = [NSDate date];
    NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
	NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents* timeComponents = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:now];
	
    df.dateFormat = dateFormat;
	NSString* dateStr = [df stringFromDate:now];
	self.date.text = [df stringFromDate:now];
	
	self.minuteNumber = [NSNumber numberWithInt:[timeComponents minute]];
	
	int h = [timeComponents hour];
	
	if (twelveHour && h > 12)
	{
		h = h - 12;
	}
	
	self.hourNumber = [NSNumber numberWithInt:h];
	
	[self updateDigits];
	
	[pool release];
}

@end

@implementation WIHeaderView (HTCUpdater)

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
	
	[HTCView updateTimeHTC];
	
	[pool release];

}

@end

@implementation HTCLockWeatherPlugin (HTCPlugin)

-(CGFloat) tableView:(UITableView*) tableView heightForHeaderInSection:(NSInteger) section
{
	return 180;
}

-(UIView*) tableView:(LITableView*) tableView viewForHeaderInSection:(NSInteger) section
{	
	HTCHeaderView* view = [[[HTCHeaderView alloc] initWithFrame:CGRectMake(0, 0, 320, 180)] autorelease];
	
	double scale = 0.25;
	
	NSString* hoursPath = [self.plugin.bundle pathForResource:[digits objectAtIndex:0] ofType:@"png"];
	UIImage* hoursImage = [UIImage imageWithContentsOfFile:hoursPath];
	
	CGSize hs = hoursImage.size;
	hs.width = hs.width * scale;
	hs.height = hs.height * scale;
	
	view.hours = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, hs.width, hs.height)] autorelease];
	view.hours.image = hoursImage;	
	view.hours.center = CGPointMake(114, 54);
	[view addSubview:view.hours];
	
	NSString* minutesPath = [self.plugin.bundle pathForResource:[digits objectAtIndex:0] ofType:@"png"];
	UIImage* minutesImage = [UIImage imageWithContentsOfFile:minutesPath];
	
	CGSize ms = minutesImage.size;
	ms.width = ms.width * scale;
	ms.height = ms.height * scale;
	
	view.minutes = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, ms.width, ms.height)] autorelease];
	view.minutes.image = minutesImage;		
	view.minutes.center = CGPointMake(205, 54);
	[view addSubview:view.minutes];
	
	view.date = [[[UILabel alloc] initWithFrame:CGRectMake(190, 105, 100, 22)] autorelease];
	view.date.font = [UIFont boldSystemFontOfSize:16];
	view.date.textAlignment = UITextAlignmentRight;
	view.date.textColor = [UIColor lightGrayColor];
	view.date.backgroundColor = [UIColor clearColor];
	[view addSubview:view.date];
	
	view.city = [[[UILabel alloc] initWithFrame:CGRectMake(29, 106, 90, 22)] autorelease];
	[view addSubview:view.city];
	view.city.font = [UIFont boldSystemFontOfSize:18];
	view.city.textAlignment = UITextAlignmentLeft;
	view.city.textColor = [UIColor orangeColor];
	view.city.backgroundColor = [UIColor clearColor];
	
	view.description = [[[UILabel alloc] initWithFrame:CGRectMake(29, 127, 90, 18)] autorelease];
	[view addSubview:view.description];
	view.description.font = [UIFont boldSystemFontOfSize:12];
	view.description.textAlignment = UITextAlignmentLeft;
	view.description.textColor = [UIColor lightGrayColor];
	view.description.backgroundColor = [UIColor clearColor];
	
	[view updateTimeHTC];
	
	double iconScale = 3.00;
	
	if (NSNumber* n = [self.plugin.preferences objectForKey:@"IconScale"])
		iconScale = n.doubleValue;
	
	view.icon = [self tableView:tableView iconForHeaderInSection:section];
	CGRect ir = view.icon.frame;
	ir.size.width *= iconScale;
	ir.size.height *= iconScale;
	view.icon.frame = ir;
	view.icon.center = CGPointMake(160, 135);
	[view addSubview:view.icon];
	
	view.temp = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	[view addSubview:view.temp];
	view.temp.font = [UIFont systemFontOfSize:37];
	view.temp.textColor = [UIColor orangeColor];
	view.temp.backgroundColor = [UIColor clearColor];
	view.temp.frame = CGRectMake(190, 127, 100, 37);
	
	view.high = [[[UILabel alloc] initWithFrame:CGRectMake(190, 128, 100, 18)] autorelease];
	[view addSubview:view.high];
	view.high.font = [UIFont boldSystemFontOfSize:14];
	view.high.textColor = [UIColor lightGrayColor];
	view.high.backgroundColor = [UIColor clearColor];
	
	view.low = [[[UILabel alloc] initWithFrame:CGRectMake(202, 145, 90, 18)] autorelease];
	[view addSubview:view.low];
	view.low.font = [UIFont boldSystemFontOfSize:14];
	view.low.textColor = [UIColor lightGrayColor];
	view.low.backgroundColor = [UIColor clearColor];
	
	if (NSNumber* t = [self.plugin.preferences objectForKey:@"TwelveHour"])
		twelveHour = t.boolValue;
	
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
		
		view.description.text = description;
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
	view.temp.center = CGPointMake(202 + (int)(tr.size.width / 2), 146);
	
	tr = view.high.frame;
	tr.origin.x = view.temp.frame.origin.x + ts.width + 4;
	view.high.frame = tr;
	
	tr = view.low.frame;
	tr.origin.x = view.temp.frame.origin.x + ts.width + 4;
	view.low.frame = tr;
	
	NSString* city = [weather objectForKey:@"city"];
	NSRange r = [city rangeOfString:@","];
	if (r.location != NSNotFound)
		city = [city substringToIndex:r.location];
	view.city.text = city;
	
	[weather release];
	
	id tmp = HTCView;
	HTCView = [view retain];
	[tmp release];
	
	return view;
}

@end

