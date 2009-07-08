#include <Foundation/Foundation.h>
#include "WeatherIconController.h"

@protocol PluginDelegate 
-(void) setPreferences:(NSDictionary*) preferences;
-(NSDictionary*) data;
@end

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
	NSString* prefsPath = @"/User/Library/Preferences/com.ashman.WeatherIcon.Condition.plist";
	NSFileManager* fm = [NSFileManager defaultManager];
	if (NSDictionary* attrs = [fm fileAttributesAtPath:prefsPath traverseLink:true])
		if (NSDate* modDate = [attrs objectForKey:NSFileModificationDate])
			if ([modDate timeIntervalSinceReferenceDate] <= lastUpdate)
				return nil;

	NSDictionary* current = [NSDictionary dictionaryWithContentsOfFile:prefsPath];
	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:1];

	if (current != nil)
		[dict setObject:current forKey:@"weather"];

	[dict setObject:self.preferences forKey:@"preferences"];
	lastUpdate = [NSDate timeIntervalSinceReferenceDate];

//	NSLog(@"WI: LockInfo: %@", dict);
	return dict;
}

@end
