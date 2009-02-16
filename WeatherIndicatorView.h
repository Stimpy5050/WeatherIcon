#import "WeatherIconModel.h"
#import <UIKit/UIView.h>

@interface WeatherIndicatorView : UIView
{
	WeatherIconModel* _model;
}

- (id) initWithModel:(WeatherIconModel*) model;
- (void) drawRect:(struct CGRect) rect;
- (void) dealloc;

@end
