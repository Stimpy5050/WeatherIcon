#include "BaseWeatherPlugin.h"

@interface LWHeaderView : LockHeaderView

@property (nonatomic, retain) UIImageView* background;
@property (nonatomic, retain) UIImageView* icon;
@property (nonatomic, retain) UILabel* description;
@property (nonatomic, retain) UILabel* city;
@property (nonatomic, retain) UILabel* temp;
@property (nonatomic, retain) UILabel* high;
@property (nonatomic, retain) UILabel* low;

@property (nonatomic, retain) UILabel* time;
@property (nonatomic, retain) UILabel* date;

@end

@interface LockWeatherPlugin : BaseWeatherPlugin

@end
