//
//  FUDotMatrix.m
//  LearnTest
//
//  Created by syq on 15/10/31.
//  Copyright © 2015年 com.chanjet. All rights reserved.
//

#import "FUDotMatrix.h"

@implementation FUDotMatrix

- (FUGridDot *)findDotWithPoint:(CGPoint)point
{
    NSInteger min = 0;
    NSInteger max = _dotArray.count - 1;
    while (min <= max)
    {
        NSInteger mid = min + (max - min)/2;
        FUGridDot *dot = [_dotArray objectAtIndex:mid];
        if ([dot isInsideWithPoint:point])
        {
            return dot;
        } else if ([dot isUpperLeftWithPoint:point])
        {
            max = mid - 1;
        } else
        {
            min = mid + 1;
        }
    }
    return nil;
}

@end
