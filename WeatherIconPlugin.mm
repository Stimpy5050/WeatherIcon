#include <substrate.h>
#include <Foundation/Foundation.h>
#include <JSON/JSON.h>
#include "WeatherIconController.h"

@interface WeatherIconPlugin : NSObject

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
	NSDictionary* wiPrefs = [NSDictionary dictionaryWithContentsOfFile:@"/User/Library/Preferences/com.ashman.WeatherIcon.plist"];
	NSDictionary* current = [wiPrefs objectForKey:@"CurrentCondition"];

	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:1];

	if (current != nil)
		[dict setObject:[wiPrefs objectForKey:@"CurrentCondition"] forKey:@"weather"];

	[dict setObject:self.preferences forKey:@"preferences"];
	NSString* json = [dict JSONRepresentation];
	NSLog(@"WI: Returning JSON: %@", json);
	return json;
}

@end
