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
	UILabel *_temp;
}

@property(nonatomic) BOOL isCelsius;
@property(nonatomic) NSString* location;
@property(nonatomic) NSString* temp;
@property(nonatomic) NSString* code;

- (id)initWithIcon:(SBApplicationIcon*)icon;
- (void)refresh;
- (void)drawRect:(CGRect)rect;

@end
