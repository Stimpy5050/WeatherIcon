#include <Foundation/NSDictionary.h>
#include <UIKit/UIColor.h>
#include <UIKit/UIFont.h>
#include <UIKit/UITableView.h>
#include <UIKit/UIView.h>
#include <UIKit/UILabel.h>

static NSString* LIUndimScreenNotification = @"com.ashman.LockInfo.screenUndimmed";
static NSString* LITimerNotification = @"com.ashman.LockInfo.timerFired";
static NSString* LIUpdateViewNotification = @"com.ashman.LockInfo.updateView";
static NSString* LIViewReadyNotification = @"com.ashman.LockInfo.viewReady";
static NSString* LIManualRefreshNotification = @".refreshRequested";
static NSString* LIPrefsUpdatedNotification = @".prefsUpdated";
static NSString* LIBadgeChangedNotification = @".badgeChanged";
static NSString* LIApplicationDeactivatedNotification = @".applicationDeactivated";

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

@property (nonatomic, retain) id<UITableViewDelegate> tableViewDelegate;
@property (nonatomic, retain) id<UITableViewDataSource> tableViewDataSource;

- (BOOL) enabled;
- (BOOL) native;
- (NSString*) bundleIdentifier;
- (NSBundle*) bundle;
- (NSDictionary*) preferences;
- (NSDictionary*) globalPreferences;
- (NSArray*) managedBundles;

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
        UILabel* label;
}

@property (nonatomic, retain) LIStyle* style;
@property (nonatomic, retain) NSString* text;
@property (nonatomic) UITextAlignment textAlignment;
@property (nonatomic) UILineBreakMode lineBreakMode;
@property (nonatomic) NSInteger numberOfLines;

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
}

@property (nonatomic, readonly) LITheme* theme;

-(BOOL) isCollapsed:(int) section;
-(BOOL) toggleSection:(int) section;

-(void) reloadPlugin:(LIPlugin*) plugin;

-(LITimeView*) timeViewWithFrame:(CGRect) frame;
-(LILabel*) labelWithFrame:(CGRect) frame;

-(UIImage*) sectionSubheader;

- (CGFloat)defaultHeightForHeader;
- (CGFloat)defaultHeightForRow;

@end

@protocol LITableViewDataSource <UITableViewDataSource>

@optional
-(NSInteger) tableView:(LITableView*)tableView numberOfItemsInSection:(NSInteger)section;
-(NSInteger) tableView:(LITableView*)tableView totalNumberOfItemsInSection:(NSInteger)section;

@end

@protocol LITableViewDelegate <UITableViewDelegate>

@optional
-(NSString*) tableView:(LITableView*) tableView detailForHeaderInSection:(NSInteger) section;
-(UIImageView*) tableView:(LITableView*) tableView iconForHeaderInSection:(NSInteger) section;

@end

@protocol LIPluginController <NSObject>

-(id) initWithPlugin:(LIPlugin*) plugin;

@end
