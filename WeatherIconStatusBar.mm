#import <substrate.h>
#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

extern "C" void UIGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale);

#define Hook(cls, sel, imp) \
        _ ## imp = MSHookMessage($ ## cls, @selector(sel), &$ ## imp)

Class $WIStatusBarCustomItemView;
BOOL hooked = NO;

UIImage* indicators[2];
NSDictionary* cachedCondition;

static NSDictionary* currentCondition()
{
	if (Class wi = objc_getClass("WeatherIconController"))
	{
		return [[wi sharedInstance] currentStatusBarCondition];
	}
	else
	{
		id dmc = [objc_getClass("CPDistributedMessagingCenter") centerNamed: @"com.ashman.WeatherIcon"];
		return [dmc sendMessageAndReceiveReplyName: @"currentStatusBarCondition" userInfo: nil];
	}
}

@interface UIScreen (WIAdditions)

-(double) scale;

@end
@interface UIImage (WIAdditions)
- (id)wi_initWithContentsOfResolutionIndependentFile:(NSString *)path;
+ (UIImage*)wi_imageWithContentsOfResolutionIndependentFile:(NSString *)path;
@end

@implementation UIImage (WIAdditions)

- (id)wi_initWithContentsOfResolutionIndependentFile:(NSString *)path
{
        double scale = ( [[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? (double)[[UIScreen mainScreen
] scale] : 1.0);
        if ( scale != 1.0)
        {
                NSString *path2x = [[path stringByDeletingLastPathComponent]
                        stringByAppendingPathComponent:[NSString stringWithFormat:@"%@@2x.%@",
                                [[path lastPathComponent] stringByDeletingPathExtension],
                                [path pathExtension]]];

                if ( [[NSFileManager defaultManager] fileExistsAtPath:path2x] )
                {
                        return [self initWithContentsOfFile:path2x];
                }
        }

        return [self initWithContentsOfFile:path];
}

+ (UIImage*) wi_imageWithContentsOfResolutionIndependentFile:(NSString *)path
{
        return [[[UIImage alloc] wi_initWithContentsOfResolutionIndependentFile:path] autorelease];
}

@end

void createIndicator(int index, NSDictionary* current)
{
	NSLog(@"WI: Creating indicator for style %d", index);
        NSString* temp = [current objectForKey:@"temp"];

	UIImage* image = nil;
        if (NSString* imgSrc = [current objectForKey:@"image"])
		image = [UIImage wi_imageWithContentsOfResolutionIndependentFile:imgSrc];

	CGSize imgSize = image.size;
        if (NSNumber* imgScale = [current objectForKey:@"imageScale"])
	{
		imgSize.width *= imgScale.doubleValue;
		imgSize.height *= imgScale.doubleValue;
	}

	UIFont* font = [UIFont boldSystemFontOfSize:13];
	CGSize tempSize = [temp sizeWithFont:font];

	CGSize size = CGSizeMake(0, 0);

	if (temp)
	{
		size = tempSize;
		size.height += 1;
	}

	if (image)
	{
		size.height = MAX(size.height, imgSize.height);
		size.width += imgSize.width;
	}

        if (UIGraphicsBeginImageContextWithOptions!=NULL)
                UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        else
                UIGraphicsBeginImageContext(size);

        if (temp)
        {
		if (index == 0)
		{
			[[[UIColor whiteColor] colorWithAlphaComponent:0.8] set];
	                [temp drawAtPoint:CGPointMake(0, 1) withFont:font];
		}

		float colorValue = 0.3 + (0.7 * index);
		[[UIColor colorWithRed:colorValue green:colorValue blue:colorValue alpha:1] set];
                [temp drawAtPoint:CGPointMake(0, 0) withFont:font];
        }

        if (image)
        {
                CGRect rect = CGRectMake(tempSize.width, 0, imgSize.width, imgSize.height);
                [image drawInRect:rect];
        }

	if (indicators[index])
		[indicators[index] release];

        indicators[index] = [UIGraphicsGetImageFromCurrentImageContext() retain];

        UIGraphicsEndImageContext();
}

void createIndicators()
{
	NSDictionary* current = currentCondition();

	if (cachedCondition && [current isEqualToDictionary:cachedCondition])
		return;

	createIndicator(0, current);
	createIndicator(1, current);

	NSDictionary* tmp = cachedCondition;
	cachedCondition = [current retain];
	[tmp release];
}

@interface UIStatusBar : UIView
@end

@interface UIStatusBarForegroundView : UIView
@end

@interface UIStatusBarItemView : UIView

-(float) updateContentsAndWidth;

@end

static void updateIndicator()
{
	// find the indicator view
	UIStatusBar* sb = [[UIApplication sharedApplication] statusBar];
	UIStatusBarForegroundView* fg = [sb.subviews objectAtIndex:1];
	for (UIStatusBarItemView* item in fg.subviews)
	{
		if ([item respondsToSelector:@selector(item)])
			if ([[[item item] indicatorName] isEqualToString:@"WeatherIcon"])
				[item updateContentsAndWidth];
	}
}

static void updateIndicators(CFNotificationCenterRef center, void* observer, CFStringRef name, void* object, CFDictionaryRef userInfo)
{
	updateIndicator();
}

MSHook(UIImage*, contentsImageForStyle, id self, SEL sel, int style)
//UIImage* wi_contentsImageForStyle(id self, SEL sel, int style)
{
	NSString* itemName = [[self item] indicatorName];
	if ([itemName isEqualToString:@"WeatherIcon"])
	{
	        int index = (style == 2 ? 1 : 0);
		createIndicators();
       		return indicators[index];
	}

	return _contentsImageForStyle(self, sel, style);
}

MSHook(id, viewClass, id self, SEL sel)
{
	if ([[self indicatorName] isEqualToString:@"WeatherIcon"])
		return $WIStatusBarCustomItemView;

	return _viewClass(self, sel);
}

MSHook(void, applicationResume, id self, SEL sel, id event)
{	
	_applicationResume(self, sel, event);
	if (currentCondition().count > 0)
	{
		NSLog(@"WI: Update indicator on resume");
		updateIndicator();
	}
}

static void createWIView()
{
	Class $UIStatusBarItemView = objc_getClass("UIStatusBarItemView");
	$WIStatusBarCustomItemView = objc_allocateClassPair($UIStatusBarItemView, "WIStatusBarCustomItemView", 0);
//	class_addMethod($WIStatusBarCustomItemView, @selector(contentsImageForStyle:), (IMP) wi_contentsImageForStyle, "@@:i");
	objc_registerClassPair($WIStatusBarCustomItemView);
}

MSHook(void, _startWindowServerIfNecessary, id self, SEL sel)
{
	__startWindowServerIfNecessary(self, sel);

	if (!hooked)
	{	
		NSLog(@"WI: Hooking class");
		Class $UIStatusBarCustomItemView = objc_getClass("UIStatusBarCustomItemView");
		Hook(UIStatusBarCustomItemView, contentsImageForStyle:, contentsImageForStyle);
		hooked = YES;
	}
}

extern "C" void WeatherIconStatusBarInit() 
{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
//	createWIView();

	Class $UIApplication = object_getClass(objc_getClass("UIApplication"));
	Hook(UIApplication, _startWindowServerIfNecessary, _startWindowServerIfNecessary);

	CFNotificationCenterRef darwin = CFNotificationCenterGetDarwinNotifyCenter();
	CFNotificationCenterAddObserver(darwin, NULL, (CFNotificationCallback) updateIndicators, (CFStringRef) @"weathericon_changed", NULL, NULL);
	CFNotificationCenterAddObserver(darwin, NULL, (CFNotificationCallback) updateIndicators, (CFStringRef) @"UIApplicationDidBecomeActiveNotification", NULL, NULL);

	[pool release];
}
