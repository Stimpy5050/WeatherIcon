#import "WeatherIndicatorView.h"
#import <UIKit/UIKit.h>

@implementation WeatherIndicatorView

- (id) initWithModel:(WeatherIconModel*) model
{
	_model = model;
	NSString* temp = [(_model.showFeelsLike ? _model.windChill : _model.temp) stringByAppendingString: @"\u00B0"];
	UIImage* image = [_model weatherImage];

	UIFont* font = [UIFont boldSystemFontOfSize:13];
	CGSize size = [temp sizeWithFont:font];

	self = [super initWithFrame:CGRectMake(0, 0, size.width + 21, 20)];
	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];

	return self;
}

- (void) drawRect:(struct CGRect) rect
{
//	NSLog(@"WI: Draw indicator: %@, %@", _temp, _image);

	CGContextRef ctx = UIGraphicsGetCurrentContext();

	UIView* parent = [self superview];
	float f = ([parent effectiveModeForImages] == 0 ? 0.2 : 1);

	NSString* temp = [(_model.showFeelsLike ? _model.windChill : _model.temp) stringByAppendingString: @"\u00B0"];
	UIImage* image = [_model weatherImage];

	UIFont* font = [UIFont boldSystemFontOfSize:13];
	CGSize size = [temp sizeWithFont:font];

	CGContextSetRGBFillColor(ctx, f, f, f, 1);
	[temp drawAtPoint:CGPointMake(0, 1) withFont:font];

	[image drawInRect:CGRectMake(size.width + 1, 1, 16, 16)];
}

- (void) dealloc
{
	[super dealloc];
//	[_temp release];
//	[_image release];
}

@end
