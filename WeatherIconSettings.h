#import <Preferences/PSListController.h>
#import <Foundation/Foundation.h>

@interface WeatherIconSettings : PSListController
{
	PSSpecifier* location;
	PSSpecifier* unit;
	PSSpecifier* bundleIdentifier;
	PSSpecifier* customBundleIdentifier;
	PSSpecifier* weatherIconSeparator;
	PSSpecifier* weatherIconText;
}

-(NSArray*) specifiers;
-(void)donate:(id) param;
-(void)showWeatherIcon:(id) value specifier:(id) specifier;
-(void)showOverride:(id) value specifier:(id) specifier;
-(void)customBundleIdentifier:(id) value specifier:(id) specifier;

@end
