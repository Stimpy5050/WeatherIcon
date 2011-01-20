#include "WeatherIconPlugin.h"
#include <UIKit/UIKit.h>
#include <substrate.h>

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

@interface CalendarScrollView : UIView <UIScrollViewDelegate>

@property (nonatomic, retain) UIButton* jumpButton;
@property (nonatomic, retain) UIScrollView* scrollView;

@property (nonatomic, retain) CalendarView* lastMonth;
@property (nonatomic, retain) CalendarView* currentMonth;
@property (nonatomic, retain) CalendarView* nextMonth;

-(id) initWithFrame:(CGRect) frame marker:(UIImage*) marker jump:(UIImage*) jump;

-(void) setTheme:(LITheme*) theme;
-(void) showWeeks:(BOOL) weeks;
-(void) setDate:(NSDate*) date;

@end
