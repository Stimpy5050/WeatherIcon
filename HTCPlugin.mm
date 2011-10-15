#import "HTCPlugin.h"
#import "HTCConstants.h"
#import <UIKit/UIKit.h>
#include <substrate.h>
#include <math.h>

#define localize(str) \
[self.plugin.bundle localizedStringForKey:str value:str table:nil]

#define isInvalidSize(size) \
isnan(size.width) || isnan(size.height) || size.width == 0 || size.height == 0

#define isInvalidNumber(x) \
isnan(x) || x == 0

#define Hook(cls, sel, imp) \
_ ## imp = MSHookMessage($ ## cls, @selector(sel), &$ ## imp)

extern "C" UIImage *_UIImageWithName(NSString *);
extern "C" CFStringRef UIDateFormatStringForFormatType(CFStringRef type);

static imageCacheController* imageCacheControl = [[imageCacheController alloc] init];
static utilTools* utilToolsControl = [[utilTools alloc] init];

@implementation HTCSettingsController
@end

@implementation utilTools

-(UIFont*) fontToFitText:(NSString*)text withFont:(UIFont*)font inSize:(CGSize)size withMinSize:(int)minSize withMaxSize:(int)maxSize allowMoreLines:(BOOL)moreLines
{		
	int i = maxSize;
	
	UIFont* newFont = font;
	CGSize constraintSize = CGSizeMake(size.width, MAXFLOAT);
	
	for(i; i >= minSize; i=i-2)
	{
		newFont = [newFont fontWithSize:i];
		
		if (moreLines)
		{
			CGSize labelSize = [text sizeWithFont:newFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
			if (labelSize.height <= size.height)
				break;
			
		} else {
			CGSize labelSize = [text sizeWithFont:newFont];
			if (labelSize.width <= size.width)
				break;
			
		}			
	}
	
	return newFont;
}

-(UIColor*) colourToSetFromInt:(int)colourInt
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

-(UIColor*) colourToSetFromRed:(CGFloat)Red andGreen:(CGFloat)Green andBlue:(CGFloat)Blue
{	
	return [UIColor colorWithRed:Red green:Green blue:Blue alpha:1.0];
}

@end

@implementation imageCacheController

@synthesize imageCache;

-(void) initCache
{	
	self.imageCache = [NSMutableDictionary dictionaryWithCapacity:13];
	
	int i=0;
	int x=0;
	NSBundle* bundle = [NSBundle bundleWithIdentifier:@"com.burgch.lockinfo.HTCPlugin"];

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

- (UIImage*)getImage:(NSString*)name
{
	NSBundle* bundle = [NSBundle bundleWithIdentifier:@"com.burgch.lockinfo.HTCPlugin"];
	
	NSString* imagePath = [bundle pathForResource:name ofType:@"png"];
	UIImage* image = [UIImage li_imageWithContentsOfResolutionIndependentFile:imagePath];
	
	if (image)
		[self.imageCache setObject:image forKey:name];
	
	return image;
}

- (UIImage*)getDigit:(int)digit
{	
	NSString* digitName = [digits objectAtIndex:digit];
	UIImage* returnDigit = [self.imageCache objectForKey:digitName];
	
	if (returnDigit)
	{
		return returnDigit;
	} else {
		return [self getImage:digitName];
	}	
}

- (UIImage*)getBackground:(int)background
{	
	NSString* backgroundName = [backgrounds objectAtIndex:background];
	UIImage* returnBackground = [self.imageCache objectForKey:backgroundName];
	
	if (returnBackground)
	{
		return returnBackground;
	} else {
		return [self getImage:backgroundName];
	}
	
}

@end

@implementation HTCClockView

@synthesize hoursUnits, minutesUnits, hoursTens, minutesTens;

-(id) initWithFrame:(CGRect)frame;
{
	self = [super initWithFrame:frame];
	
	self.hoursTens = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease];
	[self addSubview:self.hoursTens];
	
	self.hoursUnits = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease];
	[self addSubview:self.hoursUnits];
	
	self.minutesTens = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease];	
	[self addSubview:self.minutesTens];
	
	self.minutesUnits = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease];
	[self addSubview:self.minutesUnits];
	
	return self;
}

-(void) layoutSubviews
{
	[super layoutSubviews];
	
	UIImage* initImage = [imageCacheControl getDigit:0];
	
	if (initImage)
	{
		CGSize originalDigitSize = initImage.size;
		
		double newDigitScale = (self.frame.size.height / originalDigitSize.height);
		
		CGSize newDigitSize = CGSizeMake((int)(newDigitScale * originalDigitSize.width), self.frame.size.height);
		
		if (isInvalidSize(newDigitSize))
		{
			NSLog(@"HTC: Invalid digit size so not updating frames");
		} else {
			self.hoursTens.frame = CGRectMake(0, 0, newDigitSize.width, newDigitSize.height);
			self.hoursUnits.frame = CGRectMake(newDigitSize.width, 0, newDigitSize.width, newDigitSize.height);
			self.minutesTens.frame = CGRectMake(self.frame.size.width - (newDigitSize.width * 2), 0, newDigitSize.width, newDigitSize.height);
			self.minutesUnits.frame = CGRectMake(self.frame.size.width - newDigitSize.width, 0, newDigitSize.width, newDigitSize.height);
		}
	
	}
	
}

@end

@implementation HTCTempView : UIView

@synthesize temp, high, low;

-(void) layoutSubviews
{
	CGSize ts = [self.temp.text sizeWithFont:self.temp.font];
	CGSize hs = [self.high.text sizeWithFont:self.high.font];
	CGSize ls = [self.low.text sizeWithFont:self.low.font];

	if (hs.width > ls.width)
	{
		ls.width = hs.width;
	} else {
		hs.width = ls.width;
	}
	
	float tempWidth = ts.width + hs.width;
	
	CGRect frame = self.frame;
	frame.size.width = tempWidth;
	self.frame = frame;
	
	self.high.frame = CGRectMake(tempWidth - hs.width, 4, hs.width, hs.height);
	self.low.frame = CGRectMake(tempWidth - ls.width, hs.height + 4, ls.width, ls.height);
	self.temp.frame = CGRectMake(0, 0, ts.width, ts.height);
	
	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
	[center postNotificationName:@"com.burgch.lockinfo.HTCPlugin.updateLayout" object:nil];
}

-(id) initWithFrame:(CGRect)frame withTempColour:(int)tempTextColour withHighColour:(int)highTextColour withLowColour:(int)lowTextColour
{
	self = [super initWithFrame:frame];
	
	self.temp = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 37)] autorelease];
	[self addSubview:self.temp];
	self.temp.font = [UIFont systemFontOfSize:37];
	self.temp.textColor = [utilToolsControl colourToSetFromInt:tempTextColour];
	self.temp.backgroundColor = [UIColor clearColor];
	
	self.high = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 18)] autorelease];
	[self addSubview:self.high];
	self.high.font = [UIFont boldSystemFontOfSize:14];
	self.high.textColor = [utilToolsControl colourToSetFromInt:highTextColour];
	self.high.backgroundColor = [UIColor clearColor];
	
	self.low = [[[UILabel alloc] initWithFrame:CGRectMake(0, 17, 100, 18)] autorelease];
	[self addSubview:self.low];
	self.low.font = [UIFont boldSystemFontOfSize:14];
	self.low.textColor = [utilToolsControl colourToSetFromInt:lowTextColour];
	self.low.backgroundColor = [UIColor clearColor];
	
	return self;
}

@end

@implementation HTCHeaderView

@synthesize icon, background, city, date, description;
@synthesize hourNumber, minuteNumber, viewPreferences;
@synthesize clock, temp;

-(void) layoutSubviews
{
	[super layoutSubviews];
	
	/* City Settings */
	
	BOOL cityTwoLine = false;
	if (NSNumber* ctl = [self.viewPreferences objectForKey:@"CityTwoLines"])
		cityTwoLine = ctl.boolValue;
	
	int cityMaxSize = 18;
	if (NSNumber* cmxs = [self.viewPreferences objectForKey:@"CityMaxSize"])
		cityMaxSize = cmxs.intValue;
	
	int cityMinSize = 12;
	if (NSNumber* cmns = [self.viewPreferences objectForKey:@"CityMinSize"])
		cityMinSize = cmns.intValue;
	
	/* Description Settings */
	
	BOOL descriptionTwoLine = false;
	if (NSNumber* dtl = [self.viewPreferences objectForKey:@"DescriptionTwoLines"])
		descriptionTwoLine = dtl.boolValue;
	
	int descriptionMaxSize = 12;
	if (NSNumber* dmxs = [self.viewPreferences objectForKey:@"DescriptionMaxSize"])
		descriptionMaxSize = dmxs.intValue;
	
	int descriptionMinSize = 8;
	if (NSNumber* dmns = [self.viewPreferences objectForKey:@"DescriptionMinSize"])
		descriptionMinSize = dmns.intValue;
	
	/* General Settings */
	
	BOOL removeExtra = false;
	if (NSNumber* rx = [self.viewPreferences objectForKey:@"RemoveExtra"])
		removeExtra = rx.boolValue;
	
	BOOL spaceSave = false;	
	if (NSNumber* ss = [self.viewPreferences objectForKey:@"SpaceSaveEnabled"])
		spaceSave = ss.boolValue;
	
	double iconScale = 1.00;
	if (NSNumber* isc = [self.viewPreferences objectForKey:@"IconScale"])
		iconScale = isc.doubleValue;
	
	/* Update Colous */
	[self updateColours];
	
	/* Update Layout */

	float center = (self.frame.size.width / 2);

	/* Update Frame and Background */
	int bgInt = 0;
	CGRect frame;
	if (removeExtra && !spaceSave)
	{	
		bgInt = 1;
		frame = CGRectMake((center - 160), 0, 320, 170);
	} else if (spaceSave) {
		bgInt = 2;
		frame = CGRectMake((center - 160), 0, 320, 102);
	} else {
		frame = CGRectMake((center - 160), 0, 320, 180);
	}
	
	self.background.frame = frame;
	
	UIImage* bgImage = [imageCacheControl getBackground:bgInt];
	self.background.image = bgImage;
	
	/*Update Icon Size and Position */
	
	if (self.icon.image)
	{
		double iconStandardScale = 1.00;
		CGSize iconSize = self.icon.image.size;
		
		CGPoint ic = CGPointMake(center, 135);
		
		if (spaceSave)
		{
			if (iconSize.width > iconSize.height)
			{
				iconStandardScale = (55 / iconSize.width);
			} else {
				iconStandardScale = (55 / iconSize.height);
			}
			ic = CGPointMake(center, 85);
		} else {
			if (iconSize.width > iconSize.height)
			{
				iconStandardScale = (80 / iconSize.width);
			} else {
				iconStandardScale = (80 / iconSize.height);
			}
		}
		
		if (isInvalidNumber(iconStandardScale))
		{
			NSLog(@"HTC: Icon scale was invalid - replacing now");
			iconStandardScale = 1.00;
		}
		
		iconSize.width *= (iconStandardScale * iconScale);
		iconSize.height *= (iconStandardScale * iconScale);
		
		if (isInvalidSize(iconSize))
		{
			NSLog(@"HTC: invalid icon size so not updating frame");
		} else {
			self.icon.frame = CGRectMake(ic.x - (int)(iconSize.width / 2), ic.y - (int)(iconSize.height / 2), iconSize.width, iconSize.height);
		}
	}
	
	/* Set Frame Sizes */
	
	CGSize dateSize;
	
	if (spaceSave)
	{
		self.clock.frame = CGRectMake(center - 49, 15, 98, 37);
		dateSize = CGSizeMake(92, 22);
	} else {
		self.clock.frame = CGRectMake(center - 82, 24, 163, 60);
		dateSize = CGSizeMake(100, 22);
	}
	
	/* Layout Clock Images */
	[self.clock setNeedsLayout];
	
	CGSize cs;
	CGSize ds;
	
	CGSize cityDescriptionWidth = CGSizeMake(95.0f, MAXFLOAT);
	CGSize citySize;
	CGSize descriptionSize;
	
	/* Set City Frame Sizes */
	if (cityTwoLine)
	{
		citySize = CGSizeMake(95, 33);
		self.city.numberOfLines = 2;
	} else {
		citySize = CGSizeMake(95, 22);
		self.city.numberOfLines = 1;
	}
	
	/* Resize City Text */
	UIFont* tmpCityFont = self.city.font;
	self.city.font = [utilToolsControl fontToFitText:self.city.text withFont:tmpCityFont inSize:citySize withMinSize:cityMinSize withMaxSize:cityMaxSize allowMoreLines:cityTwoLine];
	
	/* Reset City Size With New Text Size */
	if (cityTwoLine)
	{
		cs = [self.city.text sizeWithFont:self.city.font constrainedToSize:cityDescriptionWidth lineBreakMode:UILineBreakModeWordWrap];
	} else {
		cs = [self.city.text sizeWithFont:self.city.font];
	}
	CGRect cr = self.city.frame;
	cr.size.height = cs.height;
	
	/* Set Description Frame Sizes */
	if (descriptionTwoLine)
	{
		descriptionSize = CGSizeMake(95, 27);
		self.description.numberOfLines = 2;
	} else {
		descriptionSize = CGSizeMake(95, 18);
		self.description.numberOfLines = 1;
	}
	
	/* Resize Description Text */
	UIFont* tmpDescriptionFont = self.description.font;
	self.description.font = [utilToolsControl fontToFitText:self.description.text withFont:tmpDescriptionFont inSize:descriptionSize withMinSize:descriptionMinSize withMaxSize:descriptionMaxSize allowMoreLines:descriptionTwoLine];
	
	/* Reset Description Size With New Text Size */
	if (descriptionTwoLine)
	{
		ds = [self.description.text sizeWithFont:self.description.font constrainedToSize:cityDescriptionWidth lineBreakMode:UILineBreakModeWordWrap];
	} else {
		ds = [self.description.text sizeWithFont:self.description.font];
	}
	CGRect dr = self.description.frame;
	dr.size.height = ds.height;
	
	/* Position City and Description */
	float cityDescLHS;
	float descriptionBottom = 97;
	float cityTop = 102;
	
	if (spaceSave)
	{
		cityDescLHS = center - 145;
		self.description.frame = CGRectMake(cityDescLHS, descriptionBottom - dr.size.height, dr.size.width, dr.size.height);
		self.city.frame = CGRectMake(cityDescLHS, descriptionBottom - (2 + dr.size.height + cr.size.height), cr.size.width, cr.size.height);
	} else {
		cityDescLHS = center - 131;
		self.city.frame = CGRectMake(cityDescLHS, cityTop, cr.size.width, cr.size.height);
		self.description.frame = CGRectMake(cityDescLHS, cityTop + cr.size.height + 2, dr.size.width, dr.size.height);
	}
	
	/* Reset Temp Positions */
		
	float tempRHS = center + 132;
	
	if (spaceSave)
	{
		tempRHS = center + 140;
	}
	
	CGSize tempSize = self.temp.frame.size;
	
	if (spaceSave)
	{
		self.temp.frame = CGRectMake(tempRHS - tempSize.width, 55, tempSize.width, tempSize.height);
		self.date.frame = CGRectMake(tempRHS - dateSize.width, 38, dateSize.width, dateSize.height);
	} else {
		self.temp.frame = CGRectMake(tempRHS - tempSize.width, 121, tempSize.width, tempSize.height);
		self.date.frame = CGRectMake(tempRHS - dateSize.width, 105, dateSize.width, dateSize.height);
	}
	
	/*Update Date Font Size */
	
	UIFont* tmpDateFont = self.date.font;
	self.date.font = [utilToolsControl fontToFitText:self.date.text withFont:tmpDateFont inSize:dateSize withMinSize:10 withMaxSize:18 allowMoreLines:FALSE];
}

-(id) initWithPreferences:(NSDictionary*)preferences
{		
	/* Setup HTCHeaderView with default values */
	CGRect frame = CGRectMake(0, 0, 320, 180);
	
	self = [super initWithFrame:frame];
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.autoresizesSubviews = YES;
	self.viewPreferences = [NSDictionary dictionaryWithDictionary:preferences];
	
	self.dateFormat = [[NSString stringWithFormat:@"EEE, %@", (NSString*)UIDateFormatStringForFormatType(CFSTR("UIAbbreviatedMonthDayFormat"))] retain];
	
	self.icon = [[[UIImageView alloc] initWithFrame:CGRectMake(120, 95, 80, 80)] autorelease];
	
	self.background = [[[UIImageView alloc] initWithFrame:frame] autorelease];
	UIImage* bgImage = [imageCacheControl getBackground:0];
	self.background.image = bgImage;
	
	self.date = [[[UILabel alloc] initWithFrame:CGRectMake(200, 105, 100, 22)] autorelease];
	self.date.font = [UIFont boldSystemFontOfSize:16];
	self.date.textAlignment = UITextAlignmentRight;
	self.date.textColor = [utilToolsControl colourToSetFromInt:1];
	self.date.backgroundColor = [UIColor clearColor];
	
	self.temp = [[[HTCTempView alloc] initWithFrame:CGRectMake(192, 121, 100, 37) withTempColour:7 withHighColour:1 withLowColour:1] autorelease];
	self.clock = [[[HTCClockView alloc] initWithFrame:CGRectMake(78, 24, 163, 60)] autorelease];

	self.city = [[[UILabel alloc] initWithFrame:CGRectMake(29, 102, 95, 22)] autorelease];
	self.city.font = [UIFont boldSystemFontOfSize:18];
	self.city.textAlignment = UITextAlignmentLeft;
	self.city.textColor = [utilToolsControl colourToSetFromInt:7];
	self.city.backgroundColor = [UIColor clearColor];
	self.city.numberOfLines = 1;
	
	self.description = [[[UILabel alloc] initWithFrame:CGRectMake(29, 126, 95, 18)] autorelease];
	self.description.font = [UIFont boldSystemFontOfSize:14];
	self.description.textAlignment = UITextAlignmentLeft;
	self.description.textColor = [utilToolsControl colourToSetFromInt:1];
	self.description.backgroundColor = [UIColor clearColor];
	self.description.numberOfLines = 1;
	
	[self addSubview:self.background];
	[self addSubview:self.date];
	[self addSubview:self.temp];
	[self addSubview:self.clock];
	[self addSubview:self.city];
	[self addSubview:self.description];
	[self addSubview:self.icon];
	
	[self updateTime];
	
	return self;
}

-(void) updateColours
{
	/* Colour Settings */

	int cityColour = 7;
	if (NSNumber* cc = [self.viewPreferences objectForKey:@"CityColour"])
	cityColour = cc.intValue;

	int descriptionColour = 1;
	if (NSNumber* dsc = [self.viewPreferences objectForKey:@"DescriptionColour"])
		descriptionColour = dsc.intValue;

	int dateColour = 1;
	if (NSNumber* dtc = [self.viewPreferences objectForKey:@"DateColour"])
		dateColour = dtc.intValue;

	int tempColour = 7;
	if (NSNumber* tc = [self.viewPreferences objectForKey:@"TempColour"])
		tempColour = tc.intValue;

	int highColour = 1;
	if (NSNumber* hc = [self.viewPreferences objectForKey:@"HighColour"])
		highColour = hc.intValue;

	int lowColour = 1;
	if (NSNumber* lc = [self.viewPreferences objectForKey:@"LowColour"])
		lowColour = lc.intValue;

	/* Update Colours */

	self.date.textColor = [utilToolsControl colourToSetFromInt:dateColour];
	self.city.textColor = [utilToolsControl colourToSetFromInt:cityColour];
	self.description.textColor = [utilToolsControl colourToSetFromInt:descriptionColour];
	self.temp.temp.textColor = [utilToolsControl colourToSetFromInt:tempColour];
	self.temp.high.textColor = [utilToolsControl colourToSetFromInt:highColour];
	self.temp.low.textColor = [utilToolsControl colourToSetFromInt:lowColour];
	self.backgroundColor = [UIColor clearColor];
}

-(void) updatePreferences:(NSDictionary*)preferences
{
	self.viewPreferences = [NSDictionary dictionaryWithDictionary:preferences];
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
	
	self.clock.hoursTens.image = [imageCacheControl getDigit:hourTensInt];
	self.clock.hoursUnits.image = [imageCacheControl getDigit:hourUnitsInt];
	self.clock.minutesTens.image = [imageCacheControl getDigit:minuteTensInt];
	self.clock.minutesUnits.image = [imageCacheControl getDigit:minuteUnitsInt];
	
	[self setNeedsDisplay];
	
	[pool release];
}

-(void) updateTime
{	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	BOOL twelveHour = false;
	if (NSNumber* th = [self.viewPreferences objectForKey:@"TwelveHour"])
		twelveHour = th.boolValue;
	
	BOOL useTwelve = false;
	if (NSNumber* ut = [self.viewPreferences objectForKey:@"UseTwelve"])
		useTwelve= ut.boolValue;
		
    NSDate* now = [NSDate date];
    NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
	NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents* timeComponents = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:now];
	
    df.dateFormat = self.dateFormat;
	NSString* dateStr = [df stringFromDate:now];
	if (![dateStr isEqualToString:self.date.text])
	{
		self.date.text = [df stringFromDate:now];
		
		UIFont* tmpDateFont = self.date.font;
		self.date.font = [utilToolsControl fontToFitText:self.date.text withFont:tmpDateFont inSize:self.date.frame.size withMinSize:10 withMaxSize:18 allowMoreLines:FALSE];
		
		[self.date setNeedsLayout];
	}
		
	int h = [timeComponents hour];
	int m = [timeComponents minute];
	
	if (twelveHour && h > 12)
	{
		h = h - 12;
	}
	
	if (twelveHour && useTwelve && h == 0)
	{	
		h = 12;
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

-(void) updateLayout
{
	[self.headerView setNeedsLayout];
}
					 
-(void) updateWeatherViews
{	
	[super updateWeatherViews];
		
	NSDictionary* weather = [[self.dataCache objectForKey:@"weather"] retain];
	HTCHeaderView* header = self.headerView;
	
	[header updatePreferences:self.plugin.preferences];
	
	UIImageView* icon = [self weatherIcon];
	header.icon.image = icon.image;
	
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
				
		header.description.hidden = false;
		header.description.text = description;
	}
	else
	{				
	header.description.hidden = true;
	}
	
	NSString* city = [weather objectForKey:@"city"];
	NSRange r = [city rangeOfString:@","];
	if (r.location != NSNotFound)
		city = [city substringToIndex:r.location];
	
	header.city.text = city;
	
	if (NSArray* forecast = [weather objectForKey:@"forecast"])
	{
		if (forecast.count > 0)
		{
			NSDictionary* today = [forecast objectAtIndex:0];
			header.temp.high.text = [NSString stringWithFormat:@"H %d\u00B0", [[today objectForKey:@"high"] intValue]];
			header.temp.low.text = [NSString stringWithFormat:@"L %d\u00B0", [[today objectForKey:@"low"] intValue]];
		}
	}
			
	header.temp.temp.text = [NSString stringWithFormat:@"%d\u00B0", [[weather objectForKey:@"temp"] intValue]];
	
	[weather release];
	
	[header.temp setNeedsLayout];
	
	[header updateTime];
	[header updateDigits];
	
	[header setNeedsLayout];
	[header setNeedsDisplay];
}

-(CGFloat) tableView:(UITableView*) tableView heightForHeaderInSection:(NSInteger) section
{
	BOOL spaceSave = false;	
	if (NSNumber* ss = [self.plugin.preferences objectForKey:@"SpaceSaveEnabled"])
		spaceSave = ss.boolValue;
	
	BOOL removeExtra = false;
	if (NSNumber* rx = [self.plugin.preferences objectForKey:@"RemoveExtra"])
		removeExtra = rx.boolValue;
	
	if (removeExtra && !spaceSave)
	{
		return 170;
	} else if (spaceSave) {
		return 102;
	} else {
		return 180;
	}
}

-(HTCHeaderView*) createHeaderView
{
	return [[[HTCHeaderView alloc] initWithPreferences:self.plugin.preferences] autorelease];
}

-(id) initWithPlugin:(LIPlugin*) plugin
{	
	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(updateLayout) name:@"com.burgch.lockinfo.HTCPlugin.updateLayout" object:nil];
	[imageCacheControl initCache];
	return [super initWithPlugin:plugin];
}

@end
