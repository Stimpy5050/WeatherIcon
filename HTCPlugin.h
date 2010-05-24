#include "LockWeatherPlugin.h"
#include <Preferences/PSListController.h>

@interface autoScaleText : NSObject

-(UIFont*) fontToFitText:(NSString*)text withFont:(UIFont*)font withMaxWidth:(CGFloat)maxWidth withMaxHeight:(CGFloat)maxHeight withMinSize:(int)minSize withMaxSize:(int)maxSize allowMoreLines:(BOOL)moreLines;		

@end

@interface imageCacheController : NSObject

@property (nonatomic, retain) NSMutableDictionary* imageCache;

-(void) initCache;
-(UIImage*) getDigit:(int)digit;
-(UIImage*) getBackground:(int)background;

@end

@interface HTCSettingsController : PSListController
@end

@interface LockWeatherPlugin (ExtendLW)
@end

@interface HTCHeaderView : UIView

@property (nonatomic, retain) UIImageView* icon;
@property (nonatomic, retain) UILabel* city;
@property (nonatomic, retain) UILabel* description;
@property (nonatomic, retain) UILabel* temp;
@property (nonatomic, retain) UILabel* high;
@property (nonatomic, retain) UILabel* low;

@property (nonatomic, retain) NSNumber* hourNumber;
@property (nonatomic, retain) NSNumber* minuteNumber;
@property (nonatomic, retain) UIImageView* hoursUnits;
@property (nonatomic, retain) UIImageView* minutesUnits;
@property (nonatomic, retain) UIImageView* hoursTens;
@property (nonatomic, retain) UIImageView* minutesTens;
@property (nonatomic, retain) UILabel* date;

-(void) updateTimeHTC;

@end

@interface HTCPlugin : LockWeatherPlugin 
@end

