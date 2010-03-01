#include "WeatherIconPlugin.h"

@interface CalendarView : UIView

@property (nonatomic, retain) LIStyle* headerStyle;
@property (nonatomic, retain) LIStyle* dayStyle;
@property (nonatomic, retain) UIImage* marker;

@end

@interface WIHeaderView : UIView

@property (nonatomic, retain) UIImageView* icon;
@property (nonatomic, retain) UILabel* city;
@property (nonatomic, retain) UILabel* temp;
@property (nonatomic, retain) UILabel* high;
@property (nonatomic, retain) UILabel* low;

@property (nonatomic, retain) UILabel* time;
@property (nonatomic, retain) UILabel* date;

-(void) updateTime;

@end

@interface LockWeatherPlugin : WeatherIconPlugin
@end

extern BOOL showCalendar;
extern CalendarView* calendarView;
