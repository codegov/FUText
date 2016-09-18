//
//  SETextSelectedMagnifier.h
//  Test
//
//  Created by syq on 14-5-29.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FuTextSelectedMagnifier : UIView


- (void)showInPoint:(CGPoint)point offY:(float)offY;
- (void)moveToPoint:(CGPoint)point offY:(float)offY;
- (void)hide;

@end
