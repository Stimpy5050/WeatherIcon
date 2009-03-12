#include <objc/runtime.h>
#import "WeatherIconSettings.h"
#import "WeatherIconController.h"
#import <Foundation/Foundation.h>
#import <SpringBoard/SBUIController.h>
#import <UIKit/UIApplication.h>

@implementation WeatherIconSettings

- (BOOL)popControllerWithAnimation:(BOOL)animation
{
	[location release];
	[unit release];
	[customBundleIdentifier release];
	return [super popControllerWithAnimation:animation];
}

- (void) customBundleIdentifier:(id) value specifier:(id) specifier
{
	[self setPreferenceValue:value specifier:specifier];

	if ([value isEqualToString:@"Custom"])
		[self insertSpecifier:customBundleIdentifier afterSpecifierID:@"WeatherBundleIdentifier" animated:YES];
	else
		[self removeSpecifier:customBundleIdentifier animated:YES];
}

- (void) showOverride:(id) value specifier:(id) specifier
{
	[self setPreferenceValue:value specifier:specifier];

	NSArray* overrideSpecs = [NSArray arrayWithObjects:location, unit, nil];
	if ([value boolValue])
	{
		[self insertContiguousSpecifiers:overrideSpecs afterSpecifierID:@"OverrideLocation" animated:YES];
	}
	else
	{
		[self removeContiguousSpecifiers:overrideSpecs animated:YES];
	}
}

- (void) viewWillBecomeVisible:(id) specifier
{
	[super viewWillBecomeVisible:specifier];

	location = [[self specifierForID:@"Location"] retain];
	unit = [[self specifierForID:@"Celsius"] retain];
	customBundleIdentifier = [[self specifierForID:@"CustomWeatherBundleIdentifier"] retain];

	PSSpecifier* override = [self specifierForID:@"OverrideLocation"];
	id value = [self readPreferenceValue:override];
	if (![value boolValue])
	{
		NSArray* overrideSpecs = [NSArray arrayWithObjects:location, unit, nil];
		[self removeContiguousSpecifiers:overrideSpecs animated:YES];
	}

	PSSpecifier* bundle = [self specifierForID:@"WeatherBundleIdentifier"];
	value = [self readPreferenceValue:bundle];
	if (!value || ![value isEqualToString:@"Custom"])
		[self removeSpecifier:customBundleIdentifier animated:YES];
}

- (NSArray*) specifiers
{
	return [self loadSpecifiersFromPlistName:@"Weather Icon" target:self];
}

- (void) donate:(id) param
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=3324856"]];
}

@end
