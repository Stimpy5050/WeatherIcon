#include "LockWeatherPlugin.h"

@interface HTCHeaderView : UIView

@property (nonatomic, retain) UIImageView* icon;
@property (nonatomic, retain) UILabel* city;
@property (nonatomic, retain) UILabel* description;
@property (nonatomic, retain) UILabel* temp;
@property (nonatomic, retain) UILabel* high;
@property (nonatomic, retain) UILabel* low;

@property (nonatomic, retain) NSNumber* hourNumber;
@property (nonatomic, retain) NSNumber* minuteNumber;
@property (nonatomic, retain) UIImageView* hours;
@property (nonatomic, retain) UIImageView* minutes;
@property (nonatomic, retain) UILabel* date;

-(void) updateTimeHTC;

@end

@interface WIHeaderView (HTCUpdater)

-(void) updateTime;

@end

@interface HTCLockWeatherPlugin (HTCPlugin)
@end

