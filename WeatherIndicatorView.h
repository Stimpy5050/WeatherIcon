#import "WeatherIconModel.h"
#import <UIKit/UIView.h>

@interface WeatherIndicatorView : UIView
{
	WeatherIconModel* _model;
	UIImage* _image;
	NSString* _temp;
}

- (id) initWithModel:(WeatherIconModel*) model;
- (void) drawRect:(struct CGRect) rect;
- (void) dealloc;

@end
