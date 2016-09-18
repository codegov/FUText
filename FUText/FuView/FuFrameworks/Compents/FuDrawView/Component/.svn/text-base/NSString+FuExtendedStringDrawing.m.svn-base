//
//  NSString+FuExtendedStringDrawing.m
//  teamwork
//
//  Created by syq on 14/9/24.
//  Copyright (c) 2014年 chanjet. All rights reserved.
//

#import "NSString+FuExtendedStringDrawing.h"

@implementation NSString (FuExtendedStringDrawing)


// Single line, no wrapping. Truncation based on the NSLineBreakMode.
- (CGSize)sizeWithFontOfCompatible:(UIFont *)font
{
    return [self sizeWithFontOfCompatible:font constrainedToSize:CGSizeMake(MAXFLOAT, MAXFLOAT)];
}

- (CGSize)sizeWithFontOfCompatible:(UIFont *)font forWidth:(CGFloat)width lineBreakMode:(NSLineBreakMode)lineBreakMode
{
    return [self sizeWithFontOfCompatible:font constrainedToSize:CGSizeMake(width, MAXFLOAT) lineBreakMode:lineBreakMode];
}

// Single line, no wrapping. Truncation based on the NSLineBreakMode.
- (CGSize)drawAtPointOfCompatible:(CGPoint)point withFont:(UIFont *)font
{
    return [self drawAtPointOfCompatible:point forWidth:MAXFLOAT withFont:font lineBreakMode:NSLineBreakByWordWrapping];
}
- (CGSize)drawAtPointOfCompatible:(CGPoint)point forWidth:(CGFloat)width withFont:(UIFont *)font lineBreakMode:(NSLineBreakMode)lineBreakMode
{
    return [self drawAtPointOfCompatible:point forWidth:width withFont:font fontSize:font.pointSize lineBreakMode:lineBreakMode baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
}

- (CGSize)sizeWithFontOfCompatible:(UIFont *)font constrainedToSize:(CGSize)size
{
    return [self sizeWithFontOfCompatible:font constrainedToSize:size lineBreakMode:NSLineBreakByWordWrapping];
}

- (CGSize)sizeWithFontOfCompatible:(UIFont *)font constrainedToSize:(CGSize)size lineBreakMode:(NSLineBreakMode)lineBreakMode
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return [self sizeWithFont:font constrainedToSize:size lineBreakMode:lineBreakMode];
#pragma clang diagnostic pop
    }
    else
    {
        NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        textStyle.lineBreakMode = lineBreakMode;
        NSDictionary *dic = @{NSFontAttributeName:font, NSParagraphStyleAttributeName:textStyle};
        return [self boundingRectWithSize:size
                                  options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading // 文本绘制时的附加选项
                               attributes:dic
                                  context:nil].size;
    }
}

// Wrapping to fit horizontal and vertical size.
- (CGSize)drawInRectOfCompatible:(CGRect)rect withFont:(UIFont *)font
{
    return [self drawInRectOfCompatible:rect withFont:font lineBreakMode:NSLineBreakByWordWrapping];
}

- (CGSize)drawInRectOfCompatible:(CGRect)rect withFont:(UIFont *)font lineBreakMode:(NSLineBreakMode)lineBreakMode
{
    return [self drawInRectOfCompatible:rect withFont:font lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentLeft];
}

- (CGSize)drawInRectOfCompatible:(CGRect)rect withFont:(UIFont *)font lineBreakMode:(NSLineBreakMode)lineBreakMode alignment:(NSTextAlignment)alignment
{
#ifdef __IPHONE_7_0
    NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    textStyle.lineBreakMode = lineBreakMode;
    textStyle.alignment = alignment;
    NSDictionary *dic = @{NSFontAttributeName:font, NSParagraphStyleAttributeName:textStyle};
    if ([self respondsToSelector:@selector(drawInRect:withAttributes:)])
    {
        [self drawInRect:rect withAttributes:dic];
    }
    if ([self respondsToSelector:@selector(sizeWithAttributes:)])
    {
        return [self sizeWithAttributes:dic];
    } else
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return [self sizeWithFont:font constrainedToSize:rect.size lineBreakMode:lineBreakMode];
#pragma clang diagnostic pop
    }
#else
    return [self drawInRect:rect withFont:font lineBreakMode:lineBreakMode alignment:alignment];
#endif
}

- (CGSize)drawAtPointOfCompatible:(CGPoint)point forWidth:(CGFloat)width withFont:(UIFont *)font fontSize:(CGFloat)fontSize lineBreakMode:(NSLineBreakMode)lineBreakMode baselineAdjustment:(UIBaselineAdjustment)baselineAdjustment
{
    CGFloat actualFontSize;
    return [self drawAtPointOfCompatible:point forWidth:width withFont:font minFontSize:fontSize actualFontSize:&actualFontSize lineBreakMode:lineBreakMode baselineAdjustment:baselineAdjustment];
}

- (CGSize)drawAtPointOfCompatible:(CGPoint)point forWidth:(CGFloat)width withFont:(UIFont *)font minFontSize:(CGFloat)minFontSize actualFontSize:(CGFloat *)actualFontSize lineBreakMode:(NSLineBreakMode)lineBreakMode baselineAdjustment:(UIBaselineAdjustment)baselineAdjustment
{
    #ifdef __IPHONE_7_0
    NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    textStyle.lineBreakMode = lineBreakMode;
    textStyle.alignment = NSTextAlignmentLeft;
    NSDictionary *dic = @{NSFontAttributeName:font, NSParagraphStyleAttributeName:textStyle};
    if ([self respondsToSelector:@selector(drawInRect:withAttributes:)])
    {
        [self drawInRect:CGRectMake(point.x, point.y, width, minFontSize) withAttributes:dic];
    }
    if ([self respondsToSelector:@selector(sizeWithAttributes:)])
    {
        return [self sizeWithAttributes:dic];
    } else
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return [self sizeWithFont:font forWidth:width lineBreakMode:lineBreakMode];
#pragma clang diagnostic pop
    }
    #else
    return [self drawAtPoint:point forWidth:width withFont:font minFontSize:minFontSize actualFontSize:actualFontSize lineBreakMode:lineBreakMode baselineAdjustment:baselineAdjustment];
    #endif
}

@end
