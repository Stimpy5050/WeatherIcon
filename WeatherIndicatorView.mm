#import "WeatherIndicatorView.h"
#import <UIKit/UIKit.h>

@implementation WeatherIndicatorView

- (id) initWithModel:(WeatherIconModel*) model
{
	_model = [model retain];

	CGSize tempSize = CGSizeMake(0, 0);
	if (_model.showStatusBarTemp)
	{
		NSString* temp = [(_model.showFeelsLike ? _model.windChill : _model.temp) stringByAppendingString: @"\u00B0"];
		UIFont* font = [UIFont boldSystemFontOfSize:13];
		tempSize = [temp sizeWithFont:font];
	}

	CGSize imageSize = CGSizeMake(0, 0);
	if (_model.showStatusBarImage && _model.statusBarImage)
	{	
		imageSize = CGSizeMake(16, 16);
	}

	self = [super initWithFrame:CGRectMake(0, 0, tempSize.width + imageSize.width, 20)];
	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];

	return self;
}

- (void) drawRect:(struct CGRect) rect
{
	CGSize tempSize = CGSizeMake(0, 0);

	if (_model.showStatusBarTemp)
	{
		NSString* temp = [(_model.showFeelsLike ? _model.windChill : _model.temp) stringByAppendingString: @"\u00B0"];

		UIFont* font = [UIFont boldSystemFontOfSize:13];
		tempSize = [temp sizeWithFont:font];

		CGContextRef ctx = UIGraphicsGetCurrentContext();
		UIView* parent = [self superview];
		float f = ([parent effectiveModeForImages] == 0 ? 0.2 : 1);
		CGContextSetRGBFillColor(ctx, f, f, f, 1);
		[temp drawAtPoint:CGPointMake(0, 1) withFont:font];
	}

	if (_model.showStatusBarImage)
	{
		UIImage* image = [_model statusBarImage];
		[image drawInRect:CGRectMake(tempSize.width, 1, 16, 16)];
	}
}

- (void) dealloc
{
	[_model release];
	[super dealloc];
}

@end
