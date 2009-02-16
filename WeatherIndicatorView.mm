#import "WeatherIndicatorView.h"
#import <UIKit/UIKit.h>

@implementation WeatherIndicatorView

- (id) initWithModel:(WeatherIconModel*) model
{
	_model = [model retain];

	NSString* temp = [(_model.showFeelsLike ? _model.windChill : _model.temp) stringByAppendingString: @"\u00B0"];
	UIFont* font = [UIFont boldSystemFontOfSize:13];
	CGSize size = [temp sizeWithFont:font];

	self = [super initWithFrame:CGRectMake(0, 0, size.width + 16, 20)];
	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];

	return self;
}

- (void) drawRect:(struct CGRect) rect
{
	NSString* temp = [(_model.showFeelsLike ? _model.windChill : _model.temp) stringByAppendingString: @"\u00B0"];
	UIImage* image = [_model statusBarImage];

	UIFont* font = [UIFont boldSystemFontOfSize:13];
	CGSize size = [temp sizeWithFont:font];

	CGContextRef ctx = UIGraphicsGetCurrentContext();
	UIView* parent = [self superview];
	float f = ([parent effectiveModeForImages] == 0 ? 0.2 : 1);
	CGContextSetRGBFillColor(ctx, f, f, f, 1);
	[temp drawAtPoint:CGPointMake(0, 1) withFont:font];

	[image drawInRect:CGRectMake(size.width, 1, 16, 16)];
}

- (void) dealloc
{
	[_model release];
	[super dealloc];
}

@end
