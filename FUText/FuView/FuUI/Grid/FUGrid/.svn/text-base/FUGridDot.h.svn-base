//
//  FUGridPoint.h
//  LearnTest
//
//  Created by syq on 15/10/31.
//  Copyright © 2015年 com.chanjet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FUGridDot : NSObject

@property (nonatomic) CGRect dotFrame;
@property (nonatomic, strong) UIView *dotView;
@property (nonatomic, strong) NSDictionary *userInfo;

- (BOOL)isInsideWithPoint:(CGPoint)point;    // 内部
- (BOOL)isUpperLeftWithPoint:(CGPoint)point; // 左上
- (BOOL)isBottomRightOfPoint:(CGPoint)point; // 右下
- (BOOL)isEqualWithDot:(FUGridDot *)dot;

@end
