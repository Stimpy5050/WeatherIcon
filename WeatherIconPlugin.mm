#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

static NSArray* dayNames = [[NSArray arrayWithObjects:@"SUN", @"MON", @"TUE", @"WED", @"THU", @"FRI", @"SAT", nil] retain];

@protocol PluginDelegate 
-(void) setPreferences:(NSDictionary*) preferences;
-(NSDictionary*) data;
@end

static NSString* prefsPath = @"/User/Library/Preferences/com.ashman.WeatherIcon.Condition.plist";

@interface CurrentCell : UITableViewCell
@property (nonatomic, retain) UIImageView* icon;
@property (nonatomic, retain) UILabel* temp;
@property (nonatomic, retain) UILabel* condition;
@end

@implementation CurrentCell

@synthesize icon, temp, condition;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
        self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier];
        self.backgroundColor = [UIColor blackColor];
        self.textColor = [UIColor whiteColor];
        self.hidesAccessoryWhenEditing = YES;

        self.icon = [[UIImageView alloc]init];
        self.icon.backgroundColor = [UIColor blackColor];

        self.temp = [[UILabel alloc]init];
        self.temp.textAlignment = UITextAlignmentLeft;
        self.temp.textColor = [UIColor whiteColor];
        self.temp.font = [UIFont boldSystemFontOfSize:13];
        self.temp.backgroundColor = [UIColor blackColor];

        self.condition = [[UILabel alloc]init];
        self.condition.textAlignment = UITextAlignmentLeft;
        self.condition.textColor = [UIColor lightGrayColor];
        self.condition.font = [UIFont boldSystemFontOfSize:11];
        self.condition.backgroundColor = [UIColor blackColor];

        [self.contentView addSubview:self.icon];
        [self.contentView addSubview:self.temp];
        [self.contentView addSubview:self.condition];

        return self;
}

-(void) layoutSubviews
{
        [super layoutSubviews];

        CGRect contentRect = self.contentView.bounds;
        self.icon.frame = CGRectMake(0, 0, 35, 35);
        self.temp.frame = CGRectMake(35 , 0, contentRect.size.width - 35, 18);
        self.condition.frame = CGRectMake(35 , 17, contentRect.size.width - 35, 13);
}

@end

@interface ForecastView : UIView

@property (nonatomic, retain) UILabel* day;
@property (nonatomic, retain) UILabel* high;
@property (nonatomic, retain) UILabel* low;

@end

@implementation ForecastView

@synthesize high, low, day;

- (id) init
{
	self = [super initWithFrame:CGRectMake(0, 0, 60, 35)];
        self.backgroundColor = [UIColor blackColor];

        self.day = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 11)];
        self.day.textAlignment = UITextAlignmentCenter;
        self.day.textColor = [UIColor whiteColor];
        self.day.font = [UIFont boldSystemFontOfSize:11];
        self.day.backgroundColor = [UIColor blackColor];

        self.high = [[UILabel alloc] initWithFrame:CGRectMake(0, 14, 29, 12)];
        self.high.textAlignment = UITextAlignmentRight;
        self.high.textColor = [UIColor whiteColor];
        self.high.font = [UIFont boldSystemFontOfSize:12];
        self.high.backgroundColor = [UIColor blackColor];

        self.low = [[UILabel alloc] initWithFrame:CGRectMake(31, 14, 30, 12)];
        self.low.textAlignment = UITextAlignmentLeft;
        self.low.textColor = [UIColor lightGrayColor];
        self.low.font = [UIFont boldSystemFontOfSize:12];
        self.low.backgroundColor = [UIColor blackColor];

	[self addSubview:self.day];
	[self addSubview:self.low];
	[self addSubview:self.high];

	return self;
}

@end

@interface ForecastIconCell : UITableViewCell

@property (nonatomic, retain) NSMutableArray* icons;

@end

@implementation ForecastIconCell

@synthesize icons;

- (id) initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
        self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier];
        self.backgroundColor = [UIColor lightGrayColor];
        self.textColor = [UIColor whiteColor];
        self.hidesAccessoryWhenEditing = YES;

	self.icons = [NSMutableArray arrayWithCapacity:5];

	for (int i = 0; i < 5; i++)
	{
        	UIImageView* v = [[UIImageView alloc] init];
	        v.backgroundColor = [UIColor blackColor];
		[self.icons addObject:v];
		[self.contentView addSubview:v];
	}

        return self;
}

-(void) layoutSubviews
{
        [super layoutSubviews];

        CGRect contentRect = self.contentView.bounds;
	int width = ((contentRect.size.width - 20) / 5);

	for (int i = 0; i < 5; i++)
	{
		UIImageView* v = [self.icons objectAtIndex:i];
		v.frame = CGRectMake(23 + (width * i), 0, 34, 34);
	}
}

@end

@interface ForecastTempCell : UITableViewCell

@property (nonatomic, retain) NSMutableArray* temps;

@end

@implementation ForecastTempCell

@synthesize temps;

- (id) initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
        self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier];
        self.backgroundColor = [UIColor whiteColor];
        self.textColor = [UIColor whiteColor];
        self.hidesAccessoryWhenEditing = YES;

	self.temps = [NSMutableArray arrayWithCapacity:5];

	for (int i = 0; i < 5; i++)
	{
        	ForecastView* v = [[ForecastView alloc] init];
		[self.temps addObject:v];
		[self.contentView addSubview:v];
	}

        return self;
}

-(void) layoutSubviews
{
        [super layoutSubviews];

        CGRect contentRect = self.contentView.bounds;
	int width = ((contentRect.size.width - 20) / 5);

	for (int i = 0; i < 5; i++)
	{
		ForecastView* v = [self.temps objectAtIndex:i];
		v.frame = CGRectMake(10 + (width * i), 0, 34, 34);
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
	switch (indexPath.row)
	{
/*
		case 0:
        		CurrentCell *current = [tableView dequeueReusableCellWithIdentifier:@"CurrentCell"];

		        if (current == nil)
		                current = [[[CurrentCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"CurrentCell"] autorelease];

       			current.temp.text = [NSString stringWithFormat:@"%@: %@\u00B0", [weather objectForKey:@"city"], [weather objectForKey:@"temp"]];;
			current.condition.text = [weather objectForKey:@"description"];
			current.icon.image = [self loadIcon:[weather objectForKey:@"icon"]];
	
			return current;
*/
		case 0:
        		ForecastIconCell *fc = [tableView dequeueReusableCellWithIdentifier:@"ForecastIconCell"];

		        if (fc == nil)
		                fc = [[[ForecastIconCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"ForecastIconCell"] autorelease];

			for (int i = 0; i < forecast.count && i < 5; i++)
			{
				NSDictionary* day = [forecast objectAtIndex:i];
				UIImageView* v = [fc.icons objectAtIndex:i];
				v.image = [self loadIcon:[day objectForKey:@"icon"]];
			}

			return fc;
		default:
        		ForecastTempCell *ft = [tableView dequeueReusableCellWithIdentifier:@"ForecastTempCell"];

		        if (ft == nil)
		                ft = [[[ForecastTempCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"ForecastTempCell"] autorelease];

			for (int i = 0; i < forecast.count && i < 5; i++)
			{
				NSDictionary* day = [forecast objectAtIndex:i];
				ForecastView* v = [ft.temps objectAtIndex:i];
				NSNumber* daycode = [day objectForKey:@"daycode"];
				v.day.text = [dayNames objectAtIndex:daycode.intValue];
				v.high.text = [NSString stringWithFormat:@" %@\u00B0", [day objectForKey:@"high"]];
				v.low.text = [NSString stringWithFormat:@" %@\u00B0", [day objectForKey:@"low"]];
			}

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
