#import "Plugin.h"
#include "Constants.h"
#include <Foundation/Foundation.h>

@interface WIForecastView : UIView

@property (nonatomic, retain) LITheme* theme;
@property (nonatomic, retain) NSArray* forecast;
@property (nonatomic, retain) NSArray* icons;
@property (nonatomic, retain) NSMutableDictionary* pluginTheme;
@property (nonatomic, retain) NSString* updatedString;
@property (nonatomic, retain) NSNumber* timestamp;

@end


@interface WeatherIconPlugin : UIViewController <LIPluginController, LITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) LIPlugin* plugin;
@property (nonatomic, retain) NSMutableDictionary* iconCache;
@property (nonatomic, retain) NSMutableDictionary* dataCache;
@property (nonatomic, retain) NSMutableDictionary* theme;
@property (nonatomic, retain) WIForecastView* forecastView;

@property (retain) NSCondition* reloadCondition;
@property (retain) NSLock* updateLock;

-(void) updateWeatherViews;

@end
