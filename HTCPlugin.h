#include "LockWeatherPlugin.h"
#include <Preferences/PSListController.h>

@interface utilTools : NSObject

-(UIFont*) fontToFitText:(NSString*)text withFont:(UIFont*)font inFrame:(CGRect)frame withMinSize:(int)minSize withMaxSize:(int)maxSize allowMoreLines:(BOOL)moreLines;		
-(UIColor*) colourToSetFromInt:(int)colourInt;
-(UIColor*) colourToSetFromRed:(CGFloat)Red andGreen:(CGFloat)Green andBlue:(CGFloat)Blue;

@end

@interface imageCacheController : NSObject

@property (nonatomic, retain) NSMutableDictionary* imageCache;

-(void) initCache;
-(UIImage*) getDigit:(int)digit;
-(UIImage*) getBackground:(int)background;

@end

@interface HTCSettingsController : PSListController
@end

@interface HTCClockView : UIView

-(id) initWithFrame:(CGRect)frame;

@property (nonatomic, retain) UIImageView* hoursUnits;
@property (nonatomic, retain) UIImageView* minutesUnits;
@property (nonatomic, retain) UIImageView* hoursTens;
@property (nonatomic, retain) UIImageView* minutesTens;

@end

@interface HTCTempView : UIView

-(id) initWithFrame:(CGRect)frame withTempColour:(int)tempTextColour withHighColour:(int)highTextColour withLowColour:(int)lowTextColour;

@property (nonatomic, retain) UILabel* temp;
@property (nonatomic, retain) UILabel* high;
@property (nonatomic, retain) UILabel* low;

@end

@interface HTCHeaderView : UIView

-(id) initWithPreferences:(NSDictionary*)preferences;

@property (nonatomic, retain) UIImageView* icon;
@property (nonatomic, retain) UIImageView* background;
@property (nonatomic, retain) UILabel* city;
@property (nonatomic, retain) UILabel* date;
@property (nonatomic, retain) UILabel* description;
@property (nonatomic, retain) HTCTempView* temp;
@property (nonatomic, retain) HTCClockView* clock;

@property (nonatomic, retain) NSNumber* hourNumber;
@property (nonatomic, retain) NSNumber* minuteNumber;

@property (nonatomic, retain) NSDictionary* viewPreferences;
@property (nonatomic, retain) NSString* dateFormat;
@property BOOL showCalendar;

-(void) updateTimeHTC;
-(void) updatePreferences:(NSDictionary*)preferences;

-(UIImageView*) iconViewToFitInFrame:(CGRect)frame;
-(UIImageView*) backgroundWithFrame:(CGRect)frame andBackgroundImage:(int)bgi;
-(UILabel*) dateViewToFitInFrame:(CGRect)frame withColour:(int)textColour;
-(UILabel*) cityViewToFitInFrame:(CGRect)frame withMaxSize:(int)maxSize usingTwoLines:(BOOL)twoLine withColour:(int)textColour;
-(UILabel*) descriptionViewToFitInFrame:(CGRect)frame withMaxSize:(int)maxSize usingTwoLines:(BOOL)twoLine withColour:(int)textColour;


@end

@interface HTCPlugin : LockWeatherPlugin 

@property (nonatomic, retain) HTCHeaderView* headerViewHTC;

-(HTCHeaderView*) createHTCHeaderView;

@end

