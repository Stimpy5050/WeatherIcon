#include <Foundation/NSDictionary.h>
#include <UIKit/UIColor.h>
#include <UIKit/UIFont.h>
#include <UIKit/UITableView.h>
#include <UIKit/UIView.h>
#include <UIKit/UILabel.h>

static double SECONDS_PER_DAY = 86400;

static BOOL isSameWeek(NSDate* date1, NSDate* date2)
{
        NSCalendar* cal = [NSCalendar currentCalendar];
        int mask = (NSWeekCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit);
        NSDateComponents* comps1 = [cal components:mask fromDate:date1];
        NSDateComponents* comps2 = [cal components:mask fromDate:date2];
        return (comps1.week == comps2.week && comps1.month == comps2.month && comps1.year == comps2.year);
}

static BOOL isSameDay(NSDate* date1, NSDate* date2)
{
        NSCalendar* cal = [NSCalendar currentCalendar];
        int mask = (NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit);
        NSDateComponents* comps1 = [cal components:mask fromDate:date1];
        NSDateComponents* comps2 = [cal components:mask fromDate:date2];
        return (comps1.day == comps2.day && comps1.month == comps2.month && comps1.year == comps2.year);
}

static BOOL isThisWeek(NSDate* date)
{
        return isSameWeek(date, [NSDate date]);
}

static BOOL isToday(NSDate* date)
{
        return isSameDay(date, [NSDate date]);
}

static BOOL isTomorrow(NSDate* date)
{
        return isSameDay(date, [NSDate dateWithTimeIntervalSinceNow:SECONDS_PER_DAY]);
}

@interface LIPlugin : NSObject

- (NSString*) bundleIdentifier;
- (id) lock;
- (NSDictionary*) preferences;
- (void) updateView:(NSDictionary*) data;

@end

@interface LIStyle : NSObject <NSCopying>

@property (nonatomic, retain) UIColor* textColor;
@property (nonatomic, retain) UIFont* font;
@property (nonatomic, retain) UIColor* shadowColor;
@property (nonatomic) CGSize shadowOffset;

@end

@interface LITheme : NSObject

@property (nonatomic, retain) LIStyle* headerStyle;
@property (nonatomic, retain) LIStyle* summaryStyle;
@property (nonatomic, retain) LIStyle* detailStyle;

@end

@interface LILabel : UIView
{
	LIStyle* style;
	NSString* text;
	UITextAlignment textAlignment;
}

@property (nonatomic, retain) LIStyle* style;
@property (nonatomic, retain) NSString* text;
@property (nonatomic) UITextAlignment textAlignment;

@end

@interface LITimeView : UIView
{
	BOOL is24Hour;
	NSDate* date;
	NSString* text;
}

@property (nonatomic) BOOL relative;
@property (nonatomic, retain) NSString* text;
@property (nonatomic, retain) NSDate* date;

-(BOOL) is24Hour;

@end

@interface LITableView : UITableView <UITableViewDataSource, UITableViewDelegate>
{
        NSMutableArray* sections;
        NSMutableDictionary* collapsed;
}

@property (nonatomic, retain) LITheme* theme;

-(BOOL) isCollapsed:(int) section;
-(BOOL) toggleSection:(int) section;

-(void) reloadPlugin:(LIPlugin*) plugin;

-(void) setProperties:(UILabel*) label summary:(BOOL) summary;

-(LITimeView*) timeViewWithFrame:(CGRect) frame;
-(LILabel*) labelWithFrame:(CGRect) frame;

@end

@protocol LITableViewDataSource <UITableViewDataSource>

@optional
-(UIImage*) tableView:(LITableView*) tableView iconForHeaderInSection:(NSInteger) section;

@end

@protocol LIPluginDelegate <NSObject>

-(void) loadDataForPlugin:(LIPlugin*) plugin;

@end
