#include "HTCPlugin.h"
#include "HTCConstants.h"
#include <UIKit/UIKit.h>
#include <SpringBoard/SBAwayDateView.h>
#include <SpringBoard/SBStatusBarController.h>
#include <SpringBoard/SBStatusBarTimeView.h>
#include "substrate.h"

#define localize(str) \
[self.plugin.bundle localizedStringForKey:str value:str table:nil]

#define Hook(cls, sel, imp) \
_ ## imp = MSHookMessage($ ## cls, @selector(sel), &$ ## imp)

extern "C" UIImage *_UIImageWithName(NSString *);
extern "C" CFStringRef UIDateFormatStringForFormatType(CFStringRef type);

static HTCHeaderView* HTCView = [[HTCHeaderView alloc] init];
static imageCacheController* imageCacheControl = [[imageCacheController alloc] init];

static BOOL twelveHour = false;
static BOOL spaceSave = false;
static BOOL removeExtra = false;

@implementation HTCSettingsController
@end

@implementation imageCacheController

@synthesize imageCache;

-(void) initCache
{	
	self.imageCache = [NSMutableDictionary dictionaryWithCapacity:13];
	
	int i=0;
	int x=0;
	NSBundle* bundle = [NSBundle bundleWithIdentifier:@"com.ashman.lockinfo.HTCPlugin"];

	for (i; i<10; i++)
	{		
		NSString* digitPath = [bundle pathForResource:[digits objectAtIndex:i] ofType:@"png"];
		UIImage* digitImage = [UIImage imageWithContentsOfFile:digitPath];
		
		NSString* digitName;
	
		if (digitImage)
		{
			digitName = [digits objectAtIndex:i];
			[self.imageCache setObject:digitImage forKey:digitName];
		}
	}
	
	for (x; x<3; x++)
	{		
		NSString* backgroundPath = [bundle pathForResource:[backgrounds objectAtIndex:x] ofType:@"png"];
		UIImage* backgroundImage = [UIImage imageWithContentsOfFile:backgroundPath];
		
		NSString* backgroundName;
		
		if (backgroundImage)
		{
			backgroundName = [backgrounds objectAtIndex:x];
			[self.imageCache setObject:backgroundImage forKey:backgroundName];
		}
		
	}
	
}

-(UIImage*) getDigit:(int)digit
{	
	NSString* digitName = [digits objectAtIndex:digit];
	
	UIImage* returnDigit = [self.imageCache objectForKey:digitName];
	if (returnDigit)
	{
		return returnDigit;
	} else {
		return nil;
	}
}

-(UIImage*) getBackground:(int)background
{	
	NSString* backgroundName = [backgrounds objectAtIndex:background];
	
	UIImage* returnBackground = [self.imageCache objectForKey:backgroundName];
	if (returnBackground)
	{
		return returnBackground;
	} else {
		return nil;
	}
}

@end

@implementation LockWeatherPlugin (ExtendLW)

-(id) initWithPlugin:(LIPlugin*) plugin
{
	dateFormat = [[NSString stringWithFormat:@"EEE, %@", (NSString*)UIDateFormatStringForFormatType(CFSTR("UIAbbreviatedMonthDayFormat"))] retain];
	timeFormat = [(NSString*)UIDateFormatStringForFormatType(CFSTR("UINoAMPMTimeFormat")) retain];
	
	return [super initWithPlugin:plugin];
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
	
	df.dateFormat = timeFormat;
	NSString* timeStr = [df stringFromDate:now];
	if (![timeStr isEqualToString:self.date.text])
	{
		self.time.text = [df stringFromDate:now];
	}
	
	[HTCView updateTimeHTC];
	
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

@implementation HTCHeaderView

@synthesize icon, city, temp, date, high, low, description, hourNumber, minuteNumber, minutesTens, minutesUnits, hoursTens, hoursUnits;

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
	
	int minutesInt = self.minuteNumber.intValue;
	int hoursInt = self.hourNumber.intValue;
	
	int minuteTensInt = (int)(minutesInt / 10);
	int minuteUnitsInt = (minutesInt - (minuteTensInt * 10));
	
	int hourTensInt = (int)(hoursInt / 10);
	int hourUnitsInt = (hoursInt - (hourTensInt * 10));
	
	self.hoursTens.image = [imageCacheControl getDigit:hourTensInt];
	self.hoursUnits.image = [imageCacheControl getDigit:hourUnitsInt];
	self.minutesTens.image = [imageCacheControl getDigit:minuteTensInt];
	self.minutesUnits.image = [imageCacheControl getDigit:minuteUnitsInt];
	
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
	if (![dateStr isEqualToString:self.date.text])
	{
		self.date.text = [df stringFromDate:now];
		[calendarView setNeedsDisplay];
	}
		
	int h = [timeComponents hour];
	int m = [timeComponents minute];
	
	if (twelveHour && h > 12)
	{
		h = h - 12;
	}
	
	if (h != self.hourNumber.intValue || m != self.minuteNumber.intValue)
	{
		self.hourNumber = [NSNumber numberWithInt:h];
		self.minuteNumber = [NSNumber numberWithInt:m];
	
		[self updateDigits];
	}
	
	[pool release];
}

@end

@implementation HTCPlugin

-(UIColor*) colourToSet:(int)colourInt
{
	if (colourInt == 0) {return [UIColor blackColor];}
	else if (colourInt == 1) {return [UIColor lightGrayColor];}
	else if (colourInt == 2) {return [UIColor whiteColor];}
	else if (colourInt == 3) {return [UIColor redColor];}
	else if (colourInt == 4) {return [UIColor greenColor];}
	else if (colourInt == 5) {return [UIColor blueColor];}
	else if (colourInt == 6) {return [UIColor yellowColor];}
	else if (colourInt == 7) {return [UIColor orangeColor];}
	else if (colourInt == 8) {return [UIColor purpleColor];}
	else {return [UIColor lightGrayColor];}
}

-(UIFont*) fontToFitText:(NSString*)text withFont:(UIFont*)font withMaxWidth:(CGFloat)maxWidth withMaxHeight:(CGFloat)maxHeight withMinSize:(int)minSize withMaxSize:(int)maxSize allowMoreLines:(BOOL)moreLines
{		
	int i = maxSize;
	
	UIFont* newFont = font;
	CGSize constraintSize = CGSizeMake(maxWidth, MAXFLOAT);
	
	for(i; i >= minSize; i=i-2)
	{
		newFont = [newFont fontWithSize:i];
		
		if (moreLines)
		{
			CGSize labelSize = [text sizeWithFont:newFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
			if (labelSize.height <= maxHeight)
				break;
			
		} else {
			CGSize labelSize = [text sizeWithFont:newFont];
			if (labelSize.width <= maxWidth)
				break;
				
		}			
	}
	
	return newFont;
}

-(CGFloat) tableView:(UITableView*) tableView heightForHeaderInSection:(NSInteger) section
{
	if (removeExtra && !spaceSave)
	{
		return 170;
	} else if (spaceSave) {
		return 102;
	} else {
		return 180;
	}
}

- (CGFloat) tableView:(LITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{	
	return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(LITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

-(UIView*) tableView:(LITableView*) tableView viewForHeaderInSection:(NSInteger) section
{	
	CGRect viewBounds;
	if (removeExtra && !spaceSave)
	{
		viewBounds = CGRectMake(0, 0, 320, 170);
	} else if (spaceSave) {
		viewBounds = CGRectMake(0, 0, 320, 102);
	} else {
		viewBounds = CGRectMake(0, 0, 320, 180);
	}
	HTCHeaderView* view = [[[HTCHeaderView alloc] initWithFrame:viewBounds] autorelease];
	
	/* City Settings */
	
	int citymaxsize = 18;
	if (NSNumber* cmxs = [self.plugin.preferences objectForKey:@"CityMaxSize"])
		citymaxsize = cmxs.intValue;
	
	int cityminsize = 12;
	if (NSNumber* cmns = [self.plugin.preferences objectForKey:@"CityMinSize"])
		cityminsize = cmns.intValue;
	
	BOOL cityTwoLine = false;
	if (NSNumber* ctl = [self.plugin.preferences objectForKey:@"CityTwoLines"])
		cityTwoLine = ctl.boolValue;
	
	/* Description Settings */
	
	int descriptionmaxsize = 12;
	if (NSNumber* dmxs = [self.plugin.preferences objectForKey:@"DescriptionMaxSize"])
		descriptionmaxsize = dmxs.intValue;
	
	int descriptionminsize = 8;
	if (NSNumber* dmns = [self.plugin.preferences objectForKey:@"DescriptionMinSize"])
		descriptionminsize = dmns.intValue;
	
	BOOL descriptionTwoLine = false;
	if (NSNumber* dtl = [self.plugin.preferences objectForKey:@"DescriptionTwoLines"])
		descriptionTwoLine = dtl.boolValue;
	
	BOOL showDescription = false;
	if (NSNumber* sd = [self.plugin.preferences objectForKey:@"ShowDescription"])
		showDescription = sd.boolValue;
	
	/* Colour Settings */
	
	int cityColour = 7;
	if (NSNumber* cc = [self.plugin.preferences objectForKey:@"CityColour"])
		cityColour = cc.intValue;
	
	int descriptionColour = 1;
	if (NSNumber* dsc = [self.plugin.preferences objectForKey:@"DescriptionColour"])
		descriptionColour = dsc.intValue;
	
	int dateColour = 1;
	if (NSNumber* dtc = [self.plugin.preferences objectForKey:@"DateColour"])
		dateColour = dtc.intValue;

	int tempColour = 7;
	if (NSNumber* tc = [self.plugin.preferences objectForKey:@"TempColour"])
		tempColour = tc.intValue;
	
	int highColour = 1;
	if (NSNumber* hc = [self.plugin.preferences objectForKey:@"HighColour"])
		highColour = hc.intValue;
	
	int lowColour = 1;
	if (NSNumber* lc = [self.plugin.preferences objectForKey:@"LowColour"])
		lowColour = lc.intValue;
	
	/* General Settings */
	
	double iconScale = 1.00;
	if (NSNumber* isc = [self.plugin.preferences objectForKey:@"IconScale"])
		iconScale = isc.doubleValue;
	
	if (NSNumber* th = [self.plugin.preferences objectForKey:@"TwelveHour"])
		twelveHour = th.boolValue;
	
	double clockScale = 0.25;
	
	if (NSNumber* ss = [self.plugin.preferences objectForKey:@"SpaceSaveEnabled"])
		spaceSave = ss.boolValue;
	
	if (spaceSave)
		clockScale = 0.15;
		
	if (NSNumber* rx = [self.plugin.preferences objectForKey:@"RemoveExtra"])
		removeExtra = rx.boolValue;
	
	/* View Code */
	
	
	int bgi = 0;
	
	if (removeExtra && !spaceSave)
	{
		bgi = 1;
	} else if (spaceSave) {
		bgi = 2;
	}
	
	UIImage* bgImage = [imageCacheControl getBackground:bgi];
	UIImageView* iv = [[[UIImageView alloc] initWithFrame:viewBounds] autorelease];
	iv.image = bgImage;
	[view addSubview:iv];
	
	UIImage* hoursTensImage = [imageCacheControl getDigit:0];
	
	CGSize hts = hoursTensImage.size;
	hts.width = hts.width * clockScale;
	hts.height = hts.height * clockScale;
	
	view.hoursTens = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, hts.width, hts.height)] autorelease];
	view.hoursTens.image = hoursTensImage;
	if (spaceSave)
	{
		view.hoursTens.center = CGPointMake(121, 33);
	} else {
		view.hoursTens.center = CGPointMake(96, 54);
	}
	[view addSubview:view.hoursTens];
	
	UIImage* hoursUnitsImage = [imageCacheControl getDigit:0];
	
	CGSize hus = hoursUnitsImage.size;
	hus.width = hus.width * clockScale;
	hus.height = hus.height * clockScale;
	
	view.hoursUnits = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, hus.width, hus.height)] autorelease];
	view.hoursUnits.image = hoursUnitsImage;
	if (spaceSave)
	{
		view.hoursUnits.center = CGPointMake(143, 33);
	} else {
		view.hoursUnits.center = CGPointMake(132, 54);
	}

	[view addSubview:view.hoursUnits];
	
	UIImage* minutesTensImage = [imageCacheControl getDigit:0];
	
	CGSize mts = minutesTensImage.size;
	mts.width = mts.width * clockScale;
	mts.height = mts.height * clockScale;
	
	view.minutesTens = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, mts.width, mts.height)] autorelease];
	view.minutesTens.image = minutesTensImage;		
	if (spaceSave)
	{
		view.minutesTens.center = CGPointMake(175, 33);
	} else {
		view.minutesTens.center = CGPointMake(187, 54);
	}
	[view addSubview:view.minutesTens];
	
	UIImage* minutesUnitsImage = [imageCacheControl getDigit:0];
	
	CGSize mus = minutesUnitsImage.size;
	mus.width = mus.width * clockScale;
	mus.height = mus.height * clockScale;
	
	view.minutesUnits = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, mus.width, mus.height)] autorelease];
	view.minutesUnits.image = minutesUnitsImage;		
	if (spaceSave)
	{
		view.minutesUnits.center = CGPointMake(197, 33);
	} else {
		view.minutesUnits.center = CGPointMake(223, 54);
	}
	[view addSubview:view.minutesUnits];
	
	view.date = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	[view addSubview:view.date];
	view.date.font = [UIFont boldSystemFontOfSize:16];
	view.date.textAlignment = UITextAlignmentRight;
	view.date.textColor = [self colourToSet:dateColour];
	view.date.backgroundColor = [UIColor clearColor];
	if (spaceSave)
	{
		view.date.frame = CGRectMake(205, 38, 95, 22);
	} else {
		view.date.frame = CGRectMake(190, 105, 100, 22);
	}
	
	view.city = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	[view addSubview:view.city];
	view.city.font = [UIFont boldSystemFontOfSize:citymaxsize];
	view.city.textAlignment = UITextAlignmentLeft;
	view.city.textColor = [self colourToSet:cityColour];
	view.city.backgroundColor = [UIColor clearColor];
	if (cityTwoLine)
	{
		view.city.numberOfLines = 2;
		view.city.frame = CGRectMake(29, 102, 95, 33);
	} else {
		view.city.numberOfLines = 1;
		view.city.frame = CGRectMake(29, 102, 95, 22);
	}

	view.description = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	[view addSubview:view.description];
	view.description.font = [UIFont boldSystemFontOfSize:descriptionmaxsize];
	view.description.textAlignment = UITextAlignmentLeft;
	view.description.textColor = [self colourToSet:descriptionColour];
	view.description.backgroundColor = [UIColor clearColor];
	if (descriptionTwoLine)
	{
		view.description.numberOfLines = 2;
		view.description.frame = CGRectMake(29, 126, 95, 27);
	} else {
		view.description.numberOfLines = 1;
		view.description.frame = CGRectMake(29, 126, 95, 18);
	}
	[view updateTimeHTC];
	
	double iconStandardScale = 3.00;
	
	view.icon = [self tableView:tableView iconForHeaderInSection:section];
	CGRect ir = view.icon.frame;
	if (spaceSave)
	{
		if (ir.size.width > ir.size.height)
		{
			iconStandardScale = (55 / ir.size.width);
		} else {
			iconStandardScale = (55 / ir.size.height);
		}
	} else {
		if (ir.size.width > ir.size.height)
		{
			iconStandardScale = (80 / ir.size.width);
		} else {
			iconStandardScale = (80 / ir.size.height);
		}
	}
	ir.size.width *= (iconStandardScale * iconScale);
	ir.size.height *= (iconStandardScale * iconScale);
	view.icon.frame = ir;
	if (spaceSave)
	{
		view.icon.center = CGPointMake(160, 85);
	} else {
		view.icon.center = CGPointMake(160, 135);
	}
	[view addSubview:view.icon];
	
	view.temp = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	[view addSubview:view.temp];
	view.temp.font = [UIFont systemFontOfSize:37];
	view.temp.textColor = [self colourToSet:tempColour];
	view.temp.backgroundColor = [UIColor clearColor];
	view.temp.frame = CGRectMake(190, 127, 100, 37);
	
	view.high = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	[view addSubview:view.high];
	view.high.font = [UIFont boldSystemFontOfSize:14];
	view.high.textColor = [self colourToSet:highColour];
	view.high.backgroundColor = [UIColor clearColor];
	if (spaceSave)
	{
		view.high.frame = CGRectMake(190, 61, 100, 18);
	} else {
		view.high.frame = CGRectMake(190, 128, 100, 18);
	}
	
	view.low = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	[view addSubview:view.low];
	view.low.font = [UIFont boldSystemFontOfSize:14];
	view.low.textColor = [self colourToSet:lowColour];
	view.low.backgroundColor = [UIColor clearColor];
	if (spaceSave)
	{
		view.low.frame = CGRectMake(190, 78, 100, 18);
	} else {
		view.low.frame = CGRectMake(190, 145, 100, 18);
	}
	
	NSDictionary* weather = [[self.dataCache objectForKey:@"weather"] retain];
	
	NSString* city = [weather objectForKey:@"city"];
	NSRange r = [city rangeOfString:@","];
	if (r.location != NSNotFound)
		city = [city substringToIndex:r.location];
	view.city.text = city;
		
	UIFont* tmpCityFont = view.city.font;
	view.city.font = [self fontToFitText:view.city.text withFont:tmpCityFont withMaxWidth:view.city.frame.size.width withMaxHeight:view.city.frame.size.height withMinSize:cityminsize withMaxSize:citymaxsize allowMoreLines:cityTwoLine];
	
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
	
	UIFont* tmpDescriptionFont = view.description.font;
	view.description.font = [self fontToFitText:view.description.text withFont:tmpDescriptionFont withMaxWidth:view.description.frame.size.width withMaxHeight:view.description.frame.size.height withMinSize:descriptionminsize withMaxSize:descriptionmaxsize allowMoreLines:descriptionTwoLine];
	
	int descriptionBottom = 97;
	int cityTop = 102;
	CGSize cs;
	CGSize ds;
	
	CGSize cityDescriptionWidth = CGSizeMake(95.0f, MAXFLOAT);
	
	if (cityTwoLine)
	{
		cs = [view.city.text sizeWithFont:view.city.font constrainedToSize:cityDescriptionWidth lineBreakMode:UILineBreakModeWordWrap];
	} else {
		cs = [view.city.text sizeWithFont:view.city.font];
	}
	CGRect cr = view.city.frame;
	cr.size.height = cs.height;
	view.city.frame = cr;
	
	if (descriptionTwoLine)
	{
		ds = [view.description.text sizeWithFont:view.description.font constrainedToSize:cityDescriptionWidth lineBreakMode:UILineBreakModeWordWrap];
	} else {
		ds = [view.description.text sizeWithFont:view.description.font];
	}
	CGRect dr = view.description.frame;
	dr.size.height = ds.height;
	view.description.frame = dr;
	
	if (spaceSave)
	{
		view.description.center = CGPointMake(15 + (int)(dr.size.width / 2), descriptionBottom - (int)(dr.size.height / 2));
		view.city.center = CGPointMake(15 + (int)(cr.size.width / 2), descriptionBottom - (2 + dr.size.height + (int)(cr.size.height / 2)));
	} else {
		view.city.center = CGPointMake(29 + (int)(cr.size.width / 2), cityTop + (int)(cr.size.height / 2));
		view.description.center = CGPointMake(29 + (int)(dr.size.width / 2), cityTop + cr.size.height + 2 + (int)(dr.size.height / 2));
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
	
	CGSize hs = [view.high.text sizeWithFont:view.high.font];
	CGRect hr = view.high.frame;
	hr.size.width = hs.width;
	hr.size.height = hs.height;
	
	CGSize ls = [view.low.text sizeWithFont:view.low.font];
	CGRect lr = view.low.frame;
	lr.size.width = ls.width;
	lr.size.height = ls.height;
	
	int highLowRHS = 290;
	
	if (spaceSave)
	{
		highLowRHS = 302;
	}

	if (hr.size.width > lr.size.width)
	{
		lr.size.width = hr.size.width;

	} else {
		hr.size.width = lr.size.width;
	}
	
	view.low.frame = lr;
	view.high.frame = hr;
	view.high.center = CGPointMake(highLowRHS - (int)(hr.size.width / 2), hr.origin.y + (int)(hr.size.height / 2));
	view.low.center = CGPointMake(highLowRHS - (int)(lr.size.width / 2), lr.origin.y + (int)(lr.size.height / 2));
										   
	if (spaceSave)
	{
		view.temp.center = CGPointMake(highLowRHS - (hr.size.width + (int)(tr.size.width / 2)), 79);
	} else {
		view.temp.center = CGPointMake(highLowRHS - (hr.size.width + (int)(tr.size.width / 2)), 146);
	}
	
	[weather release];
	
	id tmp = HTCView;
	HTCView = [view retain];
	[tmp release];
	
	return view;
	
}

-(id) initWithPlugin:(LIPlugin*) plugin
{	
	[imageCacheControl initCache];
	
	Class $SBAwayDateView = objc_getClass("SBAwayDateView");
	Hook(SBAwayDateView, updateClock, updateClock);
	Class $SBStatusBarController = objc_getClass("SBStatusBarController");
	Hook(SBStatusBarController, signicantTimeChange, significantTimeChange);
	Class $SBStatusBarTimeView = objc_getClass("SBStatusBarTimeView");
	Hook(SBStatusBarTimeView, drawRect:, sbDrawRect);
	
	return [super initWithPlugin:plugin];
}

@end
