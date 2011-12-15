#import <substrate.h>
#import "Plugin.h"
#import "CalendarScrollView.h"
#import <SpringBoard/SBStatusBarController.h>
#import <SpringBoard/SBStatusBarTimeView.h>
#import <SpringBoard/SBAwayController.h>
#import <SpringBoard/SBAwayView.h>
#import <SpringBoard/SBAwayDateView.h>
#import <TelephonyUI/TPLCDTextView.h>

#define Hook(cls, sel, imp) \
_ ## imp = MSHookMessage($ ## cls, @selector(sel), &$ ## imp)

extern "C" CFStringRef UIDateFormatStringForFormatType(CFStringRef type);

@interface ClockHeaderView : UIView

@property BOOL ampm;
@property BOOL alignBottom;
@property (nonatomic, retain) LILabel* time;
@property (nonatomic, retain) LILabel* date;

@end

@implementation ClockHeaderView

@synthesize time, date, ampm, alignBottom;

-(void) layoutSubviews
{
	[super layoutSubviews];
	
	CGRect screen = [[UIScreen mainScreen] bounds];
	int orientation = [[objc_getClass("SBStatusBarController") sharedStatusBarController] statusBarOrientation];
	float width =  (orientation == 90 || orientation == -90 ? screen.size.height : screen.size.width);
	
	CGRect r = self.bounds;
	r.origin.x = 5;
	r.size.width -= 10;
	self.time.frame = r;
	
	CGSize ts = [self.time.text sizeWithFont:self.time.style.font];
	CGRect tr = self.time.frame;
	tr.size.height = ts.height;
	
	if (self.alignBottom)		
		tr.origin.y = (int)(r.size.height - (ts.height / 2)) - 5;
	
	self.time.frame = tr;
	[self.time setNeedsDisplay];
	
	if (self.date.style.font)
	{
		CGSize ds = [self.date.text sizeWithFont:self.date.style.font];
		r.origin.y = (int)(r.size.height / 2) - (int)(ds.height / 2) + 5;
		r.size.height = ds.height;
	}
	
	self.date.frame = r;
	[self.date setNeedsDisplay];
}

-(void) updateTime
{
	NSDate* now = [NSDate date];
	NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
	df.dateFormat = (NSString*)UIDateFormatStringForFormatType(CFSTR("UIWeekdayNoYearDateFormat"));
	NSString* newDate = [df stringFromDate:now];
	self.date.text = newDate;
    
	if (self.ampm)
	{
		df.dateStyle = NSDateFormatterNoStyle;
		df.timeStyle = NSDateFormatterShortStyle;
		self.time.text = [[df stringFromDate:now] lowercaseString];
	}
	else
	{
		df.dateFormat = (NSString*)UIDateFormatStringForFormatType(CFSTR("UINoAMPMTimeFormat"));
		self.time.text = [df stringFromDate:now];
	}
    
	[self setNeedsLayout];
}

-(id) initWithFrame:(CGRect) frame
{
	self = [super initWithFrame:frame];
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.autoresizesSubviews = YES;
	self.backgroundColor = [UIColor clearColor];
	self.ampm = true;
    
	self.time = [[[objc_getClass("LILabel") alloc] initWithFrame:self.bounds] autorelease];
	self.time.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
	self.time.backgroundColor = [UIColor clearColor];
	[self addSubview:self.time];
    
	self.date = [[[objc_getClass("LILabel") alloc] initWithFrame:self.bounds] autorelease];
	self.date.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	self.date.textAlignment = UITextAlignmentRight;
	self.date.backgroundColor = [UIColor clearColor];
	[self addSubview:self.date];
    
	return self;
}

@end

@interface ClockPlugin : NSObject <LIPluginController, LITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) LIPlugin* plugin;
@property (nonatomic, retain) ClockHeaderView* header;
@property (nonatomic, retain) CalendarScrollView* calendar;

@end

@implementation ClockPlugin

@synthesize plugin, header, calendar;

-(void) updateTime
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateTime) object:nil];
	NSDate* now = [NSDate date];
	NSCalendar* cal = [NSCalendar currentCalendar];
	NSDateComponents* comps = [cal components:NSMinuteCalendarUnit | NSHourCalendarUnit | NSSecondCalendarUnit fromDate:now];
	[self performSelector:@selector(updateTime) withObject:nil afterDelay:(60 - comps.second)];
    
	[self.header updateTime];
    
	if (self.calendar)
		if (comps.hour == 0 && comps.minute == 0)
			[self.calendar setDate:now];
}

-(id) initWithPlugin:(LIPlugin*) plugin
{
	self = [super init];
	self.plugin = plugin;
	self.plugin.tableViewDataSource = self;
	self.plugin.tableViewDelegate = self;
    
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(updateTime) name:LIUndimScreenNotification object:nil];
    
	return self;
}

- (CGFloat)tableView:(LITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 35;
}

- (UIView *)tableView:(LITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	if (self.header == nil)
		self.header = [[[ClockHeaderView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 25)] autorelease];
    
	LIStyle* style = [[self.plugin.theme.headerStyle copy] autorelease];
	style.font = [UIFont boldSystemFontOfSize:25];
	self.header.time.style = style;
    
	self.header.date.style = self.plugin.theme.headerStyle;
    
	if (NSNumber* b = [self.plugin.preferences objectForKey:@"ShowAMPM"])
		self.header.ampm = b.boolValue;
	
	if (NSNumber* ab = [self.plugin.preferences objectForKey:@"AlignBottom"])
		self.header.alignBottom = ab.boolValue;
    
	[self updateTime];
    
	return self.header;
}

- (CGFloat) tableView:(LITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (6 * (tableView.theme.detailStyle.font.pointSize + 6)) + (tableView.theme.headerStyle.font.pointSize * 2) + 9;
}

- (NSInteger)tableView:(LITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(LITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LWCalendarCell"];
    
    if (cell == nil)
    {
        int height = [self tableView:tableView heightForRowAtIndexPath:indexPath];
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, height) reuseIdentifier:@"LWCalendarCell"] autorelease];
        
        UIImage* marker = [UIImage li_imageWithContentsOfResolutionIndependentFile:[self.plugin.bundle pathForResource:[NSString stringWithFormat:@"%@_LIClockTodayMarker", self.plugin.theme.sectionIconSet] ofType:@"png"]];
        UIImage* jump = [UIImage li_imageWithContentsOfResolutionIndependentFile:[self.plugin.bundle pathForResource:[NSString stringWithFormat:@"%@_LICurrentMonth", self.plugin.theme.sectionIconSet] ofType:@"png"]];
        CalendarScrollView* scroll = [[[CalendarScrollView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, height) marker:marker jump:jump] autorelease];
        scroll.tag = 9494;
		[scroll setDate:[NSDate date]];
        self.calendar = scroll;
        
        [cell.contentView addSubview:scroll];
	}
    
    CalendarScrollView* scroll = [cell.contentView viewWithTag:9494];
    
    BOOL showWeeks = NO;
    if (NSNumber* n = [self.plugin.preferences objectForKey:@"ShowCalendarWeeks"])
        showWeeks = n.boolValue;
    
	[scroll showWeeks:showWeeks];
    [scroll setTheme:self.plugin.theme];
    
    return cell;
}

@end
