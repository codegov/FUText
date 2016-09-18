//
//  FuLineLayout.m
//  Test
//
//  Created by syq on 14-5-29.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import "FuLineLayout.h"

@implementation FuLineLayout

- (id)initWithLine:(CTLineRef)line index:(NSInteger)index rect:(CGRect)rect metrics:(FuLineMetrics)metrics
{
    self = [super init];
    if (self) {
        _line    = CFRetain(line);
        _index   = index;
        _rect    = rect;
        _metrics = metrics;
    }
    return self;
}

- (void)dealloc
{
    CFRelease(_line);
}

- (NSRange)stringRange
{
    CFRange stringRange = CTLineGetStringRange(_line);
    return NSMakeRange(stringRange.location, stringRange.length);
}

- (CGRect)rectOfStringWithRange:(NSRange)range
{
    CGRect rect = CGRectZero;
    NSRange tempRange = NSMakeRange(range.location + self.stringRange.location, range.length);
//    NSRange intersectionRange = NSIntersectionRange(self.stringRange, tempRange);
    
//    if (intersectionRange.length <= 0) {
//        intersectionRange = range;
//    }
    
    CTLineRef line = self.line;
    CGFloat startOffset = CTLineGetOffsetForStringIndex(line, tempRange.location, NULL);
    CGFloat endOffset = CTLineGetOffsetForStringIndex(line, NSMaxRange(tempRange), NULL);
    
    rect = self.rect;
    rect.origin.x = startOffset;
    rect.origin.y = 0;
    rect.size.width = endOffset - startOffset;
    
    return rect;
}

@end
