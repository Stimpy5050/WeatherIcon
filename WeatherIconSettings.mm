#include <objc/runtime.h>
#import "WeatherIconSettings.h"
#import "WeatherIconController.h"
#import <Foundation/Foundation.h>
#import <SpringBoard/SBUIController.h>
#import <UIKit/UIApplication.h>

@implementation WeatherIconSettings

- (NSArray*) specifiers
{
	return [self loadSpecifiersFromPlistName:@"Weather Icon" target:self];
}

- (void) donate:(id) param
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=3324856"]];
}

@end
