//
//  FuLineLayout.h
//  Test
//
//  Created by syq on 14-5-29.
//  Copyright (c) 2014年 com.chanjet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

typedef struct {
    CGFloat ascent;
    CGFloat descent;
    CGFloat width;
    CGFloat leading;
    double trailingWhitespaceWidth;
} FuLineMetrics;

@interface FuLineLayout : NSObject

@property (nonatomic, readonly) CTLineRef     line;        // 行结构
@property (nonatomic, readonly) NSInteger     index;       // 行数
@property (nonatomic, readonly) CGRect        rect;        // 位置大小
@property (nonatomic)           CGFloat       truncationTokenWidth; // 省略宽度
@property (nonatomic, readonly) FuLineMetrics metrics;
@property (nonatomic) CGPoint attachmentOffPoint; // 附件偏移量

@property (nonatomic, readonly) NSRange       stringRange; // 文字范围
@property (nonatomic, strong)   NSAttributedString *attributedString;

@property (nonatomic, getter = isTruncated) BOOL truncated;

@property (nonatomic) CGRect highlightRect;   // 高亮文本的位置大小

- (id)initWithLine:(CTLineRef)line index:(NSInteger)index rect:(CGRect)rect metrics:(FuLineMetrics)metrics;

- (CGRect)rectOfStringWithRange:(NSRange)range;


@end