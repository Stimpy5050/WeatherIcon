#include "LockWeatherPlugin.h"
#include <UIKit/UIScreen.h>

@interface SpringBoard : UIApplication

-(int) activeInterfaceOrientation;

@end

@implementation LWHeaderView

@synthesize background, themedBackground, icon, description, city, temp, time, date, high, low;

-(void) layoutSubviews
{
	[super layoutSubviews];

	LIDebug(@"LI:LW: %@", self.superview.superview);
	float center = (self.frame.size.width / 2);

	self.background.frame = self.bounds;
	self.themedBackground.frame = self.bounds;

	self.date.frame = CGRectMake(5, 56, center - 40, 18);
	self.city.frame = CGRectMake(5, 73, center - 40, 18);
	self.description.frame = CGRectMake(5, 73, center - 40, 18);

	self.icon.center = CGPointMake(center, 73);

	CGSize ts = [self.temp.text sizeWithFont:self.temp.font];
	CGRect tr = self.temp.frame;
	tr.size.width = ts.width;
	tr.size.height = ts.height;
	self.temp.frame = tr;
	self.temp.center = CGPointMake(center + 35 + (int)(tr.size.width / 2), 74);

	tr = self.high.frame;
	tr.origin.x = self.temp.frame.origin.x + ts.width + 8;
        self.high.frame = tr;

        tr = self.low.frame;
        tr.origin.x = self.temp.frame.origin.x + ts.width + 8;
        self.low.frame = tr;

        ts = [self.time.text sizeWithFont:self.time.font];
        tr = self.time.frame;
        tr.size.height = ts.height;
        self.time.frame = tr;
        self.time.center = CGPointMake(center, 29);
}

-(id) initWithFrame:(CGRect) frame
{
	self = [super initWithFrame:frame];

	UIImage* image = _UIImageWithName(@"UILCDBackground.png");
	UIImageView* iv = [[[UIImageView alloc] initWithImage:image] autorelease];
	iv.frame = self.bounds;
	self.background = iv;
	[self addSubview:iv];

	UIImageView* iv2 = [[[UIImageView alloc] initWithFrame:self.bounds] autorelease];
	self.themedBackground = iv2;
	[self addSubview:iv2];

	self.time = [[[UILabel alloc] initWithFrame:CGRectMake(0, 4, self.frame.size.width, 50)] autorelease];
	self.time.font = [UIFont fontWithName:@"LockClock-Light" size:50];
	self.time.textAlignment = UITextAlignmentCenter;
	self.time.textColor = [UIColor whiteColor];
	self.time.backgroundColor = [UIColor clearColor];
	[self addSubview:self.time];

	self.date = [[[UILabel alloc] initWithFrame:CGRectMake(5, 56, 120, 18)] autorelease];
//	self.date.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	self.date.font = [UIFont boldSystemFontOfSize:14];
	self.date.textAlignment = UITextAlignmentRight;
	self.date.textColor = [UIColor whiteColor];
	self.date.backgroundColor = [UIColor clearColor];
	[self addSubview:self.date];

	self.city = [[[UILabel alloc] initWithFrame:CGRectMake(5, 73, 120, 18)] autorelease];
//	self.city.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	[self addSubview:self.city];
	self.city.font = [UIFont boldSystemFontOfSize:14];
	self.city.textAlignment = UITextAlignmentRight;
	self.city.textColor = [UIColor lightGrayColor];
	self.city.backgroundColor = [UIColor clearColor];

	self.description = [[[UILabel alloc] initWithFrame:CGRectMake(5, 73, 120, 18)] autorelease];
//	self.description.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	[self addSubview:self.description];
	self.description.font = [UIFont boldSystemFontOfSize:14];
	self.description.textAlignment = UITextAlignmentRight;
	self.description.textColor = [UIColor lightGrayColor];
	self.description.backgroundColor = [UIColor clearColor];

	[self updateTime];

	self.icon = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease];
//	self.icon.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	[self addSubview:self.icon];

	self.temp = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	[self addSubview:self.temp];
//	self.temp.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	self.temp.font = [UIFont systemFontOfSize:37];
	self.temp.textColor = [UIColor whiteColor];
	self.temp.backgroundColor = [UIColor clearColor];
	self.temp.frame = CGRectMake(195, 52, 120, 37);

	self.high = [[[UILabel alloc] initWithFrame:CGRectMake(195, 56, 120, 18)] autorelease];
	[self addSubview:self.high];
//	self.high.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	self.high.font = [UIFont boldSystemFontOfSize:14];
	self.high.textColor = [UIColor lightGrayColor];
	self.high.backgroundColor = [UIColor clearColor];

	self.low = [[[UILabel alloc] initWithFrame:CGRectMake(195, 73, 120, 18)] autorelease];
	[self addSubview:self.low];
//	self.low.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	self.low.font = [UIFont boldSystemFontOfSize:14];
	self.low.textColor = [UIColor lightGrayColor];
	self.low.backgroundColor = [UIColor clearColor];

	self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.backgroundColor = [UIColor clearColor];

	return self;
}

-(void) setFrame:(CGRect) frame
{
	[super setFrame:frame];
	NSLog(@"LI:LW: setFrame: %@", [NSThread callStackSymbols]);
	[self setNeedsLayout];
}

-(void) updateTime
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

        NSDate* now = [NSDate date];
        NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];

        df.dateFormat = self.dateFormat;
	NSString* dateStr = [df stringFromDate:now];
	if (![dateStr isEqualToString:self.date.text])
	{
//		NSLog(@"LI:Weather: Refreshing date.");
	        self.date.text = [df stringFromDate:now];
		[self.date setNeedsLayout];
	}

        df.dateFormat = self.timeFormat;
	NSString* timeStr = [df stringFromDate:now];
	if (![timeStr isEqualToString:self.time.text])
	{
//		NSLog(@"LI:Weather: Refreshing time.");
	        self.time.text = [df stringFromDate:now];
		[self.time setNeedsLayout];
	}

	[pool release];
}

@end

@implementation LockWeatherPlugin

-(void) updateWeatherViews
{
	[super updateWeatherViews];

	NSDictionary* weather = [[self.dataCache objectForKey:@"weather"] copy];

	LWHeaderView* header = (LWHeaderView*)self.headerView;

	BOOL themeBG = NO;
	if (NSNumber* n = [self.plugin.preferences objectForKey:@"ThemeBackground"])
		themeBG = n.boolValue;

	if (themeBG)
	{
		header.themedBackground.image = self.plugin.theme.largeHeaderBackground;
		header.themedBackground.alpha = self.plugin.headerTransparency;
		header.background.alpha = 0;

/*
		UIImageView* countBG = [[[UIImageView alloc] initWithImage:self.plugin.theme.countBackground] autorelease];
                countBG.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
                countBG.tag = 93450;
                countBG.alpha = self.plugin.headerTransparency * 0.8;
                countBG.contentStretch = CGRectMake(0.5, 0.0, 0.0, 1.0);

                CGRect countRect = countBG.frame;
                countRect.origin.y = (header.frame.size.height - countRect.size.height) / 2;
                countRect.origin.x = header.bounds.size.width - countRect.size.width - 3;
                countBG.frame = countRect;
                CGPoint countBGCenter = countBG.center;
		[header addSubview:countBG];
*/
	}
	else
	{
		header.background.alpha = 1.0;
		header.themedBackground.alpha = 0;
//                [[header viewWithTag:93450] removeFromSuperview];
	}

	UIImageView* icon = [self weatherIcon];
	header.icon.image = icon.image;
	CGRect ir = header.icon.frame;
	ir.size.width = icon.frame.size.width * 2.75;
	ir.size.height = icon.frame.size.height * 2.75;
	header.icon.frame = ir;

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

		header.city.hidden = true;
		header.description.hidden = false;
		header.description.text = description;
	}
	else
	{
		NSString* city = [weather objectForKey:@"city"];
		NSRange r = [city rangeOfString:@","];
		if (r.location != NSNotFound)
			city = [city substringToIndex:r.location];

		header.city.hidden = false;
		header.description.hidden = true;
		header.city.text = city;
	}

	if (NSArray* forecast = [weather objectForKey:@"forecast"])
	{
		if (forecast.count > 0)
		{
			NSDictionary* today = [forecast objectAtIndex:0];
			header.high.text = [NSString stringWithFormat:@"H %d\u00B0", [[today objectForKey:@"high"] intValue]];
			header.low.text = [NSString stringWithFormat:@"L %d\u00B0", [[today objectForKey:@"low"] intValue]];
		}
	}

	header.temp.text = [NSString stringWithFormat:@"%d\u00B0", [[weather objectForKey:@"temp"] intValue]];
	
	[weather release];
	
	[header setNeedsLayout];
	[header setNeedsDisplay];
}

-(CGFloat) tableView:(UITableView*) tableView heightForHeaderInSection:(NSInteger) section
{
	return 96;
}

-(LWHeaderView*) createHeaderView
{
	return [[[LWHeaderView alloc] initWithFrame:CGRectMake(0, 0, 320, 96)] autorelease];
}

@end
