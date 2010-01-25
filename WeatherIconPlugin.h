#include "Plugin.h"
#include <Foundation/Foundation.h>

@interface WIForecastView : UIView

@property (nonatomic, retain) LITheme* theme;
@property (nonatomic, retain) NSArray* forecast;

@end

@interface WIForecastDaysView : WIForecastView
@end

@interface WIForecastIconView : WIForecastView

@property (nonatomic, retain) NSArray* icons;

@end

@interface WIForecastTempView : WIForecastView

@property (nonatomic, retain) NSString* updatedString;
@property (nonatomic, retain) NSNumber* timestamp;

@end


@interface WeatherIconPlugin : NSObject <LIPluginController, LITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) LIPlugin* plugin;
@property (nonatomic, retain) NSMutableDictionary* iconCache;
@property (nonatomic, retain) NSMutableDictionary* dataCache;

@property (nonatomic, retain) WIForecastDaysView* daysView;
@property (nonatomic, retain) WIForecastIconView* iconView;
@property (nonatomic, retain) WIForecastTempView* tempView;

@end
