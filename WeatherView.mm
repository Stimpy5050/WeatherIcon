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
#import <SpringBoard/SleepProofTimer.h>
#import <UIKit/UIStringDrawing.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <Foundation/NSObjCRuntime.h>

@implementation WeatherView

@synthesize isCelsius;
@synthesize overrideLocation;
@synthesize location;
@synthesize temp;
@synthesize code;
@synthesize refreshInterval;
@synthesize nextRefreshTime;
@synthesize lastUpdateTime;
@synthesize tempStyle;

+ (NSDictionary*) preferences
{
	NSBundle* bundle = [NSBundle mainBundle];
	NSString* settingsPath = [bundle pathForResource:@"com.ashman.WeatherIcon" ofType:@"plist"];
	NSLog(@"WI: Settings: %@", settingsPath);
	if (settingsPath)
	{
		NSDictionary* dict = [[NSDictionary alloc] initWithContentsOfFile:settingsPath];
		[dict autorelease];
		return dict;
	}

	return nil;
}

- (void) _parseWeatherPreferences
{
	NSString* prefsPath = @"/User/Library/Preferences/com.apple.weather.plist";
	NSDictionary* dict = [[NSDictionary alloc] initWithContentsOfFile:prefsPath];
	[dict autorelease];

	if (dict)
	{
		self.isCelsius = [[dict objectForKey:@"Celsius"] boolValue];

		NSNumber* activeCity = [dict objectForKey:@"ActiveCity"];
		NSArray* cities = [dict objectForKey:@"Cities"];
		NSDictionary* city = [cities objectAtIndex:0];
		self.location = [[city objectForKey:@"Zip"] substringToIndex:8];
	}
}

- (id) initWithIcon:(SBApplicationIcon*)icon
{
        CGRect rect = CGRectMake(0, 0, icon.frame.size.width, icon.frame.size.height);
        id ret = [self initWithFrame:rect];

	self.temp = @"?";
	self.code = @"3200";
	self.isCelsius = false;
	self.overrideLocation = false;
	self.refreshInterval = 900;
	self.opaque = NO;
	self.userInteractionEnabled = NO;

	NSDictionary* dict = [WeatherView preferences];
	if (dict)
	{
		if (NSNumber* ol = [dict objectForKey:@"OverrideLocation"])
			self.overrideLocation = [ol boolValue];
		NSLog(@"WI: Location: %@", self.location);

		if (self.overrideLocation)
		{
			if (NSString* loc = [dict objectForKey:@"Location"])
				self.location = [[NSString alloc] initWithString:loc];

			if (NSNumber* celsius = [dict objectForKey:@"Celsius"])
				self.isCelsius = [celsius boolValue];
		}
		else
		{
			[self _parseWeatherPreferences];
		}

		NSLog(@"WI: Location: %@", self.location);
		NSLog(@"WI: Celsius: %@", (self.isCelsius ? @"YES" : @"NO"));

		if (NSString* style = [dict objectForKey:@"TempStyle"])
			self.tempStyle = [[NSString alloc] initWithString:style];

		if (NSNumber* interval = [dict objectForKey:@"RefreshInterval"])
			self.refreshInterval = ([interval intValue] * 60);
		NSLog(@"WI: Refresh Interval: %d seconds", self.refreshInterval);
	}	
	
        _icon = icon;

	_image = [[UIImageView alloc] initWithFrame:CGRectMake((rect.size.width - 35) / 2, 4, 35, 35)];
	[self addSubview:_image];

	self.nextRefreshTime = [NSDate date];

/*
	_locationManager = [[[CLLocationManager alloc] init] autorelease];
	_locationManager.delegate = self; // Tells the location manager to send updates to this object
	_locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
	[_locationManager startUpdatingLocation];
	NSLog(@"WI: Location: %@", _locationManager.location);
*/

	return ret;
}

- (void) drawRect:(CGRect) rect
{
	NSString* t = [self.temp stringByAppendingString: @"\u00B0"];

        NSString* tempStyle(@""
               	"font-family: Helvetica; "
	        "font-weight: bold; "
	        "font-size: 13px; "
	        "color: white; "
	        "margin-top: 38px; "
		"margin-left: 3px; "
	        "width: 59px; "
		"text-align: center; "
		"text-shadow: rgba(0, 0, 0, 0.4) -1px -1px 2px; "
	"");

	if (self.tempStyle)
		tempStyle = [tempStyle stringByAppendingString:self.tempStyle];
	
	[t drawAtPoint:CGPointMake(0, 0) withStyle:tempStyle];
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

//		if (self.lastUpdateTime)
//			[self.lastUpdateTime release];

		self.lastUpdateTime = [[NSDate alloc] init];
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
	NSDate* now = [NSDate date];
//	NSLog(@"WI: Checking refresh dates: %@ vs %@", now, self.nextRefreshTime);

	// are we ready for an update?
	if ([now compare:self.nextRefreshTime] == NSOrderedAscending)
	{
//		NSLog(@"WI: No refresh yet.");
		return;
	}

	[NSThread detachNewThreadSelector:@selector(_refresh) toTarget:self withObject:nil];
}

- (void) _refresh
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	// reparse the preferences
	if (!self.overrideLocation)
		[self _parseWeatherPreferences];

	if (!self.location)
	{
		NSLog(@"WI: No location set.");
		return;
	}

	NSLog(@"WI: Refreshing weather for %@...", self.location);
	NSString* urlStr = [NSString stringWithFormat:@"http://weather.yahooapis.com/forecastrss?p=%@&u=%@", self.location, (self.isCelsius ? @"c" : @"f")];
	NSURL* url = [NSURL URLWithString:urlStr];
	NSXMLParser* parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
	[parser setDelegate:self];
	[parser parse];
	[parser release];

	NSLog(@"WI: Did the update succeed? %@ vs %@", self.lastUpdateTime, self.nextRefreshTime);
	if (!self.lastUpdateTime || [self.lastUpdateTime compare:self.nextRefreshTime] == NSOrderedAscending)
	{
		NSLog(@"WI: Update failed.");
		return;
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
		UIImage* weatherIcon = [UIImage imageWithContentsOfFile:iconPath];
		UIImage* appIcon = [_icon icon];

		if (weatherIcon.size.width == appIcon.size.width && weatherIcon.size.height == appIcon.size.height)
			_image = weatherIcon;
		else
		{
			CGImageRef imageRef = [weatherIcon CGImage];
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
	}
	else
	{
		_image.image = nil;
	}

	[_image setNeedsDisplay];
	[self setNeedsDisplay];

//	if (self.nextRefreshTime)
//		[self.nextRefreshTime release];
	
	self.nextRefreshTime = [[NSDate alloc] initWithTimeIntervalSinceNow:self.refreshInterval];
	NSLog(@"WI: Next refresh time: %@", self.nextRefreshTime);

	[pool release];
}

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
	NSLog(@"WI: New location: %@", newLocation);
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
	NSLog(@"WI: Location Error: %@", error);
}
@end
