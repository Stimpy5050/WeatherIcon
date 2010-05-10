#include "WeatherIconPlugin.h"
#include <SpringBoard/SBAwayDateView.h>
#include <SpringBoard/SBStatusBarController.h>
#include <SpringBoard/SBStatusBarTimeView.h>
#include <UIKit/UIKit.h>
#include <substrate.h>

#define localize(str) \
        [self.plugin.bundle localizedStringForKey:str value:str table:nil]

#define Hook(cls, sel, imp) \
        _ ## imp = MSHookMessage($ ## cls, @selector(sel), &$ ## imp)

extern "C" UIImage *_UIImageWithName(NSString *);
extern "C" CFStringRef UIDateFormatStringForFormatType(CFStringRef type);

@interface CalendarView : UIView

@property BOOL showWeeks;
@property (nonatomic, retain) NSDate* date;
@property (nonatomic, retain) LIStyle* headerStyle;
@property (nonatomic, retain) LIStyle* dayStyle;
@property (nonatomic, retain) UIImage* marker;

@end

@interface NSDate (LICalendar)

-(NSDate*) lastMonth;
-(NSDate*) nextMonth;

@end

@interface CalendarScrollView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, retain) CalendarView* lastMonth;
@property (nonatomic, retain) CalendarView* currentMonth;
@property (nonatomic, retain) CalendarView* nextMonth;

@end

@interface LWHeaderView : UIView

@property (nonatomic, retain) UIImageView* background;
@property (nonatomic, retain) UIImageView* icon;
@property (nonatomic, retain) UILabel* description;
@property (nonatomic, retain) UILabel* city;
@property (nonatomic, retain) UILabel* temp;
@property (nonatomic, retain) UILabel* high;
@property (nonatomic, retain) UILabel* low;

@property (nonatomic, retain) UILabel* time;
@property (nonatomic, retain) UILabel* date;

@property (nonatomic, retain) NSString* dateFormat;
@property (nonatomic, retain) NSString* timeFormat;

@property BOOL showCalendar;

-(void) updateTime;

@end

@interface LockWeatherPlugin : WeatherIconPlugin

@property (nonatomic, retain) LWHeaderView* headerView;

-(LWHeaderView*) createHeaderView;

@end
