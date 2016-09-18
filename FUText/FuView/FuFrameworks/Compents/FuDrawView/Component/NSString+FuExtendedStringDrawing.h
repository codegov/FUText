//
//  NSString+FuExtendedStringDrawing.h
//  teamwork
//
//  Created by syq on 14/9/24.
//  Copyright (c) 2014年 chanjet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (FuExtendedStringDrawing)

// Single line, no wrapping. Truncation based on the NSLineBreakMode.
- (CGSize)sizeWithFontOfCompatible:(UIFont *)font;
- (CGSize)sizeWithFontOfCompatible:(UIFont *)font forWidth:(CGFloat)width lineBreakMode:(NSLineBreakMode)lineBreakMode;

// Single line, no wrapping. Truncation based on the NSLineBreakMode.
- (CGSize)drawAtPointOfCompatible:(CGPoint)point withFont:(UIFont *)font;
- (CGSize)drawAtPointOfCompatible:(CGPoint)point forWidth:(CGFloat)width withFont:(UIFont *)font lineBreakMode:(NSLineBreakMode)lineBreakMode;

- (CGSize)sizeWithFontOfCompatible:(UIFont *)font constrainedToSize:(CGSize)size; // Uses NSLineBreakModeWordWrap
- (CGSize)sizeWithFontOfCompatible:(UIFont *)font constrainedToSize:(CGSize)size lineBreakMode:(NSLineBreakMode)lineBreakMode; // NSTextAlignment is not needed to determine size

// Wrapping to fit horizontal and vertical size.
- (CGSize)drawInRectOfCompatible:(CGRect)rect withFont:(UIFont *)font;
- (CGSize)drawInRectOfCompatible:(CGRect)rect withFont:(UIFont *)font lineBreakMode:(NSLineBreakMode)lineBreakMode;
- (CGSize)drawInRectOfCompatible:(CGRect)rect withFont:(UIFont *)font lineBreakMode:(NSLineBreakMode)lineBreakMode alignment:(NSTextAlignment)alignment;

- (CGSize)drawAtPointOfCompatible:(CGPoint)point forWidth:(CGFloat)width withFont:(UIFont *)font fontSize:(CGFloat)fontSize lineBreakMode:(NSLineBreakMode)lineBreakMode baselineAdjustment:(UIBaselineAdjustment)baselineAdjustment;

- (CGSize)drawAtPointOfCompatible:(CGPoint)point forWidth:(CGFloat)width withFont:(UIFont *)font minFontSize:(CGFloat)minFontSize actualFontSize:(CGFloat *)actualFontSize lineBreakMode:(NSLineBreakMode)lineBreakMode baselineAdjustment:(UIBaselineAdjustment)baselineAdjustment;

@end
