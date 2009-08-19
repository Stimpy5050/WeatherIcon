#include <Foundation/Foundation.h>

@protocol PluginDelegate 
-(void) setPreferences:(NSDictionary*) preferences;
-(NSDictionary*) data;
@end

static NSString* prefsPath = @"/User/Library/Preferences/com.ashman.WeatherIcon.Condition.plist";

@interface WeatherIconPlugin : NSObject <PluginDelegate>
{
	double lastUpdate;
}

@property (nonatomic, retain) NSDictionary* preferences;

@end

@implementation WeatherIconPlugin

@synthesize preferences;

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

	return dict;
}

@end
