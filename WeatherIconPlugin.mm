#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

static NSArray* dayNames = [[NSArray arrayWithObjects:@"SUN", @"MON", @"TUE", @"WED", @"THU", @"FRI", @"SAT", nil] retain];

@protocol PluginDelegate 
-(void) setPreferences:(NSDictionary*) preferences;
-(NSDictionary*) data;
@end

static NSString* prefsPath = @"/User/Library/Preferences/com.ashman.WeatherIcon.Condition.plist";

@interface ForecastView : UIView

@property (nonatomic, retain) NSArray* icons;
@property (nonatomic, retain) NSArray* forecast;

@end

@implementation ForecastView

@synthesize forecast, icons;

-(void) drawRect:(struct CGRect) rect
{
	NSLog(@"LI:WeatherIcon: Redrawing temps...");
	int width = (rect.size.width / 6);

	for (int i = 0; i < self.forecast.count && i < 6; i++)
	{
		NSDictionary* day = [self.forecast objectAtIndex:i];
		
		NSNumber* daycode = [day objectForKey:@"daycode"];
		NSString* str = [dayNames objectAtIndex:daycode.intValue];
        	CGRect r = CGRectMake(rect.origin.x + (width * i), rect.origin.y + 4, width, 11);
		[[UIColor whiteColor] set];
		[str drawInRect:r withFont:[UIFont boldSystemFontOfSize:11] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];

		UIImage* image = [self.icons objectAtIndex:i];
		r = CGRectMake(rect.origin.x + ((width - 40) / 2) + (width * i), r.origin.y + r.size.height - 1, 40, 40);
		[image drawInRect:r];

		str = [NSString stringWithFormat:@" %@\u00B0", [day objectForKey:@"high"]];
        	r = CGRectMake(rect.origin.x + (width * i), r.origin.y + r.size.height - 1, width, 12);
		[[UIColor whiteColor] set];
		[str drawInRect:r withFont:[UIFont boldSystemFontOfSize:12] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];

		str = [NSString stringWithFormat:@" %@\u00B0", [day objectForKey:@"low"]];
        	r = CGRectMake(rect.origin.x + (width * i), r.origin.y + r.size.height + 2, width, 12);
		[[UIColor lightGrayColor] set];
		[str drawInRect:r withFont:[UIFont boldSystemFontOfSize:12] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
	}
}

@end

@interface HeaderView : UIView

@property (nonatomic, retain) UIImage* icon;
@property (nonatomic, retain) NSString* city;
@property (nonatomic) int temp;
@property (nonatomic, retain) NSString* condition;

@end

@implementation HeaderView

@synthesize icon, city, temp, condition;

-(void) drawRect:(struct CGRect) rect
{
	NSLog(@"LI:WeatherIcon: Drawing section header");

        [self.icon drawInRect:CGRectMake(0, 0, 23, 23)];

	NSString* city = self.city;
	NSRange r = [city rangeOfString:@","];
	if (r.location != NSNotFound)
		city = [city substringToIndex:r.location];

        NSString* str = [NSString stringWithFormat:@"%@: %d\u00B0", city, self.temp];
        [[UIColor blackColor] set];
	[str drawInRect:CGRectMake(23, 3, 137, 22) withFont:[UIFont boldSystemFontOfSize:14] lineBreakMode:UILineBreakModeClip];
        [[UIColor lightGrayColor] set];
	[str drawInRect:CGRectMake(23, 2, 137, 22) withFont:[UIFont boldSystemFontOfSize:14] lineBreakMode:UILineBreakModeClip];

        [[UIColor blackColor] set];
	[self.condition drawInRect:CGRectMake(165, 4, 150, 21) withFont:[UIFont boldSystemFontOfSize:12] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];
        [[UIColor lightGrayColor] set];
	[self.condition drawInRect:CGRectMake(165, 3, 150, 21) withFont:[UIFont boldSystemFontOfSize:12] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];
}

@end

@interface WeatherIconPlugin : NSObject <PluginDelegate, UITableViewDataSource>
{
	double lastUpdate;
}

@property (nonatomic, retain) NSMutableDictionary* iconCache;
@property (nonatomic, retain) NSDictionary* dataCache;
@property (nonatomic, retain) NSDictionary* preferences;

@end

@implementation WeatherIconPlugin

@synthesize preferences, dataCache, iconCache;

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
        return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	HeaderView* v = [[[HeaderView alloc] initWithFrame:CGRectMake(0, 0, 320, 23)] autorelease];
	v.backgroundColor = [UIColor clearColor];

	NSDictionary* weather = [self.dataCache objectForKey:@"weather"];
	v.icon = [self loadIcon:[weather objectForKey:@"icon"]];
	v.city = [weather objectForKey:@"city"];
	v.temp = [[weather objectForKey:@"temp"] intValue];
	v.condition = [weather objectForKey:@"description"];

	return v;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 85;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary* weather = [self.dataCache objectForKey:@"weather"];
	NSArray* forecast = [weather objectForKey:@"forecast"];
        	
	UITableViewCell *fc = [tableView dequeueReusableCellWithIdentifier:@"ForecastCell"];

	if (fc == nil)
	{
		fc = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"ForecastCell"] autorelease];
		fc.backgroundColor = [UIColor clearColor];
		
		ForecastView* fcv = [[[ForecastView alloc] initWithFrame:CGRectMake(10, 0, 300, 85)] autorelease];
		fcv.backgroundColor = [UIColor clearColor];
		fcv.tag = 42;
		[fc.contentView addSubview:fcv];
	}

	ForecastView* fcv = [fc viewWithTag:42];
	fcv.forecast = [forecast copy];

	NSMutableArray* arr = [NSMutableArray arrayWithCapacity:6];
	for (int i = 0; i < forecast.count && i < 6; i++)
	{
		NSDictionary* day = [forecast objectAtIndex:i];
		[arr addObject:[self loadIcon:[day objectForKey:@"icon"]]];
	}
	fcv.icons = arr;

	return fc;
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

	return dict;
}

@end
