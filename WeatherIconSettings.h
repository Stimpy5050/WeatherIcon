#import <Preferences/PSListController.h>
#import <Foundation/Foundation.h>

@interface WeatherIconSettings : PSListController
{
	PSSpecifier* location;
	PSSpecifier* unit;
}

-(NSArray*) specifiers;
-(void)donate:(id) param;
-(void)showOverride:(id) value specifier:(id) specifier;
-(void)viewDidBecomeVisible;

@end
