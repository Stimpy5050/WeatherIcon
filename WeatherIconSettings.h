#import <Preferences/PSListController.h>
#import <Foundation/Foundation.h>

@interface WeatherIconSettings : PSListController
{
	PSSpecifier* location;
	PSSpecifier* unit;
	PSSpecifier* customBundleIdentifier;
}

-(NSArray*) specifiers;
-(void)donate:(id) param;
-(void)showOverride:(id) value specifier:(id) specifier;
-(void)customBundleIdentifier:(id) value specifier:(id) specifier;

@end
