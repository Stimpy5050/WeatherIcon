/*
 *  ReflectiveDock.mm
 *  
 *
 *  Created by David Ashman on 1/12/09.
 *  Copyright 2009 David Ashman. All rights reserved.
 *
 */

#import "WeatherView.h"
#import <substrate.h>
#import <SpringBoard/SBApplicationIcon.h>
#import <UIKit/UIStringDrawing.h>
#import <UIKit/UIKit.h>

@implementation WeatherView

@synthesize isCelsius;
@synthesize location;
@synthesize temp;
@synthesize code;

- (id) initWithIcon:(SBApplicationIcon*)icon
{
        CGRect rect = CGRectMake(0, 0, icon.frame.size.width, icon.frame.size.height);
        id ret = [self initWithFrame:rect];

	self.temp = @"?";
	self.code = @"3200";
	self.isCelsius = false;

	NSBundle* bundle = [NSBundle mainBundle];
	NSString* settingsPath = [bundle pathForResource:@"com.ashman.WeatherIcon" ofType:@"plist"];
	NSLog(@"WI: Settings: %@", settingsPath);
	if (settingsPath)
	{
		NSDictionary* dict = [[NSDictionary alloc] initWithContentsOfFile:settingsPath];
		[dict autorelease];

		if (NSString* loc = [dict objectForKey:@"Location"])
			self.location = [[NSString alloc] initWithString:loc];
		NSLog(@"WI: Location: %@", self.location);

		if (NSNumber* celsius = [dict objectForKey:@"Celsius"])
			self.isCelsius = [celsius boolValue];
		NSLog(@"WI: Celsius: %@", (self.isCelsius ? @"YES" : @"NO"));
	}	
	
        _icon = icon;

	_image = [[UIImageView alloc] initWithFrame:CGRectMake((rect.size.width - 35) / 2, 4, 35, 35)];
	[self addSubview:_image];
	
	// refresh the weather info
	[self refresh];

	return ret;
}


- (void) drawRect:(CGRect) rect
{
        NSString* tempStyle(@""
               	"font-family: Helvetica; "
	        "font-weight: bold; "
	        "font-size: 14px; "
	        "color: white; "
		"text-shadow: rgba(0, 0, 0, 0.2) -1px -1px 2px; "
	"");

//        NSLog(@"WI: Rendering temp %@", self.temp);
        float viewWidth([self bounds].size.width);
//        float leeway(10);
//        CGSize tempSize = [self.temp sizeWithFont:[UIFont systemFontOfSize:14]];
	float width = [self.temp length] * 8;
	NSLog(@"WI: Size? %@", width);
	NSString* t = [self.temp stringByAppendingString:@"\u00B0"];
	[t drawAtPoint:CGPointMake((viewWidth + 1 - width) / 2, 38) withStyle:tempStyle];
//        NSLog(@"WI: Rendered temp.");
}

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
namespaceURI:(NSString *)namespaceURI
qualifiedName:(NSString *)qName
   attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"yweather:condition"])
	{
		self.temp = [[NSString alloc] initWithString:[attributeDict objectForKey:@"temp"]];
		NSLog(@"WI: Temp: %@", self.temp);
		self.code = [[NSString alloc] initWithString:[attributeDict objectForKey:@"code"]];
		NSLog(@"WI: Code: %@", self.code);
	}
}

- (void)parser:(NSXMLParser *)parser
didEndElement:(NSString *)elementName
namespaceURI:(NSString *)namespaceURI
qualifiedName:(NSString *)qName
{
}


- (void)parser:(NSXMLParser *)parser
foundCharacters:(NSString *)string
{   
}

- (void) refresh
{
	NSLog(@"WI: Refreshing weather...");
	if (self.location)
	{
		NSString* urlStr = [NSString stringWithFormat:@"http://weather.yahooapis.com/forecastrss?p=%@&u=%@", self.location, (self.isCelsius ? @"c" : @"f")];
		NSURL* url = [NSURL URLWithString:urlStr];
		NSXMLParser* parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
		[parser setDelegate:self];
		[parser parse];
		[parser release];
	}

	if (!self.temp)
		self.temp = @"?";

	if (!self.code)
		self.code = @"3200";

	NSBundle* sb = [NSBundle mainBundle];
	NSString* iconName = [@"weather" stringByAppendingString:self.code];
	NSString* iconPath = [sb pathForResource:iconName ofType:@"png"];
	if (iconPath)
	{
		UIImage* icon = [UIImage imageWithContentsOfFile:iconPath];
		CGImageRef imageRef = [icon CGImage];
		CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
		CGRect iconRect = CGRectMake(0, 0, 35, 35);
	
	// There's a wierdness with kCGImageAlphaNone and CGBitmapContextCreate
	// see Supported Pixel Formats in the Quartz 2D Programming Guide
	// Creating a Bitmap Graphics Context section
	// only RGB 8 bit images with alpha of kCGImageAlphaNoneSkipFirst, kCGImageAlphaNoneSkipLast, kCGImageAlphaPremultipliedFirst,
	// and kCGImageAlphaPremultipliedLast, with a few other oddball image kinds are supported
	// The images on input here are likely to be png or jpeg files
		if (alphaInfo == kCGImageAlphaNone)
			alphaInfo = kCGImageAlphaNoneSkipLast;

		// Build a bitmap context that's the size of the thumbRect
		CGContextRef bitmap = CGBitmapContextCreate(
				NULL,
				iconRect.size.width,		// width
				iconRect.size.height,		// height
				CGImageGetBitsPerComponent(imageRef),	// really needs to always be 8
				4 * iconRect.size.width,	// rowbytes
				CGImageGetColorSpace(imageRef),
				alphaInfo
		);

		// Draw into the context, this scales the image
		CGContextDrawImage(bitmap, iconRect, imageRef);

		// Get an image from the context and a UIImage
		CGImageRef ref = CGBitmapContextCreateImage(bitmap);
		UIImage* result = [UIImage imageWithCGImage:ref];

		CGContextRelease(bitmap);	// ok if NULL
		CGImageRelease(ref);
		_image.image = result;
	}
	else
	{
		_image.image = nil;
	}

	[_temp setText:self.temp];

	[_image setNeedsDisplay];
	[_temp setNeedsDisplay];
	[self setNeedsDisplay];
}

@end
