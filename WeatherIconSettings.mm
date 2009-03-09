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

- (void) setNeedsRefresh:(id) value specifier:(id) specifier
{
	[self setPreferenceValue:value specifier:specifier];

	Class cls2 = objc_getClass("SBUIController");
	SBUIController* ctlr2 = [cls2 sharedInstance];
	NSLog(@"WI:Debug: Controller: %@, %@", cls2, ctlr2);

	// force update
	Class cls = objc_getClass("WeatherIconController");
	WeatherIconController* ctlr = [cls sharedInstance];
	NSLog(@"WI: Setting refresh on ctlr %@ of type %@", ctlr, cls);
	[ctlr setNeedsRefresh];
}

- (void) donate:(id) param
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=3324856"]];
}

@end
