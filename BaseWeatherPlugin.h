#include "CalendarScrollView.h"

#define localize(str) \
        [self.plugin.bundle localizedStringForKey:str value:str table:nil]

#define Hook(cls, sel, imp) \
        _ ## imp = MSHookMessage($ ## cls, @selector(sel), &$ ## imp)

extern "C" UIImage *_UIImageWithName(NSString *);
extern "C" CFStringRef UIDateFormatStringForFormatType(CFStringRef type);

@interface LockHeaderView : UIView

@property (nonatomic, retain) NSString* dateFormat;
@property (nonatomic, retain) NSString* timeFormat;

@property BOOL showCalendar;

-(void) updateTime;

@end

@interface BaseWeatherPlugin : WeatherIconPlugin

@property (nonatomic, retain) LockHeaderView* headerView;
@property (nonatomic, retain) CalendarScrollView* calendarScrollView;

-(LockHeaderView*) createHeaderView;

@end
