#include <substrate.h>
#include <Foundation/Foundation.h>
#include <JSON/JSON.h>
#include "WeatherIconController.h"

@interface WeatherIconPlugin : NSObject
{
	double lastUpdate;
}

@property (nonatomic, retain) NSDictionary* preferences;

@end

@implementation WeatherIconPlugin

@synthesize preferences;

-(NSTimeInterval) refreshInterval
{
	return 1;
}

-(NSString*) json
{
	NSString* prefsPath = @"/User/Library/Preferences/com.ashman.WeatherIcon.plist";
	NSFileManager* fm = [NSFileManager defaultManager];
	if (NSDictionary* attrs = [fm fileAttributesAtPath:prefsPath traversLink:true])
		if (NSDate* modDate = [attrs objectForKey:NSFileModificationDate])
			if ([modDate timeIntervalSinceReferenceDate] <= lastUpdate)
				return nil;

	NSDictionary* wiPrefs = [NSDictionary dictionaryWithContentsOfFile:prefsPath];
	NSDictionary* current = [wiPrefs objectForKey:@"CurrentCondition"];

	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:1];

	if (current != nil)
		[dict setObject:[wiPrefs objectForKey:@"CurrentCondition"] forKey:@"weather"];

	[dict setObject:self.preferences forKey:@"preferences"];
	NSString* json = [dict JSONRepresentation];
	NSLog(@"WI: Returning JSON: %@", json);
	lastUpdate = [NSDate timeIntervalSinceReferenceDate];
	return json;
}

@end
