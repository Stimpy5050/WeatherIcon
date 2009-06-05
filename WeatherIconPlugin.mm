#include <substrate.h>
#include <Foundation/Foundation.h>
#include <JSON/JSON.h>
#include "WeatherIconController.h"
#include "PluginDelegate.h"

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
	NSString* prefsPath = @"/User/Library/Preferences/com.ashman.WeatherIcon.plist";
	NSFileManager* fm = [NSFileManager defaultManager];
	if (NSDictionary* attrs = [fm fileAttributesAtPath:prefsPath traverseLink:true])
		if (NSDate* modDate = [attrs objectForKey:NSFileModificationDate])
			if ([modDate timeIntervalSinceReferenceDate] <= lastUpdate)
				return nil;

	NSDictionary* wiPrefs = [NSDictionary dictionaryWithContentsOfFile:prefsPath];
	NSDictionary* current = [wiPrefs objectForKey:@"CurrentCondition"];

	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:1];

	if (current != nil)
		[dict setObject:[wiPrefs objectForKey:@"CurrentCondition"] forKey:@"weather"];

	[dict setObject:self.preferences forKey:@"preferences"];
	lastUpdate = [NSDate timeIntervalSinceReferenceDate];
	return dict;
}

@end
