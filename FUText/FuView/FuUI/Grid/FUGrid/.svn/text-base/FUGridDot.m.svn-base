//
//  FUGridPoint.m
//  LearnTest
//
//  Created by syq on 15/10/31.
//  Copyright © 2015年 com.chanjet. All rights reserved.
//

#import "FUGridDOt.h"

@implementation FUGridDot

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _dotFrame = CGRectZero;
    }
    return self;
}

- (BOOL)isInsideWithPoint:(CGPoint)point
{
    return CGRectContainsPoint(_dotFrame, point);
}

- (BOOL)isUpperLeftWithPoint:(CGPoint)point
{
    if ((point.x < _dotFrame.origin.x && point.y <= CGRectGetMaxY(_dotFrame)) || point.y <_dotFrame.origin.y)
    {
        return YES;
    }
    return NO;
}

- (BOOL)isBottomRightOfPoint:(CGPoint)point
{
    if ((point.x > CGRectGetMaxX(_dotFrame) && point.y >= _dotFrame.origin.y) || point.y > _dotFrame.origin.y)
    {
        return YES;
    }
    return NO;
}

- (BOOL)isEqualWithDot:(FUGridDot *)dot
{
    return CGRectEqualToRect(self.dotFrame, dot.dotFrame);
}

@end
