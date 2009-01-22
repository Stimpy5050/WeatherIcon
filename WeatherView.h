/*
 *  ReflectionView.h
 *  
 *
 *  Created by David Ashman on 1/12/09.
 *  Copyright 2009 David Ashman. All rights reserved.
 *
 */

#import <SpringBoard/SBApplicationIcon.h>
#import <UIKit/UIKit.h>

@interface WeatherView : UIView
{
	SBApplicationIcon *_icon;
	UIImageView *_image;
}

@property(nonatomic) BOOL isCelsius;
@property(nonatomic retain) NSString* location;
@property(nonatomic retain) NSString* temp;
@property(nonatomic retain) NSString* code;
@property(nonatomic) int refreshInterval;
@property(nonatomic retain) NSDate* nextRefreshTime;
@property(nonatomic retain) NSDate* lastUpdateTime;

+ (NSDictionary*)preferences;
- (id)initWithIcon:(SBApplicationIcon*)icon;
- (void)refresh;
- (void)drawRect:(CGRect)rect;

@end
