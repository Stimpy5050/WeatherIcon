#include <objc/runtime.h>
#import "WeatherIconSettings.h"
#import <Foundation/Foundation.h>
#import <SpringBoard/SBUIController.h>
#import <UIKit/UIApplication.h>

@implementation WeatherIconSettings

- (void) donate:(id) param
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=3324856"]];
}

@end
