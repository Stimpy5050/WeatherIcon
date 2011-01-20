#import "BaseWeatherPlugin.h"
#import <Preferences/PSListController.h>

@interface utilTools : NSObject

-(UIFont*) fontToFitText:(NSString*)text withFont:(UIFont*)font inSize:(CGSize)size withMinSize:(int)minSize withMaxSize:(int)maxSize allowMoreLines:(BOOL)moreLines;		
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

@interface HTCHeaderView : LockHeaderView

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

-(void) updatePreferences:(NSDictionary*)preferences;
-(void) updateDigits;
-(void) updateColours;

@end

@interface HTCPlugin : BaseWeatherPlugin
@end

