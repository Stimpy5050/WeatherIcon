#include <objc/runtime.h>
#import "WeatherIconSettings.h"
#import <Foundation/Foundation.h>
#import <SpringBoard/SBUIController.h>
#import <UIKit/UIApplication.h>

static NSString* CUSTOM = @"Custom";

@implementation WeatherIconSettings

- (void)dealloc
{
	NSLog(@"WI:Debug: Dealloc");
	[location release];
	[unit release];
	[bundleIdentifier release];
	[customBundleIdentifier release];
	[weatherIconSeparator release];
	[weatherIconText release];
	[super dealloc];
}

- (void) showWeatherIcon:(id) value specifier:(id) specifier
{
	[self setPreferenceValue:value specifier:specifier];
	
	NSLog(@"WI:Debug: showWeatherIcon");

	id custom = [self readPreferenceValue:bundleIdentifier];
	NSArray* bundleSpecs;
	if ([custom isEqualToString:CUSTOM])
		bundleSpecs = [NSArray arrayWithObjects:bundleIdentifier, customBundleIdentifier, weatherIconSeparator, weatherIconText, nil];
	else
		bundleSpecs = [NSArray arrayWithObjects:bundleIdentifier, weatherIconSeparator, weatherIconText, nil];

	if ([value boolValue])
		[self insertContiguousSpecifiers:bundleSpecs afterSpecifierID:@"ShowWeatherIcon" animated:YES];
	else
		[self removeContiguousSpecifiers:bundleSpecs animated:YES];
}

- (void) customBundleIdentifier:(id) value specifier:(id) specifier
{
	[self setPreferenceValue:value specifier:specifier];
	NSLog(@"WI:Debug: custom %@", customBundleIdentifier);

	if ([value isEqualToString:CUSTOM])
		[self insertSpecifier:customBundleIdentifier afterSpecifierID:@"WeatherBundleIdentifier" animated:YES];
	else
		[self removeSpecifier:customBundleIdentifier animated:YES];
}

- (void) showOverride:(id) value specifier:(id) specifier
{
	[self setPreferenceValue:value specifier:specifier];
	
	NSLog(@"WI:Debug: showOverride %@, %@", location, unit);
	NSArray* overrideSpecs = [NSArray arrayWithObjects:location, unit, nil];
	if ([value boolValue])
		[self insertContiguousSpecifiers:overrideSpecs afterSpecifierID:@"OverrideLocation" animated:YES];
	else
		[self removeContiguousSpecifiers:overrideSpecs animated:YES];
}

- (void) viewWillBecomeVisible:(id) specifier
{
	[super viewWillBecomeVisible:specifier];

	location = [[self specifierForID:@"Location"] retain];
	unit = [[self specifierForID:@"Celsius"] retain];
	NSLog(@"WI:Debug: %@, %@", location, unit);
	PSSpecifier* override = [self specifierForID:@"OverrideLocation"];
	id value = [self readPreferenceValue:override];
	if (![value boolValue])
	{
		NSArray* overrideSpecs = [NSArray arrayWithObjects:location, unit, nil];
		NSLog(@"WI:Debug: Removing %@", overrideSpecs);
		[self removeContiguousSpecifiers:overrideSpecs animated:YES];
	}

	bundleIdentifier = [[self specifierForID:@"WeatherBundleIdentifier"] retain];
	customBundleIdentifier = [[self specifierForID:@"CustomWeatherBundleIdentifier"] retain];
	weatherIconSeparator = [[self specifierForID:@"WeatherIconSeparator"] retain];
	weatherIconText = [[self specifierForID:@"WeatherIconText"] retain];

	NSLog(@"WI:Debug: Checking icon");
	PSSpecifier* icon = [self specifierForID:@"ShowWeatherIcon"];
	value = [self readPreferenceValue:icon];
	if (![value boolValue])
	{
		NSArray* bundleSpecs = [NSArray arrayWithObjects:bundleIdentifier, customBundleIdentifier, weatherIconSeparator, weatherIconText, nil];
		NSLog(@"WI:Debug: Removing %@", bundleSpecs);
		[self removeContiguousSpecifiers:bundleSpecs animated:YES];
	}
	else
	{
		NSLog(@"WI:Debug: Checking custom");
		PSSpecifier* bundle = [self specifierForID:@"WeatherBundleIdentifier"];
		value = [self readPreferenceValue:bundle];
		if (![value isEqualToString:CUSTOM])
		{
			NSLog(@"WI:Debug: Removing custom");
			[self removeSpecifier:customBundleIdentifier animated:YES];
		}
	}

	NSLog(@"WI:Debug: Done with init");
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
