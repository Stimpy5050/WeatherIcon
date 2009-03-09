#import "WeatherIconSettings.h"
#import <Foundation/Foundation.h>

@implementation WeatherIconSettings

- (NSArray*) specifiers
{
	return [self loadSpecifiersFromPlistName:@"Weather Icon" target:self];
}

- (void) donate:(id) param
{
	NSLog(@"WI:Donate!");
}

@end
