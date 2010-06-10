#include "HTCPlugin.h"
#include "HTCConstants.h"
#include <UIKit/UIKit.h>
#include "substrate.h"

Class $SBStatusBarControllerHTC = objc_getClass("SBStatusBarController");

#define localize(str) \
[self.plugin.bundle localizedStringForKey:str value:str table:nil]

#define Hook(cls, sel, imp) \
_ ## imp = MSHookMessage($ ## cls, @selector(sel), &$ ## imp)

extern "C" UIImage *_UIImageWithName(NSString *);
extern "C" CFStringRef UIDateFormatStringForFormatType(CFStringRef type);

static imageCacheController* imageCacheControl = [[imageCacheController alloc] init];
static utilTools* utilToolsControl = [[utilTools alloc] init];

@implementation HTCSettingsController
@end

@implementation utilTools

-(UIFont*) fontToFitText:(NSString*)text withFont:(UIFont*)font inFrame:(CGRect)frame withMinSize:(int)minSize withMaxSize:(int)maxSize allowMoreLines:(BOOL)moreLines
{		
	int i = maxSize;
	
	UIFont* newFont = font;
	CGSize constraintSize = CGSizeMake(frame.size.width, MAXFLOAT);
	
	for(i; i >= minSize; i=i-2)
	{
		newFont = [newFont fontWithSize:i];
		
		if (moreLines)
		{
			CGSize labelSize = [text sizeWithFont:newFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
			if (labelSize.height <= frame.size.height)
				break;
			
		} else {
			CGSize labelSize = [text sizeWithFont:newFont];
			if (labelSize.width <= frame.size.width)
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

-(UIImage*) getDigit:(int)digit
{	
	NSString* digitName = [digits objectAtIndex:digit];
	UIImage* returnDigit = [self.imageCache objectForKey:digitName];

	return returnDigit;
}

-(UIImage*) getBackground:(int)background
{	
	NSString* backgroundName = [backgrounds objectAtIndex:background];
	UIImage* returnBackground = [self.imageCache objectForKey:backgroundName];

	return returnBackground;
}

@end

@implementation HTCClockView

@synthesize hoursUnits, minutesUnits, hoursTens, minutesTens;

-(id) initWithFrame:(CGRect)frame;
{
	self = [super initWithFrame:frame];
	self.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	
	UIImage* initImage = [imageCacheControl getDigit:0];
	
	CGSize originalDigitSize = initImage.size;
	CGSize newDigitSize = CGSizeMake(((frame.size.height / originalDigitSize.height)*originalDigitSize.width),frame.size.height);
	
	self.hoursTens = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, newDigitSize.width, newDigitSize.height)] autorelease];
	self.hoursTens.image = initImage;
	self.hoursTens.center = CGPointMake((newDigitSize.width / 2), (frame.size.height / 2));
	[self addSubview:self.hoursTens];
	
	self.hoursUnits = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, newDigitSize.width, newDigitSize.height)] autorelease];
	self.hoursUnits.image = initImage;
	self.hoursUnits.center = CGPointMake((newDigitSize.width * 1.5), (frame.size.height / 2));
	[self addSubview:self.hoursUnits];
	
	self.minutesTens = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, newDigitSize.width, newDigitSize.height)] autorelease];
	self.minutesTens.image = initImage;		
	self.minutesTens.center = CGPointMake((frame.size.width - (newDigitSize.width * 1.5)), (frame.size.height / 2));
	[self addSubview:self.minutesTens];
	
	self.minutesUnits = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, newDigitSize.width, newDigitSize.height)] autorelease];
	self.minutesUnits.image = initImage;
	self.minutesUnits.center = CGPointMake((frame.size.width - (newDigitSize.width / 2)), (frame.size.height / 2));
	[self addSubview:self.minutesUnits];
	
	return self;
}

-(void) layoutSubviews
{
	[super layoutSubviews];
	
	UIImage* initImage = [imageCacheControl getDigit:0];
	
	CGSize originalDigitSize = initImage.size;
	CGSize newDigitSize = CGSizeMake(((self.frame.size.height / originalDigitSize.height)*originalDigitSize.width),self.frame.size.height);
	
	self.hoursTens.frame = CGRectMake(0, 0, newDigitSize.width, newDigitSize.height);
	self.hoursUnits.frame = CGRectMake(0, 0, newDigitSize.width, newDigitSize.height);
	self.minutesTens.frame = CGRectMake(0, 0, newDigitSize.width, newDigitSize.height);
	self.minutesUnits.frame = CGRectMake(0, 0, newDigitSize.width, newDigitSize.height);
	
	self.hoursTens.center = CGPointMake((newDigitSize.width / 2), (self.frame.size.height / 2));
	self.hoursUnits.center = CGPointMake((newDigitSize.width * 1.5), (self.frame.size.height / 2));
	self.minutesTens.center = CGPointMake((self.frame.size.width - (newDigitSize.width * 1.5)), (self.frame.size.height / 2));
	self.minutesUnits.center = CGPointMake((self.frame.size.width - (newDigitSize.width / 2)), (self.frame.size.height / 2));
}

@end

@implementation HTCTempView : UIView

@synthesize temp, high, low;

-(void) layoutSubviews
{
	CGSize ts = [self.temp.text sizeWithFont:self.temp.font];
	CGRect tr = self.temp.frame;
	tr.size.width = ts.width;
	tr.size.height = ts.height;
	self.temp.frame = tr;
	
	CGSize hs = [self.high.text sizeWithFont:self.high.font];
	CGRect hr = self.high.frame;
	hr.size.width = hs.width;
	hr.size.height = hs.height;
	
	CGSize ls = [self.low.text sizeWithFont:self.low.font];
	CGRect lr = self.low.frame;
	lr.size.width = ls.width;
	lr.size.height = ls.height;
	
	if (hr.size.width > lr.size.width)
	{
		lr.size.width = hr.size.width;
	} else {
		hr.size.width = lr.size.width;
	}
	
	self.low.frame = lr;
	self.high.frame = hr;
	
	float tempWidth = self.temp.frame.size.width + self.high.frame.size.width;
	
	self.frame.size.width = tempWidth;
	
	self.high.center = CGPointMake(tempWidth - (hr.size.width / 2), (hr.size.height / 2));
	self.low.center = CGPointMake(tempWidth - (lr.size.width / 2), hr.size.height + (lr.size.height / 2));
	self.temp.center = CGPointMake(tempWidth - (2 + hr.size.width + (self.temp.frame.size.width / 2)), ((self.temp.frame.size.height / 2) -2));
}


-(id) initWithFrame:(CGRect)frame withTempColour:(int)tempTextColour withHighColour:(int)highTextColour withLowColour:(int)lowTextColour
{
	self = [super initWithFrame:frame];
	self.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	
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
@synthesize dateFormat, showCalendar;

-(void) layoutSubviews
{
	NSLog(@"Layout HTCHeaderView");
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
	
	/* Update Layout */

        CGRect screen = [[UIScreen mainScreen] bounds];
        int orientation = [[$SBStatusBarControllerHTC sharedStatusBarController] statusBarOrientation];
        float center = (orientation == 90 || orientation == -90 ? screen.size.height : screen.size.width) / 2;

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
	double iconStandardScale = 3.00;
	CGSize is = self.icon.image.size; 
	CGRect ir = CGRectMake(0, 0, is.width, is.height);
	
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
	self.icon.frame = ir;
	
	/* Set Frame Sizes */
	if (spaceSave)
	{
		self.clock.frame = CGRectMake(0, 0, 98, 37);
		self.date.frame = CGRectMake(0, 0, 92, 22);
		self.clock.center = CGPointMake(center, 33);
	} else {
		self.clock.frame = CGRectMake(0, 0, 163, 60);
		self.date.frame = CGRectMake(0, 0, 100, 22);
		self.clock.center = CGPointMake(center, 54);
	}
	
	/* Layout Clock Images */
	[self.clock setNeedsLayout];
	
	CGSize cs;
	CGSize ds;
	
	CGSize cityDescriptionWidth = CGSizeMake(95.0f, MAXFLOAT);
	
	/* Set City Frame Sizes */
	if (cityTwoLine)
	{
		self.city.frame = CGRectMake(0, 0, 95, 33);
		self.city.numberOfLines = 2;
	} else {
		self.city.frame = CGRectMake(0, 0, 95, 22);
		self.city.numberOfLines = 1;
	}
	
	/* Resize City Text */
	UIFont* tmpCityFont = self.city.font;
	self.city.font = [utilToolsControl fontToFitText:self.city.text withFont:tmpCityFont inFrame:self.city.frame withMinSize:cityMinSize withMaxSize:cityMaxSize allowMoreLines:cityTwoLine];
	
	/* Reset City Size With New Text Size */
	if (cityTwoLine)
	{
		cs = [self.city.text sizeWithFont:self.city.font constrainedToSize:cityDescriptionWidth lineBreakMode:UILineBreakModeWordWrap];
	} else {
		cs = [self.city.text sizeWithFont:self.city.font];
	}
	CGRect cr = self.city.frame;
	cr.size.height = cs.height;
	self.city.frame = cr;
	
	/* Set Description Frame Sizes */
	if (descriptionTwoLine)
	{
		self.description.frame = CGRectMake(0, 0, 95, 27);
		self.description.numberOfLines = 2;
	} else {
		self.description.frame = CGRectMake(0, 0, 95, 18);
		self.description.numberOfLines = 1;
	}
	
	/* Resize Description Text */
	UIFont* tmpDescriptionFont = self.description.font;
	self.description.font = [utilToolsControl fontToFitText:self.description.text withFont:tmpDescriptionFont inFrame:self.description.frame withMinSize:descriptionMinSize withMaxSize:descriptionMaxSize allowMoreLines:descriptionTwoLine];
	
	/* Reset Description Size With New Text Size */
	if (descriptionTwoLine)
	{
		ds = [self.description.text sizeWithFont:self.description.font constrainedToSize:cityDescriptionWidth lineBreakMode:UILineBreakModeWordWrap];
	} else {
		ds = [self.description.text sizeWithFont:self.description.font];
	}
	CGRect dr = self.description.frame;
	dr.size.height = ds.height;
	self.description.frame = dr;
	
	/* Position City and Description */
	float cityDescLHS;
	float descriptionBottom = 97;
	float cityTop = 102;
	
	if (spaceSave)
	{
		cityDescLHS = center - 145;
		self.description.center = CGPointMake(cityDescLHS + (dr.size.width / 2), descriptionBottom - (dr.size.height / 2));
		self.city.center = CGPointMake(cityDescLHS + (cr.size.width / 2), descriptionBottom - (2 + dr.size.height + (cr.size.height / 2)));
	} else {
		cityDescLHS = center - 131;
		self.city.center = CGPointMake(cityDescLHS + (cr.size.width / 2), cityTop + (cr.size.height / 2));
		self.description.center = CGPointMake(cityDescLHS + (dr.size.width / 2), cityTop + cr.size.height + 2 + (dr.size.height / 2));
	}
	
	/* Resize Temp, then reset positions */
	[self.temp setNeedsLayout];
	
	float tempRHS = center + 130;
	
	if (spaceSave)
	{
		tempRHS = center + 140;
	}
	
	float tempWidth = self.temp.temp.frame.size.width + self.temp.high.frame.size.width;
	
	self.temp.frame.size.width = tempWidth;
	
	if (spaceSave)
	{
		self.temp.center = CGPointMake(tempRHS - (int)(tempWidth / 2), 79);
		self.date.center = CGPointMake((tempRHS - (self.date.frame.size.width / 2)), (38 + (self.date.frame.size.height / 2)));
		self.icon.center = CGPointMake(center, 85);
	} else {
		self.temp.center = CGPointMake(tempRHS - (int)(tempWidth / 2), 146);
		self.date.center = CGPointMake((tempRHS - (self.date.frame.size.width / 2)), (105 + (self.date.frame.size.height / 2)));
		self.icon.center = CGPointMake(center, 135);
	}
	
	/*Update Date Font Size */
	
	UIFont* tmpDateFont = self.date.font;
	self.date.font = [utilToolsControl fontToFitText:self.date.text withFont:tmpDateFont inFrame:self.date.frame withMinSize:10 withMaxSize:18 allowMoreLines:FALSE];
}

-(id) initWithPreferences:(NSDictionary*)preferences
{	
	/* General Settings */
	BOOL spaceSave = false;	
	if (NSNumber* ss = [preferences objectForKey:@"SpaceSaveEnabled"])
		spaceSave = ss.boolValue;
	
	BOOL removeExtra = false;
	if (NSNumber* rx = [preferences objectForKey:@"RemoveExtra"])
		removeExtra = rx.boolValue;
	
	/* Setup HTCHeaderView with default values */
	int bgInt = 0;
	CGRect frame;
	if (removeExtra && !spaceSave)
	{	
		bgInt = 1;
		frame = CGRectMake(0, 0, 320, 170);
	} else if (spaceSave) {
		bgInt = 2;
		frame = CGRectMake(0, 0, 320, 102);
	} else {
		frame = CGRectMake(0, 0, 320, 180);
	}
	
	self = [super initWithFrame:frame];
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.autoresizesSubviews = YES;
	self.viewPreferences = [NSDictionary dictionaryWithDictionary:preferences];
	
	self.dateFormat = [[NSString stringWithFormat:@"EEE, %@", (NSString*)UIDateFormatStringForFormatType(CFSTR("UIAbbreviatedMonthDayFormat"))] retain];
	
	self.icon = [self iconViewToFitInFrame:CGRectMake(0, 0, 80, 80)];
	self.background = [self backgroundWithFrame:frame andBackgroundImage:bgInt];
	self.date = [self dateViewToFitInFrame:CGRectMake(0, 0, 100, 22) withColour:1];
	
	self.temp = [[[HTCTempView alloc] initWithFrame:CGRectMake(0, 0, 100, 37) withTempColour:7 withHighColour:1 withLowColour:1] autorelease];
	self.clock = [[[HTCClockView alloc] initWithFrame:CGRectMake(0, 0, 163, 60)] autorelease];

	self.city = [self cityViewToFitInFrame:CGRectMake(0, 0, 95, 22) withMaxSize:18 usingTwoLines:FALSE withColour:7];
	self.description = [self descriptionViewToFitInFrame:CGRectMake(0, 0, 95, 18) withMaxSize:14 usingTwoLines:FALSE withColour:1];
			
	[self addSubview:self.background];
	[self addSubview:self.date];
	[self addSubview:self.temp];
	[self addSubview:self.clock];
	[self addSubview:self.city];
	[self addSubview:self.description];
	[self addSubview:self.icon];
		
	return self;
}

-(void) updatePreferences:(NSDictionary*)preferences
{
	self.viewPreferences = [NSDictionary dictionaryWithDictionary:preferences];
}

-(UIImageView*) iconViewToFitInFrame:(CGRect)frame
{
	UIImageView* icon = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease];
	icon.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	return icon;
}

-(UIImageView*) backgroundWithFrame:(CGRect)frame andBackgroundImage:(int)bgi
{	
	UIImage* bgImage = [imageCacheControl getBackground:bgi];
	UIImageView* background = [[[UIImageView alloc] initWithFrame:frame] autorelease];
	background.image = bgImage;
	background.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	return background;
}					 
					 
-(UILabel*) dateViewToFitInFrame:(CGRect)frame withColour:(int)textColour
{
	UILabel* date = [[[UILabel alloc] initWithFrame:frame] autorelease];
	date.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	date.font = [UIFont boldSystemFontOfSize:16];
	date.textAlignment = UITextAlignmentRight;
	date.textColor = [utilToolsControl colourToSetFromInt:textColour];
	date.backgroundColor = [UIColor clearColor];
	return date;
}

-(UILabel*) cityViewToFitInFrame:(CGRect)frame withMaxSize:(int)maxSize usingTwoLines:(BOOL)twoLine withColour:(int)textColour
{
	UILabel* city = [[[UILabel alloc] initWithFrame:frame] autorelease];
	city.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	city.font = [UIFont boldSystemFontOfSize:maxSize];
	city.textAlignment = UITextAlignmentLeft;
	city.textColor = [utilToolsControl colourToSetFromInt:textColour];
	city.backgroundColor = [UIColor clearColor];
	if (twoLine)
	{
		city.numberOfLines = 2;
	} else {
		city.numberOfLines = 1;
	}
	return city;
}

-(UILabel*) descriptionViewToFitInFrame:(CGRect)frame withMaxSize:(int)maxSize usingTwoLines:(BOOL)twoLine withColour:(int)textColour
{
	UILabel* description = [[[UILabel alloc] initWithFrame:frame] autorelease];
	description.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	description.font = [UIFont boldSystemFontOfSize:maxSize];
	description.textAlignment = UITextAlignmentLeft;
	description.textColor = [utilToolsControl colourToSetFromInt:textColour];
	description.backgroundColor = [UIColor clearColor];
	if (twoLine)
	{
		description.numberOfLines = 2;
	} else {
		description.numberOfLines = 1;
	}
	return description;
}

-(void) touchesEnded:(NSSet*) touches withEvent:(UIEvent*) event
{
	UITouch* touch = [touches anyObject];
	CGPoint p = [touch locationInView:self];
	self.showCalendar = (p.x < (self.frame.size.width / 2));
	return [self.nextResponder touchesEnded:touches withEvent:event];
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
	
	[pool release];
}

-(void) updateTimeHTC

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
		self.date.font = [utilToolsControl fontToFitText:self.date.text withFont:tmpDateFont inFrame:self.date.frame withMinSize:10 withMaxSize:18 allowMoreLines:FALSE];
		
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

@synthesize headerViewHTC;

-(void) _updateTime
{
	[self.headerViewHTC updateTimeHTC];
}
					 
-(void) updateWeatherViews
{	
	if (self.headerViewHTC == nil)
	{
		self.headerViewHTC = [self createHTCHeaderView];
	} else {
		[self.headerViewHTC updatePreferences:self.plugin.preferences];
	}

	[self updateTime];
	
	NSDictionary* weather = [[self.dataCache objectForKey:@"weather"] retain];
	
	UIImageView* icon = [self weatherIcon];
	self.headerViewHTC.icon.image = icon.image;
	
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
				
		self.headerViewHTC.description.hidden = false;
		self.headerViewHTC.description.text = description;
	}
	else
	{				
	self.headerViewHTC.description.hidden = true;
	}
	
	NSString* city = [weather objectForKey:@"city"];
	NSRange r = [city rangeOfString:@","];
	if (r.location != NSNotFound)
		city = [city substringToIndex:r.location];
	
	self.headerViewHTC.city.text = city;
	
	if (NSArray* forecast = [weather objectForKey:@"forecast"])
	{
		if (forecast.count > 0)
		{
			NSDictionary* today = [forecast objectAtIndex:0];
			self.headerViewHTC.temp.high.text = [NSString stringWithFormat:@"H %d\u00B0", [[today objectForKey:@"high"] intValue]];
			self.headerViewHTC.temp.low.text = [NSString stringWithFormat:@"L %d\u00B0", [[today objectForKey:@"low"] intValue]];
		}
	}
			
	self.headerViewHTC.temp.temp.text = [NSString stringWithFormat:@"%d\u00B0", [[weather objectForKey:@"temp"] intValue]];
			
	[self.headerViewHTC setNeedsLayout];
	[self.headerViewHTC setNeedsDisplay];
	
	[super updateWeatherViews];
}

-(BOOL) showCalendar
{
	int detail = 0;
	if (NSNumber* n = [self.plugin.preferences objectForKey:@"Detail"])
		detail = n.intValue;
	
	if (detail == 2)
	{
		return self.headerViewHTC.showCalendar;
	}
	
	return (detail == 1);
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

- (CGFloat) tableView:(LITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{	
	return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(LITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

-(HTCHeaderView*) createHTCHeaderView
{
	HTCHeaderView* view = [[[HTCHeaderView alloc] initWithPreferences:self.plugin.preferences] autorelease];
	return view;
}

-(UIView*) tableView:(LITableView*) tableView viewForHeaderInSection:(NSInteger) section
{	
	[self updateWeatherViews];
	return self.headerViewHTC;
}

-(id) initWithPlugin:(LIPlugin*) plugin
{	
	[imageCacheControl initCache];
	
	return [super initWithPlugin:plugin];
}

@end
