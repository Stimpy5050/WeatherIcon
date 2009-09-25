#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

static NSArray* dayNames = [[NSArray arrayWithObjects:@"SUN", @"MON", @"TUE", @"WED", @"THU", @"FRI", @"SAT", nil] retain];

@protocol PluginDelegate 
-(void) setPreferences:(NSDictionary*) preferences;
-(NSDictionary*) data;
@end

static NSString* prefsPath = @"/User/Library/Preferences/com.ashman.WeatherIcon.Condition.plist";

@interface ForecastTempView : UIView

@property (nonatomic, retain) NSArray* forecast;

@end

@implementation ForecastTempView

@synthesize forecast;

-(void) drawRect:(struct CGRect) rect
{
	NSLog(@"LI:WeatherIcon: Redrawing temps...");
	int width = (rect.size.width / 5);

	for (int i = 0; i < self.forecast.count && i < 5; i++)
	{
		NSDictionary* day = [self.forecast objectAtIndex:i];
		
		NSNumber* daycode = [day objectForKey:@"daycode"];
		NSString* str = [dayNames objectAtIndex:daycode.intValue];
        	CGRect r = CGRectMake(rect.origin.x + (width * i), rect.origin.y, 60, 11);
		[[UIColor whiteColor] set];
		[str drawInRect:r withFont:[UIFont boldSystemFontOfSize:11] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];

		str = [NSString stringWithFormat:@" %@\u00B0", [day objectForKey:@"high"]];
        	r = CGRectMake(rect.origin.x + (width * i), rect.origin.y + 14, 29, 12);
		[[UIColor whiteColor] set];
		[str drawInRect:r withFont:[UIFont boldSystemFontOfSize:12] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];

		str = [NSString stringWithFormat:@" %@\u00B0", [day objectForKey:@"low"]];
        	r = CGRectMake(rect.origin.x + (width * i) + 31, rect.origin.y + 14, 29, 12);
		[[UIColor lightGrayColor] set];
		[str drawInRect:r withFont:[UIFont boldSystemFontOfSize:12] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentLeft];
	}
}

@end

@interface ForecastIconView : UIView

@property (nonatomic, retain) NSArray* icons;

@end

@implementation ForecastIconView

@synthesize icons;

-(void) drawRect:(struct CGRect) rect
{
	NSLog(@"LI:WeatherIcon: Redrawing icons...");
	int width = (rect.size.width / 5);

	for (int i = 0; i < self.icons.count && i < 5; i++)
	{
		UIImage* image = [self.icons objectAtIndex:i];
		CGRect frame = CGRectMake(rect.origin.x + 13 + (width * i), rect.origin.y, 34, 34);
		[image drawInRect:frame];
	}
}

@end

@interface WeatherIconPlugin : NSObject <PluginDelegate, UITableViewDataSource>
{
	double lastUpdate;
}

@property (nonatomic, retain) NSMutableDictionary* iconCache;
@property (nonatomic, retain) NSDictionary* dataCache;
@property (nonatomic, retain) NSDictionary* preferences;
@property (nonatomic, retain) UIView* sectionHeaderView;

@end

@implementation WeatherIconPlugin

@synthesize preferences, dataCache, iconCache, sectionHeaderView;

-(id) init
{
	self.iconCache = [NSMutableDictionary dictionaryWithCapacity:10];
	return [super init];
}

-(UIImage*) loadIcon:(NSString*) path
{
	UIImage* icon = [self.iconCache objectForKey:path];

	if (icon == nil)
	{
		icon = [UIImage imageWithContentsOfFile:path];
		[self.iconCache setValue:icon forKey:path];
	}

	return icon;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
        return 2;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	if (self.sectionHeaderView == nil)
	{
		NSLog(@"LI:WeatherIcon: Creating section header");
		UIView* c = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 23)] autorelease];
        	c.backgroundColor = [UIColor blackColor];

		NSDictionary* weather = [self.dataCache objectForKey:@"weather"];
       		UIImageView* ic = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 23, 23)] autorelease];
		ic.image = [self loadIcon:[weather objectForKey:@"icon"]];
		[c addSubview:ic];

	        UILabel* l = [[[UILabel alloc] initWithFrame:CGRectMake(ic.frame.size.width, 0, 170, 22)] autorelease];
	        l.font = [UIFont boldSystemFontOfSize:14];
	        l.textColor = [UIColor lightGrayColor];
	        l.shadowColor = [UIColor blackColor];
	        l.shadowOffset = CGSizeMake(0, 1);
	        l.backgroundColor = [UIColor clearColor];
	      	l.text = [NSString stringWithFormat:@"%@: %@\u00B0", [weather objectForKey:@"city"], [weather objectForKey:@"temp"]];;
	        [c addSubview:l];
	
	        l = [[[UILabel alloc] initWithFrame:CGRectMake(170, 0, 145, 21)] autorelease];
		l.textAlignment = UITextAlignmentRight;
	        l.font = [UIFont boldSystemFontOfSize:12];
	        l.textColor = [UIColor lightGrayColor];
	        l.shadowColor = [UIColor blackColor];
	        l.shadowOffset = CGSizeMake(0, 1);
	        l.backgroundColor = [UIColor clearColor];
		l.text = [weather objectForKey:@"description"];
	        [c addSubview:l];

		self.sectionHeaderView = c;
	}
	
        return self.sectionHeaderView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary* weather = [self.dataCache objectForKey:@"weather"];
	NSArray* forecast = [weather objectForKey:@"forecast"];
	if (indexPath.row == 0)
	{
        	UITableViewCell *fc = [tableView dequeueReusableCellWithIdentifier:@"ForecastIconCell"];

		if (fc == nil)
		{
			fc = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"ForecastIconCell"] autorelease];
			fc.backgroundColor = [UIColor blackColor];
				
			ForecastIconView* fcv = [[[ForecastIconView alloc] initWithFrame:CGRectMake(10, 0, 300, 35)] autorelease];
			fcv.backgroundColor = [UIColor blackColor];
			fcv.tag = 42;
			[fc.contentView addSubview:fcv];
		}

		ForecastIconView* fcv = [fc viewWithTag:42];
		NSMutableArray* arr = [NSMutableArray arrayWithCapacity:5];
		for (int i = 0; i < forecast.count && i < 5; i++)
		{
			NSDictionary* day = [forecast objectAtIndex:i];
			[arr addObject:[self loadIcon:[day objectForKey:@"icon"]]];
		}
		fcv.icons = arr;

		return fc;
	}
	else
	{
        	UITableViewCell *ft = [tableView dequeueReusableCellWithIdentifier:@"ForecastTempCell"];

		if (ft == nil)
		{
			ft = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"ForecastTempCell"] autorelease];

			ForecastTempView* ftv = [[[ForecastTempView alloc] initWithFrame:CGRectMake(10, 0, 300, 35)] autorelease];
			ftv.backgroundColor = [UIColor blackColor];
			ftv.tag = 42;
			[ft.contentView addSubview:ftv];
		}

		ForecastTempView* ftv = [ft viewWithTag:42];
		ftv.forecast = [forecast copy];

		return ft;
        }
}

-(NSDictionary*) data
{
	NSDate* modDate = nil;
	NSFileManager* fm = [NSFileManager defaultManager];
	if (NSDictionary* attrs = [fm fileAttributesAtPath:prefsPath traverseLink:true])
		if (modDate = [attrs objectForKey:NSFileModificationDate])
			if ([modDate timeIntervalSinceReferenceDate] <= lastUpdate)
				return nil;

	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:1];

	if (NSDictionary* current = [NSDictionary dictionaryWithContentsOfFile:prefsPath])
	{
		[dict setObject:current forKey:@"weather"];
		lastUpdate = (modDate == nil ? lastUpdate : [modDate timeIntervalSinceReferenceDate]);
	}

	[dict setObject:self.preferences forKey:@"preferences"];

	self.dataCache = dict;
	self.sectionHeaderView = nil;

	return dict;
}

@end
