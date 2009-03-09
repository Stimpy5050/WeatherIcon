#import <Preferences/PSListController.h>
#import <Foundation/Foundation.h>

@interface WeatherIconSettings : PSListController
{
}

-(NSArray*) specifiers;
-(void)setNeedsRefresh:(id) value specifier:(id) specifier;
-(void)donate:(id) param;

@end
